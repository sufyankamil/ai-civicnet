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
import '../components/auth_background.dart';
import '../../../profile/presentation/components/slide_fade_transition.dart';
import 'dart:ui';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        AppLocalizations.of(context)!.createAccount,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Theme.of(context).primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 250),
                      child: Text(
                        AppLocalizations.of(context)!.joinCommunity,
                        style: TextStyle(
                          fontSize: 16, 
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Premium Glassmorphic Card
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 400),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            decoration: BoxDecoration(
                              color: isDark 
                                ? Colors.white.withValues(alpha: 0.05) 
                                : Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 450),
                                    child: CustomTextField(
                                      hintText: AppLocalizations.of(context)!.fullName,
                                      prefixIcon: Icons.person_outline,
                                      controller: _nameController,
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return AppLocalizations.of(context)!.enterName;
                                        if (value.trim().length < 3) return AppLocalizations.of(context)!.nameTooShort;
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 550),
                                    child: CustomTextField(
                                      hintText: AppLocalizations.of(context)!.emailAddress,
                                      prefixIcon: Icons.email_outlined,
                                      controller: _emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterEmail;
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 650),
                                    child: CustomTextField(
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
                                  ),
                                  
                                  // Password requirements within the glass card
                                  if (_passwordController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        children: _buildPasswordRequirements(),
                                      ),
                                    ),
                                    
                                  const SizedBox(height: 12),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 750),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: Checkbox(
                                            value: _acceptTerms,
                                            activeColor: Theme.of(context).primaryColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                                                  fontSize: 12,
                                                  color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.7),
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: AppLocalizations.of(context)!.termsAndConditions,
                                                    style: TextStyle(
                                                      fontSize: 12,
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
                                  ),
                                  const SizedBox(height: 28),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 850),
                                    child: Obx(() => PrimaryButton(
                                      text: AppLocalizations.of(context)!.signup,
                                      isLoading: _authViewModel.isLoading,
                                      onPressed: _acceptTerms ? _handleSignup : null,
                                    )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.alreadyHaveAccount.split('?').first}?',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              AppLocalizations.of(context)!.login,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
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
              met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 16,
              color: met ? Colors.green[400] : Colors.grey.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.grey.withValues(alpha: 0.6),
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
