
import 'dart:math' show cos, sin, sqrt, asin;
import 'dart:io';
import 'dart:convert';


import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/foundation.dart'; // For compute
import '../models/models.dart';
import 'package:civic_net/services/logger_service.dart';
import 'package:civic_net/services/cache_service.dart';
import 'package:civic_net/services/notification_service.dart';
import 'package:civic_net/services/encryption_service.dart';
import 'package:civic_net/services/ai_service.dart';
import '../features/request/domain/entities/help_request_entity.dart';

import '../features/events/models/event_comment.dart';
import '../core/utils/timeout_extension.dart';

// Top-level function for isolate
List<HelpRequest> parseHelpRequests(List<dynamic> data) {
  return data.map((json) => HelpRequest.fromJson(json)).toList();
}

List<CommunityAsset> parseCommunityAssets(List<dynamic> data) {
  return data.map((json) => CommunityAsset.fromJson(json)).toList();
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

  Future<AuthResponse> signUp(String email, String password,
      String name) async {
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

  // --- Session Management ---

  /// Extracts the exact session_id from the local JWT token for precise 'This Device' identification
  String? get currentSessionId {
    final token = _client.auth.currentSession?.accessToken;
    if (token == null) return null;
    
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      String payloadStr = parts[1];
      // Pad base64 string if necessary
      while (payloadStr.length % 4 != 0) {
        payloadStr += '=';
      }
      
      final payloadStrDecoded = utf8.decode(base64Url.decode(payloadStr));
      final payload = jsonDecode(payloadStrDecoded);
      return payload['session_id'] as String?;
    } catch (e) {
      logger.e('Failed to parse JWT for session_id: $e');
      return null;
    }
  }

  Future<List<UserSession>> getUserSessions() async {
    try {
      final response = await _client.rpc('get_user_sessions').withServerTimeout();
      final data = response as List<dynamic>;
      return data.map((json) => UserSession.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching user sessions: $e');
      rethrow; // Rethrow so the UI can catch and display the error
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      await _client.rpc('revoke_session', params: {'session_id': sessionId}).withServerTimeout();
      logger.d('Session $sessionId revoked.');
    } catch (e) {
      logger.e('Error revoking session: $e');
      rethrow;
    }
  }

  Future<void> revokeAllOtherSessions() async {
    try {
      await _client.rpc('revoke_all_other_sessions').withServerTimeout();
      logger.d('All other sessions revoked.');
    } catch (e) {
      logger.e('Error revoking all other sessions: $e');
      rethrow;
    }
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
        .map((data) =>
        data.map((json) => AppNotification.fromJson(json)).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.from('notifications').update({'is_read': true}).eq(
        'id', notificationId).withServerTimeout();
  }

  // Create a new request
  Future<void> createHelpRequest(HelpRequest request) async {
    final userId = _client.auth.currentUser!.id;
    final categoryStr = request.category
        .toString()
        .split('.')
        .last;

    // Generate AI embedding for "True AI" matching
    final embedding = await AiService().generateRequestEmbedding(
        request.title,
        request.description,
        categoryStr
    );

    await _client.from('help_requests').insert({
      'requester_id': userId,
      'title': request.title,
      'description': request.description,
      'category': categoryStr,
      'urgency': request.urgency
          .toString()
          .split('.')
          .last,
      'lat': request.lat,
      'lng': request.lng,
      'location_name': request.locationName,
      'embedding': embedding, // Save the vector
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'open',
    }).withServerTimeout();
  }


  Future<void> updateHelpRequestStatus(String requestId,
      RequestStatus status) async {
    await _client.from('help_requests').update({
      'status': status
          .toString()
          .split('.')
          .last,
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

  // Fetch requests (future) with optional radius and center
  Future<List<HelpRequest>> getHelpRequests({double? centerLat, double? centerLng, double? radiusKm}) async {
    try {
      final query = _client
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url, lat, lng)')
          .order('created_at', ascending: false);

      final response = await query.withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;

      // Cache the data with a 15-minute TTL
      await CacheService().put(
          'help_requests', data, ttl: const Duration(minutes: 15));

      // Parse in background isolate
      List<HelpRequest> requests = await compute(parseHelpRequests, data);

      // Post-processing: Filter blocked users and inject true distance
      final currentUserProfile = await getCurrentUserProfile();
      final blockedUserIds = await getBlockedUserIds();

      if (blockedUserIds.isNotEmpty) {
        requests =
            requests
                .where((r) => !blockedUserIds.contains(r.requesterId))
                .toList();
      }

      // Dynamic distance calculation and filtering
      final lat = centerLat ?? currentUserProfile?.lat;
      final lng = centerLng ?? currentUserProfile?.lng;

      if (lat != null && lng != null && lat != 0 && lng != 0) {
        requests = requests.map((r) {
          if (r.lat != 0 && r.lng != 0) {
            double distKm = _calculateDistance(r.lat, r.lng, lat, lng);
            return r.copyWith(distance: '${distKm.toStringAsFixed(1)} km');
          }
          return r.copyWith(distance: 'Unknown');
        }).toList();

        // Apply radius filter if provided
        if (radiusKm != null) {
          requests = requests.where((r) {
            if (r.lat == 0 || r.lng == 0) return false;
            double dist = _calculateDistance(r.lat, r.lng, lat, lng);
            return dist <= radiusKm;
          }).toList();
        }
      } else {
        requests = requests.map((r) => r.copyWith(distance: 'Unknown')).toList();
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
          .select(
          'id, status, created_at, help_requests(*, profiles:requester_id(name, avatar_url))')
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

      final skillsList = (data['skills'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      return User(
        id: data['id'],
        name: data['name'] ?? 'Unknown',
        email: '',
        // Email is not public
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
        isPublicProfile: data['is_public_profile'] ?? true,
        showNeighborhood: data['show_neighborhood'] ?? true,
        showImpactStats: data['show_impact_stats'] ?? true,
        showAchievements: data['show_achievements'] ?? true,
      );
    } catch (e) {
      logger.e('Error fetching user profile $userId: $e');

      // Fallback
      final cachedData = await CacheService().get('user_profile_$userId');
      if (cachedData != null) {
        logger.i('Returning cached profile for $userId');
        final data = cachedData;
        final skillsList = (data['skills'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        return User(
          id: data['id'],
          name: data['name'] ?? 'Unknown',
          email: '',
          avatarUrl: sanitizeAvatarUrl(data['avatar_url']),
          rating: (data['rating'] ?? 0.0).toDouble(),
          helpCount: data['help_count'] ?? 0,
          reportCount: data['report_count'] ?? 0,
          ratingCount: (data['rating_count'] ?? 0).toInt(),
          points: (data['points'] ?? 0).toInt(),
          skills: skillsList,
          lat: (data['lat'] ?? 0.0).toDouble(),
          lng: (data['lng'] ?? 0.0).toDouble(),
          role: data['role'] ?? 'user',
          isPublicProfile: data['is_public_profile'] ?? true,
          showNeighborhood: data['show_neighborhood'] ?? true,
          showImpactStats: data['show_impact_stats'] ?? true,
          showAchievements: data['show_achievements'] ?? true,
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

      if (data == null) throw Exception('Profile not found.');

      return User.fromMap(data, email: user.email);
    } catch (e, stack) {
      logger.e('DEBUG: Error parsing profile: $e\n$stack');
      return User(
        id: user.id,
        name: user.userMetadata?['name'] ?? 'Guest',
        email: user.email ?? '',
        avatarUrl: '',
        isPublicProfile: true,
        showNeighborhood: true,
        showImpactStats: true,
        showAchievements: true,
      );
    }
  }

  Future<List<User>> getActiveNeighbors({double? centerLat, double? centerLng, double? radiusKm}) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('show_neighborhood', true)
          .not('lat', 'is', null)
          .not('lng', 'is', null)
          .withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      List<User> neighbors = data.map((json) => User.fromMap(json)).toList();

      final currentUserProfile = await getCurrentUserProfile();
      final lat = centerLat ?? currentUserProfile?.lat;
      final lng = centerLng ?? currentUserProfile?.lng;

      if (lat != null && lng != null && lat != 0 && lng != 0 && radiusKm != null) {
        neighbors = neighbors.where((n) {
          if (n.lat == null || n.lng == null) return false;
          double dist = _calculateDistance(n.lat!, n.lng!, lat, lng);
          return dist <= radiusKm;
        }).toList();
      }

      return neighbors;
    } catch (e) {
      logger.e('Error fetching active neighbors: $e');
      return [];
    }
  }

  /// Real-time stream for the current user's profile with robust Future fallback.
  Stream<User?> getCurrentUserProfileStream() async* {
    final user = _client.auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    // 1. Initial Fetch (Robust Future)
    // We immediately fetch and yield the profile via a standard request to ensure the UI
    // has data even if the real-time subscription is slow or times out.
    try {
      final initialProfile = await getCurrentUserProfile();
      yield initialProfile;
    } catch (e) {
      logger.e('Initial profile fetch failed: $e');
    }

    // 2. Real-time Subscription (Background Upgrade)
    // We attempt to subscribe to changes. If it times out, we log a warning but DO NOT
    // emit an error, allowing the app to stay on the initial fetch result.
    try {
      yield* _client
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .map((data) {
            try {
              if (data.isEmpty) return null;
              final row = data.first;
              return User.fromMap(row, email: user.email);
            } catch (e) {
              logger.e('Error mapping profile stream: $e');
              return null;
            }
          })
          .handleError((error) {
            if (error.toString().contains('RealtimeSubscribeException')) {
              logger.w('Profile real-time subscription timed out. Staying on fetched data.');
            } else {
              logger.e('Profile stream encountered error: $error');
            }
            return null;
          });
    } catch (e) {
      logger.w('Failed to initialize profile real-time stream: $e');
    }
  }

  Future<void> updatePrivacySettings(Map<String, bool> settings) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (settings.containsKey('public')) {
      updates['is_public_profile'] = settings['public']!;
    }
    if (settings.containsKey('location')) {
      updates['show_neighborhood'] = settings['location']!;
    }
    if (settings.containsKey('stats')) {
      updates['show_impact_stats'] = settings['stats']!;
    }
    if (settings.containsKey('badges')) {
      updates['show_achievements'] = settings['badges']!;
    }

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id)
        .withServerTimeout();
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

  Future<void> updateUserProfile(String name, String avatarUrl,
      List<String> skills) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Generate AI embedding for "True AI" matching
    final embedding = await AiService().generateProfileEmbedding(name, skills);

    final updates = {
      'id': user.id,
      'name': name,
      'avatar_url': sanitizeAvatarUrl(avatarUrl),
      'skills': skills,
      'embedding': embedding, // Save the vector
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
      // 1. Generate Query Embedding for the request if it doesn't have one
      final queryEmbedding = await AiService().generateRequestEmbedding(
        request.title,
        request.description,
        request.category
            .toString()
            .split('.')
            .last,
        isQuery: true, // This is a search query
      );


      if (queryEmbedding == null) {
        logger.w(
            'Semantic Match: Failed to generate embedding, falling back to basic fetching.');
        return []; // Or implement basic fallback here
      }

      // 2. Call semantic matching RPC "match_helpers_v3"
      final response = await _client.rpc('match_helpers_v3', params: {
        'query_embedding': queryEmbedding,
        'match_threshold': 0.5,
        'match_count': 5,
        'excluded_id': request.requesterId,
      }).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      final List<Helper> helpers = [];

      for (var json in data) {
        final skillsList = (json['skills'] as List?)
            ?.map((e) => e.toString())
            .toList() ?? [];

        final user = User(
          id: json['id'],
          name: json['name'] ?? 'Unknown',
          email: '',
          avatarUrl: sanitizeAvatarUrl(json['avatar_url']),
          rating: (json['rating'] ?? 0.0).toDouble(),
          helpCount: json['help_count'] ?? 0,
          skills: skillsList,
          lat: (json['lat'] ?? 0.0).toDouble(),
          lng: (json['lng'] ?? 0.0).toDouble(),
          isPublicProfile: true,
          // Defaulting if not in RPC
          showNeighborhood: true,
          showImpactStats: true,
          showAchievements: true,
        );

        // Calculate distance for the UI
        String distanceStr = 'Unknown';
        if (user.lat != null && user.lng != null && user.lat != 0 &&
            user.lng != 0 && request.lat != 0 && request.lng != 0) {
          double distKm = _calculateDistance(
              request.lat, request.lng, user.lat!, user.lng!);
          distanceStr = '${distKm.toStringAsFixed(1)} km';
        }

        helpers.add(Helper(
          user: user,
          matchScore: (json['similarity'] ?? 0.0).toDouble(),
          distance: distanceStr,
          matchReasons: [
            'Semantic Match',
            if ((json['similarity'] ?? 0.0) > 0.8) 'Highly Relevant'
          ],
        ));
      }

      return helpers;
    } catch (e) {
      logger.e('Error fetching helpers via semantic match: $e');
      return [];
    }
  }

  /// True AI: Fetch help requests matching the user's skills using vector similarity
  Future<List<HelpRequest>> getRecommendedHelpRequests() async {
    final user = await getCurrentUserProfile();
    if (user == null) return [];
    
    logger.d('AI MATCH DEBUG: Checking recommendations for User "${user.name}" with Skills: ${user.skills}');

    try {
      final profileEmbedding = await AiService().generateProfileEmbedding(
        user.name,
        user.skills,
        isQuery: true, // This is a search query
      );

      if (profileEmbedding == null) return [];

      final response = await _client.rpc('match_requests_v3', params: {
        'query_embedding': profileEmbedding,
        'match_threshold': 0.3,
        // Restored to a more realistic similarity threshold
        'match_count': 10,
        'excluded_id': user.id,
        // Exclude the current user's own requests
      }).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final req = HelpRequest.fromJson(json);
        return req.copyWith(
            aiRelevanceScore: (json['similarity'] ?? 0.0).toDouble());
      }).toList();
    } catch (e) {
      logger.e('Error fetching recommended requests: $e');
      return [];
    }
  }


  // --- Community Assets Discovery ---

  Future<List<CommunityAsset>> getCommunityAssets({double? centerLat, double? centerLng, double? radiusKm, String? category}) async {
    try {
      var query = _client.from('community_assets').select('*, profiles:owner_id(name, avatar_url, lat, lng)');
      
      if (category != null && category != 'All') {
        query = query.eq('category', category);
      }

      final response = await query.neq('status', 'private').order('created_at', ascending: false).withServerTimeout();
      final List<dynamic> data = response as List<dynamic>;
      List<CommunityAsset> assets = await compute(parseCommunityAssets, data);

      final currentUserProfile = await getCurrentUserProfile();
      final lat = centerLat ?? currentUserProfile?.lat;
      final lng = centerLng ?? currentUserProfile?.lng;

      if (lat != null && lng != null && lat != 0 && lng != 0 && radiusKm != null) {
        assets = assets.where((a) {
          if (a.lat == null || a.lng == null) return false;
          double dist = _calculateDistance(a.lat!, a.lng!, lat, lng);
          return dist <= radiusKm;
        }).toList();
      }

      return assets;
    } catch (e) {
      logger.e('Error fetching community assets: $e');
      return [];
    }
  }

  // Haversine formula — returns distance in km
  double _calculateDistance(double lat1, double lng1, double lat2,
      double lng2) {
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
        final otherId = participants.firstWhere((id) => id != user.id,
            orElse: () => '');

        if (otherId.isEmpty) continue;

        // Check for point-in-time deletion
        final Map<String, dynamic> deletionTimestamps = Map<String, dynamic>.from(conv['user_deletion_timestamps'] ?? {});
        final String? lastDeletedAtStr = deletionTimestamps[user.id];
        final DateTime? lastDeletedAt = lastDeletedAtStr != null ? DateTime.tryParse(lastDeletedAtStr) : null;

        final profile = await _client.from('profiles').select().eq(
            'id', otherId).maybeSingle().withServerTimeout();
        final name = profile?['name'] ?? 'Unknown User';
        final avatar = profile?['avatar_url'] ?? '';

        // Only fetch messages sent AFTER the last deletion timestamp
        var lastMsgQuery = _client
            .from('messages')
            .select()
            .eq('conversation_id', conv['id']);
        
        if (lastDeletedAt != null) {
          lastMsgQuery = lastMsgQuery.gt('created_at', lastDeletedAt.toUtc().toIso8601String());
        }

        final lastMsgRes = await lastMsgQuery
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle().withServerTimeout();

        // If no message appears after deletion, the conversation is effectively hidden
        if (lastMsgRes == null && lastDeletedAt != null) {
          continue;
        }

        final unreadMessagesRes = await _client
            .from('messages')
            .select('id')
            .eq('conversation_id', conv['id'])
            .eq('is_read', false)
            .neq('sender_id', user.id).withServerTimeout();

        final int unreadCount = (unreadMessagesRes as List).length;

        final String? dateString = lastMsgRes?['created_at'] ??
            conv['updated_at'] ?? conv['created_at'];
        final DateTime messageTime = DateTime.tryParse(dateString ?? '') ??
            DateTime.now();

        conversations.add(ChatConversation(
          id: conv['id'].toString(),
          otherUserId: otherId,
          otherUserName: name,
          otherUserAvatar: sanitizeAvatarUrl(avatar),
          lastMessage: lastMsgRes != null && lastMsgRes['content'] != null
              ? EncryptionService().decryptPayload(lastMsgRes['content'])
              : 'No messages yet',
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

  Future<void> deleteConversation(String conversationId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      // Fetch current deletion timestamps
      final response = await _client
          .from('conversations')
          .select('user_deletion_timestamps')
          .eq('id', conversationId)
          .single().withServerTimeout();
      
      final Map<String, dynamic> timestamps = Map<String, dynamic>.from(response['user_deletion_timestamps'] ?? {});
      timestamps[user.id] = DateTime.now().toUtc().toIso8601String();

      await _client.from('conversations').update({
        'user_deletion_timestamps': timestamps,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId).withServerTimeout();
    } catch (e) {
      logger.e('Error deleting conversation: $e');
      rethrow;
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
      logger.e(
          'Error marking conversation $conversationId as read via RPC: $e');

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
    final user = _client.auth.currentUser;
    if (user == null) return const Stream.empty();

    // We fetch the conversation to get its deletion timestamp, then fetch messages
    return _client
        .from('conversations')
        .stream(primaryKey: ['id'])
        .eq('id', conversationId)
        .asyncMap((convList) async {
          if (convList.isEmpty) return <Message>[];
          final conv = convList.first;
          final Map<String, dynamic> deletionTimestamps = Map<String, dynamic>.from(conv['user_deletion_timestamps'] ?? {});
          final String? lastDeletedAtStr = deletionTimestamps[user.id];
          final DateTime? lastDeletedAt = lastDeletedAtStr != null ? DateTime.tryParse(lastDeletedAtStr) : null;
          
          // Now fetch the actual messages
          final messagesRes = await _client
              .from('messages')
              .select()
              .eq('conversation_id', conversationId)
              .order('created_at', ascending: true).withServerTimeout();
          
          final List<dynamic> data = messagesRes as List<dynamic>;
          return data.map((json) {
            final mutableJson = Map<String, dynamic>.from(json);
            if (mutableJson['content'] != null) {
              mutableJson['content'] =
                  EncryptionService().decryptPayload(mutableJson['content']);
            }
            return Message.fromJson(mutableJson);
          }).where((m) {
            if (lastDeletedAt == null) return true;
            return m.createdAt.isAfter(lastDeletedAt);
          }).toList();
        });
  }

  Future<void> sendMessage(String conversationId, String content,
      {String type = 'text', String? replyToId}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final encryptedContent = EncryptionService().encryptPayload(content);

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'content': encryptedContent,
      'message_type': type,
      'reply_to_id': replyToId,
    }).withServerTimeout();

    await _client.from('conversations').update({
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', conversationId).withServerTimeout();
  }

  Future<void> deleteMessage(String messageId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('messages').update({
      'is_deleted': true,
      'content': EncryptionService().encryptPayload('This message was deleted'),
    }).eq('id', messageId).eq('sender_id', user.id).withServerTimeout();
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
            (e) =>
        e
            .toString()
            .split('.')
            .last == response['status'],
        orElse: () => ApplicationStatus.pending,
      );
    } catch (e) {
      logger.e('Error checking application status: $e');
      return null;
    }
  }

  Future<List<RequestApplication>> getApplicationsForRequest(
      String requestId) async {
    try {
      final response = await _client
          .from('request_applications')
          .select('*, profiles:applicant_id(name, avatar_url)')
          .eq('request_id', requestId)
          .order('created_at', ascending: false).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      logger.d('DEBUG: Fetched ${data
          .length} applications for request $requestId'); // DEBUG LOG
      return data.map((json) {
        logger.d('DEBUG: App JSON: $json'); // DEBUG LOG
        return RequestApplication.fromJson(json);
      }).toList();
    } catch (e) {
      logger.e('Error fetching applications: $e');
      return [];
    }
  }

  Future<void> updateApplicationStatus(String applicationId,
      ApplicationStatus status) async {
    await _client.from('request_applications').update({
      'status': status
          .toString()
          .split('.')
          .last,
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
        .map((data) =>
        data.map((json) => SupportMessage.fromJson(json)).toList());
  }

  Future<void> sendSupportMessage(SupportMessage message) async {
    try {
      await _client
          .from('support_messages')
          .insert(message.toJson())
          .withServerTimeout();
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

    final fileName = 'feedback_${user.id}_${DateTime
        .now()
        .millisecondsSinceEpoch}.png';
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
      rethrow;
    }
  }

  Stream<List<Announcement>> getAnnouncementsStream() {
    return _client
        .from('announcements')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
        data.map((json) {
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

    final fileName = 'announcement_${user.id}_${DateTime
        .now()
        .millisecondsSinceEpoch}.png';
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
      await _client
          .from('announcements')
          .delete()
          .eq('id', id)
          .withServerTimeout();
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
        await _client
            .from('announcements')
            .delete()
            .eq('id', id)
            .withServerTimeout();
        return;
      }
    }

    throw Exception(
        'Permission denied: You can only delete your own announcements.');
  }

  Future<void> verifyAnnouncement(String id, bool isVerified) async {
    final user = await getCurrentUserProfile();
    if (user?.role != 'super_admin') {
      throw Exception(
          'Permission denied: Only super admins can verify announcements.');
    }

    await _client.from('announcements').update({
      'is_verified': isVerified,
    }).eq('id', id).withServerTimeout();
  }

  Future<void> toggleAnnouncementVote(String announcementId,
      bool shouldVote) async {
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

  Future<Map<String, dynamic>> getAnnouncementVotesInfo(
      String announcementId) async {
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
      logger.w(
          'increment_helper_stats RPC not found, falling back to direct update: $e');
      await _client.rpc('increment', params: {
        'table': 'profiles',
        'id': helperId,
      }).catchError((_) async {
        // Last resort: raw update
        final current = await _client
            .from('profiles')
            .select(
            'help_count, points')
            .eq('id', helperId)
            .maybeSingle()
            .withServerTimeout();
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

  Future<List<Event>> getEvents() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      final currentUserProfile = await getCurrentUserProfile();

      double userLat = currentUserProfile?.lat ?? 0.0;
      double userLng = currentUserProfile?.lng ?? 0.0;

      // ... (Location fetch logic remains same) ...
      if (userLat == 0.0 || userLng == 0.0) {
        try {
          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
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

      final List<Event> events = [];
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
        if (creatorId != currentUserId && userLat != 0 && userLng != 0 &&
            eventLat != 0 && eventLng != 0) {
          final distance = _calculateDistance(
              userLat, userLng, eventLat, eventLng);
          if (distance > radiusKm) continue;
        }

        final attendees = eventAttendeesMap[eventId] ?? [];
        final attendeeCount = attendees.length;
        final bool isUserAttending = currentUserId != null &&
            attendees.contains(currentUserId);

        events.add(Event.fromJson({
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

  Future<void> createEvent(Event event) async {
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

  Future<void> deleteEvent(String eventId) async {
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
        throw Exception(
            'Permission denied: You are not the creator of this event.');
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
        throw Exception(
            'Access Denied: Your database "Delete" policy is blocking this action. Please check your Supabase RLS settings.');
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
      final List<EventComment> allComments = data.map((json) =>
          EventComment.fromJson(json)).toList();

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
    await _client
        .from('event_comments')
        .delete()
        .eq('id', commentId)
        .withServerTimeout();
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
      throw Exception(
          'Failed to update user role. You might not have permission.');
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
            final lastRejection = DateTime.parse(
                rejectionData[0]['updated_at']);
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
          if (currentUserProfile?.role != 'admin' &&
              currentUserProfile?.role != 'super_admin') {
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

  // --- Community Polling ---

  Future<List<Poll>> getActivePolls() async {
    final user = _client.auth.currentUser;
    try {
      final response = await _client
          .from('polls')
          .select('*, poll_options(*)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .withServerTimeout();

      final List<dynamic> pollsData = response as List<dynamic>;

      // Fetch user votes for these polls
      Map<String, String> userVotes = {};
      if (user != null) {
        final pollIds = pollsData.map((p) => p['id'] as String).toList();
        final votesRes = await _client
            .from('poll_votes')
            .select('poll_id, option_id')
            .eq('user_id', user.id)
            .inFilter('poll_id', pollIds)
            .withServerTimeout();

        for (var vote in votesRes as List<dynamic>) {
          userVotes[vote['poll_id']] = vote['option_id'];
        }
      }

      return pollsData.map((json) {
        final List<dynamic> optionsData = json['poll_options'] as List<dynamic>;
        final options = optionsData.map((o) => PollOption.fromJson(o)).toList();
        return Poll.fromJson(
          json,
          options: options,
          userVoteOptionId: userVotes[json['id']],
        );
      }).toList();
    } catch (e) {
      logger.e('Error fetching active polls: $e');
      return [];
    }
  }

  Future<void> voteInPoll(String pollId, String optionId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('poll_votes').insert({
      'poll_id': pollId,
      'user_id': user.id,
      'option_id': optionId,
    }).withServerTimeout();
  }

  Future<void> createPoll(String question, List<String> options,
      {String? description, DateTime? endDate}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final pollRes = await _client.from('polls').insert({
        'creator_id': user.id,
        'question': question,
        'description': description,
        'end_date': (endDate ?? DateTime.now().add(const Duration(days: 7)))
            .toIso8601String(),
      }).select().single().withServerTimeout();

      final pollId = pollRes['id'];

      final optionsToInsert = options.map((opt) =>
      {
        'poll_id': pollId,
        'option_text': opt,
      }).toList();

      await _client
          .from('poll_options')
          .insert(optionsToInsert)
          .withServerTimeout();
    } catch (e) {
      logger.e('Error creating poll or options: $e');
      rethrow;
    }
  }

  Future<void> deletePoll(String pollId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('polls').delete().eq('id', pollId).eq(
        'creator_id', user.id).withServerTimeout();
  }

  // --- Interest-Based Guilds ---

  Future<List<Guild>> getGuilds() async {
    final user = _client.auth.currentUser;
    try {
      final response = await _client
          .from('guilds')
          .select()
          .order('member_count', ascending: false)
          .withServerTimeout();

      final List<dynamic> guildsData = response as List<dynamic>;

      // Fetch user memberships
      Set<String> memberGuildIds = {};
      if (user != null) {
        final membershipsRes = await _client
            .from('guild_memberships')
            .select('guild_id')
            .eq('user_id', user.id)
            .withServerTimeout();

        memberGuildIds = (membershipsRes as List<dynamic>)
            .map((m) => m['guild_id'] as String)
            .toSet();
      }

      return guildsData.map((json) =>
          Guild.fromJson(
            json,
            isUserMember: memberGuildIds.contains(json['id']),
          )).toList();
    } catch (e) {
      logger.e('Error fetching guilds: $e');
      return [];
    }
  }

  Future<void> joinGuild(String guildId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('guild_memberships').insert({
      'guild_id': guildId,
      'user_id': user.id,
    }).withServerTimeout();
  }

  Future<void> leaveGuild(String guildId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('guild_memberships').delete().match({
      'guild_id': guildId,
      'user_id': user.id,
    }).withServerTimeout();
  }

  // --- Reputation & Badges ---

  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final response = await _client
          .from('user_badges')
          .select('*, badges(*)')
          .eq('user_id', userId)
          .withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        final badgeJson = json['badges'];
        return Badge.fromJson({
          ...badgeJson,
          'awarded_at': json['awarded_at'],
        });
      }).toList();
    } catch (e) {
      logger.e('Error fetching user badges: $e');
      return [];
    }
  }
  // --- Community Asset Library ---

  Future<void> createCommunityAsset(CommunityAsset asset, File? imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _uploadAssetImage(imageFile, asset.id);
    }

    // Generate AI embedding for semantic matching
    final embedding = await AiService().generateAssetEmbedding(
      asset.title,
      asset.description,
      asset.category.name,
    );
    final assetMap = asset.toJson();
    assetMap['embedding'] = embedding;
    if (imageUrl != null) assetMap['image_url'] = imageUrl;

    await _client.from('community_assets').insert(assetMap).withServerTimeout();
  }

  Future<List<CommunityAsset>> getMyAssets() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('community_assets')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false)
          .withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => CommunityAsset.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching my assets: $e');
      return [];
    }
  }

  Future<List<CommunityAsset>> getPublicAssets({AssetCategory? category}) async {
    try {
      var query = _client.from('community_assets').select().neq('status', 'private');

      if (category != null) {
        query = query.eq('category', category.name);
      }

      final response = await query.order('created_at', ascending: false).withServerTimeout();
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => CommunityAsset.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error fetching public assets: $e');
      return [];
    }
  }

  Future<void> updateCommunityAsset(CommunityAsset asset, File? imageFile) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    Map<String, dynamic> updates = {
      'title': asset.title,
      'description': asset.description,
      'category': asset.category.name,
      'status': asset.status.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (imageFile != null) {
      updates['image_url'] = await _uploadAssetImage(imageFile, asset.id);
    }

    // Re-generate embedding if title/description/category changed
    final embedding = await AiService().generateAssetEmbedding(
      asset.title,
      asset.description,
      asset.category.name,
    );
    updates['embedding'] = embedding;

    await _client
        .from('community_assets')
        .update(updates)
        .eq('id', asset.id)
        .eq('owner_id', user.id)
        .withServerTimeout();
  }

  Future<void> deleteCommunityAsset(String assetId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client
        .from('community_assets')
        .delete()
        .eq('id', assetId)
        .eq('owner_id', user.id)
        .withServerTimeout();
  }

  Future<String?> _uploadAssetImage(File imageFile, String assetId) async {
    try {
      final fileName = 'asset_${assetId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'public/$fileName';

      await _client.storage.from('asset-images').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      return _client.storage.from('asset-images').getPublicUrl(path);
    } catch (e) {
      logger.e('Error uploading asset image: $e');
      return null;
    }
  }

  /// AI Matching: Find community assets that could help with a specific help request
  Future<List<CommunityAsset>> matchAssetsForRequest(HelpRequestEntity request) async {
    if (_client.auth.currentSession == null) return [];
    try {
      // 1. Generate query embedding for the request description
      final queryEmbedding = await AiService().generateAssetEmbedding(
        request.title,
        request.description,
        request.category.toString().split('.').last,
        isQuery: true,
      );

      if (queryEmbedding == null) return [];

      // 2. Call RPC match_assets_v1
      final response = await _client.rpc('match_assets_v1', params: {
        'query_embedding': queryEmbedding,
        'match_threshold': 0.4,
        'match_count': 5,
        'excluded_id': request.requesterId,
      }).withServerTimeout();

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => CommunityAsset.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error matching assets for request: $e');
      return [];
    }
  }

  // --- AI Assistant & RAG ---

    Future<String> searchCommunityContent({
      required List<double> queryEmbedding,
      required String queryText,
    }) async {
      try {
        final List<String> contextParts = [];

        // 1. Search Help Requests (Vector Match)
        final requestsResponse = await _client.rpc(
            'match_requests_v3', params: {
          'query_embedding': queryEmbedding,
          'match_threshold': 0.3,
          'match_count': 5,
        });

        if (requestsResponse != null && (requestsResponse as List).isNotEmpty) {
          contextParts.add('--- RECENT HELP REQUESTS ---');
          for (var req in requestsResponse) {
            contextParts.add(
                'ID: ${req['id']} | Title: ${req['title']} | Category: ${req['category']}\nDescription: ${req['description']}');
          }
        }

        // 2. Search Events (Keyword Match)
        final eventsResponse = await _client
            .from('local_events')
            .select('id, title, description, location_name, event_date')
            .or('title.ilike.%$queryText%,description.ilike.%$queryText%')
            .limit(3);

        if ((eventsResponse as List).isNotEmpty) {
          contextParts.add('\n--- UPCOMING EVENTS ---');
          for (var ev in eventsResponse as List) {
            contextParts.add(
                'ID: ${ev['id']} | Title: ${ev['title']} | Date: ${ev['event_date']}\nLocation: ${ev['location_name']}\nDescription: ${ev['description']}');
          }
        }

        // 3. Search Announcements (Keyword Match)
        final newsResponse = await _client
            .from('announcements')
            .select('id, title, content, category')
            .or('title.ilike.%$queryText%,content.ilike.%$queryText%')
            .limit(3);

        if ((newsResponse as List).isNotEmpty) {
          contextParts.add('\n--- COMMUNITY NEWS ---');
          for (var news in newsResponse as List) {
            contextParts.add(
                'Category: ${news['category']} | Title: ${news['title']}\nContent: ${news['content']}');
          }
        }

        if (contextParts.isEmpty) {
          return "No specific community data found for this query.";
        }

        return contextParts.join('\n');
      } catch (e) {
        logger.e('Error searching community content: $e');
        return "Error retrieving community context.";
      }
    }
  }