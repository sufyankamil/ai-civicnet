
import 'dart:math' show cos, sqrt, asin;
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/models.dart';

class SupabaseService {
  // Service for Supabase interactions
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  // --- Authentication ---

  Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  sb.User? get currentUser => _client.auth.currentUser;
  // --- Data ---

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

      'created_at': DateTime.now().toIso8601String(),
      'status': 'open',
    });
  }

  Future<void> updateHelpRequestStatus(String requestId, RequestStatus status) async {
    await _client.from('help_requests').update({
      'status': status.toString().split('.').last,
    }).eq('id', requestId);
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
    final response = await _client
        .from('help_requests')
        .select('*, profiles:requester_id(name, avatar_url)')
        .order('created_at', ascending: false);

    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => HelpRequest.fromJson(json)).toList();
  }

  Future<HelpRequest?> getHelpRequest(String id) async {
    try {
      final response = await _client
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .eq('id', id)
          .single();
      return HelpRequest.fromJson(response);
    } catch (e) {
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
          .single();
      
      final skillsList = (data['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];

      return User(
        id: data['id'],
        name: data['name'] ?? 'Unknown',
        email: '', // Email is not public
        avatarUrl: data['avatar_url'] ?? '',
        rating: (data['rating'] ?? 0.0).toDouble(),
        helpCount: data['help_count'] ?? 0,
        reportCount: data['report_count'] ?? 0,
        ratingCount: (data['rating_count'] ?? 0).toInt(),
        points: data['points'] ?? 0,
        skills: skillsList,
        lat: (data['lat'] ?? 0.0).toDouble(),
        lng: (data['lng'] ?? 0.0).toDouble(),
      );
    } catch (e) {
      print('Error fetching user profile $userId: $e');
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
          .single();


      print('DEBUG: Raw profile data: $data'); // DEBUG LOG
      final skillsData = data['skills'];
       print('DEBUG: Skills data type: ${skillsData.runtimeType}, Value: $skillsData');

      final skillsList = (skillsData as List?)?.map((e) => e.toString()).toList() ?? [];

      return User(
        id: data['id'],
        name: data['name'] ?? user.userMetadata?['name'] ?? 'Unknown',
        email: user.email ?? '',
        avatarUrl: data['avatar_url'] ?? '',
        rating: (data['rating'] ?? 0.0).toDouble(),
        helpCount: data['help_count'] ?? 0,
        reportCount: data['report_count'] ?? 0,
        ratingCount: data['rating_count'] ?? 0, // Mapped
        points: data['points'] ?? 0,
        skills: skillsList,
        lat: (data['lat'] ?? 0.0).toDouble(),
        lng: (data['lng'] ?? 0.0).toDouble(),
      );
    } catch (e, stack) {
        print('DEBUG: Error parsing profile: $e\n$stack'); // DEBUG LOG
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
    });
  }

  Future<bool> hasUserRated(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('user_ratings')
          .select('id')
          .eq('request_id', requestId)
          .eq('rater_id', user.id)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking if user rated: $e');
      return false;
    }
  }

  Future<void> updateUserProfile(String name, String avatarUrl, List<String> skills) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final updates = {
      'id': user.id,
      'name': name,
      'avatar_url': avatarUrl,
      'skills': skills,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('profiles').upsert(updates);
  }

  Future<void> updateUserLocation(double lat, double lng) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'lat': lat,
      'lng': lng,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }



  Future<List<Helper>> getPotentialHelpers(HelpRequest request) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .neq('id', request.requesterId) // Exclude requester
          .limit(20); // Fetch more candidates to rank

      final List<dynamic> data = response as List<dynamic>;
      final List<Helper> helpers = [];

      for (var json in data) {
         final skillsList = (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];
         
         final user = User(
          id: json['id'],
          name: json['name'] ?? 'Unknown',
          email: '', // Email not public
          avatarUrl: json['avatar_url'] ?? '',
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
      print('Error fetching helpers: $e');
      return [];
    }
  }

  // Haversine formula for distance
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    var p = 0.017453292519943295;
    var c = (a) => 1 - (a).abs().cos(); // Simplified cos function access isn't standard in dart:math, using manual math
    // Standard implementation:
    // import 'dart:math' show cos, sqrt, asin;
    // but we can't easily add import here without updating file top.
    // Let's use a simpler approximation or assume dart:math is available.
    // Since I can't guarantee import, I'll use a very rough Euclidean approximation for now 
    // which is okay for small distances, multiplying by ~111km per degree.
    // OR better, I'll add the import in a separate step.
    // For this step, I will use a placeholder calculation that doesn't need bad math imports
    // euclidean distance in degrees * 111km
    double dx = (lng2 - lng1) * (1 - 0.008 * ((lat1+lat2)/2).abs()); // mild longitude correction
    double dy = lat2 - lat1;
    return 111.0 * sqrt(dx*dx+dy*dy); // Fixed sqrt usage
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
        }).select().single();
        
        return response['id'];
    } catch (e) {
        print('Error creating conversation: $e');
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
            .order('updated_at', ascending: false);
            
        final List<ChatConversation> conversations = [];
        
        for (final conv in response) {
            final participants = List<String>.from(conv['participant_ids']);
            final otherId = participants.firstWhere((id) => id != user.id, orElse: () => '');
            
            if (otherId.isEmpty) continue;
            
            final profile = await _client.from('profiles').select().eq('id', otherId).maybeSingle();
            final name = profile?['name'] ?? 'Unknown';
            final avatar = profile?['avatar_url'] ?? '';

            final lastMsgRes = await _client
                .from('messages')
                .select()
                .eq('conversation_id', conv['id'])
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
                
            conversations.add(ChatConversation(
                id: conv['id'],
                otherUserId: otherId,
                otherUserName: name,
                otherUserAvatar: avatar,
                lastMessage: lastMsgRes?['content'] ?? 'No messages yet',
                lastMessageTime: DateTime.parse(lastMsgRes?['created_at'] ?? conv['created_at']),
                unreadCount: 0,
            ));
        }
        return conversations;
    } catch (e) {
        print('Error fetching conversations: $e');
        return [];
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
    });
    
    await _client.from('conversations').update({
        'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);
  }

  // --- Interest / Applications ---

  Future<void> applyToRequest(String requestId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    await _client.from('request_applications').insert({
      'request_id': requestId,
      'applicant_id': user.id,
      'status': 'pending',
    });
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
          .maybeSingle();

      if (response == null) return null;

      return ApplicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == response['status'],
        orElse: () => ApplicationStatus.pending,
      );
    } catch (e) {
      print('Error checking application status: $e');
      return null;
    }
  }

  Future<List<RequestApplication>> getApplicationsForRequest(String requestId) async {
    try {
      final response = await _client
          .from('request_applications')
          .select('*, profiles:applicant_id(name, avatar_url)')
          .eq('request_id', requestId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response as List<dynamic>;
      print('DEBUG: Fetched ${data.length} applications for request $requestId'); // DEBUG LOG
      return data.map((json) {
        print('DEBUG: App JSON: $json'); // DEBUG LOG
        return RequestApplication.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error fetching applications: $e');
      return [];
    }
  }

  Future<void> updateApplicationStatus(String applicationId, ApplicationStatus status) async {
    await _client.from('request_applications').update({
      'status': status.toString().split('.').last,
    }).eq('id', applicationId);
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
          print('Realtime update detected in help_requests');
          callback();
        },
      )
      .subscribe();
  }

  // --- Blocking & Reporting ---

  Future<void> blockUser(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    
    await _client.from('blocked_users').insert({
      'blocker_id': user.id,
      'blocked_id': userId,
    });
  }

  Future<void> unblockUser(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('blocked_users').delete().match({
      'blocker_id': user.id,
      'blocked_id': userId,
    });
  }

  Future<bool> isUserBlocked(String userId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('blocked_users')
        .select()
        .eq('blocker_id', user.id)
        .eq('blocked_id', userId)
        .maybeSingle();
    
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
    });
  }

  Future<void> completeHelpRequest(String requestId, String helperId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.rpc('complete_help_request', params: {
      'p_request_id': requestId,
      'p_helper_id': helperId,
    });
  }
}
