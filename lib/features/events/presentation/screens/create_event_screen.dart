import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../components/custom_textfield.dart';
import '../../../../components/primary_button.dart';
import '../../../../services/toast_service.dart';
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
      ToastService.showSuccess(context, 'Location selected on map');
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

      final newEvent = LocalEvent(
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
          ToastService.showSuccess(context, 'Event posted successfully!');
        } else {
          ToastService.showError(context, 'Failed to post event. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post an Event',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Event Details'),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Event Title (e.g., Park Cleanup)',
                controller: _titleController,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what\'s happening...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('When & Where'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      label: 'Date',
                      value: DateFormat('MMM d, yyyy').format(_selectedDate),
                      icon: Icons.calendar_today,
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerTile(
                      label: 'Time',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Location Name (e.g., Central Park)',
                controller: _locationController,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pickLocationOnMap,
                icon: const Icon(Icons.map),
                label: Text(_selectedLatLng == null ? 'Select exact location on map' : 'Change location on map'),
              ),
              if (_selectedLatLng != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    'Selected: ${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 48),
              Obx(() => PrimaryButton(
                text: 'Post Event',
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
      style: GoogleFonts.poppins(
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
}
