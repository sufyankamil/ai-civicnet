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
  static User fromMap(Map<String, dynamic> data, {String? email}) {
    final skillsData = data['skills'];
    final List<String> skillsList = (skillsData is List) ? skillsData.map((e) => e.toString()).toList() : [];
    
    return User(
      id: data['id'],
      name: data['name'] ?? 'Unknown',
      email: email ?? data['email'] ?? '',
      avatarUrl: sanitizeAvatarUrl(data['avatar_url']),
      rating: (data['rating'] ?? 0.0).toDouble(),
      helpCount: data['help_count'] ?? 0,
      reportCount: data['report_count'] ?? 0,
      ratingCount: data['rating_count'] ?? 0,
      points: data['points'] ?? 0,
      skills: skillsList,
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      role: data['role'] ?? 'user',
      isPublicProfile: data['is_public_profile'] ?? true,
      showNeighborhood: data['show_neighborhood'] ?? true,
      showImpactStats: data['show_impact_stats'] ?? true,
      showAchievements: data['show_achievements'] ?? true,
    );
  }
}
