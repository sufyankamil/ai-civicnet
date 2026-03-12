import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../services/theme_service.dart';
import '../../../../theme/app_theme.dart';

import 'package:get/get.dart';
import '../../../../services/biometric_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../viewmodels/settings_controller.dart';

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

  Future<void> _showPasswordPromptDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void handleEnable() async {
              final password = passwordController.text;
              if (password.isEmpty) return;

              setDialogState(() => isLoading = true);

              // Re-authenticate to confirm password
              final currentUser = SupabaseService().currentUser;
              if (currentUser?.email == null) {
                 setDialogState(() => isLoading = false);
                 Navigator.pop(ctx);
                 return;
              }
              
              try {
                // Attempt sign in to verify password
                final response = await SupabaseService().signIn(currentUser!.email!, password);
                
                if (response.session != null) {
                   // Verified! Encrypt and save
                    await BiometricService().enableBiometrics(currentUser.email!, password);
                    _controller.loadBiometricSettings();
                   if (ctx.mounted) {
                     Navigator.pop(ctx);
                     ToastService.showSuccess(context, 'Biometric Login Enabled!');
                   }
                }
              } catch (e) {
                setDialogState(() => isLoading = false);
                if (ctx.mounted) {
                  ToastService.showError(ctx, 'Invalid password. Try again.');
                }
              }
            }

            final contentWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please verify your password to enable biometric login.',
                  style: isIOS 
                      ? const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel) 
                      : null,
                ),
                const SizedBox(height: 16),
                isIOS
                  ? Material( // Need material for styling
                      color: Colors.transparent,
                      child: CupertinoTextField(
                        controller: passwordController,
                        obscureText: true,
                        placeholder: 'Password',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12.0),
                          child: Icon(CupertinoIcons.lock, color: Colors.grey, size: 20),
                        ),
                      ),
                    )
                  : CustomTextField(
                      controller: passwordController,
                      obscureText: true,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                    ),
              ],
            );

            if (isIOS) {
              return CupertinoAlertDialog(
                title: const Text('Confirm Password'),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: contentWidget,
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: isLoading ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: isLoading ? null : handleEnable,
                    child: isLoading 
                      ? const CupertinoActivityIndicator() 
                      : const Text('Enable'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text('Confirm Password', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: contentWidget,
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enable'),
                ),
              ],
            );
          }
        );
      }
    );
  }

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

          _buildSectionHeader('Security'),
          Obx(() => _controller.isLoadingBiometrics && !_controller.isBiometricEnabled
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                   height: 24, width: 24, 
                   child: CircularProgressIndicator(strokeWidth: 2)
                ),
              )
            : SwitchListTile(
            title: const Text('Biometric Login'),
            subtitle: const Text('Use Face ID / Fingerprint to log in securely'),
            value: _controller.isBiometricEnabled,
            secondary: const Icon(Icons.fingerprint, color: AppColors.primaryLight),
            onChanged: (bool value) async {
              if (value) {
                // Determine if device supports biometrics
                final isAvailable = await BiometricService().isBiometricAvailable();
                if (!isAvailable) {
                  if (context.mounted) {
                    ToastService.showError(context, 'Biometrics not available on this device.');
                  }
                  return;
                }
                
                // Prompt user for their password since we can't get it from the session
                if (context.mounted) {
                  _showPasswordPromptDialog(context);
                }
              } else {
                // Disable it
                await _controller.toggleBiometrics(false);
              }
            },
          )),
          const Divider(height: 32),

          _buildSectionHeader('Account'),
          ListTile(
            title: const Text('Help History'),
            leading: const Icon(Icons.history, color: AppColors.primaryLight),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/activity'),
          ),
          ListTile(
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            leading: const Icon(Icons.person_remove, color: Colors.red),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => context.push('/delete-account'),
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
