import 'package:flutter/material.dart';
import 'user.dart';

class Milestone {
  final String name;
  final String desc;
  final IconData icon;
  final bool isUnlocked; // Visible but not yet earned
  final bool isEarned;

  const Milestone({
    required this.name,
    required this.desc,
    required this.icon,
    required this.isUnlocked,
    required this.isEarned,
  });

  static List<Milestone> getMilestonesForUser(User user) {
    return [
      Milestone(
        name: 'First Step',
        desc: 'Post your first help request',
        icon: Icons.rocket_launch_rounded,
        isUnlocked: true, // Always show as "started"
        isEarned: user.helpCount >= 0, // Mocked as true if they exist
      ),
      Milestone(
        name: 'Neighborly',
        desc: 'Help your first neighbor',
        icon: Icons.handshake_rounded,
        isUnlocked: user.helpCount >= 1,
        isEarned: user.helpCount >= 1,
      ),
      Milestone(
        name: 'Community Hero',
        desc: 'Help 10 neighbors',
        icon: Icons.auto_awesome_rounded,
        isUnlocked: user.helpCount >= 1,
        isEarned: user.helpCount >= 10,
      ),
      Milestone(
        name: 'Golden Heart',
        desc: 'Maintain a 4.8+ rating',
        icon: Icons.favorite_rounded,
        isUnlocked: user.rating >= 4.0,
        isEarned: user.rating >= 4.8,
      ),
      Milestone(
        name: 'Civic Leader',
        desc: 'Earn 1,000 points',
        icon: Icons.emoji_events_rounded,
        isUnlocked: user.points >= 500,
        isEarned: user.points >= 1000,
      ),
    ];
  }
}
