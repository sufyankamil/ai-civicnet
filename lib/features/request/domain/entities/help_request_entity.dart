import 'package:equatable/equatable.dart';
import 'request_enums.dart';

class HelpRequestEntity extends Equatable {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterAvatarUrl;
  final String title;
  final String description;
  final HelpCategory category;
  final UrgencyLevel urgency;
  final DateTime postedAt;
  final String distance;
  final double aiRelevanceScore;
  final String locationName;
  final double lat;
  final double lng;
  final RequestStatusEnum status;
  final String? helperId;

  const HelpRequestEntity({
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

  HelpRequestEntity copyWith({
    String? distance,
    double? aiRelevanceScore,
    RequestStatusEnum? status,
  }) {
    return HelpRequestEntity(
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
      status: status ?? this.status,
      helperId: helperId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        requesterId,
        requesterName,
        requesterAvatarUrl,
        title,
        description,
        category,
        urgency,
        postedAt,
        distance,
        aiRelevanceScore,
        locationName,
        lat,
        lng,
        status,
        helperId,
      ];
}
