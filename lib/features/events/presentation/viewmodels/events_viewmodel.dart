import 'package:get/get.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../models/event.dart';

class EventsViewModel extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();
  
  final RxList<LocalEvent> _events = <LocalEvent>[].obs;
  List<LocalEvent> get events => _events;

  // Filtered lists
  List<LocalEvent> get upcomingEvents => _events
      .where((e) => e.eventDate.isAfter(DateTime.now()))
      .toList();
      
  List<LocalEvent> get pastEvents => _events
      .where((e) => e.eventDate.isBefore(DateTime.now()))
      .toList();
  
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    _isLoading.value = true;
    try {
      final fetchedEvents = await _supabaseService.getLocalEvents();
      _events.assignAll(fetchedEvents);
    } catch (e) {
      logger.e('Error in EventsViewModel.fetchEvents: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> createEvent(LocalEvent event) async {
    _isLoading.value = true;
    try {
      await _supabaseService.createLocalEvent(event);
      await fetchEvents();
      return true;
    } catch (e) {
      logger.e('Error in EventsViewModel.createEvent: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String?> deleteEvent(String eventId) async {
    _isLoading.value = true;
    try {
      await _supabaseService.deleteLocalEvent(eventId);
      _events.removeWhere((e) => e.id == eventId);
      return null; // Success
    } catch (e) {
      final errorMsg = e.toString().contains('Permission denied') 
          ? 'Permission denied: You are not the creator.' 
          : 'Failed to delete event: $e';
      logger.e('Error in EventsViewModel.deleteEvent: $e');
      return errorMsg;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggleRSVP(String eventId, bool isJoining) async {
    try {
      await _supabaseService.rsvpToEvent(eventId, isJoining);
      
      // Update local state for immediate feedback
      final index = _events.indexWhere((e) => e.id == eventId);
      if (index != -1) {
        final event = _events[index];
        _events[index] = event.copyWith(
          isUserAttending: isJoining,
          attendeeCount: isJoining ? event.attendeeCount + 1 : event.attendeeCount - 1,
        );
      }
    } catch (e) {
      logger.e('Error in EventsViewModel.toggleRSVP: $e');
    }
  }
}
