import 'package:civic_net/services/ai_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProxyAiGateway.generateText', () {
    test('sends feature wire name, prompt and history to the proxy', () async {
      Map<String, dynamic>? sent;
      final gateway = ProxyAiGateway((body) async {
        sent = body;
        return const AiProxyResponse(200, {'text': 'hello'});
      });

      final text = await gateway.generateText(
        feature: AiFeature.assistantChat,
        prompt: 'hi',
        history: const [AiHistoryTurn(role: 'user', text: 'earlier')],
      );

      expect(text, 'hello');
      expect(sent!['feature'], 'assistant_chat');
      expect(sent!['prompt'], 'hi');
      expect(sent!['history'], [
        {'role': 'user', 'text': 'earlier'},
      ]);
    });

    test('maps HTTP 402 to AiQuotaExceededException with details', () async {
      final gateway = ProxyAiGateway(
        (_) async => const AiProxyResponse(402, {
          'error': 'quota_exceeded',
          'limit': 10,
          'resets_at': '2026-12-01T00:00:00.000Z',
        }),
      );

      expect(
        () => gateway.generateText(feature: AiFeature.briefing, prompt: 'x'),
        throwsA(
          isA<AiQuotaExceededException>()
              .having((e) => e.limit, 'limit', 10)
              .having((e) => e.resetsAt, 'resetsAt', DateTime.utc(2026, 12, 1)),
        ),
      );
    });

    test('maps other non-200 statuses to AiGatewayException', () async {
      final gateway = ProxyAiGateway(
        (_) async => const AiProxyResponse(500, {'error': 'boom'}),
      );

      expect(
        () => gateway.generateText(feature: AiFeature.support, prompt: 'x'),
        throwsA(
          isA<AiGatewayException>().having((e) => e.status, 'status', 500),
        ),
      );
    });

    test('throws AiGatewayException when 200 has no text', () async {
      final gateway = ProxyAiGateway(
        (_) async => const AiProxyResponse(200, <String, dynamic>{}),
      );

      expect(
        () => gateway.generateText(feature: AiFeature.support, prompt: 'x'),
        throwsA(isA<AiGatewayException>()),
      );
    });
  });

  group('ProxyAiGateway.embed', () {
    test('returns doubles and sends the embedding feature', () async {
      Map<String, dynamic>? sent;
      final gateway = ProxyAiGateway((body) async {
        sent = body;
        return const AiProxyResponse(200, {
          'embedding': [1, 2.5, 3],
        });
      });

      final values = await gateway.embed('text', taskType: 'retrievalQuery');

      expect(values, [1.0, 2.5, 3.0]);
      expect(sent!['feature'], 'embedding');
      expect(sent!['text'], 'text');
      expect(sent!['task_type'], 'retrievalQuery');
    });

    test('throws AiGatewayException when embedding is missing', () async {
      final gateway = ProxyAiGateway(
        (_) async => const AiProxyResponse(200, <String, dynamic>{}),
      );

      expect(() => gateway.embed('t'), throwsA(isA<AiGatewayException>()));
    });
  });

  test('only user-facing features are metered', () {
    expect(AiFeature.assistantChat.isMetered, isTrue);
    expect(AiFeature.voiceTask.isMetered, isTrue);
    expect(AiFeature.briefing.isMetered, isTrue);
    expect(AiFeature.support.isMetered, isTrue);
    expect(AiFeature.assistantSearch.isMetered, isFalse);
    expect(AiFeature.categorize.isMetered, isFalse);
  });
}
