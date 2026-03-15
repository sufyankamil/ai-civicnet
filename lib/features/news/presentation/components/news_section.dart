import 'package:flutter/material.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/models/models.dart';
import 'announcement_card.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Announcement>>(
      stream: SupabaseService().getAnnouncementsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final announcements = snapshot.data ?? [];
        
        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No announcements yet',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return AnnouncementCard(
              announcement: announcements[index],
              onTap: () {
                // Future: Slide up full announcement detail
              },
            );
          },
        );
      },
    );
  }
}
