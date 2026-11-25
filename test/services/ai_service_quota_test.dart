import 'package:civic_net/services/ai_gateway.dart';
import 'package:civic_net/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FakeGateway implements AiGateway {
  Object? error;
  String text = 'ai reply';
  List<double> embedding = List<double>.filled(800, 0.5);
  final calls = <(AiFeature, String, List<AiHistoryTurn>)>[];

  @override
  Future<String> generateText({
    required AiFeature feature,
    required String prompt,
    List<AiHistoryTurn> history = const [],
  }) async {
    calls.add((feature, prompt, history));
    if (error != null) throw error!;
    return text;
  }

  @override
  Future<List<double>> embed(String text, {String? taskType}) async {
    if (error != null) throw error!;
    return embedding;
  }
}

class _FakeUser {
  final points = 0;
  final helpCount = 0;
  final karmaLevel = 'Newcomer';
  final neighborsImpacted = 0;
}

void main() {
  late FakeGateway gateway;
  final service = AiService();

  setUp(() {
    gateway = FakeGateway();
    service.setGateway(gateway);
  });

  final quota = AiQuotaExceededException(limit: 10);

  group('metered methods surface quota exhaustion', () {
    test('generateChatResponse rethrows instead of falling back', () async {
      gateway.error = quota;
      expect(
        () => service.generateChatResponse(query: 'q', context: 'ctx'),
        throwsA(isA<AiQuotaExceededException>()),
      );
    });

    test('parseVoiceTask rethrows instead of using heuristics', () async {
      gateway.error = quota;
      expect(
        () => service.parseVoiceTask('my sink is leaking'),
        throwsA(isA<AiQuotaExceededException>()),
      );
    });

    test('generateSupportChatResponse rethrows', () async {
      gateway.error = quota;
      expect(
        () => service.generateSupportChatResponse(userQuery: 'how?'),
        throwsA(isA<AiQuotaExceededException>()),
      );
    });

    test('generateCommunityBriefing rethrows', () async {
      gateway.error = quota;
      expect(
        () => service.generateCommunityBriefing(
          requests: const [],
          events: const [],
          user: _FakeUser(),
        ),
        throwsA(isA<AiQuotaExceededException>()),
      );
    });
  });

  group('non-quota failures keep the existing fallbacks', () {
    test('chat falls back to community context', () async {
      gateway.error = AiGatewayException(500, 'down');
      final result = await service.generateChatResponse(
        query: 'q',
        context: 'nearby help request',
      );
      expect(result, contains('nearby help request'));
    });

    test('voice task falls back to heuristics', () async {
      gateway.error = AiGatewayException(500, 'down');
      final result = await service.parseVoiceTask('my sink is leaking');
      expect(result.usedAi, isFalse);
      expect(result.categoryString, 'HOUSEHOLD');
    });

    test('support chat falls back to the local knowledge base', () async {
      gateway.error = AiGatewayException(500, 'down');
      final result = await service.generateSupportChatResponse(
        userQuery: 'how does matching work',
      );
      expect(result.usedAi, isFalse);
    });

    test('categorizeRequest returns null on failure', () async {
      gateway.error = AiGatewayException(500, 'down');
      expect(await service.categorizeRequest('t', 'd'), isNull);
    });
  });

  group('routes through the gateway with the right feature', () {
    test('chat uses assistantChat and returns the reply', () async {
      final result = await service.generateChatResponse(
        query: 'q',
        context: 'ctx',
        history: [
          Content('user', [TextPart('earlier')]),
        ],
      );
      expect(result, 'ai reply');
      expect(gateway.calls.single.$1, AiFeature.assistantChat);
      expect(gateway.calls.single.$3.single.text, 'earlier');
      expect(gateway.calls.single.$3.single.role, 'user');
    });

    test('search query uses the unmetered assistantSearch feature', () async {
      await service.generateSearchQuery('find a plumber');
      expect(gateway.calls.single.$1, AiFeature.assistantSearch);
    });

    test('categorize uses the unmetered categorize feature', () async {
      gateway.text = 'household';
      expect(await service.categorizeRequest('t', 'd'), 'HOUSEHOLD');
      expect(gateway.calls.single.$1, AiFeature.categorize);
    });

    test('voice task parses JSON from the gateway', () async {
      gateway.text =
          '{"title":"Fix sink","description":"d","category":"household",'
          '"urgency":"high","suggested_tools":["Wrench"]}';
      final result = await service.parseVoiceTask('sink leak');
      expect(result.usedAi, isTrue);
      expect(result.title, 'Fix sink');
      expect(result.categoryString, 'HOUSEHOLD');
      expect(gateway.calls.single.$1, AiFeature.voiceTask);
    });

    test('generateEmbedding truncates to 768 dimensions', () async {
      final values = await service.generateEmbedding('text');
      expect(values, hasLength(768));
    });
  });
}
