import 'package:flutter/material.dart' hide Badge;
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../components/app_loader.dart';
import '../components/verification_request_dialog.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:civic_net/features/chat/presentation/screens/support_chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Future<User?>? _profileFuture;
  Future<Map<String, dynamic>>? _eligibilityFuture;
  late final AnimationController _bannerController;
  late final Animation<double> _bannerAnim;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // Hero is fully collapsed once we've scrolled past
  // expandedHeight (280) - kToolbarHeight (56) = 224
  static const double _collapseOffset = 224.0;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
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
      _profileFuture = SupabaseService().getCurrentUserProfile();
      _eligibilityFuture = SupabaseService().checkVerificationEligibility();
    });
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
            return const AppLoader();
          }

          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Could not load profile', // TODO: Localize
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  AppElevatedButton(
                      onPressed: _refreshProfile,
                      child: const Text('Retry')),
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
                      _buildKarmaIndicator(user, isDark),
                      const SizedBox(height: 28),
                      _buildBadgeGallery(user, isDark),
                      const SizedBox(height: 28),
                      _buildSkillsSection(user, isDark),
                      const SizedBox(height: 28),
                      _buildActionsSection(context, isDark, user),
                      // Extra clearance so content scrolls above the bottom nav bar
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom +
                            kBottomNavigationBarHeight +
                            24,
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

  // ─── Hero Sliver ─────────────────────────────────────────────────────────

  Widget _buildHeroSliver(User user, bool isDark) {
    final displayName =
        user.name.isEmpty || user.name == 'Unknown' ? AppLocalizations.of(context)!.noName : user.name;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      // ── Collapsed AppBar content — only visible when banner is scrolled away
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
                  style: TextStyle(
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
      actions: [
        AnimatedOpacity(
          opacity: _isCollapsed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !_isCollapsed,
            child: IconButton(
              tooltip: AppLocalizations.of(context)!.editProfile,
              icon: Icon(
                Icons.edit_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
              onPressed: () async {
                await context.push('/edit-profile');
                if (context.mounted) _refreshProfile();
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: FadeTransition(
          opacity: _bannerAnim,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gradient banner
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Subtle circle accents
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
              // Name + email overlay at bottom
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
                      // Avatar with ring
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
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email.isEmpty ? AppLocalizations.of(context)!.noEmail : user.email,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Trust badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (user.role == 'admin' || user.role == 'super_admin')
                                    ? Colors.amber.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: (user.role == 'admin' || user.role == 'super_admin')
                                        ? Colors.amber.withValues(alpha: 0.6)
                                        : Colors.white.withValues(alpha: 0.4)),
                                boxShadow: (user.role == 'admin' || user.role == 'super_admin')
                                    ? [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    (user.role == 'admin' || user.role == 'super_admin')
                                        ? Icons.verified_user_rounded
                                        : Icons.verified_rounded,
                                    color: (user.role == 'admin' || user.role == 'super_admin')
                                        ? Colors.amber[100]
                                        : Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _trustLevel(user),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: (user.role == 'admin' || user.role == 'super_admin')
                                          ? Colors.amber[50]
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit avatar button
                      IconButton(
                        onPressed: () async {
                          await context.push('/edit-profile');
                          if (mounted) _refreshProfile();
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
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

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(User user, bool isDark) {
    final stats = [
      (Icons.handshake_rounded, AppLocalizations.of(context)!.helps, user.helpCount.toString(), Colors.blue),
      (Icons.star_rounded, AppLocalizations.of(context)!.rating, user.rating.toStringAsFixed(1), Colors.amber),
      (Icons.emoji_events_rounded, AppLocalizations.of(context)!.points, user.points.toString(), Colors.orange),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(stats[0].$1, stats[0].$2, stats[0].$3, stats[0].$4, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(stats[1].$1, stats[1].$2, stats[1].$3, stats[1].$4, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard(stats[2].$1, stats[2].$2, stats[2].$3, stats[2].$4, isDark)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      IconData icon, String label, String value, Color iconColor, bool isDark) {
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
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Skills ───────────────────────────────────────────────────────────────

  Widget _buildSkillsSection(User user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.skills,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await context.push('/edit-profile');
                  if (mounted) _refreshProfile();
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(AppLocalizations.of(context)!.add),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  textStyle: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.skills.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.2),
                    style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.primaryLight.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)!.addSkillsDescription,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
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
                    style: TextStyle(
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

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _buildActionsSection(BuildContext context, bool isDark, User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.account,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                _buildActionTile(
                  icon: Icons.edit_rounded,
                  iconColor: AppColors.primaryLight,
                  label: AppLocalizations.of(context)!.editProfile,
                  onTap: () async {
                    await context.push('/edit-profile');
                    if (mounted) _refreshProfile();
                  },
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                if (user.role == 'super_admin')
                  FutureBuilder<int>(
                    future: SupabaseService().getPendingRequestsCount(),
                    builder: (context, countSnapshot) {
                      final count = countSnapshot.data ?? 0;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionTile(
                            icon: Icons.admin_panel_settings_rounded,
                            iconColor: Colors.amber,
                            label: AppLocalizations.of(context)!.adminControlPanel,
                            onTap: () async {
                              await context.push('/admin-panel');
                              _refreshProfile();
                            },
                            isDark: isDark,
                            badgeCount: count > 0 ? count : null,
                          ),
                          _buildDivider(isDark),
                        ],
                      );
                    },
                  )
                else if (user.role == 'admin')
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionTile(
                        icon: Icons.verified_rounded,
                        iconColor: Colors.green,
                        label: AppLocalizations.of(context)!.verifiedLeaderStatus,
                        onTap: () {
                          showAdaptiveDialog(
                            context: context,
                            builder: (context) => AlertDialog.adaptive(
                              title: const Text('Verified Leader'),
                              content: const Text(
                                'Congratulations! You are a verified community leader. You can now post official news announcements to the community feed.'
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Awesome'),
                                ),
                              ],
                            ),
                          );
                        },
                        isDark: isDark,
                        showChevron: false,
                      ),
                      _buildDivider(isDark),
                    ],
                  )
                else
                  FutureBuilder<Map<String, dynamic>>(
                    future: _eligibilityFuture,
                      builder: (context, elSnapshot) {
                        final data = elSnapshot.data;
                        final String? reason = data?['reason'];
                      final String? lastStatus = data?['lastStatus'];
                      
                      if (reason == 'pending') {
                        return _buildActionTile(
                          icon: Icons.hourglass_empty_rounded,
                          iconColor: Colors.orange,
                          label: 'Leader Status Pending',
                          onTap: () {},
                          isDark: isDark,
                          showChevron: false,
                        );
                      }

                      if (reason == 'cooldown') {
                        final DateTime end = data!['cooldownEnd'];
                        final daysLeft = end.difference(DateTime.now()).inDays;
                        return _buildActionTile(
                          icon: Icons.timer_outlined,
                          iconColor: Colors.redAccent,
                          label: 'Application Limit Reached',
                          onTap: () {
                            showAdaptiveDialog(
                              context: context,
                              builder: (context) => AlertDialog.adaptive(
                                title: const Text('Application Limit'),
                                content: Text(
                                  'Your application has been declined 3 times. To ensure quality, there is a 30-day waiting period.\n\n'
                                  'You can reapply in $daysLeft ${daysLeft == 1 ? 'day' : 'days'} (on ${end.day}/${end.month}/${end.year}).',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            );
                          },
                          isDark: isDark,
                        );
                      }

                      return _buildActionTile(
                        icon: Icons.verified_user_rounded,
                        iconColor: lastStatus == 'rejected' ? Colors.redAccent : Colors.blue,
                        label: lastStatus == 'rejected' 
                          ? 'Application Rejected - Try Again' 
                          : (lastStatus == 'approved_pending_sync' 
                              ? 'Leader Status Approved - Syncing...'
                              : 'Apply for Leader Status'),
                        onTap: () async {
                          final result = await showDialog<bool>(
                            context: context,
                            builder: (context) => const VerificationRequestDialog(),
                          );
                          if (result == true) _refreshProfile();
                        },
                        isDark: isDark,
                      );
                    },
                  ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.shield_rounded,
                  iconColor: AppColors.accentLight,
                  label: AppLocalizations.of(context)!.commitmentSafety,
                  onTap: () => context.push('/commitment'),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.settings_rounded,
                  iconColor: Colors.grey,
                  label: AppLocalizations.of(context)!.appSettings,
                  onTap: () => context.push('/settings'),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: Colors.blueAccent,
                  label: AppLocalizations.of(context)!.supportChat,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                  ),
                  isDark: isDark,
                ),
                _buildDivider(isDark),
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  iconColor: Colors.red,
                  label: AppLocalizations.of(context)!.logout,
                  labelColor: Colors.red,
                  onTap: () async {
                    final confirmed = await showAdaptiveDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog.adaptive(
                        title: Text(AppLocalizations.of(context)!.logoutConfirm),
                        content: Text(
                            AppLocalizations.of(context)!.logoutDescription),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: Text(
                              AppLocalizations.of(context)!.logout,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await SupabaseService().signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  isDark: isDark,
                  showChevron: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? labelColor,
    bool showChevron = true,
    int? badgeCount,
  }) {
    return AppHaptic(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ??
                      (isDark ? Colors.white : AppColors.textPrimaryLight),
                ),
              ),
            ),
            if (badgeCount != null && badgeCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: isDark ? Colors.white10 : Colors.grey.shade100,
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _trustLevel(User user) {
    if (user.role == 'admin' || user.role == 'super_admin') return AppLocalizations.of(context)!.verifiedLeader;
    if (user.points >= 350 && user.helpCount >= 25) return AppLocalizations.of(context)!.eliteHelper;
    if (user.points >= 150 && user.helpCount >= 10) return AppLocalizations.of(context)!.trustedHelper;
    if (user.points >= 50 && user.helpCount >= 2) return AppLocalizations.of(context)!.activeMember;
    return AppLocalizations.of(context)!.newMember;
  }

  // ─── Karma Indicator ──────────────────────────────────────────────────

  Widget _buildKarmaIndicator(User user, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.civicKarma,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    user.karmaLevel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocalizations.of(context)!.score,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  user.points.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Badge Gallery ──────────────────────────────────────────────────

  Widget _buildBadgeGallery(User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            AppLocalizations.of(context)!.achievements,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Badge>>(
          future: SupabaseService().getUserBadges(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: AppLoader(),
              );
            }
            final badges = snapshot.data ?? [];
            if (badges.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppLocalizations.of(context)!.noBadges,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getBadgeIcon(badge.name),
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          badge.name,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getBadgeIcon(String name) {
    switch (name) {
      case 'First Responder': return Icons.flash_on_rounded;
      case 'Community Voice': return Icons.how_to_vote_rounded;
      case 'Social Butterfly': return Icons.groups_rounded;
      case 'Century Club': return Icons.military_tech_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }
}
