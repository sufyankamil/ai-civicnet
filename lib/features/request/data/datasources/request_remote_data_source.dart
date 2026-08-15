import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../models/help_request_model.dart';
import '../../domain/entities/request_enums.dart';
import '../../../../core/utils/timeout_extension.dart';
import '../../../../core/utils/safe_profile_embed.dart';
import '../../../../services/ai_service.dart';

abstract class RequestRemoteDataSource {
  Future<List<dynamic>> getRawHelpRequests();
  Future<List<dynamic>> getMyRawHelpRequests(String userId);
  Future<dynamic> getRawHelpRequest(String id);
  Future<void> createHelpRequest(HelpRequestModel request);
  Future<void> updateHelpRequestStatus(String requestId, RequestStatusEnum status);
  Future<void> deleteHelpRequest(String requestId);
  
  void subscribeToHelpRequests(Function() callback);
  void unsubscribeFromHelpRequests();
}

class RequestRemoteDataSourceImpl implements RequestRemoteDataSource {
  final sb.SupabaseClient supabaseClient;
  sb.RealtimeChannel? _subscription;

  RequestRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<dynamic>> getRawHelpRequests() async {
    try {
      final response = await supabaseClient
          .from('help_requests')
          .select('*')
          .order('created_at', ascending: false)
          .withServerTimeout();

      return await attachSafeProfiles(
        supabaseClient,
        response as List<dynamic>,
        userIdKey: 'requester_id',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<dynamic>> getMyRawHelpRequests(String userId) async {
    try {
      final response = await supabaseClient
          .from('help_requests')
          .select('*')
          .eq('requester_id', userId)
          .order('created_at', ascending: false)
          .withServerTimeout();

      return await attachSafeProfiles(
        supabaseClient,
        response as List<dynamic>,
        userIdKey: 'requester_id',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<dynamic> getRawHelpRequest(String id) async {
    try {
      final response = await supabaseClient
          .from('help_requests')
          .select('*')
          .eq('id', id)
          .single()
          .withServerTimeout();

      return await attachSafeProfile(
        supabaseClient,
        Map<String, dynamic>.from(response as Map),
        userIdKey: 'requester_id',
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createHelpRequest(HelpRequestModel request) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated.');

      // Generate AI embedding
      final categoryStr = request.category.toString().split('.').last;
      final embedding = await AiService().generateRequestEmbedding(
        request.title,
        request.description,
        categoryStr,
      );

      await supabaseClient.from('help_requests').insert({
        'requester_id': userId,
        'title': request.title,
        'description': request.description,
        'category': categoryStr,
        'urgency': request.urgency.toString().split('.').last,
        'lat': request.lat,
        'lng': request.lng,
        'location_name': request.locationName,
        'embedding': embedding, // Save the vector
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'open',
      }).withServerTimeout();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateHelpRequestStatus(String requestId, RequestStatusEnum status) async {
    try {
      await supabaseClient.from('help_requests').update({
        'status': status.toString().split('.').last,
      }).eq('id', requestId).withServerTimeout();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteHelpRequest(String requestId) async {
    try {
      // 1. Normalize ID (Handle both string and integer IDs for PostgREST)
      final dynamic idValue = int.tryParse(requestId) ?? requestId;

      // 2. Sequential Deep Deletion (Handle related data to bypass constraints)
      
      // Delete any associated ratings
      await supabaseClient
          .from('user_ratings')
          .delete()
          .eq('request_id', idValue)
          .withServerTimeout();

      // Delete any associated notifications
      await supabaseClient
          .from('notifications')
          .delete()
          .eq('related_id', requestId) // relatedIds are usually strings in notifications
          .withServerTimeout();

      // Delete any associated applications
      await supabaseClient
          .from('request_applications')
          .delete()
          .eq('request_id', idValue)
          .withServerTimeout();
          
      // 3. Delete the request itself and VERIFY (Strict check)
      final response = await supabaseClient
          .from('help_requests')
          .delete()
          .eq('id', idValue)
          .select() // Returning the deleted row to confirm it happened
          .withServerTimeout();
      
      // If the list is empty, it means RLS blocked the delete or the row is already gone.
      if ((response as List).isEmpty) {
        throw const ServerException(
          'Failed to delete. You may not have permission or the request was already removed.'
        );
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  void subscribeToHelpRequests(Function() callback) {
    unsubscribeFromHelpRequests();
    _subscription = supabaseClient
      .channel('public:help_requests_module')
      .onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: 'help_requests',
        callback: (payload) {
          callback();
        },
      )
      .subscribe();
  }

  @override
  void unsubscribeFromHelpRequests() {
    _subscription?.unsubscribe();
    _subscription = null;
  }
}
