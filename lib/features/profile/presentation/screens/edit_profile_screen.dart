import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/firebase_service.dart';
import '../../../../theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skillController = TextEditingController();
  List<String> _skills = [];
  String _currentAvatarUrl = '';
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await SupabaseService().getCurrentUserProfile();
    if (user != null) {
      if (mounted) {
        setState(() {
          _nameController.text = user.name;
          _currentAvatarUrl = user.avatarUrl;
          _skills = List.from(user.skills);
          _countryCode = user.countryCode;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = await SupabaseService().getCurrentUserProfile();
      if (user == null) throw Exception("User not found");

      String avatarToSave = _currentAvatarUrl;
      if (_selectedImage != null) {
        final uploadedUrl = await StorageService().uploadAvatar(_selectedImage!, user.id);
        if (uploadedUrl != null) {
          avatarToSave = uploadedUrl;
        } else {
           if (mounted) {
             ToastService.showError(context, 'Failed to upload image. Keeping previous avatar.');
           }
        }
      }

      await SupabaseService().updateUserProfile(
        _nameController.text.trim(),
        avatarToSave,
        _skills,
        countryCode: _countryCode,
      );
      await FirebaseService().syncCountryTopic(_countryCode);
      if (mounted) {
        ToastService.showSuccess(context, 'Profile updated successfully!');
        context.pop(); // Go back to profile screen
      }
    } catch (e) {
      if (mounted) {
        logger.e('Error updating profile: $e');
        ToastService.showError(context, 'Unable to update profile. Please try again later.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

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
        _currentAvatarUrl = '';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator.adaptive())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
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
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
                                : (_currentAvatarUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: _currentAvatarUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                                        ),
                                      )
                                    : Icon(Icons.person, size: 60, color: Colors.grey.shade400)),
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
                      'Tap to change photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Regional updates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Used only for relevant community and holiday updates. You can change this anytime.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _countryCode,
                    decoration: InputDecoration(
                      labelText: 'Country / region',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.public_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'IN', child: Text('India')),
                      DropdownMenuItem(value: 'US', child: Text('United States')),
                      DropdownMenuItem(value: 'GB', child: Text('United Kingdom')),
                      DropdownMenuItem(value: 'CA', child: Text('Canada')),
                      DropdownMenuItem(value: 'AU', child: Text('Australia')),
                    ],
                    onChanged: (value) => setState(() => _countryCode = value),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Skills & Expertise',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add skills to help neighbors find you (e.g. Plumbing, IT Support, Babysitting)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _skillController,
                          decoration: InputDecoration(
                            labelText: 'Add a skill',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (_) => _addSkill(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _addSkill,
                        icon: const Icon(Icons.add_circle, color: AppColors.primaryLight, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills.map((skill) => Chip(
                      label: Text(skill),
                      backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppColors.primaryLight),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeSkill(skill),
                    )).toList(),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                        : Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
