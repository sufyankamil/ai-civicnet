import '../../home/models/badge.dart';

String sanitizeAvatarUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  return url.contains('?t=') ? url.split('?t=').first : url;
}

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double rating;
  final int helpCount;
  final int reportCount;
  final int ratingCount;
  final int points;
  final List<String> skills;
  final List<Badge> badges;
  final String role; // 'user' or 'admin'
  final String karmaLevel;
  final double? lat;
  final double? lng;
  final bool isPublicProfile;
  final bool showNeighborhood;
  final bool showImpactStats;
  final bool showAchievements;

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
    this.badges = const [],
    this.role = 'user',
    this.karmaLevel = 'Seedling',
    this.lat,
    this.lng,
    this.isPublicProfile = true,
    this.showNeighborhood = true,
    this.showImpactStats = true,
    this.showAchievements = true,
  });

  // Calculated impact properties
  int get hoursSaved => helpCount * 2;
  int get neighborsImpacted => helpCount + (points ~/ 50);

  // Level progress (assuming 500 pts per rank)
  static const int pointsPerRank = 500;
  int get pointsInCurrentLevel => points % pointsPerRank;
  double get levelProgress => pointsInCurrentLevel / pointsPerRank;
  int get pointsToNextRank => pointsPerRank - pointsInCurrentLevel;
}
