import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../services/ai_service.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  AiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiAssistantViewModel extends GetxController {
  final AiService _aiService = AiService();
  final SupabaseService _supabaseService = SupabaseService();

  final RxList<AiMessage> messages = <AiMessage>[].obs;
  final RxBool isLoading = false.obs;
  
  // History for maintaining conversation context
  final List<Content> _history = [];

  @override
  void onInit() {
    super.onInit();
    // Welcome message
    messages.add(AiMessage(
      text: "Hello! I'm your CivicNet AI Assistant. I can help you find help requests, upcoming events, or community news. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message
    final userMsg = AiMessage(text: text, isUser: true, timestamp: DateTime.now());
    messages.add(userMsg);
    isLoading.value = true;

    try {
      // 2. RAG: Retrieve context
      logger.i('AI Assistant: Processing query "$text"');
      
      // We generate both an embedding and a search query for maximum coverage
      final List<dynamic> results = await Future.wait([
        _aiService.generateEmbedding(text, taskType: TaskType.retrievalQuery),
        _aiService.generateSearchQuery(text),
      ]);

      final List<double>? embedding = results[0] as List<double>?;
      final String searchQuery = results[1] as String;

      logger.d('AI Assistant: Search Query: $searchQuery');

      final String context = await _supabaseService.searchCommunityContent(
        queryEmbedding: embedding ?? [],
        queryText: searchQuery,
      );

      // 3. Generate AI Response
      final aiResponse = await _aiService.generateChatResponse(
        query: text,
        context: context,
        history: _history,
      );

      // 4. Update UI and History
      final aiMsg = AiMessage(text: aiResponse, isUser: false, timestamp: DateTime.now());
      messages.add(aiMsg);

      // Add to history (User + Model)
      _history.add(Content.text(text));
      _history.add(Content('model', [TextPart(aiResponse)]));

    } catch (e) {
      logger.e('AI Assistant Error: $e');
      messages.add(AiMessage(
        text: "I'm sorry, I'm having trouble connecting to the community brain right now. Please try again in a moment.",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
    _history.clear();
    messages.add(AiMessage(
      text: "Chat cleared! How can I help you now?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }
}
