import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/theme_service.dart';
import '../../../../theme/app_theme.dart';

import 'package:get/get.dart';
import '../../../../services/rating_service.dart';
import '../viewmodels/settings_controller.dart';
import '../../../../core/services/version_service.dart';
import '../../../chat/presentation/screens/support_chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsController _controller = Get.find<SettingsController>();

  @override
  void initState() {
    super.initState();
    // Refresh settings in case they changed elsewhere, but do it in background
    _controller.loadBiometricSettings();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Access the provided theme service
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(0, 16, 0, MediaQuery.of(context).padding.bottom + 100),
        children: [
          // Theme settings - kept for convenience but cleaner
          _buildSectionHeader(l10n.appearance),
          ListTile(
            title: Text(l10n.theme),
            leading: const Icon(Icons.brightness_6_outlined, color: AppColors.primaryLight),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.themeMode,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(l10n.system)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(l10n.light)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(l10n.dark)),
              ],
              onChanged: (ThemeMode? mode) async {
                if (mode != null) {
                  await themeService.toggleTheme(mode);
                }
              },
            ),
          ),
          const Divider(),

          // Support section - kept for utility
          _buildSectionHeader(l10n.support),
          ListTile(
            title: Text(l10n.howItWorks),
            leading: const Icon(Icons.route_outlined, color: Colors.blueGrey),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/how-it-works'),
          ),
          ListTile(
            title: Text(l10n.faq),
            leading: const Icon(Icons.help_outline_rounded, color: Colors.blueGrey),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/faq'),
          ),
          ListTile(
            title: const Text('Rate CivicNet'),
            leading: const Icon(Icons.star_outline_rounded, color: Colors.amber),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => RatingService.openStore(),
          ),
          ListTile(
            title: Text(l10n.supportChat),
            leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.blueAccent),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const SupportChatScreen()),
            ),
          ),
          const Divider(),

          const SizedBox(height: 16),

          // NEW MODULES FROM IMAGE 1
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, size: 28, color: Colors.blueGrey),
            title: const Text(
              'Refer friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/referral'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.person_outline, size: 28, color: Colors.blueGrey),
            title: const Text(
              'Manage CivicNet account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/account-management'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline, size: 28, color: Colors.blueGrey),
            title: const Text(
              'Legal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/legal'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.shield_outlined, size: 28, color: AppColors.accentLight),
            title: Text(
              l10n.commitmentSafety,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/commitment'),
          ),

          const SizedBox(height: 48),

          // VERSION FOOTER MATCHING IMAGE 1
          FutureBuilder<String>(
            future: VersionService.getFullVersionString(),
            builder: (context, snapshot) {
              final version = snapshot.data ?? '1.1.5+46';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'v$version',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? suffix}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryLight,
              fontSize: 14,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            suffix,
          ],
        ],
      ),
    );
  }
}
