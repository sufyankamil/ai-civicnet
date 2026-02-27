import '../../profile/models/user.dart';

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
