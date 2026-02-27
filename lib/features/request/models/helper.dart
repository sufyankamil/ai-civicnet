import '../../profile/models/user.dart';

class Helper {
  final User user;
  final double matchScore; // 0.0 to 1.0
  final String distance; // e.g., "0.5 km"
  final List<String> matchReasons; // AI explanation

  Helper({
    required this.user,
    required this.matchScore,
    required this.distance,
    required this.matchReasons,
  });
}
