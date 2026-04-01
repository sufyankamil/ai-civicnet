import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../components/social_login_button.dart';
import '../../../../components/social_icons.dart';
import 'package:get/get.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/biometric_service.dart';
import '../components/auth_background.dart';
import '../../../profile/presentation/components/slide_fade_transition.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _biometricEnabled = false;

  final AuthViewModel _authViewModel = Get.find<AuthViewModel>();

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await BiometricService().isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authenticated = await BiometricService().authenticate(
      localizedReason: AppLocalizations.of(context)!.biometricLoginReason,
    );

    if (authenticated) {
      final creds = await BiometricService().getSavedCredentials();
      if (creds != null) {
        if (!mounted) return;
        final error = await _authViewModel.signIn(
          creds['email']!,
          creds['password']!,
        );

        if (mounted) {
          if (error == null) {
            context.go('/home');
          } else {
             ToastService.showError(context, AppLocalizations.of(context)!.biometricLoginFailed(error));
          }
        }
      } else {
        if (mounted) {
          ToastService.showError(context, AppLocalizations.of(context)!.noCredentialsFound);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final error = await _authViewModel.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        if (error == null) {
          context.go('/home');
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
        context.go('/home');
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final error = await _authViewModel.signInWithApple();
    if (mounted) {
      if (error == null) {
        context.go('/home');
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        AppLocalizations.of(context)!.welcomeBack,
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
                        AppLocalizations.of(context)!.signInToContinue,
                        style: TextStyle(
                          fontSize: 16, 
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Premium Glassmorphic Card
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 400),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(32),
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
                                      hintText: AppLocalizations.of(context)!.emailAddress,
                                      prefixIcon: Icons.email_outlined,
                                      controller: _emailController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterEmail;
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 550),
                                    child: CustomTextField(
                                      hintText: AppLocalizations.of(context)!.password,
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      controller: _passwordController,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return AppLocalizations.of(context)!.enterPassword;
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
                                  const SizedBox(height: 4),
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 600),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => context.push('/forgot-password'),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.forgotPassword,
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  
                                  // Action Row
                                  SlideFadeTransition(
                                    delay: const Duration(milliseconds: 750),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Obx(() => PrimaryButton(
                                            text: AppLocalizations.of(context)!.login,
                                            isLoading: _authViewModel.isLoading,
                                            onPressed: _handleLogin,
                                          )),
                                        ),
                                        if (_biometricEnabled) ...[
                                          const SizedBox(width: 16),
                                          Container(
                                            height: 56, // Match primary button
                                            width: 56,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                defaultTargetPlatform == TargetPlatform.iOS
                                                    ? Icons.face
                                                    : Icons.fingerprint,
                                                color: Theme.of(context).primaryColor,
                                                size: 28,
                                              ),
                                              onPressed: _handleBiometricLogin,
                                              tooltip: AppLocalizations.of(context)!.loginWithBiometrics,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
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
                            '${AppLocalizations.of(context)!.dontHaveAccount.split('?').first}?',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () => context.push('/signup'),
                            child: Text(
                              AppLocalizations.of(context)!.signup,
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
}
