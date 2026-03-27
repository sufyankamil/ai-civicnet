import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;

  final client = SupabaseClient(supabaseUrl, supabaseKey);

  try {
    final response = await client.from('help_requests').select('id, title, embedding');
    final List<dynamic> requests = response;

    int total = requests.length;
    int withEmbedding = 0;
    int withoutEmbedding = 0;

    print('\n--- Help Requests in Database ---');
    for (var req in requests) {
      bool hasEmbedding = req['embedding'] != null;
      if (hasEmbedding) {
         withEmbedding++;
         print('✅ [WITH EMBEDDING] ${req['id']} - ${req['title']}');
         // Check dimension of the first one
         List<dynamic> vector = req['embedding'];
         print('   -> Vector dimension: ${vector.length}');
      } else {
         withoutEmbedding++;
         print('❌ [NO EMBEDDING] ${req['id']} - ${req['title']}');
      }
    }

    print('\nSummary: $total total requests. $withEmbedding have embeddings, $withoutEmbedding do not.');
    
    // Attempt an RPC call to test matching directly
    if (withEmbedding > 0) {
      print('\n--- Testing match_requests_v3 RPC against first request ---');
      final firstEmbeddingRequest = requests.firstWhere((r) => r['embedding'] != null);
      
      final rpcResponse = await client.rpc('match_requests_v3', params: {
        'query_embedding': firstEmbeddingRequest['embedding'],
        'match_threshold': 0.0,
        'match_count': 10,
        'excluded_id': null,
      });
      print('RPC Response length: ${(rpcResponse as List).length}');
      for(var match in rpcResponse) {
        print(' - Matches: ${match['title']} (Score: ${(match['similarity'] * 100).toStringAsFixed(1)}%)');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
