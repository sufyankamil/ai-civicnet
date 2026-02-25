import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../components/social_login_button.dart';
import '../../../../components/social_icons.dart';
import 'package:get/get.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../services/toast_service.dart';

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

  final AuthViewModel _authViewModel = Get.find<AuthViewModel>();

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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue connecting with your community.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                CustomTextField(
                  hintText: 'Email Address',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Forgot Password?',
                        style: TextStyle(color: Theme.of(context).primaryColor)),
                  ),
                ),
                const SizedBox(height: 24),
                Obx(() => PrimaryButton(
                  text: 'Login',
                  isLoading: _authViewModel.isLoading,
                  onPressed: _handleLogin,
                )),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: Text('Sign Up',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildSocialButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
