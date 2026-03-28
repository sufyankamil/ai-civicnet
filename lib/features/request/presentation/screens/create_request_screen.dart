import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';
import '../viewmodels/request_viewmodel.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final RequestViewModel _viewModel = Get.find<RequestViewModel>();

  HelpCategory? _selectedCategory;
  UrgencyLevel _selectedUrgency = UrgencyLevel.medium;
  bool _isCategorizing = false;
  LocationPermission? _permission;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position? pos;
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (e) {
        // Fallback
      }
    }

    setState(() {
      _permission = permission;
      _currentPosition = pos;
    });
  }

  void _detectCategory() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.length + description.length < 10) {
      ToastService.showInfo(
        context,
        'Please enter more details to auto-categorize.',
      );
      return;
    }

    setState(() => _isCategorizing = true);

    final aiService = AiService();
    final categoryString = await aiService.categorizeRequest(title, description);

    if (!mounted) return;

    HelpCategory? detected;
    if (categoryString != null) {
      for (var cat in HelpCategory.values) {
        if (cat.name.toUpperCase() == categoryString) {
          detected = cat;
          break;
        }
      }
    }

    if (detected != null) {
      setState(() {
        _selectedCategory = detected;
        _isCategorizing = false;
      });
      ToastService.showSuccess(
        context,
        'Auto-categorized as ${_categoryName(detected)}',
      );
    } else {
      setState(() => _isCategorizing = false);
      ToastService.showInfo(
        context,
        'Could not auto-categorize. Please select manually.',
      );
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      try {
        Position position;
        if (_currentPosition != null) {
          position = _currentPosition!;
        } else {
          try {
            position = await Geolocator.getCurrentPosition();
          } catch (e) {
            position = Position(
              longitude: 0.0,
              latitude: 0.0,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
          }
        }

        final newRequest = HelpRequestEntity(
          id: '',
          requesterId: '',
          requesterName: '',
          requesterAvatarUrl: '',
          title: _titleController.text,
          description: _descController.text,
          category: _selectedCategory!,
          urgency: _selectedUrgency,
          postedAt: DateTime.now(),
          distance: '',
          aiRelevanceScore: 0,
          locationName: 'Current Location',
          lat: position.latitude,
          lng: position.longitude,
          status: RequestStatusEnum.open,
        );

        final error = await _viewModel.createRequest(newRequest);

        if (mounted) {
          if (error == null) {
            context.pop();
            ToastService.showSuccess(context, 'Request posted successfully!');
          } else {
            ToastService.showError(context, error);
          }
        }
      } catch (e) {
        if (mounted) {
          logger.e('Error creating request: $e');
        }
      }
    } else if (_selectedCategory == null) {
      ToastService.showInfo(context, 'Please select a category');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('What do you need help with?'),
              const SizedBox(height: 8),
              CustomTextField(
                hintText: AppLocalizations.of(context)!.requestTitleHint,
                controller: _titleController,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (_containsBannedWords(v)) {
                    return 'These words are not allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                // removed onChanged
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.requestDescriptionHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (_containsBannedWords(v)) {
                    return 'These words are not allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _isCategorizing ? null : _detectCategory,
                          icon: _isCategorizing
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: Text(
                            _isCategorizing ? 'Analyzing...' : 'Auto-Categorize',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'BETA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        'This feature is in beta and can make mistakes.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HelpCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(_categoryName(cat)),
                    selected: isSelected,
                    onSelected: (selected) => setState(
                      () => _selectedCategory = selected ? cat : null,
                    ),
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2),
                    backgroundColor: Theme.of(context).cardColor,
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black87),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Location'),
              const SizedBox(height: 8),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image:
                      (_permission == LocationPermission.always ||
                              _permission == LocationPermission.whileInUse) &&
                          _currentPosition != null
                      ? DecorationImage(
                          image: NetworkImage(
                            'https://maps.googleapis.com/maps/api/staticmap?center=${_currentPosition!.latitude},${_currentPosition!.longitude}&zoom=14&size=600x300&markers=color:red%7C${_currentPosition!.latitude},${_currentPosition!.longitude}&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Center(
                  child:
                      (_permission == LocationPermission.always ||
                          _permission == LocationPermission.whileInUse)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Current Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_off,
                              color: Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Location permission not given',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _checkPermission,
                              child: const Text('Retry Permission'),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Urgency'),
              const SizedBox(height: 8),
              Slider(
                value: _selectedUrgency.index.toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                label: _urgencyName(_selectedUrgency),
                activeColor: _urgencyColor(_selectedUrgency),
                onChanged: (val) {
                  setState(
                    () => _selectedUrgency = UrgencyLevel.values[val.toInt()],
                  );
                },
              ),
              Center(
                child: Text(
                  _urgencyName(_selectedUrgency).toUpperCase(),
                  style: TextStyle(
                    color: _urgencyColor(_selectedUrgency),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Obx(() {
                final hasBannedWords =
                    _containsBannedWords(_titleController.text) ||
                    _containsBannedWords(_descController.text);
                return PrimaryButton(
                  text: 'Post Request',
                  isLoading: _viewModel.isLoading,
                  onPressed: hasBannedWords ? null : () => _submitRequest(),
                );
              }),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87,
      ),
    );
  }

  bool _containsBannedWords(String text) {
    var bannedWords = ['sex', 'porn', 'pornography', 'hate', 'death'];
    var lowerText = text.toLowerCase();
    for (var word in bannedWords) {
      if (lowerText.contains(word)) return true;
    }
    return false;
  }

  String _categoryName(HelpCategory cat) {
    return cat.toString().split('.').last.toUpperCase();
  }

  String _urgencyName(UrgencyLevel level) {
    return level.toString().split('.').last;
  }

  Color _urgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.low:
        return Colors.green;
      case UrgencyLevel.medium:
        return Colors.orange;
      case UrgencyLevel.high:
        return Colors.deepOrange;
      case UrgencyLevel.critical:
        return Colors.red;
    }
  }
}
