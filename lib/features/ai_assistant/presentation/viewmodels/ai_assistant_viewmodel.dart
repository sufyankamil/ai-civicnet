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
    messages.add(
      AiMessage(
        text:
            "Hello! I'm **Aura AI**, your CivicNet community intelligence companion.\n\n"
            "I can help you search urgent requests, find borrowable tools, discover local events, or navigate neighborhood activities.\n\n"
            "How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message
    final userMsg = AiMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMsg);
    isLoading.value = true;

    try {
      // 2. RAG: Resiliently retrieve context
      logger.i('AI Assistant: Processing query "$text"');

      List<double>? embedding;
      try {
        embedding = await _aiService.generateEmbedding(
          text,
          taskType: TaskType.retrievalQuery,
        );
      } catch (e) {
        logger.d('Embedding generation skipped: $e');
      }

      String searchQuery = text;
      try {
        searchQuery = await _aiService.generateSearchQuery(text);
      } catch (e) {
        logger.d('Search query optimization skipped: $e');
      }

      String context = '';
      try {
        context = await _supabaseService.searchCommunityContent(
          queryEmbedding: embedding ?? [],
          queryText: searchQuery,
        );
      } catch (e) {
        logger.w('Community content search skipped: $e');
      }

      // 3. Generate AI Response (with built-in Gemini & local synthesis fallback)
      final aiResponse = await _aiService.generateChatResponse(
        query: text,
        context: context,
        history: _history,
      );

      // 4. Update UI and History
      final aiMsg = AiMessage(
        text: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(aiMsg);

      // Add to history (User + Model)
      _history.add(Content.text(text));
      _history.add(Content('model', [TextPart(aiResponse)]));
    } catch (e) {
      logger.e('AI Assistant Error: $e');
      messages.add(
        AiMessage(
          text:
              "I'm sorry, I'm having trouble connecting to the community brain right now. Please try again in a moment.",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearChat() {
    messages.clear();
    _history.clear();
    messages.add(
      AiMessage(
        text: "Chat cleared! How can I help you now?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }
}
