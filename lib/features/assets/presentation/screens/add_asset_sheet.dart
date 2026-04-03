import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/assets_viewmodel.dart';
import '../../../../models/models.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/toast_service.dart';

class AddAssetSheet extends StatefulWidget {
  final CommunityAsset? asset;

  const AddAssetSheet({super.key, this.asset});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late AssetCategory _category;
  late AssetStatus _status;
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.asset?.title);
    _descriptionController = TextEditingController(text: widget.asset?.description);
    _category = widget.asset?.category ?? AssetCategory.tools;
    _status = widget.asset?.status ?? AssetStatus.available;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<AssetsViewModel>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.asset == null ? 'Add New Asset' : 'Edit Asset',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'List a resource you are willing to lend to neighbors.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                        style: BorderStyle.none,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : widget.asset?.imageUrl != null
                              ? DecorationImage(image: NetworkImage(widget.asset!.imageUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: _imageFile == null && (widget.asset?.imageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              const Text('Add Photo (Optional)', style: TextStyle(fontSize: 12)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                controller: _titleController,
                hintText: 'Asset Title (e.g. Electric Power Drill)',
                validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Description (Condition, rules, or specs...)',
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Category Picker
              DropdownButtonFormField<AssetCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AssetCategory.values.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c.name));
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Status Picker
              DropdownButtonFormField<AssetStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AssetStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()));
                }).toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 32),

              Obx(() => PrimaryButton(
                    onPressed: controller.isLoading ? null : _save,
                    text: controller.isLoading ? 'Saving...' : 'Save Asset',
                    icon: Icons.check,
                  )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final controller = Get.find<AssetsViewModel>();
      bool success;
      
      if (widget.asset == null) {
        success = await controller.addAsset(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category,
          status: _status,
          imageFile: _imageFile,
        );
      } else {
        final updated = widget.asset!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          category: _category,
          status: _status,
        );
        success = await controller.updateAsset(updated, imageFile: _imageFile);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ToastService.showSuccess(
          context,
          widget.asset == null ? 'Asset listed successfully' : 'Asset updated',
        );
      } else if (mounted) {
        ToastService.showError(
          context,
          controller.errorMessage ?? 'An unexpected error occurred',
        );
      }
    }
  }
}
