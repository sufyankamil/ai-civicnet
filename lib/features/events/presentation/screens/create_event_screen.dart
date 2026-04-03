import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/toast_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
import '../../models/event.dart';
import '../viewmodels/events_viewmodel.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  LatLng? _selectedLatLng;
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);

  final EventsViewModel _viewModel = Get.find<EventsViewModel>();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickLocationOnMap() async {
    final result = await context.push<LatLng?>('/location-picker', extra: _selectedLatLng);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _selectedLatLng = result;
      });
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(result.latitude, result.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final String address = [
            if (p.name != null && p.name!.isNotEmpty) p.name,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ].join(', ');
          
          if (address.isNotEmpty) {
            setState(() {
              _locationController.text = address;
            });
          }
        }
      } catch (e) {
        logger.e('Error performing reverse geocoding: $e');
      }

      if (mounted) {
        ToastService.showSuccess(context, AppLocalizations.of(context)!.locationSelectedOnMap);
      }
    }
  }

  void _submitEvent() async {
    if (_formKey.currentState!.validate()) {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newEvent = Event(
        id: '',
        title: _titleController.text,
        description: _descController.text,
        eventDate: eventDateTime,
        locationName: _locationController.text,
        lat: _selectedLatLng?.latitude ?? 0.0,
        lng: _selectedLatLng?.longitude ?? 0.0,
        creatorId: '',
        creatorName: '',
        creatorAvatarUrl: '',
        createdAt: DateTime.now(),
      );

      final success = await _viewModel.createEvent(newEvent);

      if (mounted) {
        if (success) {
          context.pop();
          ToastService.showSuccess(context, AppLocalizations.of(context)!.eventPostedSuccess);
        } else {
          ToastService.showError(context, AppLocalizations.of(context)!.eventPostedError);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
              elevation: 0,
              centerTitle: true,
              systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              title: Text(
                l10n.postAnEventTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
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
            center: const Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.8],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(l10n.eventDetails),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.5 : 0.8),
                    borderRadius: BorderRadius.circular(24),
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
                        hintText: l10n.eventTitleHint,
                        controller: _titleController,
                        validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                      ),
                      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 16, endIndent: 16),
                      TextFormField(
                        controller: _descController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l10n.eventDescriptionHint,
                          contentPadding: const EdgeInsets.all(20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                _buildSectionTitle(l10n.whenAndWhere),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPremiumPickerTile(
                        label: l10n.dateLabel.toUpperCase(),
                        value: _getLocalizedDate(context, _selectedDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPremiumPickerTile(
                        label: l10n.timeLabel.toUpperCase(),
                        value: _selectedTime.format(context),
                        icon: Icons.access_time_filled_rounded,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.5 : 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.1 : 0.2)),
                  ),
                  child: CustomTextField(
                    hintText: l10n.locationNameHint,
                    controller: _locationController,
                    validator: (v) => (v == null || v.isEmpty) ? l10n.required : null,
                  ),
                ),
                
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppHaptic(
                    onTap: _pickLocationOnMap,
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
                          Icon(Icons.map_rounded, size: 16, color: AppColors.primaryLight),
                          const SizedBox(width: 8),
                          Text(
                            (_selectedLatLng == null ? l10n.selectLocationOnMap : l10n.changeLocationOnMap).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                

                const SizedBox(height: 48),
                Obx(() => PrimaryButton(
                  text: l10n.postAnEvent,
                  isLoading: _viewModel.isLoading,
                  onPressed: _submitEvent,
                )),
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

  Widget _buildPremiumPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppHaptic(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.4 : 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.05 : 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 0.5),
                  ),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('MMM d, yyyy', locale).format(date);
  }
}
