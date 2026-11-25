import 'package:supabase_flutter/supabase_flutter.dart';

/// AI capabilities served by the `ai-proxy` edge function.
///
/// Metered features count against the user's monthly AI quota (free tier) and
/// are unlimited for Pro. Unmetered features power background matching and
/// helper steps, so they never run out for free users.
enum AiFeature {
  assistantChat('assistant_chat', metered: true),
  voiceTask('voice_task', metered: true),
  briefing('briefing', metered: true),
  support('support', metered: true),
  assistantSearch('assistant_search', metered: false),
  categorize('categorize', metered: false),
  embedding('embedding', metered: false);

  const AiFeature(this.wireName, {required this.metered});

  final String wireName;
  final bool metered;
  bool get isMetered => metered;
}

/// Thrown when a free user has used up the monthly AI quota.
class AiQuotaExceededException implements Exception {
  AiQuotaExceededException({this.limit, this.resetsAt});

  final int? limit;
  final DateTime? resetsAt;

  @override
  String toString() =>
      'AiQuotaExceededException(limit: $limit, resetsAt: $resetsAt)';
}

/// Thrown for any other failure reported by the AI proxy.
class AiGatewayException implements Exception {
  AiGatewayException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => 'AiGatewayException($status): $message';
}

class AiHistoryTurn {
  const AiHistoryTurn({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

class AiProxyResponse {
  const AiProxyResponse(this.status, this.body);

  final int status;
  final Map<String, dynamic> body;
}

typedef AiProxyInvoker =
    Future<AiProxyResponse> Function(Map<String, dynamic> body);

/// Transport between [AiService] and Gemini. The app never talks to Gemini
/// directly, so the API key stays on the server.
abstract class AiGateway {
  Future<String> generateText({
    required AiFeature feature,
    required String prompt,
    List<AiHistoryTurn> history = const [],
  });

  Future<List<double>> embed(String text, {String? taskType});
}

class ProxyAiGateway implements AiGateway {
  ProxyAiGateway([AiProxyInvoker? invoker])
    : _invoke = invoker ?? supabaseAiInvoker;

  final AiProxyInvoker _invoke;

  @override
  Future<String> generateText({
    required AiFeature feature,
    required String prompt,
    List<AiHistoryTurn> history = const [],
  }) async {
    final response = await _invoke({
      'feature': feature.wireName,
      'prompt': prompt,
      'history': history.map((t) => t.toJson()).toList(),
    });
    _throwIfFailed(response);

    final text = response.body['text'];
    if (text is! String) {
      throw AiGatewayException(response.status, 'AI proxy returned no text');
    }
    return text;
  }

  @override
  Future<List<double>> embed(String text, {String? taskType}) async {
    final response = await _invoke({
      'feature': AiFeature.embedding.wireName,
      'text': text,
      'task_type': ?taskType,
    });
    _throwIfFailed(response);

    final values = response.body['embedding'];
    if (values is! List) {
      throw AiGatewayException(
        response.status,
        'AI proxy returned no embedding',
      );
    }
    return values.map((e) => (e as num).toDouble()).toList();
  }

  void _throwIfFailed(AiProxyResponse response) {
    if (response.status == 200) return;
    if (response.status == 402) {
      final limit = response.body['limit'];
      final resets = response.body['resets_at'];
      throw AiQuotaExceededException(
        limit: limit is num ? limit.toInt() : null,
        resetsAt: resets is String ? DateTime.tryParse(resets) : null,
      );
    }
    throw AiGatewayException(
      response.status,
      '${response.body['error'] ?? 'AI proxy error'}',
    );
  }
}

/// Calls the `ai-proxy` Supabase edge function as the signed-in user.
Future<AiProxyResponse> supabaseAiInvoker(Map<String, dynamic> body) async {
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'ai-proxy',
      body: body,
    );
    return AiProxyResponse(res.status, _asMap(res.data));
  } on FunctionException catch (e) {
    return AiProxyResponse(e.status, _asMap(e.details));
  }
}

Map<String, dynamic> _asMap(Object? data) =>
    data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
