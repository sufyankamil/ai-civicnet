import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../../../components/custom_textfield.dart';

class PollCreationScreen extends StatefulWidget {
  const PollCreationScreen({super.key});

  @override
  State<PollCreationScreen> createState() => _PollCreationScreenState();
}

class _PollCreationScreenState extends State<PollCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 5) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    } else {
      ToastService.showInfo(context, AppLocalizations.of(context)!.maxOptionsAllowed);
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final options = _optionControllers.map((c) => c.text).toList();
      await SupabaseService().createPoll(
        _questionController.text,
        options,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      );
      
      if (mounted) {
        ToastService.showSuccess(context, AppLocalizations.of(context)!.pollCreatedSuccessfully);
        Get.find<HomeViewModel>().fetchPolls();
        context.pop();
      }
    } catch (e) {
      if (mounted) ToastService.showError(context, '${AppLocalizations.of(context)!.failedToCreatePoll}: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createPoll, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.pollCreationIntro,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              
              Text(AppLocalizations.of(context)!.question, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _questionController,
                hintText: AppLocalizations.of(context)!.pollQuestionHint,
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.fieldRequired : null,
              ),
              const SizedBox(height: 24),

              Text(AppLocalizations.of(context)!.descriptionOptional, style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                hintText: AppLocalizations.of(context)!.pollDescriptionHint,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.options, style: TextStyle(fontWeight: FontWeight.bold)),
                  if (_optionControllers.length < 5)
                    TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context)!.addOption),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ..._optionControllers.asMap().entries.map((entry) {
                final idx = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: controller,
                          hintText: AppLocalizations.of(context)!.optionHint(idx + 1),
                          validator: (v) => v == null || v.isEmpty ? AppLocalizations.of(context)!.fieldRequired : null,
                        ),
                      ),
                      if (_optionControllers.length > 2)
                        IconButton(
                          onPressed: () => _removeOption(idx),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AppElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context)!.createPoll, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
