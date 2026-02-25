import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../models/models.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final Set<HelpCategory> _selectedSkills = {};
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final Map<HelpCategory, String> _skillLabels = {
    HelpCategory.techSupport: 'Tech Support',
    HelpCategory.household: 'Household Tasks',
    HelpCategory.errands: 'Errands & Shopping',
    HelpCategory.education: 'Tutoring & Education',
    HelpCategory.transport: 'Rides & Transport',
    HelpCategory.emergency: 'Emergency Help',
    HelpCategory.health: 'Health & Care',
    HelpCategory.other: 'Other Skills',
  };

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCompleteProfile() async {
    setState(() => _isLoading = true);

    try {
      final user = await SupabaseService().getCurrentUserProfile();
      if (user == null) throw Exception("User not found");

      String avatarUrl = '';
      if (_selectedImage != null) {
        final uploadedUrl = await StorageService().uploadAvatar(_selectedImage!, user.id);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        } else {
           if (mounted) {
             ToastService.showError(context, 'Failed to upload image. Using default avatar.');
           }
        }
      }

      final skillsList = _selectedSkills.map((s) => s.toString().split('.').last).toList();

      await SupabaseService().updateUserProfile(
        user.name,
        avatarUrl,
        skillsList,
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        logger.e('Failed to update profile: $e');
        ToastService.showError(context, 'Could not save profile setup. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Complete Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to CivicNet!',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add an avatar and select your skills to help us match you with community requests.',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),

              // Avatar Selection
              Center(
                child: GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: _selectedImage == null ? 0.3 : 1.0),
                            width: 3,
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Tap to upload a photo (Optional)',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 32),

              Text(
                'Your Skills',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'What kind of help can you offer? Select all that apply:',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: HelpCategory.values.map((category) {
                  final isSelected = _selectedSkills.contains(category);
                  return FilterChip(
                    label: Text(_skillLabels[category] ?? 'Unknown'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSkills.add(category);
                        } else {
                          _selectedSkills.remove(category);
                        }
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
              ),

              const SizedBox(height: 48),

              PrimaryButton(
                text: 'Finish Setup',
                isLoading: _isLoading,
                onPressed: _handleCompleteProfile,
              ),
              
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey[600]),
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
