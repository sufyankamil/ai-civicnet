import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import 'package:get/get.dart';
import '../viewmodels/auth_viewmodel.dart';

import '../../../../theme/app_theme.dart';
import '../../../../services/toast_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  final AuthViewModel _authViewModel = Get.find<AuthViewModel>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    final error = await _authViewModel.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    
    if (mounted) {
      if (error == null) {
        setState(() => _emailSent = true);
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  Future<void> _handleResend() async {
    final error = await _authViewModel.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    
    if (mounted) {
      if (error == null) {
        ToastService.showSuccess(context, AppLocalizations.of(context)!.resetLinkResent);
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _emailSent ? _buildSuccessView(isDark) : _buildFormView(isDark),
        ),
      ),
    );
  }

  // ─── Form view ─────────────────────────────────────────────────────────────

  Widget _buildFormView(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Icon header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.lock_reset_rounded,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 28),
          Text(
            AppLocalizations.of(context)!.forgotPassword,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.noWorriesReset,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          CustomTextField(
            hintText: AppLocalizations.of(context)!.emailAddress,
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.enterEmail;
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return AppLocalizations.of(context)!.enterValidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          Obx(() => PrimaryButton(
            text: AppLocalizations.of(context)!.sendResetLink,
            isLoading: _authViewModel.isLoading,
            onPressed: _handleReset,
          )),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                AppLocalizations.of(context)!.backToLogin,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success view ──────────────────────────────────────────────────────────

  Widget _buildSuccessView(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Animated check circle
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF34C759), Color(0xFF50E3C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34C759).withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: Colors.white, size: 52),
        ),
        const SizedBox(height: 36),
        Text(
          AppLocalizations.of(context)!.checkYourInbox,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppLocalizations.of(context)!.resetSentTo(_emailController.text.trim()),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.linkExpires,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            text: AppLocalizations.of(context)!.backToLogin,
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: _handleResend,
          child: Text(
            AppLocalizations.of(context)!.didntReceive,
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }
}
