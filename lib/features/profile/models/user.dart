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
