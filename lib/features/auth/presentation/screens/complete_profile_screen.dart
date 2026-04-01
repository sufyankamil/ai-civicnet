import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/logger_service.dart';
import '../../../request/domain/entities/request_enums.dart';
import '../components/auth_background.dart';
import '../../../profile/presentation/components/slide_fade_transition.dart';
import 'dart:ui';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Complete Profile', 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            color: isDark ? Colors.white : Theme.of(context).primaryColor,
            letterSpacing: -0.5,
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
                        'Welcome to CivicNet!',
                        style: TextStyle(
                          fontSize: 32,
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
                        'Add an avatar and select your skills to help us match you with community requests.',
                        style: TextStyle(
                          fontSize: 15, 
                          color: isDark ? Colors.white60 : Colors.grey[700],
                          height: 1.5,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Avatar Selection
                                Center(
                                  child: GestureDetector(
                                    onTap: _showImageSourceDialog,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
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
                                                  Icons.face_unlock_rounded,
                                                  size: 60,
                                                  color: isDark ? Colors.white30 : Colors.grey.shade400,
                                                ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
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
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: isDark ? Colors.white38 : Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 40),

                                Text(
                                  'Your Skills',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 10.0,
                                  children: HelpCategory.values.map((category) {
                                    final isSelected = _selectedSkills.contains(category);
                                    return ChoiceChip(
                                      label: Text(
                                        _skillLabels[category] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                                        ),
                                      ),
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
                                      selectedColor: Theme.of(context).primaryColor,
                                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200],
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 48),

                                PrimaryButton(
                                  text: 'Finish Setup',
                                  isLoading: _isLoading,
                                  onPressed: _handleCompleteProfile,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SlideFadeTransition(
                      delay: const Duration(milliseconds: 600),
                      child: Center(
                        child: TextButton(
                          onPressed: () => context.go('/home'),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
