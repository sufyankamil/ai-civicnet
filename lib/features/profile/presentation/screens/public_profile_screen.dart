import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/toast_service.dart';
import '../../../../components/report_dialog.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  Future<User?>? _profileFuture;
  late final AnimationController _bannerController;
  late final Animation<double> _bannerAnim;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  static const double _collapseOffset = 224.0;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _bannerAnim =
        CurvedAnimation(parent: _bannerController, curve: Curves.easeOutCubic);
    _scrollController.addListener(() {
      final collapsed = _scrollController.offset > _collapseOffset;
      if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
    });
    _refreshProfile();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = SupabaseService().getUserProfile(widget.userId);
    });
  }

  Future<void> _startChat(User user) async {
    if (_isStartingChat) return;
    if (SupabaseService().currentUserId == user.id) {
      ToastService.showInfo(context, 'You cannot chat with yourself');
      return;
    }

    setState(() => _isStartingChat = true);
    try {
      final conversationId =
          await SupabaseService().createConversation(user.id);
      if (mounted) {
        final encodedName = Uri.encodeComponent(user.name);
        context.push(
            '/chat-detail?id=$conversationId&name=$encodedName&uid=${user.id}');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(
            context, 'Unable to start chat with ${user.name}.');
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: FutureBuilder<User?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const Icon(Icons.person_off_outlined,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('User not found',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ],
              ),
            );
          }

          final user = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshProfile();
              await _profileFuture;
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeroSliver(user, isDark),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildStatsRow(user, isDark),
                      const SizedBox(height: 28),
                      _buildSkillsSection(user, isDark),
                      const SizedBox(height: 32),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isStartingChat ? null : () => _startChat(user),
                            icon: _isStartingChat 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2, backgroundColor: Colors.white))
                                : const Icon(Icons.chat_bubble_outline),
                            label: const Text('Send Message'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      
                      // Extra clearance
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSliver(User user, bool isDark) {
    final displayName =
        user.name.isEmpty || user.name == 'Unknown' ? 'Community Member' : user.name;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      actions: [
        if (SupabaseService().currentUserId != null &&
            SupabaseService().currentUserId != user.id)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.flag_outlined, color: Colors.red),
                          title: const Text('Report & Block User'),
                          onTap: () {
                            Navigator.pop(context);
                            _showReportUserDialog(user);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
      title: AnimatedOpacity(
        opacity: _isCollapsed ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !_isCollapsed,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: user.avatarUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: user.avatarUrl,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          radius: 16,
                          backgroundImage: imageProvider,
                        ),
                        errorWidget: (context, url, error) => const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                      )
                    : const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 20, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: FadeTransition(
          opacity: _bannerAnim,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 60,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          child: user.avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: user.avatarUrl,
                                  imageBuilder: (context, imageProvider) => CircleAvatar(
                                    radius: 38,
                                    backgroundImage: imageProvider,
                                  ),
                                  errorWidget: (context, url, error) => const CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, size: 40, color: Colors.white),
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 38,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, size: 40, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    _trustLevel(user),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(User user, bool isDark) {
    final stats = [
      ('🤝', 'Helps', user.helpCount.toString()),
      ('⭐', 'Rating', user.rating.toStringAsFixed(1)),
      ('🏆', 'Points', user.points.toString()),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(stats[0].$1, stats[0].$2, stats[0].$3, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(stats[1].$1, stats[1].$2, stats[1].$3, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(stats[2].$1, stats[2].$2, stats[2].$3, isDark)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String emoji, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection(User user, bool isDark) {
    if (user.skills.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  skill,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _trustLevel(User user) {
    if (user.points >= 350 && user.helpCount >= 25) return 'Elite Helper';
    if (user.points >= 150 && user.helpCount >= 10) return 'Trusted Helper';
    if (user.points >= 50 && user.helpCount >= 2) return 'Active Member';
    return 'Community Member';
  }

  void _showReportUserDialog(User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => ReportDialog(
        title: 'Report ${user.name}',
        onReport: (reason) async {
          try {
            await SupabaseService().reportUser(user.id, reason);
            if (!mounted) return;
            
            // ignore: use_build_context_synchronously
            ToastService.showSuccess(context, 'User reported and blocked. Thank you for helping keep the community safe.');
            
            // Wait a brief moment for toast to start showing, then close
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            
            // ignore: use_build_context_synchronously
            Navigator.of(dialogContext).pop(); // Close dialog
            // ignore: use_build_context_synchronously
            context.pop(); // Go back from profile
          } catch (e) {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            ToastService.showError(context, 'Failed to submit report. Please try again.');
          }
        },
      ),
    );
  }
}
