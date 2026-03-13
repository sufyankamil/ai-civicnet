import '../../profile/models/user.dart';

enum EventCategory {
  community,
  cleanup,
  meeting,
  social,
  workshop,
  other
}

class LocalEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String locationName;
  final double lat;
  final double lng;
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;
  final DateTime createdAt;
  final int attendeeCount;
  final bool isUserAttending;

  LocalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatarUrl,
    required this.createdAt,
    this.attendeeCount = 0,
    this.isUserAttending = false,
  });

  factory LocalEvent.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'];
    final Map<String, dynamic> profile = (profileData is List && profileData.isNotEmpty) 
        ? profileData.first 
        : (profileData is Map<String, dynamic> ? profileData : {});

    return LocalEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      eventDate: DateTime.tryParse(json['event_date'] ?? '') ?? DateTime.now(),
      locationName: json['location_name'] ?? 'Unknown Location',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      creatorId: json['creator_id'] ?? '',
      creatorName: profile['name'] ?? 'Unknown',
      creatorAvatarUrl: sanitizeAvatarUrl(profile['avatar_url']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      attendeeCount: json['attendee_count'] ?? 0,
      isUserAttending: json['is_user_attending'] ?? false,
    );
  }

  LocalEvent copyWith({
    int? attendeeCount,
    bool? isUserAttending,
  }) {
    return LocalEvent(
      id: id,
      title: title,
      description: description,
      eventDate: eventDate,
      locationName: locationName,
      lat: lat,
      lng: lng,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      createdAt: createdAt,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      isUserAttending: isUserAttending ?? this.isUserAttending,
    );
  }
}
