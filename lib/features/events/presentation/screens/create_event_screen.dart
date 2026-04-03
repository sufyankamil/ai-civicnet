import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.postAnEventTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(AppLocalizations.of(context)!.eventDetails),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: AppLocalizations.of(context)!.eventTitleHint,
                controller: _titleController,
                validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.required : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.eventDescriptionHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.required : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(AppLocalizations.of(context)!.whenAndWhere),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: AppLocalizations.of(context)!.dateLabel,
                      value: _getLocalizedDate(context, _selectedDate),
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      label: AppLocalizations.of(context)!.timeLabel,
                      value: _selectedTime.format(context),
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: AppLocalizations.of(context)!.locationNameHint,
                controller: _locationController,
                validator: (v) => (v == null || v.isEmpty) ? AppLocalizations.of(context)!.required : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickLocationOnMap,
                icon: const Icon(Icons.map),
                label: Text(_selectedLatLng == null 
                    ? AppLocalizations.of(context)!.selectLocationOnMap 
                    : AppLocalizations.of(context)!.changeLocationOnMap),
              ),
              if (_selectedLatLng != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    AppLocalizations.of(context)!.selectedLocation(
                      _selectedLatLng!.latitude.toStringAsFixed(4),
                      _selectedLatLng!.longitude.toStringAsFixed(4),
                    ),
                    style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 48),
              Obx(() => PrimaryButton(
                text: AppLocalizations.of(context)!.postAnEvent,
                isLoading: _viewModel.isLoading,
                onPressed: _submitEvent,
              )),
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
      ),
    );
  }

  Widget _buildPickerTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
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
