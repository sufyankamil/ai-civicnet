import 'package:flutter/material.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/models/models.dart';
import 'announcement_card.dart';
import '../screens/create_announcement_screen.dart';
import '../../../../widgets/haptic_buttons.dart';

class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: SupabaseService().getCurrentUserProfile(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

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
            
            return Stack(
              children: [
                if (announcements.isEmpty)
                  Center(
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
                  )
                else
                  ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 100, // Extra space for FAB
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      return AnnouncementCard(
                        announcement: announcements[index],
                        onTap: () {},
                      );
                    },
                  ),
                if (isAdmin)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: AppFloatingActionButton.extended(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateAnnouncementScreen()),
                        );
                      },
                      label: const Text('Post News'),
                      icon: const Icon(Icons.add_comment_rounded),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
