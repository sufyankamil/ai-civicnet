import 'package:flutter/material.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/models/models.dart';
import 'announcement_card.dart';
import '../screens/create_announcement_screen.dart';
import '../../../../widgets/haptic_buttons.dart';
import 'announcement_card_skeleton.dart';
import '../../../../theme/app_theme.dart';

class NewsSection extends StatefulWidget {
  final String? searchQuery;
  
  const NewsSection({super.key, this.searchQuery});

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> with AutomaticKeepAliveClientMixin {
  late Future<User?> _userProfileFuture;
  late Stream<List<Announcement>> _announcementsStream;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = SupabaseService().getCurrentUserProfile();
    _announcementsStream = SupabaseService().getAnnouncementsStream();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FutureBuilder<User?>(
      future: _userProfileFuture,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

        return StreamBuilder<List<Announcement>>(
          stream: _announcementsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(3, (index) => const AnnouncementCardSkeleton()),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ),
              );
            }
            
            List<Announcement> announcements = snapshot.data ?? [];

            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
              final query = widget.searchQuery!.toLowerCase();
              announcements = announcements.where((a) {
                return a.title.toLowerCase().contains(query) || 
                       a.content.toLowerCase().contains(query) ||
                       a.category.name.toLowerCase().contains(query);
              }).toList();
            }
            
            return Column(
              children: [
                if (announcements.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      return AnnouncementCard(
                        announcement: announcements[index],
                        onTap: () {},
                      );
                    },
                  ),
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: AppHaptic(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateAnnouncementScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: AppColors.auraGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryLight.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Text(
                              'Post News',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
                ? Icons.search_off_rounded 
                : Icons.newspaper_rounded, 
              size: 64, 
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
              ? 'No matches found' 
              : 'No announcements yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
              ? 'Try a different search term.'
              : 'Stay tuned for official updates from your community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
