
import 'dart:math' show cos, sin, sqrt, asin;
import 'dart:io';


import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/foundation.dart'; // For compute
import '../models/models.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/cache_service.dart';
import 'package:civic_net/services/notification_service.dart';
import '../features/events/models/event_comment.dart';
import '../core/utils/timeout_extension.dart';

// Top-level function for isolate
List<HelpRequest> parseHelpRequests(List<dynamic> data) {
  return data.map((json) => HelpRequest.fromJson(json)).toList();
}

class SupabaseService {
  // Service for Supabase interactions
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() {
    _client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _setupNotificationListener();
        initVoteCache(); // Initialize the vote cache on login
      } else {
        _notificationChannel?.unsubscribe();
        _notificationChannel = null;
      }
    });
  }

  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _notificationChannel;
  final Set<String> _userVotedIds = {};

  Future<void> initVoteCache() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('announcement_votes')
          .select('announcement_id')
          .eq('user_id', user.id);
      
      final List<dynamic> data = response as List<dynamic>;
      _userVotedIds.clear();
      for (var item in data) {
        _userVotedIds.add(item['announcement_id'] as String);
      }
    } catch (e) {
      logger.e('Error initializing vote cache: $e');
    }
  }

  void _setupNotificationListener() {
    final userId = currentUserId;
    if (userId == null) return;
    
    _notificationChannel?.unsubscribe();
    
    _notificationChannel = _client.channel('public:notifications_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          final newRecord = payload.newRecord;
          final notification = AppNotification.fromJson(newRecord);
          NotificationService().showLocalNotification(
            id: notification.id.hashCode,
            title: notification.title,
            body: notification.body,
          );
        }
      )
      .subscribe();
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  // --- Authentication ---

  Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    ).withServerTimeout();
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    ).withServerTimeout();
  }

  Future<void> signOut() async {
    await _client.auth.signOut().withServerTimeout();
    await CacheService().clear();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email).withServerTimeout();
  }

  Future<void> deleteUserAccount() async {
    // Requires secure Postgres function "delete_user_account()" to exist
    await _client.rpc('delete_user_account').withServerTimeout();
    await signOut();
  }

  // --- Social Auth ---

  sb.User? get currentUser => _client.auth.currentUser;
  // --- Data ---

  // Notifications
  Stream<List<AppNotification>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) return const Stream.empty();
    
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AppNotification.fromJson(json)).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq('id', notificationId).withServerTimeout();
  }

  // Create a new request
  Future<void> createHelpRequest(HelpRequest request) async {
    await _client.from('help_requests').insert({
      'requester_id': _client.auth.currentUser!.id,
      'title': request.title,
      'description': request.description,
      'category': request.category.toString().split('.').last,
      'urgency': request.urgency.toString().split('.').last,
      'lat': request.lat,
      'lng': request.lng,
      'location_name': request.locationName,

      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'open',
    }).withServerTimeout();
  }

  Future<void> updateHelpRequestStatus(String requestId, RequestStatus status) async {
    await _client.from('help_requests').update({
      'status': status.toString().split('.').last,
    }).eq('id', requestId).withServerTimeout();
  }

  // Fetch requests (real-time stream or list)
  Stream<List<HelpRequest>> getHelpRequestsStream() {
    return _client
        .from('help_requests')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => HelpRequest.fromJson(json)).toList());
  }

  // Fetch requests (future)
  Future<List<HelpRequest>> getHelpRequests() async {
    try {
      final response = await _client
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .order('created_at', ascending: false).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      
      // Cache the data with a 15-minute TTL
      await CacheService().put('help_requests', data, ttl: const Duration(minutes: 15));
      
      // Parse in background isolate
      List<HelpRequest> requests = await compute(parseHelpRequests, data);
      
      // Post-processing: Filter blocked users and inject true distance
      final currentUserProfile = await getCurrentUserProfile();
      final blockedUserIds = await getBlockedUserIds();
      
      if (blockedUserIds.isNotEmpty) {
        requests = requests.where((r) => !blockedUserIds.contains(r.requesterId)).toList();
      }

      if (currentUserProfile != null) {
        // Calculate dynamic distances
        if (currentUserProfile.lat != null && currentUserProfile.lng != null && 
            currentUserProfile.lat != 0 && currentUserProfile.lng != 0) {
          
          requests = requests.map((r) {
            if (r.lat != 0 && r.lng != 0) { // Valid request location check
              double distKm = _calculateDistance(r.lat, r.lng, currentUserProfile.lat!, currentUserProfile.lng!);
              return r.copyWith(distance: '${distKm.toStringAsFixed(1)} km');
            }
            return r.copyWith(distance: 'Unknown');
          }).toList();
        } else {
           // User location is unknown, all distances should be unknown
           requests = requests.map((r) => r.copyWith(distance: 'Unknown')).toList();
        }
      }

      return requests;
    } catch (e) {
      logger.e('Error fetching help requests from network', error: e);
      // Fallback to cache
      final cachedData = await CacheService().get('help_requests');
      if (cachedData != null) {
        logger.i('Returning cached help requests');
        final List<dynamic> data = cachedData as List<dynamic>;
        return await compute(parseHelpRequests, data);
      }
      rethrow;
    }
  }

  Future<List<HelpRequest>> getMyHelpRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .eq('requester_id', user.id)
          .order('created_at', ascending: false).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return await compute(parseHelpRequests, data);
    } catch (e) {
      logger.e('Error fetching my help requests', error: e);
      return [];
    }
  }

  /// Fetches all help requests the current user has shown interest in (applied to).
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // Get the user's applications, joined with the help_request details
      final response = await _client
          .from('request_applications')
          .select('id, status, created_at, help_requests(*, profiles:requester_id(name, avatar_url))')
          .eq('applicant_id', user.id)
          .order('created_at', ascending: false).withServerTimeout();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.e('Error fetching my applications: $e');
      return [];
    }
  }

  Future<HelpRequest?> getHelpRequest(String id) async {
    try {
      final response = await _client
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .eq('id', id)
          .single().withServerTimeout();
          
      // Cache individual request
      await CacheService().put('help_request_$id', response);
      
      return HelpRequest.fromJson(response);
    } catch (e) {
       logger.e('Error fetching help request $id from network', error: e);
       // Fallback to cache
       final cachedData = await CacheService().get('help_request_$id');
       if (cachedData != null) {
         logger.i('Returning cached help request $id');
         return HelpRequest.fromJson(cachedData);
       }
      return null;
    }
  }

  // --- Profiles ---

  Future<User?> getUserProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single().withServerTimeout();
      
      // Cache profile
      await CacheService().put('user_profile_$userId', data);

      final skillsList = (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return User(
        id: data['id'],
        name: data['name'] ?? 'Unknown',
        email: '', // Email is not public
        avatarUrl: sanitizeAvatarUrl(data['avatar_url']),
        rating: (data['rating'] ?? 0.0).toDouble(),
        helpCount: data['help_count'] ?? 0,
        reportCount: data['report_count'] ?? 0,
        ratingCount: (data['rating_count'] ?? 0).toInt(),
        points: data['points'] ?? 0,
        skills: skillsList,
        lat: (data['lat'] ?? 0.0).toDouble(),
        lng: (data['lng'] ?? 0.0).toDouble(),
        role: data['role'] ?? 'user',
      );
    } catch (e) {
      logger.e('Error fetching user profile $userId: $e');
      
      // Fallback
      final cachedData = await CacheService().get('user_profile_$userId');
      if (cachedData != null) {
         logger.i('Returning cached profile for $userId');
         final data = cachedData;
         final skillsList = (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];
         return User(
            id: data['id'],
            name: data['name'] ?? 'Unknown',
            email: '',
            avatarUrl: sanitizeAvatarUrl(data['avatar_url']),
            rating: (data['rating'] ?? 0.0).toDouble(),
            helpCount: data['help_count'] ?? 0,
            reportCount: data['report_count'] ?? 0,
            ratingCount: (data['rating_count'] ?? 0).toInt(),
            points: data['points'] ?? 0,
            skills: skillsList,
            lat: (data['lat'] ?? 0.0).toDouble(),
            lng: (data['lng'] ?? 0.0).toDouble(),
            role: data['role'] ?? 'user',
         );
      }
      return null;
    }
  }

  Future<User?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle().withServerTimeout();

      logger.d('DEBUG: Raw profile data: $data'); // DEBUG LOG

      // If data is null (meaning no profile row exists yet), throw to the catch block 
      // or return a default user immediately.
      if (data == null) {
        throw Exception('Profile not found.');
      }

      final skillsData = data['skills'];
       logger.d('DEBUG: Skills data type: ${skillsData.runtimeType}, Value: $skillsData');

      final skillsList = (skillsData as List?)?.map((e) => e.toString()).toList() ?? [];

      return User(
        id: data['id'],
        name: data['name'] ?? user.userMetadata?['name'] ?? 'Unknown',
        email: user.email ?? '',
        avatarUrl: sanitizeAvatarUrl(data['avatar_url']),
        rating: (data['rating'] ?? 0.0).toDouble(),
        helpCount: data['help_count'] ?? 0,
        reportCount: data['report_count'] ?? 0,
        ratingCount: data['rating_count'] ?? 0, // Mapped
        points: data['points'] ?? 0,
        skills: skillsList,
        lat: (data['lat'] ?? 0.0).toDouble(),
        lng: (data['lng'] ?? 0.0).toDouble(),
        role: data['role'] ?? 'user',
      );
    } catch (e, stack) {
        logger.e('DEBUG: Error parsing profile: $e\n$stack'); // DEBUG LOG
        // If profile fetch fails (e.g. no row), return basic auth info
        return User(
          id: user.id,
          name: user.userMetadata?['name'] ?? 'Guest',
          email: user.email ?? '',
          avatarUrl: '',
          rating: 0.0,
          helpCount: 0,
          reportCount: 0,
          ratingCount: 0,
          points: 0,
          skills: [],
        );
    }
  }

  // ... (existing update methods) ...

  // --- Ratings ---

  Future<void> rateUser({
    required String requestId,
    required String ratedUserId,
    required int rating,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('user_ratings').insert({
      'request_id': requestId,
      'rater_id': user.id,
      'rated_id': ratedUserId,
      'rating': rating,
    }).withServerTimeout();
  }

  Future<int?> hasUserRated(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_ratings')
          .select('rating')
          .eq('request_id', requestId)
          .eq('rater_id', user.id)
          .maybeSingle().withServerTimeout();
      
      if (response != null && response['rating'] != null) {
        return response['rating'] as int;
      }
      return null;
    } catch (e) {
      logger.e('Error checking if user rated: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String name, String avatarUrl, List<String> skills) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updates = {
      'id': user.id,
      'name': name,
      'avatar_url': sanitizeAvatarUrl(avatarUrl),
      'skills': skills,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('profiles').upsert(updates).withServerTimeout();
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id).withServerTimeout();
  }



  Future<List<Helper>> getPotentialHelpers(HelpRequest request) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .neq('id', request.requesterId) // exclude the requester
          .limit(20); // Fetch more candidates to rank

      final List<dynamic> data = response as List<dynamic>;
      final List<Helper> helpers = [];

      for (var json in data) {
         final skillsList = (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];
         
         final user = User(
          id: json['id'],
          name: json['name'] ?? 'Unknown',
          email: '', // Email not public
          avatarUrl: sanitizeAvatarUrl(json['avatar_url']),
          rating: (json['rating'] ?? 0.0).toDouble(),
          helpCount: json['help_count'] ?? 0,
          skills: skillsList,
          lat: (json['lat'] ?? 0.0).toDouble(),
          lng: (json['lng'] ?? 0.0).toDouble(),
        );

        // --- Scoring Logic ---
        double score = 0.0;
        List<String> reasons = [];

        // 1. Skill Match (40%)
        // Simple distinct string match; ideally fuzzy matching
        bool hasSkill = user.skills.any((s) => s.toLowerCase().contains(request.category.toString().split('.').last.toLowerCase()));
        if (hasSkill) {
          score += 0.4;
          reasons.add('Matches Category');
        }

        // 2. Distance (50%)
        String distanceStr = 'Unknown';
        if (user.lat != null && user.lng != null && user.lat != 0 && user.lng != 0 && request.lat != 0 && request.lng != 0) {
           double distKm = _calculateDistance(request.lat, request.lng, user.lat!, user.lng!);
           distanceStr = '${distKm.toStringAsFixed(1)} km';
           
           // Score decays with distance: 1.0 at 0km, 0.5 at 10km
           double distanceScore = 1.0 / (1.0 + (distKm / 10.0));
           score += (distanceScore * 0.5);
           
           if (distKm < 5.0) reasons.add('Nearby');
        }

        // 3. Rating (10%)
        score += (user.rating / 5.0) * 0.1;
        if (user.rating > 4.5) reasons.add('Highly Rated');

        helpers.add(Helper(
          user: user,
          matchScore: score,
          distance: distanceStr,
          matchReasons: reasons,
        ));
      }

      // Sort by score descending
      helpers.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      return helpers.take(5).toList(); // Return top 5
    } catch (e) {
      logger.e('Error fetching helpers: $e');
      return [];
    }
  }

  // Haversine formula — returns distance in km
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const toRad = 0.017453292519943295; // pi / 180
    final dLat = (lat2 - lat1) * toRad;
    final dLng = (lng2 - lng1) * toRad;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * toRad) * cos(lat2 * toRad) * sin(dLng / 2) * sin(dLng / 2);
    final clampedA = a > 1.0 ? 1.0 : a;
    return 6371.0 * 2 * asin(sqrt(clampedA)); // Earth radius 6371 km
  }

  // --- Chat ---

  /// Creates a conversation if one doesn't exist, or returns the existing one.
  Future<String> createConversation(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
        final myConversations = await _client
            .from('conversations')
            .select()
            .contains('participant_ids', [user.id]);
        
        for (final conv in myConversations) {
            final participants = List<String>.from(conv['participant_ids']);
            if (participants.contains(otherUserId)) {
                return conv['id'];
            }
        }
    
        final response = await _client.from('conversations').insert({
            'participant_ids': [user.id, otherUserId]
        }).select().single().withServerTimeout();
        
        return response['id'];
    } catch (e) {
        logger.e('Error creating conversation: $e');
        rethrow;
    }
  }

  Future<List<ChatConversation>> getConversations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
        final response = await _client
            .from('conversations')
            .select()
            .contains('participant_ids', [user.id])
            .order('updated_at', ascending: false).withServerTimeout();
            
        final List<ChatConversation> conversations = [];
        
        for (final conv in response) {
            final rawParticipants = conv['participant_ids'];
            if (rawParticipants == null) continue;
            
            final participants = List<String>.from(rawParticipants);
            final otherId = participants.firstWhere((id) => id != user.id, orElse: () => '');
            
            if (otherId.isEmpty) continue;
            
            final profile = await _client.from('profiles').select().eq('id', otherId).maybeSingle().withServerTimeout();
            final name = profile?['name'] ?? 'Unknown User';
            final avatar = profile?['avatar_url'] ?? '';

            final lastMsgRes = await _client
                .from('messages')
                .select()
                .eq('conversation_id', conv['id'])
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle().withServerTimeout();

            final unreadMessagesRes = await _client
                .from('messages')
                .select('id')
                .eq('conversation_id', conv['id'])
                .eq('is_read', false)
                .neq('sender_id', user.id).withServerTimeout();
            
            final int unreadCount = (unreadMessagesRes as List).length;

            final String? dateString = lastMsgRes?['created_at'] ?? conv['updated_at'] ?? conv['created_at'];
            final DateTime messageTime = DateTime.tryParse(dateString ?? '') ?? DateTime.now();
                
            conversations.add(ChatConversation(
                id: conv['id'].toString(),
                otherUserId: otherId,
                otherUserName: name,
                otherUserAvatar: sanitizeAvatarUrl(avatar),
                lastMessage: lastMsgRes?['content'] ?? 'No messages yet',
                lastMessageTime: messageTime,
                unreadCount: unreadCount,
            ));
        }
        return conversations;
    } catch (e, stack) {
        logger.e('Error fetching conversations: $e\n$stack');
        return [];
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Direct updates fail silently due to RLS (updates 0 rows instead of throwing).
      // Therefore, we must use the RPC directly.
      await _client.rpc('mark_conversation_as_read', params: {
        'p_conversation_id': conversationId,
      }).withServerTimeout();
      
      // Force UI update by touching the conversation table
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId).withServerTimeout();
    } catch (e) {
      logger.e('Error marking conversation $conversationId as read via RPC: $e');
      
      // Fallback to direct update just in case the RPC doesn't exist on some environments
      try {
         await _client
            .from('messages')
            .update({'is_read': true})
            .eq('conversation_id', conversationId)
            .eq('is_read', false)
            .neq('sender_id', user.id).withServerTimeout();
            
         await _client.from('conversations').update({
            'updated_at': DateTime.now().toUtc().toIso8601String(),
         }).eq('id', conversationId).withServerTimeout();
      } catch (directError) {
         logger.e('Direct update fallback also failed: $directError');
      }
    }
  }

  Stream<List<Message>> getMessagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }

  Future<void> sendMessage(String conversationId, String content, {String type = 'text'}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'content': content,
      'message_type': type,
    }).withServerTimeout();
    
    await _client.from('conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId).withServerTimeout();
  }

  // --- Interest / Applications ---

  Future<void> applyToRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('request_applications').insert({
      'request_id': requestId,
      'applicant_id': user.id,
      'status': 'pending',
    }).withServerTimeout();
  }

  Future<ApplicationStatus?> getApplicationStatus(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('request_applications')
          .select('status')
          .eq('request_id', requestId)
          .eq('applicant_id', user.id)
          .maybeSingle().withServerTimeout();

      if (response == null) return null;

      return ApplicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == response['status'],
        orElse: () => ApplicationStatus.pending,
      );
    } catch (e) {
      logger.e('Error checking application status: $e');
      return null;
    }
  }

  Future<List<RequestApplication>> getApplicationsForRequest(String requestId) async {
    try {
      final response = await _client
          .from('request_applications')
          .select('*, profiles:applicant_id(name, avatar_url)')
          .eq('request_id', requestId)
          .order('created_at', ascending: false).withServerTimeout();
      
      final List<dynamic> data = response as List<dynamic>;
      logger.d('DEBUG: Fetched ${data.length} applications for request $requestId'); // DEBUG LOG
      return data.map((json) {
        logger.d('DEBUG: App JSON: $json'); // DEBUG LOG
        return RequestApplication.fromJson(json);
      }).toList();
    } catch (e) {
      logger.e('Error fetching applications: $e');
      return [];
    }
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status) async {
    await _client.from('request_applications').update({
      'status': status.toString().split('.').last,
    }).eq('id', applicationId).withServerTimeout();
  }

  // --- Feedback ---

  Future<void> submitFeedback({
    required int rating,
    required String description,
    String? screenshotUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('app_feedback').insert({
      'user_id': user.id,
      'rating': rating,
      'description': description,
      'screenshot_url': screenshotUrl,
    }).withServerTimeout();
  }

  // --- Support Chat ---

  Future<String> createSupportConversation() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    try {
      final response = await _client.from('support_conversations').insert({
        'user_id': user.id,
      }).select().single().withServerTimeout();
      
      return response['id'];
    } catch (e) {
      logger.e('Error creating support conversation: $e');
      rethrow;
    }
  }

  Stream<List<SupportMessage>> getSupportMessagesStream(String conversationId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => SupportMessage.fromJson(json)).toList());
  }

  Future<void> sendSupportMessage(SupportMessage message) async {
    try {
      await _client.from('support_messages').insert(message.toJson()).withServerTimeout();
    } catch (e) {
      logger.e('Error sending support message: $e');
      rethrow;
    }
  }

  Future<void> closeSupportConversation(String id) async {
    try {
      await _client.from('support_conversations').update({
        'status': 'closed',
      }).eq('id', id).withServerTimeout();
    } catch (e) {
      logger.e('Error closing support conversation: $e');
    }
  }

  Future<void> updateSupportFeedback(String id, String feedback) async {
    try {
      await _client.from('support_conversations').update({
        'feedback': feedback,
      }).eq('id', id).withServerTimeout();
    } catch (e) {
      logger.e('Error updating support feedback: $e');
      rethrow;
    }
  }

  Future<String?> uploadFeedbackScreenshot(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final fileName = 'feedback_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = 'feedback/$fileName';

    await _client.storage.from('app-feedback').uploadBinary(
      path,
      file.readAsBytesSync(),
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    ).withServerTimeout();

    return _client.storage.from('app-feedback').getPublicUrl(path);
  }

  // --- Announcements ---

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await _client
          .from('announcements')
          .select('*, profiles:author_id(name, avatar_url)')
          .order('created_at', ascending: false)
          .withServerTimeout();
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final annId = json['id'] as String;
        return Announcement.fromJson(json).copyWith(
          isVotedByMe: _userVotedIds.contains(annId),
        );
      }).toList();
    } catch (e) {
      logger.e('Error fetching announcements: $e');
      return [];
    }
  }

  Stream<List<Announcement>> getAnnouncementsStream() {
    return _client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) {
              final annId = json['id'] as String;
              return Announcement.fromJson(json).copyWith(
                isVotedByMe: _userVotedIds.contains(annId),
              );
            }).toList());
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String category,
    String? imageUrl,
    String? sourceUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('announcements').insert({
      'title': title,
      'content': content,
      'category': category,
      'image_url': imageUrl,
      'source_url': sourceUrl,
      'author_id': user.id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).withServerTimeout();
  }

  Future<String?> uploadAnnouncementImage(File file) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final fileName = 'announcement_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = 'announcements/$fileName';

    await _client.storage.from('announcements').uploadBinary(
      path,
      file.readAsBytesSync(),
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    ).withServerTimeout();

    return _client.storage.from('announcements').getPublicUrl(path);
  }

  Future<void> deleteAnnouncement(String id) async {
    final user = await getCurrentUserProfile();
    if (user == null) throw Exception('Not authenticated');

    if (user.role == 'super_admin') {
      await _client.from('announcements').delete().eq('id', id).withServerTimeout();
      return;
    }

    if (user.role == 'admin') {
      // Fetch the announcement to check author
      final announcement = await _client
          .from('announcements')
          .select('author_id')
          .eq('id', id)
          .maybeSingle()
          .withServerTimeout();
      
      if (announcement != null && announcement['author_id'] == user.id) {
        await _client.from('announcements').delete().eq('id', id).withServerTimeout();
        return;
      }
    }

    throw Exception('Permission denied: You can only delete your own announcements.');
  }

  Future<void> verifyAnnouncement(String id, bool isVerified) async {
    final user = await getCurrentUserProfile();
    if (user?.role != 'super_admin') {
      throw Exception('Permission denied: Only super admins can verify announcements.');
    }

    await _client.from('announcements').update({
      'is_verified': isVerified,
    }).eq('id', id).withServerTimeout();
  }

  Future<void> toggleAnnouncementVote(String announcementId, bool shouldVote) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (shouldVote) {
      await _client.from('announcement_votes').insert({
        'announcement_id': announcementId,
        'user_id': user.id,
      }).withServerTimeout();
      _userVotedIds.add(announcementId);
    } else {
      await _client.from('announcement_votes').delete().match({
        'announcement_id': announcementId,
        'user_id': user.id,
      }).withServerTimeout();
      _userVotedIds.remove(announcementId);
    }
  }

  Future<Map<String, dynamic>> getAnnouncementVotesInfo(String announcementId) async {
    final user = _client.auth.currentUser;
    
    // Get total count
    final countRes = await _client
        .from('announcement_votes')
        .select('id')
        .eq('announcement_id', announcementId);
    
    final count = countRes.length;

    // Check if user voted
    bool userVoted = false;
    if (user != null) {
      final userVoteRes = await _client
          .from('announcement_votes')
          .select('id')
          .match({
            'announcement_id': announcementId,
            'user_id': user.id,
          })
          .maybeSingle();
      
      userVoted = userVoteRes != null;
    }

    return {
      'count': count,
      'user_voted': userVoted,
    };
  }

  // --- Realtime ---

  RealtimeChannel subscribeToHelpRequests(Function() callback) {
    return _client
      .channel('public:help_requests')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'help_requests',
        callback: (payload) {
          logger.i('Realtime update detected in help_requests');
          callback();
        },
      )
      .subscribe();
  }

  Future<void> markAllConversationsAsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.rpc('mark_all_conversations_as_read').withServerTimeout();
    } catch (e) {
      logger.e('Error marking all conversations as read: $e');
      throw Exception('Failed to mark all as read: $e');
    }
  }

  // --- Blocking & Reporting ---

  Future<void> blockUser(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _client.from('blocked_users').insert({
      'blocker_id': user.id,
      'blocked_id': userId,
    }).withServerTimeout();
  }

  Future<void> unblockUser(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('blocked_users').delete().match({
      'blocker_id': user.id,
      'blocked_id': userId,
    }).withServerTimeout();
  }

  Future<bool> isUserBlocked(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('blocked_users')
        .select()
        .eq('blocker_id', user.id)
        .eq('blocked_id', userId)
        .maybeSingle().withServerTimeout();
    
    return response != null;
  }

  Future<List<String>> getBlockedUserIds() async {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('blocked_users')
          .select('blocked_id')
          .eq('blocker_id', user.id);
      
      final List<dynamic> data = response as List<dynamic>;
      return data.map((e) => e['blocked_id'] as String).toList();
  }

  Future<void> reportUser(String userId, String reason) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Block the user first (as per requirement: "block and report")
    // Check if already blocked to avoid error
    final isBlocked = await isUserBlocked(userId);
    if (!isBlocked) {
      await blockUser(userId);
    }

    await _client.from('user_reports').insert({
      'reporter_id': user.id,
      'reported_id': userId,
      'reason': reason,
    }).withServerTimeout();
  }

  Future<void> completeHelpRequest(String requestId, String helperId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Mark the request as completed and award points to both parties
    await _client.rpc('complete_help_request', params: {
      'p_request_id': requestId,
      'p_helper_id': helperId,
    }).withServerTimeout();

    // 2. Increment the helper's help_count and award bonus points
    //    Uses a Postgres RPC to safely do an atomic increment.
    //    Run this in your Supabase SQL Editor if not already created:
    //
    //    CREATE OR REPLACE FUNCTION increment_helper_stats(p_helper_id uuid, p_points int)
    //    RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
    //    BEGIN
    //      UPDATE profiles
    //      SET help_count = help_count + 1,
    //          points = points + p_points
    //      WHERE id = p_helper_id;
    //    END;
    //    $$;
    try {
      await _client.rpc('increment_helper_stats', params: {
        'p_helper_id': helperId,
        'p_points': 10, // Same bonus points awarded for helping
      }).withServerTimeout();
    } catch (e) {
      // Fallback: direct update if the RPC doesn't exist yet
      logger.w('increment_helper_stats RPC not found, falling back to direct update: $e');
      await _client.rpc('increment', params: {
        'table': 'profiles',
        'id': helperId,
      }).catchError((_) async {
        // Last resort: raw update
        final current = await _client.from('profiles').select('help_count, points').eq('id', helperId).maybeSingle().withServerTimeout();
        if (current != null) {
          await _client.from('profiles').update({
            'help_count': (current['help_count'] ?? 0) + 1,
            'points': (current['points'] ?? 0) + 10,
          }).eq('id', helperId).withServerTimeout();
        }
      });
    }
  }

  // --- Local Events ---

  Future<List<LocalEvent>> getLocalEvents() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final currentUserProfile = await getCurrentUserProfile();
      
      double userLat = currentUserProfile?.lat ?? 0.0;
      double userLng = currentUserProfile?.lng ?? 0.0;

      // ... (Location fetch logic remains same) ...
      if (userLat == 0.0 || userLng == 0.0) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 3),
              ),
            );
            if (position.latitude != 0 || position.longitude != 0) {
              userLat = position.latitude;
              userLng = position.longitude;
            }
          }
        } catch (e) {
          logger.w('Fast location fetch for local events failed: $e');
        }
      }

      // Step 1: Fetch all events
      final response = await _client
          .from('local_events')
          .select('*, profiles:creator_id(name, avatar_url)')
          .order('event_date', ascending: true).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      
      // Step 2: Fetch all attendees for these events in one go
      final eventIds = data.map((e) => e['id']).toList();
      final attendeesResponse = await _client
          .from('event_attendees')
          .select('event_id, user_id')
          .inFilter('event_id', eventIds).withServerTimeout();
      
      final List<dynamic> allAttendees = attendeesResponse as List<dynamic>;
      
      // Group attendees by event_id for easy lookup
      final Map<String, List<String>> eventAttendeesMap = {};
      for (var attendee in allAttendees) {
        final eid = attendee['event_id'].toString();
        final uid = attendee['user_id'].toString();
        eventAttendeesMap.putIfAbsent(eid, () => []).add(uid);
      }

      final List<LocalEvent> events = [];
      const double radiusKm = 100.0;
      final blockedUserIds = await getBlockedUserIds();

      for (var json in data) {
        final String eventId = json['id'].toString();
        final creatorId = json['creator_id'];

        // Filter blocked users
        if (blockedUserIds.contains(creatorId)) continue;
        
        final eventLat = (json['lat'] ?? 0).toDouble();
        final eventLng = (json['lng'] ?? 0).toDouble();

        // Filtering logic
        if (creatorId != currentUserId && userLat != 0 && userLng != 0 && eventLat != 0 && eventLng != 0) {
          final distance = _calculateDistance(userLat, userLng, eventLat, eventLng);
          if (distance > radiusKm) continue;
        }

        final attendees = eventAttendeesMap[eventId] ?? [];
        final attendeeCount = attendees.length;
        final bool isUserAttending = currentUserId != null && attendees.contains(currentUserId);

        events.add(LocalEvent.fromJson({
          ...json,
          'attendee_count': attendeeCount,
          'is_user_attending': isUserAttending,
        }));
      }

      return events;
    } catch (e) {
      logger.e('Error fetching local events: $e');
      return [];
    }
  }

  Future<void> createLocalEvent(LocalEvent event) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _client.from('local_events').insert({
      'title': event.title,
      'description': event.description,
      'event_date': event.eventDate.toIso8601String(),
      'lat': event.lat,
      'lng': event.lng,
      'location_name': event.locationName,
      'creator_id': user.id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).select().single().withServerTimeout();

    final eventId = response['id'];

    // Auto-RSVP the creator
    await _client.from('event_attendees').insert({
      'event_id': eventId,
      'user_id': user.id,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).withServerTimeout();
  }

  Future<void> rsvpToEvent(String eventId, bool isJoining) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (isJoining) {
      await _client.from('event_attendees').insert({
        'event_id': eventId,
        'user_id': user.id,
      }).withServerTimeout();
    } else {
      await _client.from('event_attendees').delete().match({
        'event_id': eventId,
        'user_id': user.id,
      }).withServerTimeout();
    }
  }

  Future<void> deleteLocalEvent(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // 1. Fetch the event first to get its raw ID and verify owner
      // This handles cases where eventId (String) might map to an int8 in DB
      final existingEvent = await _client
          .from('local_events')
          .select('id, creator_id')
          .eq('id', eventId)
          .maybeSingle()
          .withServerTimeout();

      if (existingEvent == null) return;

      final dbId = existingEvent['id'];
      final dbCreatorId = existingEvent['creator_id'];

      if (dbCreatorId != user.id) {
        throw Exception('Permission denied: You are not the creator of this event.');
      }

      // 2. Delete associated attendees using the RAW ID
      await _client
          .from('event_attendees')
          .delete()
          .eq('event_id', dbId)
          .withServerTimeout();
      
      // 3. Delete the event using the RAW ID
      final response = await _client
          .from('local_events')
          .delete()
          .eq('id', dbId)
          .select()
          .withServerTimeout();

      if ((response as List).isEmpty) {
        throw Exception('Access Denied: Your database "Delete" policy is blocking this action. Please check your Supabase RLS settings.');
      }
    } catch (e) {
      logger.e('Database error during deletion: $e');
      rethrow;
    }
  }

  // --- Event Comments ---

  Future<List<EventComment>> getEventComments(String eventId) async {
    try {
      final response = await _client
          .from('event_comments')
          .select('*, profiles:user_id(name, avatar_url)')
          .eq('event_id', eventId)
          .order('created_at', ascending: true)
          .withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      final List<EventComment> allComments = data.map((json) => EventComment.fromJson(json)).toList();
      
      // Build threaded structure
      final List<EventComment> topLevelComments = [];
      final Map<String, List<EventComment>> repliesMap = {};

      for (var comment in allComments) {
        if (comment.parentId == null) {
          topLevelComments.add(comment);
        } else {
          repliesMap.putIfAbsent(comment.parentId!, () => []).add(comment);
        }
      }

      // Attach replies to parents (one level deep as per requirement for host reply)
      return topLevelComments.map((parent) {
        return parent.copyWith(replies: repliesMap[parent.id] ?? []);
      }).toList();
    } catch (e) {
      logger.e('Error fetching event comments: $e');
      return [];
    }
  }

  Future<void> postEventComment({
    required String eventId,
    required String content,
    String? parentId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('event_comments').insert({
      'event_id': eventId,
      'user_id': user.id,
      'content': content,
      'parent_id': parentId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    }).withServerTimeout();
  }

  Future<void> deleteEventComment(String commentId) async {
    await _client.from('event_comments').delete().eq('id', commentId).withServerTimeout();
  }

  // --- Admin & Verification ---

  Future<void> submitVerificationRequest(String reason) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('verification_requests').insert({
      'user_id': user.id,
      'reason': reason,
      'status': 'pending',
    }).withServerTimeout();
  }

  /// Get count of pending verification requests
  Future<int> getPendingRequestsCount() async {
    try {
      final response = await _client
          .from('verification_requests')
          .select('id')
          .eq('status', 'pending');
      
      return (response as List).length;
    } catch (e) {
      logger.e('Error getting pending requests count: $e');
      return 0;
    }
  }

  /// Get pending verification requests for admin review
  Future<List<VerificationRequest>> getPendingVerificationRequests() async {
    try {
      final response = await _client
          .from('verification_requests')
          .select('*, profiles:user_id(name, avatar_url)')
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => VerificationRequest.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching verification requests: $e');
      return [];
    }
  }

  Future<void> updateUserRole(String userId, String role) async {
    final response = await _client
        .from('profiles')
        .update({'role': role})
        .eq('id', userId)
        .select()
        .withServerTimeout();
    
    if ((response as List).isEmpty) {
      throw Exception('Failed to update user role. You might not have permission.');
    }
  }

  Future<void> updateVerificationStatus(String requestId, String status) async {
    await _client
        .from('verification_requests')
        .update({'status': status})
        .eq('id', requestId)
        .withServerTimeout();
  }

  Future<Map<String, dynamic>> checkVerificationEligibility() async {
    final user = _client.auth.currentUser;
    if (user == null) return {'eligible': false, 'reason': 'Not authenticated'};

    try {
      // 1. Check for pending requests
      final pendingResponse = await _client
          .from('verification_requests')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'pending')
          .maybeSingle();
      
      if (pendingResponse != null) {
        return {'eligible': false, 'reason': 'pending'};
      }

      // 2. Check for latest request (approved or rejected)
      final latestRequestResponse = await _client
          .from('verification_requests')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(1);
      
      final List<dynamic> historyData = latestRequestResponse as List<dynamic>;

      if (historyData.isNotEmpty) {
        final lastRequest = historyData[0];
        final String status = lastRequest['status'];

        if (status == 'rejected') {
          // Check for cooldown (3 rejections)
          final allRejections = await _client
              .from('verification_requests')
              .select()
              .eq('user_id', user.id)
              .eq('status', 'rejected');
          
          final List<dynamic> rejectionData = allRejections as List<dynamic>;

          if (rejectionData.length >= 3) {
            final lastRejection = DateTime.parse(rejectionData[0]['updated_at']);
            final cooldownEnd = lastRejection.add(const Duration(days: 30));
            
            if (DateTime.now().isBefore(cooldownEnd)) {
              return {
                'eligible': false, 
                'reason': 'cooldown',
                'cooldownEnd': cooldownEnd,
              };
            }
          }

          return {
            'eligible': true,
            'lastStatus': 'rejected',
            'rejectionCount': rejectionData.length,
          };
        } else if (status == 'approved') {
          final currentUserProfile = await getCurrentUserProfile();
          if (currentUserProfile?.role != 'admin' && currentUserProfile?.role != 'super_admin') {
            return {
              'eligible': true,
              'lastStatus': 'approved_pending_sync',
            };
          }

          return {
            'eligible': false,
            'lastStatus': 'approved',
          };
        }
      }
      return {'eligible': true};
    } catch (e) {
      logger.e('Error checking verification eligibility: $e');
      return {'eligible': false, 'reason': 'error'};
    }
  }
}
