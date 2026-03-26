import 'package:equatable/equatable.dart';

class Poll extends Equatable {
  final String id;
  final String creatorId;
  final String question;
  final String? description;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isActive;
  final List<PollOption> options;
  final String? userVoteOptionId;

  const Poll({
    required this.id,
    required this.creatorId,
    required this.question,
    this.description,
    required this.endDate,
    required this.createdAt,
    this.isActive = true,
    this.options = const [],
    this.userVoteOptionId,
  });

  factory Poll.fromJson(Map<String, dynamic> json, {List<PollOption> options = const [], String? userVoteOptionId}) {
    return Poll(
      id: json['id'],
      creatorId: json['creator_id'],
      question: json['question'],
      description: json['description'],
      endDate: DateTime.parse(json['end_date']),
      createdAt: DateTime.parse(json['created_at']),
      isActive: json['is_active'] ?? true,
      options: options,
      userVoteOptionId: userVoteOptionId,
    );
  }

  bool get isExpired => endDate.isBefore(DateTime.now());
  int get daysLeft => endDate.difference(DateTime.now()).inDays;

  @override
  List<Object?> get props => [id, creatorId, question, description, endDate, createdAt, isActive, options, userVoteOptionId];
}

class PollOption extends Equatable {
  final String id;
  final String pollId;
  final String optionText;
  final int voteCount;

  const PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
    this.voteCount = 0,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'],
      pollId: json['poll_id'],
      optionText: json['option_text'],
      voteCount: json['vote_count'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, pollId, optionText, voteCount];
}
