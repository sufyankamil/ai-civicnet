import 'package:flutter/material.dart';
import 'package:civic_net/theme/app_theme.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/features/profile/models/user.dart' as model;

class PrivacySettingsSection extends StatefulWidget {
  final bool isDark;
  final model.User user;

  const PrivacySettingsSection({
    super.key,
    required this.isDark,
    required this.user,
  });

  @override
  State<PrivacySettingsSection> createState() => _PrivacySettingsSectionState();
}

class _PrivacySettingsSectionState extends State<PrivacySettingsSection> {
  late bool _isPublicProfile;
  late bool _showNeighborhood;
  late bool _showImpactStats;
  late bool _showAchievements;

  @override
  void initState() {
    super.initState();
    _isPublicProfile = widget.user.isPublicProfile;
    _showNeighborhood = widget.user.showNeighborhood;
    _showImpactStats = widget.user.showImpactStats;
    _showAchievements = widget.user.showAchievements;
  }

  @override
  void didUpdateWidget(PrivacySettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _isPublicProfile = widget.user.isPublicProfile;
      _showNeighborhood = widget.user.showNeighborhood;
      _showImpactStats = widget.user.showImpactStats;
      _showAchievements = widget.user.showAchievements;
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await SupabaseService().updatePrivacySettings({key: value});
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Privacy & Visibility',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPrivacyToggle(
            'Public Profile',
            'Allow others to find and view your impact.',
            Icons.visibility_rounded,
            _isPublicProfile,
            (val) => setState(() {
              _isPublicProfile = val;
              _updateSetting('public', val);
            }),
          ),
          const Divider(height: 24),
          _buildPrivacyToggle(
            'Share Neighborhood',
            'Show your relative location on impact maps.',
            Icons.map_rounded,
            _showNeighborhood,
            (val) => setState(() {
              _showNeighborhood = val;
              _updateSetting('location', val);
            }),
          ),
          const Divider(height: 24),
          _buildPrivacyToggle(
            'Display Impact Stats',
            'Show help counts and community hours saved.',
            Icons.bar_chart_rounded,
            _showImpactStats,
            (val) => setState(() {
              _showImpactStats = val;
              _updateSetting('stats', val);
            }),
          ),
          const Divider(height: 24),
          _buildPrivacyToggle(
            'Show Achievements',
            'Display badges and milestones publicly.',
            Icons.emoji_events_rounded,
            _showAchievements,
            (val) => setState(() {
              _showAchievements = val;
              _updateSetting('badges', val);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: widget.isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryLight,
          activeTrackColor: AppColors.primaryLight.withValues(alpha: 0.5),
        ),
      ],
    );
  }
}
