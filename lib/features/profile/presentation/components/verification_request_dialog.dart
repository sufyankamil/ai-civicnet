import 'package:flutter/material.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../widgets/haptic_buttons.dart';

class VerificationRequestDialog extends StatefulWidget {
  const VerificationRequestDialog({super.key});

  @override
  State<VerificationRequestDialog> createState() => _VerificationRequestDialogState();
}

class _VerificationRequestDialogState extends State<VerificationRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ToastService.showError(context, 'Please provide a reason');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService().submitVerificationRequest(reason);
      if (mounted) {
        Navigator.pop(context, true);
        ToastService.showSuccess(context, 'Request submitted successfully!');
      }
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Failed to submit request: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Apply for Leader Status',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explain why you want to become a community leader. This will be reviewed by existing admins.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your role or contributions to the community...',
              hintStyle: TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
            ),
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        AppTextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Request'),
        ),
      ],
    );
  }
}
