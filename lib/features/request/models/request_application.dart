import '../../profile/models/user.dart';

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
