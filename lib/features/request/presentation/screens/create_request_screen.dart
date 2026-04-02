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
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
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
    _checkPermission(request: false);
  }

  Future<void> _checkPermission({bool request = false}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    } else if (permission == LocationPermission.deniedForever && request) {
      await Geolocator.openAppSettings();
      return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              title: Text(
                'New Request',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              leading: Center(
                child: AppHaptic(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: const Alignment(0.7, -0.6),
            radius: 1.5,
            colors: [
              AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 32),
          child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('What do you need help with?'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.5 : 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.1 : 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.requestDescriptionHint,
                        contentPadding: const EdgeInsets.all(16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (_containsBannedWords(v)) {
                          return 'These words are not allowed.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppHaptic(
                    onTap: _isCategorizing ? null : _detectCategory,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCategorizing)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            _isCategorizing ? 'ANALYZING...' : 'AUTO-CATEGORIZE',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'This feature is in beta and can make mistakes.',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Category'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: HelpCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return AppHaptic(
                    onTap: () => setState(() => _selectedCategory = isSelected ? null : cat),
                    child: _buildPremiumChip(
                      _categoryName(cat),
                      isSelected ? AppColors.primaryLight : Colors.grey,
                      isSelected: isSelected,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Location'),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    if ((_permission == LocationPermission.always || _permission == LocationPermission.whileInUse) && _currentPosition != null)
                      AppHaptic(
                        onTap: _openInMaps,
                        child: Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${_currentPosition!.latitude},${_currentPosition!.longitude}&zoom=14&size=600x300&markers=color:red%7C${_currentPosition!.latitude},${_currentPosition!.longitude}&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey.withValues(alpha: 0.05),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off_rounded, color: Colors.grey[400], size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _permission == LocationPermission.deniedForever 
                                  ? 'Location Access Restricted' 
                                  : 'Location Permission Missing', 
                                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold)
                              ),
                              TextButton(
                                onPressed: () => _permission == LocationPermission.deniedForever ? Geolocator.openAppSettings() : _checkPermission(request: true), 
                                child: Text(_permission == LocationPermission.deniedForever ? 'Go to Settings' : 'Grant Permission')
                              ),
                            ],
                          ),
                        ),
                      ),
                    if ((_permission == LocationPermission.always || _permission == LocationPermission.whileInUse) && _currentPosition != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Current Location',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Urgency'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _urgencyColor(_selectedUrgency).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _urgencyColor(_selectedUrgency).withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                      ),
                      child: Slider(
                        value: _selectedUrgency.index.toDouble(),
                        min: 0,
                        max: 3,
                        divisions: 3,
                        activeColor: _urgencyColor(_selectedUrgency),
                        inactiveColor: _urgencyColor(_selectedUrgency).withValues(alpha: 0.2),
                        onChanged: (val) {
                          setState(() => _selectedUrgency = UrgencyLevel.values[val.toInt()]);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _urgencyName(_selectedUrgency).toUpperCase(),
                      style: TextStyle(
                        color: _urgencyColor(_selectedUrgency),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
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
    ),
  );
}

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildPremiumChip(String label, Color color, {bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          fontSize: 13,
        ),
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

  Future<void> _openInMaps() async {
    if (_currentPosition == null) return;
    
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    final String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final String appleUrl = 'https://maps.apple.com/?q=$lat,$lng';

    if (Platform.isIOS) {
      final uri = Uri.parse(appleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
      }
    } else {
      final uri = Uri.parse(googleUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
