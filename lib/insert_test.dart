import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final supabaseUrl = Platform.environment['SUPABASE_URL']!;
  final serviceRole = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  final anonKey = Platform.environment['SUPABASE_ANON_KEY']!;
  
  final dummyVector = List<double>.generate(768, (index) => 0.01);
  final client = SupabaseClient(supabaseUrl, serviceRole ?? anonKey);

  try {
    print('Inserting dummy request with embedding...');
    // If using anon_key without auth, RLS might reject it!
    // But let's try. If it inserts, we can see if embedding is null.
    final result = await client.from('help_requests').insert({
      // Provide valid mock data
      'requester_id': '00b415f8-7ea3-4eac-8fd1-ef4b258613d9', // Mocking android's ID for safety
      'title': 'DUMMY VECTOR TEST',
      'description': 'Testing if vector saves',
      'category': 'other',
      'urgency': 'low',
      'lat': 0.0,
      'lng': 0.0,
      'location_name': 'Test',
      'status': 'open',
      'embedding': dummyVector, // Test saving a 768 dimension vector
    }).select().single();

    print('Insert Result:');
    print('- ID: ${result['id']}');
    print('- Is Embedding Null?: ${result['embedding'] == null}');
    if (result['embedding'] != null) {
       print('- Embedding Length: ${(result['embedding'] as List).length}');
    }

  } catch (e) {
    print('Failed to insert: $e');
  }
  exit(0);
}
