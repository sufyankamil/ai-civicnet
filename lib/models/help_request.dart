
enum RequestCategory {
  borrow,
  assistance,
  transport,
  skill,
  emergency
}

enum RequestUrgency {
  low,
  medium,
  high,
  critical
}

class HelpRequest {
  final String id;
  final String title;
  final String description;
  final RequestCategory category;
  final RequestUrgency urgency;
  final String userId;
  final String userName;
  final String userAvatar; // URL or asset path
  final double distance; // Simplified for now (in km)
  final DateTime postedAt;
  final double latitude;
  final double longitude;

  HelpRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.distance,
    required this.postedAt,
    required this.latitude,
    required this.longitude,
  });

  // Mock Data
  static List<HelpRequest> mockRequests = [
    HelpRequest(
      id: '1',
      title: 'Need a ladder for roof repair',
      description: 'Hi neighbors, I need a tall ladder to fix some shingles on my roof. Will only need it for an afternoon.',
      category: RequestCategory.borrow,
      urgency: RequestUrgency.medium,
      userId: 'u1',
      userName: 'Alice Johnson',
      userAvatar: 'https://i.pravatar.cc/150?u=a',
      distance: 0.5,
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      latitude: 37.7749,
      longitude: -122.4194,
    ),
    HelpRequest(
      id: '2',
      title: 'Groceries delivery for elderly neighbor',
      description: 'My mother is unwell and needs some groceries picked up from Whole Foods. I am out of town.',
      category: RequestCategory.assistance,
      urgency: RequestUrgency.high,
      userId: 'u2',
      userName: 'Bob Smith',
      userAvatar: 'https://i.pravatar.cc/150?u=b',
      distance: 1.2,
      postedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      latitude: 37.7849,
      longitude: -122.4094,
    ),
    HelpRequest(
      id: '3',
      title: 'Lost cat near Elm Street',
      description: 'My cat Mittens got out last night. She is a calico with a pink collar. Please let me know if you see her!',
      category: RequestCategory.emergency,
      urgency: RequestUrgency.critical,
      userId: 'u3',
      userName: 'Carol White',
      userAvatar: 'https://i.pravatar.cc/150?u=c',
      distance: 0.8,
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
      latitude: 37.7649,
      longitude: -122.4294,
    ),
  ];
}
