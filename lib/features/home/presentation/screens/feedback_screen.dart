import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  final TextEditingController _descriptionController = TextEditingController();
  File? _screenshot;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _screenshot = File(image.path);
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      ToastService.showInfo(context, 'Please select a rating');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ToastService.showInfo(context, 'Please provide some description');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? screenshotUrl;
      if (_screenshot != null) {
        screenshotUrl = await SupabaseService().uploadFeedbackScreenshot(_screenshot!);
      }

      await SupabaseService().submitFeedback(
        rating: _rating,
        description: _descriptionController.text.trim(),
        screenshotUrl: screenshotUrl,
      );

      if (mounted) {
        ToastService.showSuccess(context, 'Thank you for your valuable feedback!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Failed to submit feedback. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.appFeedback, style: const TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Added bottom padding for keyboard clearance
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.stars_rounded, color: AppColors.primaryLight, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'How is your experience?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve Civic Net for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Rating',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < _rating ? Colors.amber : Colors.grey[400],
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.feedbackHint,
                hintStyle: TextStyle(fontSize: 14),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Screenshot (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _screenshot != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _screenshot!,
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _screenshot = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400], size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Screenshot',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
