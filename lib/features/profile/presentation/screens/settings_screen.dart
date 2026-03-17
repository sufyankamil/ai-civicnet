import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
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
                 if (ctx.mounted) Navigator.pop(ctx);
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
                     ToastService.showSuccess(context, 'Biometric Login Enabled!'); // TODO: Localize Toast
                   }
                }
              } catch (e) {
                setDialogState(() => isLoading = false);
                if (ctx.mounted) {
                  ToastService.showError(ctx, 'Invalid password. Try again.'); // TODO: Localize Toast
                }
              }
            }

            final contentWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.verifyPassword,
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
                        placeholder: AppLocalizations.of(context)!.password,
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
                      hintText: AppLocalizations.of(context)!.password,
                      prefixIcon: Icons.lock_outline,
                    ),
              ],
            );

            if (isIOS) {
              return CupertinoAlertDialog(
                title: Text(AppLocalizations.of(context)!.confirmPassword),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: contentWidget,
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: isLoading ? null : () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: isLoading ? null : handleEnable,
                    child: isLoading 
                      ? const CupertinoActivityIndicator() 
                      : Text(AppLocalizations.of(context)!.enable),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.confirmPassword, style: TextStyle(fontWeight: FontWeight.bold)),
              content: contentWidget,
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(AppLocalizations.of(context)!.enable),
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
    final l10n = AppLocalizations.of(context)!;
    // Access the provided theme service
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: TextStyle(fontWeight: FontWeight.bold)),
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
          _buildSectionHeader(l10n.appearance),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.theme),
            subtitle: Text(themeService.themeMode == ThemeMode.system 
                ? l10n.system 
                : themeService.themeMode == ThemeMode.light 
                    ? l10n.light 
                    : l10n.dark),
            leading: const Icon(Icons.brightness_6, color: AppColors.primaryLight),
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
          const Divider(height: 32),

          _buildSectionHeader(
            l10n.languageTitle,
            suffix: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l10n.beta,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.languageTitle),
            subtitle: Text(themeService.locale?.languageCode == 'hi' ? l10n.hindi : l10n.english),
            leading: const Icon(Icons.language, color: AppColors.primaryLight),
            trailing: DropdownButton<Locale>(
              value: themeService.locale ?? const Locale('en'),
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: const Locale('en'), child: Text(l10n.english)),
                DropdownMenuItem(value: const Locale('hi'), child: Text(l10n.hindi)),
              ],
              onChanged: (Locale? locale) async {
                if (locale != null) {
                  await themeService.setLocale(locale);
                }
              },
            ),
          ),
          const Divider(height: 32),

          _buildSectionHeader(l10n.support),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.howItWorks),
            subtitle: Text(
              'Interactive data-flow canvas', // TODO: Localize if needed
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
            title: Text(l10n.faq),
            leading: const Icon(Icons.help_outline, color: AppColors.primaryLight),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/faq'),
          ),
          ListTile(
            title: Text(l10n.privacyPolicy),
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.grey),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/privacy-policy');
            },
          ),
          const Divider(height: 32),

          _buildSectionHeader(l10n.security),
          Obx(() => _controller.isLoadingBiometrics && !_controller.isBiometricEnabled
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SizedBox(
                   height: 24, width: 24, 
                   child: CircularProgressIndicator(strokeWidth: 2)
                ),
              )
            : SwitchListTile(
            title: Text(l10n.biometricLogin),
            subtitle: Text(l10n.biometricDescription),
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

          _buildSectionHeader(l10n.account),
          ListTile(
            title: Text(l10n.helpHistory),
            leading: const Icon(Icons.history, color: AppColors.primaryLight),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/activity'),
          ),
          ListTile(
            title: Text(l10n.deleteAccount, style: const TextStyle(color: Colors.red)),
            leading: const Icon(Icons.person_remove, color: Colors.red),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () => context.push('/delete-account'),
          ),
          const Divider(height: 32),

          _buildSectionHeader(l10n.about),
          const SizedBox(height: 8),
          ListTile(
            title: Text(l10n.version),
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey)),
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
