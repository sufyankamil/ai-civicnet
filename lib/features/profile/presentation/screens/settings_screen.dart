import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../services/theme_service.dart';
import '../../../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the provided theme service
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 100),
        children: [
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(themeService.themeMode.toString().split('.').last.toUpperCase()),
            leading: const Icon(Icons.brightness_6, color: AppColors.primaryLight),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (ThemeMode? mode) async {
                if (mode != null) {
                  await themeService.toggleTheme(mode);
                }
              },
            ),
          ),
          const Divider(height: 32),

          _buildSectionHeader('Support'),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('How TaskNet Works'),
            subtitle: Text(
              'Interactive data-flow canvas',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.route_rounded, color: Colors.white, size: 18),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/how-it-works'),
          ),
          ListTile(
            title: const Text('FAQ'),
            leading: const Icon(Icons.help_outline, color: AppColors.primaryLight),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/faq'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/privacy-policy');
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.person_remove, color: Colors.red),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => context.push('/delete-account'),
          ),

          const Divider(height: 32),

          _buildSectionHeader('Diagnostics'),
          ListTile(
            title: const Text('Test Crash (Crashlytics)'),
            leading: const Icon(Icons.bug_report, color: Colors.red),
            onTap: () {
              throw Exception('Test Crash for Civic Net!');
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Version'),
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
          fontSize: 14,
        ),
      ),
    );
  }
}
