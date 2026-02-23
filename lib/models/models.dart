String sanitizeAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  return url.contains('?t=') ? url.split('?t=').first : url;
}

enum HelpCategory {
  errands,
  techSupport,
  emergency,
  education,
  transport,
  household,
  other, health
}

enum UrgencyLevel {
  low,
  medium,
  high,
  critical
}

enum RequestStatus {
  open,
  inProgress,
  completed,
  closed
}

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double rating;
  final int helpCount;
  final int reportCount;
  final int ratingCount; // Added rating count
  final int points;
  final List<String> skills;

  final double? lat;
  final double? lng;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.rating = 0.0,
    this.helpCount = 0,
    this.reportCount = 0,
    this.ratingCount = 0,
    this.points = 0,
    this.skills = const [],
    this.lat,
    this.lng,
  });
}

class Helper {
  final User user;
  final double matchScore; // 0.0 to 1.0
  final String distance; // e.g., "0.5 km"
  final List<String> matchReasons; // AI explanation

  Helper({
    required this.user,
    required this.matchScore,
    required this.distance,
    required this.matchReasons,
  });
}

class HelpRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterAvatarUrl;
  final String title;
  final String description;
  final HelpCategory category;
  final UrgencyLevel urgency;
  final DateTime postedAt;
  final String distance; // Relative to current user
  final double aiRelevanceScore; // For the current user viewing the feed
  final String locationName;
  final double lat;
  final double lng;
  final RequestStatus status;
  final String? helperId;

  HelpRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterAvatarUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.postedAt,
    required this.distance,
    required this.aiRelevanceScore,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.status,
    this.helperId,
  });

  HelpRequest copyWith({
    String? distance,
    double? aiRelevanceScore,
  }) {
    return HelpRequest(
      id: id,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterAvatarUrl: requesterAvatarUrl,
      title: title,
      description: description,
      category: category,
      urgency: urgency,
      postedAt: postedAt,
      distance: distance ?? this.distance,
      aiRelevanceScore: aiRelevanceScore ?? this.aiRelevanceScore,
      locationName: locationName,
      lat: lat,
      lng: lng,
      status: status,
      helperId: helperId,
    );
  }

  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    // Handle potential nulls or missing fields comfortably
    var profileData = json['profiles'];
    // Handle if profiles is returned as list or map
    final Map<String, dynamic> profile = (profileData is List && profileData.isNotEmpty) 
        ? profileData.first 
        : (profileData is Map<String, dynamic> ? profileData : {});

    return HelpRequest(
      id: json['id'].toString(),
      requesterId: json['requester_id'] ?? '',
      requesterName: profile['name'] ?? 'Unknown',
      requesterAvatarUrl: sanitizeAvatarUrl(profile['avatar_url']) == '' ? 'https://i.pravatar.cc/150' : sanitizeAvatarUrl(profile['avatar_url']), // Fallback
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: HelpCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => HelpCategory.other,
      ),
      urgency: UrgencyLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['urgency'],
        orElse: () => UrgencyLevel.medium,
      ),
      postedAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      distance: 'Unknown', 
      aiRelevanceScore: (json['ai_score'] ?? 0.85).toDouble(), // Use real score if available
      locationName: json['location_name'] ?? 'Unknown Location',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      status: RequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'open'),
        orElse: () => RequestStatus.open,
      ),
      helperId: json['helper_id'],
    );
  }
}

class ChatConversation {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String type; // 'text', 'image', 'audio'
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
        senderId: json['sender_id'],
        content: json['content'] ?? '',
        type: json['message_type'] ?? 'text',
        createdAt: DateTime.parse(json['created_at']),
        isRead: json['is_read'] ?? false,
    );
  }
}

enum ApplicationStatus { pending, accepted, rejected }

class RequestApplication {
  final String id;
  final String requestId;
  final String applicantId;
  final String applicantName;
  final String applicantAvatarUrl;
  final ApplicationStatus status;
  final DateTime createdAt;

  RequestApplication({
    required this.id,
    required this.requestId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantAvatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory RequestApplication.fromJson(Map<String, dynamic> json) {
    // Handle potential joined profile data
    var profileData = json['profiles'];
    final Map<String, dynamic> profile = (profileData is List && profileData.isNotEmpty) 
        ? profileData.first 
        : (profileData is Map<String, dynamic> ? profileData : {});

    return RequestApplication(
      id: json['id'],
      requestId: json['request_id'].toString(),
      applicantId: json['applicant_id'],
      applicantName: profile['name'] ?? 'Unknown User',
      applicantAvatarUrl: sanitizeAvatarUrl(profile['avatar_url']),
      status: ApplicationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'info',
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
