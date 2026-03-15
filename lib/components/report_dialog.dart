import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'primary_button.dart';

class ReportDialog extends StatefulWidget {
  final String title;
  final Function(String reason) onReport;

  const ReportDialog({
    super.key,
    required this.title,
    required this.onReport,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  bool _isLoading = false;
  final List<String> _reasons = [
    'Scam or Fraud',
    'Harassment or Abuse',
    'Inappropriate Content',
    'Spam',
    'Soliciting Money',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _reasons.map((reason) {
            final isSelected = _selectedReason == reason;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryLight.withValues(alpha: 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryLight : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: _isLoading ? null : () => setState(() => _selectedReason = reason),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? AppColors.primaryLight : Colors.grey,
                  size: 20,
                ),
                title: Text(
                  reason,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
        SizedBox(
          width: 100,
          child: PrimaryButton(
            text: 'Report',
            isLoading: _isLoading,
            onPressed: _selectedReason == null || _isLoading
              ? null 
              : () async {
                setState(() => _isLoading = true);
                try {
                  await widget.onReport(_selectedReason!);
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
          ),
        ),
      ],
    );
  }
}
