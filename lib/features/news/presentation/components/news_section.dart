import 'package:flutter/material.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/models/models.dart';
import 'announcement_card.dart';
import '../screens/create_announcement_screen.dart';
import '../../../../widgets/haptic_buttons.dart';
import 'announcement_card_skeleton.dart';

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

  Future<void> _handleRefresh() async {
    setState(() {
      _announcementsStream = SupabaseService().getAnnouncementsStream();
    });
    // Stream updates are handled by StreamBuilder, we just return a future that completes quickly
    // to hide the indicator once the state is updated.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    
    return FutureBuilder<User?>(
      future: _userProfileFuture,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final isAdmin = user?.role == 'admin' || user?.role == 'super_admin';

        return StreamBuilder<List<Announcement>>(
          stream: _announcementsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) => const AnnouncementCardSkeleton(),
              );
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
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
            
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Stack(
                children: [
                  if (announcements.isEmpty)
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
                                  ? Icons.search_off_rounded 
                                  : Icons.newspaper_rounded, 
                                size: 64, 
                                color: Colors.grey.withValues(alpha: 0.3)
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.searchQuery != null && widget.searchQuery!.isNotEmpty 
                                  ? 'No matches found' 
                                  : 'No announcements yet',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              ),
            );
          },
        );
      },
    );
  }
}
