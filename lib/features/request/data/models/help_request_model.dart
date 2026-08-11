import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';

class HelpRequestModel extends HelpRequestEntity {
  const HelpRequestModel({
    required super.id,
    required super.requesterId,
    required super.requesterName,
    required super.requesterAvatarUrl,
    required super.title,
    required super.description,
    required super.category,
    required super.urgency,
    required super.postedAt,
    required super.distance,
    required super.aiRelevanceScore,
    required super.locationName,
    required super.lat,
    required super.lng,
    required super.status,
    super.helperId,
  });

  factory HelpRequestModel.fromJson(Map<String, dynamic> json) {
    var profileData = json['profiles'];
    final Map<String, dynamic> profile = (profileData is List && profileData.isNotEmpty) 
        ? profileData.first 
        : (profileData is Map<String, dynamic> ? profileData : {});

    String rawAvatar =
        json['requester_avatar_url'] ?? profile['avatar_url'] ?? '';
    String avatarUrl = rawAvatar.contains('?t=') ? rawAvatar.split('?t=').first : rawAvatar;

    return HelpRequestModel(
      id: json['id'].toString(),
      requesterId: json['requester_id'] ?? '',
      requesterName: json['requester_name'] ?? profile['name'] ?? 'Unknown',
      requesterAvatarUrl: avatarUrl,
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
      aiRelevanceScore: (json['ai_score'] ?? json['similarity'] ?? 0.0).toDouble(),
      locationName: json['location_name'] ?? 'Unknown Location',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      status: RequestStatusEnum.values.firstWhere(
        (e) => e.toString().split('.').last == (json['status'] ?? 'open'),
        orElse: () => RequestStatusEnum.open,
      ),
      helperId: json['helper_id'],
    );
  }
}
