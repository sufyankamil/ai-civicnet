import 'package:equatable/equatable.dart';

class VerificationRequest extends Equatable {
  final String id;
  final String userId;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? userName;
  final String? userAvatarUrl;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    
    return VerificationRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: profile?['name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, userId, reason, status, createdAt, userName, userAvatarUrl];
}
