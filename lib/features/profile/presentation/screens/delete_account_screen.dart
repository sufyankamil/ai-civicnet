import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/pending_toast_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      setState(() {
        _isConfirmed = _confirmController.text.trim() == 'DELETE';
      });
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDeleteAccount() async {
    if (!_isConfirmed) return;

    setState(() => _isLoading = true);

    try {
      // Queue the toast BEFORE deletion — auth redirect fires immediately on signOut,
      // so we store it in a singleton and display it on the next screen.
      PendingToastService().setSuccess('Your account has been deleted successfully.');

      await SupabaseService().deleteUserAccount();
      // GoRouter's refreshListenable now redirects to /onboarding automatically.
      // The pending toast will be consumed there.
    } catch (e) {
      // Clear the pending toast since deletion failed
      PendingToastService().consumeSuccess();
      logger.e('Failed to delete account: $e');
      if (mounted) {
        ToastService.showError(
          context,
          'Failed to delete account. Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'civicnet.app@gmail.com',
      queryParameters: {'subject': 'Feedback / Support Request'},
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
         ToastService.showError(context, 'Could not open email client.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delete Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                'We hate to see you go',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'If you delete your account, your profile, active requests, and all associated data will be permanently deleted. This action cannot be undone.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you experiencing issues?',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Before you leave, please consider reaching out. We are here to help and would love your feedback to improve CivicNet.',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _contactSupport,
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Contact Support'),
                      style: OutlinedButton.styleFrom(
                         foregroundColor: Theme.of(context).primaryColor,
                         side: BorderSide(color: Theme.of(context).primaryColor),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              Text(
                'To verify your request, please type "DELETE" below:',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConfirmed && !_isLoading ? _handleDeleteAccount : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : Text(
                          'Permanently Delete Account',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Cancel & Go Back',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
