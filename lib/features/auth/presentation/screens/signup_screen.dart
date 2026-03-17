import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../components/social_login_button.dart';
import 'package:get/get.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../components/social_icons.dart';
import '../../../../services/toast_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptTerms = false;


  final AuthViewModel _authViewModel = Get.find<AuthViewModel>();

  // Password requirement flags (updated live as user types)
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      final pw = _passwordController.text;
      setState(() {
        _hasMinLength = pw.length >= 8;
        _hasUppercase = pw.contains(RegExp(r'[A-Z]'));
        _hasLowercase = pw.contains(RegExp(r'[a-z]'));
        _hasDigit    = pw.contains(RegExp(r'[0-9]'));
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final error = await _authViewModel.signUp(


        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        if (error == null) {
          context.go('/auth-check');
        } else {
          ToastService.showError(context, error);
        }
      }
    }
  }
  Future<void> _handleGoogleSignIn() async {
    final error = await _authViewModel.signInWithGoogle();
    if (mounted) {
      if (error == null) {
        context.go('/auth-check');
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final error = await _authViewModel.signInWithApple();
    if (mounted) {
      if (error == null) {
        context.go('/auth-check');
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.createAccount,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.joinCommunity,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  hintText: AppLocalizations.of(context)!.fullName,
                  prefixIcon: Icons.person_outline,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return AppLocalizations.of(context)!.enterName;
                    if (value.trim().length < 3) return AppLocalizations.of(context)!.nameTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: AppLocalizations.of(context)!.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: AppLocalizations.of(context)!.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterPasswordSignup;
                    if (value.length < 8) return AppLocalizations.of(context)!.passwordTooShort;
                    if (!value.contains(RegExp(r'[A-Z]'))) return AppLocalizations.of(context)!.passwordUppercase;
                    if (!value.contains(RegExp(r'[a-z]'))) return AppLocalizations.of(context)!.passwordLowercase;
                    if (!value.contains(RegExp(r'[0-9]'))) return AppLocalizations.of(context)!.passwordNumber;
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                // Live password requirements widget
                if (_passwordController.text.isNotEmpty) ...
                  _buildPasswordRequirements(),
                // Terms and Conditions checkbox
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        activeColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://privacypolicy-ruddy.vercel.app/terms'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: AppLocalizations.of(context)!.agreeTerms(AppLocalizations.of(context)!.termsAndConditions).split(AppLocalizations.of(context)!.termsAndConditions).first,
                            style: TextStyle(
                              fontSize: 13,
                              color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.7),
                            ),
                            children: [
                              TextSpan(
                                text: AppLocalizations.of(context)!.termsAndConditions,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Obx(() => PrimaryButton(
                  text: AppLocalizations.of(context)!.signup,
                  isLoading: _authViewModel.isLoading,
                  onPressed: _acceptTerms ? _handleSignup : null,
                )),


                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${AppLocalizations.of(context)!.alreadyHaveAccount.split('?').first}?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(AppLocalizations.of(context)!.login,
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                  ],
                ),
                // TODO: Re-enable social login in next release
                // const SizedBox(height: 24),
                // _buildDivider(),
                // const SizedBox(height: 24),
                // _buildSocialButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OR', style: TextStyle(color: Colors.grey.shade500)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildSocialButtons() {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isAndroid)
          Obx(() => SocialLoginButton(
            icon: googleIcon(),
            label: 'Google',
            isLoading: _authViewModel.isGoogleLoading,
            onTap: _handleGoogleSignIn,
          )),
        if (isIOS)
          Obx(() => SocialLoginButton(
            icon: appleIcon(),
            label: 'Apple',
            isLoading: _authViewModel.isAppleLoading,
            onTap: _handleAppleSignIn,
          )),
      ],
    );
  }

  // ─── Password requirements rows ──────────────────────────────────────────

  List<Widget> _buildPasswordRequirements() {
    return [
      const SizedBox(height: 10),
      _reqRow(AppLocalizations.of(context)!.atLeast8Chars, _hasMinLength),
      _reqRow(AppLocalizations.of(context)!.oneUppercase, _hasUppercase),
      _reqRow(AppLocalizations.of(context)!.oneLowercase, _hasLowercase),
      _reqRow(AppLocalizations.of(context)!.oneNumber, _hasDigit),
      const SizedBox(height: 4),
    ];
  }

  Widget _reqRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 16,
              color: met ? const Color(0xFF1B5E20) : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: met ? const Color(0xFF1B5E20) : Colors.grey.shade500,
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
