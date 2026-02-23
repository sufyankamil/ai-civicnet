
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/custom_textfield.dart';
import '../../components/primary_button.dart';
import '../../components/social_login_button.dart';
import '../../services/supabase_service.dart';
import '../../services/toast_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/social_icons.dart';

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
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService().signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (mounted) {
          context.go('/home');
          ToastService.showSuccess(context, 'Account created! Welcome to CivicNet.');
        }
      } on AuthException catch (e) {
        _showError(e.message);
      } catch (_) {
        _showError('Unexpected error. Please try again.');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await SupabaseService().signInWithGoogle();
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled') && !msg.contains('cancel')) {
        _showError('Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isAppleLoading = true);
    try {
      await SupabaseService().signInWithApple();
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled') && !msg.contains('cancel') && !msg.contains('AuthorizationErrorCode')) {
        _showError('Apple sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ToastService.showError(context, message);
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
                  'Create Account',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join your community to help and be helped.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  hintText: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
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
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Sign Up',
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text('Login',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
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
    return Row(
      children: [
        SocialLoginButton(
          icon: googleIcon(),
          label: 'Google',
          isLoading: _isGoogleLoading,
          onTap: _handleGoogleSignIn,
        ),
        const SizedBox(width: 12),
        SocialLoginButton(
          icon: appleIcon(),
          label: 'Apple',
          isLoading: _isAppleLoading,
          onTap: _handleAppleSignIn,
        ),
      ],
    );
  }
}
