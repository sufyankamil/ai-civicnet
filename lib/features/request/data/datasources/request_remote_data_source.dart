import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../models/help_request_model.dart';
import '../../domain/entities/request_enums.dart';
import '../../../../core/utils/timeout_extension.dart';

abstract class RequestRemoteDataSource {
  Future<List<dynamic>> getRawHelpRequests();
  Future<List<dynamic>> getMyRawHelpRequests(String userId);
  Future<dynamic> getRawHelpRequest(String id);
  Future<void> createHelpRequest(HelpRequestModel request);
  Future<void> updateHelpRequestStatus(String requestId, RequestStatusEnum status);
  
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
          .select('*, profiles:requester_id(name, avatar_url)')
          .order('created_at', ascending: false)
          .withServerTimeout();

      return response as List<dynamic>;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<dynamic>> getMyRawHelpRequests(String userId) async {
    try {
      final response = await supabaseClient
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .eq('requester_id', userId)
          .order('created_at', ascending: false)
          .withServerTimeout();

      return response as List<dynamic>;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<dynamic> getRawHelpRequest(String id) async {
    try {
      final response = await supabaseClient
          .from('help_requests')
          .select('*, profiles:requester_id(name, avatar_url)')
          .eq('id', id)
          .single()
          .withServerTimeout();
          
      return response;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> createHelpRequest(HelpRequestModel request) async {
    try {
      final userId = supabaseClient.auth.currentUser?.id;
      if (userId == null) throw ServerException('User not authenticated.');

      await supabaseClient.from('help_requests').insert({
        'requester_id': userId,
        'title': request.title,
        'description': request.description,
        'category': request.category.toString().split('.').last,
        'urgency': request.urgency.toString().split('.').last,
        'lat': request.lat,
        'lng': request.lng,
        'location_name': request.locationName,
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
