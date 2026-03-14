import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../models/event.dart';
import '../../models/event_comment.dart';

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
    
    // Listen for auth state changes to refresh events for the new user (location, RSVPs, etc.)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        fetchEvents();
      }
    });

    fetchEvents();
  }

  Future<void> fetchEvents() async {
    _isLoading.value = true;
    _events.clear(); // Clear old data to avoid showing User A's status to User B
    try {
      final fetchedEvents = await _supabaseService.getLocalEvents();
      _events.assignAll(fetchedEvents);
    } catch (e) {
      logger.e('Error in EventsViewModel.fetchEvents: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearEvents() {
    _events.clear();
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

  // --- Comments ---
  
  final RxList<EventComment> _comments = <EventComment>[].obs;
  List<EventComment> get comments => _comments;
  
  final RxBool _isCommentsLoading = false.obs;
  bool get isCommentsLoading => _isCommentsLoading.value;

  Future<void> fetchComments(String eventId) async {
    _isCommentsLoading.value = true;
    _comments.clear(); // Clear previous event's comments to prevent leakage
    try {
      final fetchedComments = await _supabaseService.getEventComments(eventId);
      _comments.assignAll(fetchedComments);
    } catch (e) {
      logger.e('Error in EventsViewModel.fetchComments: $e');
    } finally {
      _isCommentsLoading.value = false;
    }
  }

  Future<void> postComment(String eventId, String content, {String? parentId}) async {
    try {
      await _supabaseService.postEventComment(
        eventId: eventId,
        content: content,
        parentId: parentId,
      );
      // Re-fetch all comments to update threaded view
      await fetchComments(eventId);
    } catch (e) {
      logger.e('Error in EventsViewModel.postComment: $e');
    }
  }

  Future<void> deleteComment(String eventId, String commentId) async {
    try {
      await _supabaseService.deleteEventComment(commentId);
      await fetchComments(eventId);
    } catch (e) {
      logger.e('Error in EventsViewModel.deleteComment: $e');
    }
  }
}
