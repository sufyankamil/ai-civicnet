import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../viewmodels/settings_controller.dart';
import '../../../../services/biometric_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../models/models.dart';
import 'package:shimmer/shimmer.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SettingsController _controller = Get.find<SettingsController>();
  late Stream<User?> _userStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.loadBiometricSettings();
    _userStream = SupabaseService().getCurrentUserProfileStream().asBroadcastStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CivicNet Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: isDark ? Colors.white : Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryLight,
          tabs: [
            Tab(text: 'Personal info'),
            Tab(text: 'Security'),
            Tab(text: 'Privacy & Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          KeepAliveWrapper(child: _buildPersonalInfoTab()),
          KeepAliveWrapper(child: _buildSecurityTab()),
          KeepAliveWrapper(child: _buildPrivacyTab()),
        ],
      ),
    );
  }


  Widget _buildPersonalInfoTab() {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return _buildProfileShimmer();
        }

        final user = snapshot.data;
        final name = user?.name ?? 'CivicNet User';
        final email = user?.email ?? '...';
        final avatarUrl = user?.avatarUrl;
        
        String initials = '';
        if (name.isNotEmpty) {
          final parts = name.split(' ');
          if (parts.length > 1) {
            initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
          } else {
            initials = parts[0][0].toUpperCase();
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PROFILE HEADER
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: (avatarUrl == null || avatarUrl.isEmpty)
                          ? AppColors.primaryGradient(Theme.of(context).brightness)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.transparent,
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    email,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            ListTile(
              title: Text(l10n.editProfile),
              leading: const Icon(Icons.person_outline),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/edit-profile'),
            ),
            const Divider(),
            ListTile(
              title: const Text('Verified Status'),
              subtitle: const Text('Your identity is verified for community trust.'),
              leading: const Icon(Icons.verified_user_outlined, color: Colors.green),
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
          ],
        );
      }
    );
  }

  Widget _buildProfileShimmer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 24,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        _buildShimmerTile(baseColor, highlightColor),
        const Divider(),
        _buildShimmerTile(baseColor, highlightColor),
      ],
    );
  }

  Widget _buildShimmerTile(Color base, Color highlight) {
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(
          height: 16,
          width: double.infinity,
          color: Colors.white,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }

  Widget _buildSecurityTab() {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Obx(() => _controller.isLoadingBiometrics
          ? const Center(child: CupertinoActivityIndicator())
          : SwitchListTile(
              title: Text(l10n.biometricLogin),
              subtitle: Text(l10n.biometricDescription),
              value: _controller.isBiometricEnabled,
              secondary: const Icon(Icons.fingerprint, color: AppColors.primaryLight),
              onChanged: (bool value) async {
                if (value) {
                  final isAvailable = await BiometricService().isBiometricAvailable();
                  if (!mounted) return;
                  
                  if (!isAvailable) {
                    ToastService.showError(context, 'Biometrics not available on this device.');
                    return;
                  }
                  _showPasswordPromptDialog(context);
                } else {
                  await _controller.toggleBiometrics(false);
                }
              },
            )),
        const Divider(),
        ListTile(
          title: const Text('Change Password'),
          subtitle: const Text('Update your login credentials'),
          leading: const Icon(Icons.lock_reset_outlined, color: Colors.blueGrey),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/forgot-password'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Active Sessions'),
          subtitle: const Text('Manage devices logged into your account'),
          leading: const Icon(Icons.devices_outlined, color: Colors.blueGrey),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/active-sessions'),
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: Text(l10n.privacyPolicy),
                leading: const Icon(Icons.privacy_tip_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/privacy-policy'),
              ),
              const Divider(),
              ListTile(
                title: const Text('Data & Personalization'),
                subtitle: const Text('Manage what data is shared and how it is used.'),
                leading: const Icon(Icons.data_usage),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showDataTransparencyBottomSheet(context);
                },
              ),
            ],
          ),
        ),
        // HIDDEN DELETE ACCOUNT LINK
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: TextButton(
            onPressed: () => context.push('/delete-account'),
            child: Text(
              l10n.deleteAccount,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[400] 
                    : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDataTransparencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data & Personalization',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'At CivicNet, your privacy is our priority. We use localized data to connect you with relevant community help requests. Your data is encrypted and never sold to third parties.',
                style: TextStyle(fontSize: 15, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Current Settings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const BulletItem(text: 'Location usage: High relevance matching'),
              const BulletItem(text: 'Skill analysis: AI-driven task suggestions'),
              const BulletItem(text: 'Encryption: End-to-end active'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('I Understand'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPasswordPromptDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool isLoading = false;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.macOS;
    final l10n = AppLocalizations.of(context)!;
    
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

              final currentUser = SupabaseService().currentUser;
              if (currentUser?.email == null) {
                 setDialogState(() => isLoading = false);
                 if (ctx.mounted) Navigator.pop(ctx);
                 return;
              }
              
              try {
                final response = await SupabaseService().signIn(currentUser!.email!, password);
                
                if (response.session != null) {
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
                  l10n.verifyPassword,
                  style: isIOS 
                      ? const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel) 
                      : null,
                ),
                const SizedBox(height: 16),
                isIOS
                  ? Material(
                      color: Colors.transparent,
                      child: CupertinoTextField(
                        controller: passwordController,
                        obscureText: true,
                        placeholder: l10n.password,
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
                      hintText: l10n.password,
                      prefixIcon: Icons.lock_outline,
                    ),
              ],
            );

            if (isIOS) {
              return CupertinoAlertDialog(
                title: Text(l10n.confirmPassword),
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: contentWidget,
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: isLoading ? null : () => Navigator.pop(ctx),
                    child: Text(l10n.cancel),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: isLoading ? null : handleEnable,
                    child: isLoading 
                      ? const CupertinoActivityIndicator() 
                      : Text(l10n.enable),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: Text(l10n.confirmPassword, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: contentWidget,
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleEnable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(l10n.enable),
                ),
              ],
            );
          }
        );
      }
    );
  }
}

class BulletItem extends StatelessWidget {
  final String text;
  const BulletItem({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
