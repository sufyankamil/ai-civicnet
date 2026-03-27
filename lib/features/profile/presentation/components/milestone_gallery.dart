import 'package:flutter/material.dart';
import 'parallax_card.dart';
import '../../models/user.dart';
import '../../models/milestone_models.dart';

class MilestoneGallery extends StatelessWidget {
  final User user;
  final bool isDark;
  final ScrollController scrollController;

  const MilestoneGallery({
    super.key,
    required this.user,
    required this.isDark,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = Milestone.getMilestonesForUser(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming Milestones',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final m = milestones[index];
              return _buildMilestoneCard(context, m);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneCard(BuildContext context, Milestone m) {
    final color = m.isEarned ? Colors.amber : Colors.grey;
    final opacity = m.isEarned ? 1.0 : 0.6;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: m.isEarned 
            ? Colors.amber.withValues(alpha: 0.3) 
            : Colors.transparent,
          width: 2,
        ),
        boxShadow: m.isEarned ? [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ParallaxCard(
                scrollController: scrollController,
                parallaxSpeed: 0.5,
                child: Icon(
                  m.icon,
                  size: 32,
                  color: color.withValues(alpha: opacity),
                ),
              ),
              if (!m.isEarned && !m.isUnlocked)
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Colors.white70,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            m.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            m.desc,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

