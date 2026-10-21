import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../models/models.dart';
import '../../../services/ai_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/bug_report_service.dart';

class SupportViewModel extends GetxController {
  final SupabaseService _supabase = SupabaseService();
  final AiService _aiService = AiService();

  final RxString conversationId = ''.obs;
  final RxList<SupportMessage> messages = <SupportMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isWaitingForInput = true.obs;
  final RxBool isFeedbackState = false.obs;
  final RxBool isSessionFinished = false.obs;

  /// Multi-turn conversation memory for Gemini LLM context
  final List<Content> _aiHistory = [];

  static const List<String> initialTopics = [
    'How matching works',
    'Create a Request',
    'How to help others',
    'Safety Guidelines',
  ];

  @override
  void onInit() {
    super.onInit();
    startNewSession();
  }

  /// Initializes or resumes the active support conversation with Supabase persistence.
  Future<void> startNewSession({bool forceNew = false}) async {
    logger.i('SupportViewModel: Initializing AI support session...');
    messages.clear();
    _aiHistory.clear();
    isTyping.value = false;
    isWaitingForInput.value = true;
    isFeedbackState.value = false;
    isSessionFinished.value = false;
    conversationId.value = '';
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final String id;
      if (forceNew) {
        id = await _supabase.createSupportConversation();
      } else {
        id = await _supabase.getOrCreateActiveSupportConversation();
      }

      conversationId.value = id;
      logger.i('SupportViewModel: Conversation ID: $id');

      // Listen to Realtime stream of messages
      _supabase.getSupportMessagesStream(id).listen(
        (newMessages) {
          messages.value = newMessages;

          // Rebuild AI history context from loaded messages
          _aiHistory.clear();
          for (final msg in newMessages) {
            if (msg.senderType == SupportSenderType.user) {
              _aiHistory.add(Content.text(msg.content));
            } else if (msg.senderType == SupportSenderType.bot) {
              _aiHistory.add(Content('model', [TextPart(msg.content)]));
            }
          }
        },
        onError: (err) {
          logger.e('SupportViewModel: Realtime message stream error: $err');
          errorMessage.value =
              'Connection to chat support lost. Messages are still stored.';
        },
      );

      // If this is a fresh conversation with no messages, send the AI welcome greeting
      await Future.delayed(const Duration(milliseconds: 600));
      if (messages.isEmpty) {
        await _sendBotMessageContent(
          'Hello! I am your **CivicNet AI Assistant & Community Guide**.\n\n'
          'I can help you navigate open requests, understand our AI relevance matching, offer assistance, or troubleshoot account questions.\n\n'
          'How can I help you today?',
          options: initialTopics,
        );
      }
    } catch (e) {
      logger.e('SupportViewModel: Error starting support session: $e');
      errorMessage.value =
          'Could not start chat session. Please check your internet connection.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Sends a free-text message from the user, generates an AI response, and saves both to Supabase.
  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || isTyping.value) return;

    if (isFeedbackState.value) {
      await submitExitFeedback(cleanText);
      return;
    }

    try {
      Map<String, dynamic>? metadata;
      if (cleanText.toLowerCase().contains('bug') ||
          cleanText.toLowerCase().contains('crash')) {
        try {
          metadata = await BugReportService().collectMetadata();
        } catch (_) {}
      }

      // 1. Send & persist user message in Supabase
      await _sendUserMessage(cleanText, metadata: metadata);

      // 2. Trigger typing indicator
      isTyping.value = true;

      // 3. Generate AI response (Gemini Flash with context memory + local heuristic fallback)
      final aiResponse = await _aiService.generateSupportChatResponse(
        userQuery: cleanText,
        history: _aiHistory,
      );

      // 4. Update multi-turn history memory
      _aiHistory.add(Content.text(cleanText));
      _aiHistory.add(Content('model', [TextPart(aiResponse.message)]));

      // 5. Send & persist bot response with suggested action chips in Supabase
      await _sendBotMessageContent(
        aiResponse.message,
        options: aiResponse.suggestedActions,
      );
    } catch (e) {
      logger.e('SupportViewModel: Error handling message: $e');
      await _sendBotMessageContent(
        'I ran into a temporary issue retrieving that information. Please try asking again in a moment, or tap one of the suggested topics.',
        options: initialTopics,
      );
    } finally {
      isTyping.value = false;
    }
  }

  /// Handles quick-action chip selection
  Future<void> selectOption(String option) async {
    if (option == 'Exit' || option == 'Just Exit') {
      if (option == 'Just Exit') {
        isSessionFinished.value = true;
      } else {
        await prepareFeedbackSession();
      }
      return;
    }

    if (option == 'Back to Chat') {
      cancelFeedback();
      return;
    }

    // Treat option chip as a user prompt
    await sendMessage(option);
  }

  /// Compatibility alias for legacy callers
  Future<void> sendFreeTextMessage(String text) => sendMessage(text);

  /// Prepares post-chat feedback collection
  Future<void> prepareFeedbackSession() async {
    isFeedbackState.value = true;
    await _sendBotMessageContent(
      'Thank you for chatting with CivicNet AI Support! Before you leave, how was your experience today? Any feedback helps us improve!',
      options: ['Back to Chat', 'Just Exit'],
    );
  }

  /// Submits post-chat feedback to Supabase and closes the conversation
  Future<void> submitExitFeedback(String feedback) async {
    final cleanFeedback = feedback.trim();
    if (cleanFeedback.isEmpty) return;

    isLoading.value = true;
    try {
      if (conversationId.isNotEmpty) {
        await _supabase.updateSupportFeedback(
          conversationId.value,
          cleanFeedback,
        );
        await _sendUserMessage('Feedback: $cleanFeedback');
        await _sendBotMessageContent(
          'Thank you for your valuable feedback! We appreciate you helping make CivicNet better. Have a wonderful day!',
          options: [],
        );
        await closeSession();
        isSessionFinished.value = true;
      }
    } catch (e) {
      logger.e('SupportViewModel: Error submitting feedback: $e');
      await closeSession();
      isSessionFinished.value = true;
    } finally {
      isLoading.value = false;
      isFeedbackState.value = false;
    }
  }

  void cancelFeedback() {
    isFeedbackState.value = false;
    _sendBotMessageContent(
      'Welcome back! What else can I help you with?',
      options: initialTopics,
    );
  }

  Future<void> _sendUserMessage(
    String content, {
    Map<String, dynamic>? metadata,
  }) async {
    if (conversationId.isEmpty) return;
    final msg = SupportMessage(
      id: '',
      conversationId: conversationId.value,
      senderType: SupportSenderType.user,
      content: content,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    await _supabase.sendSupportMessage(msg);
  }

  Future<void> _sendBotMessageContent(
    String content, {
    List<String>? options,
  }) async {
    if (conversationId.isEmpty) return;
    final msg = SupportMessage(
      id: '',
      conversationId: conversationId.value,
      senderType: SupportSenderType.bot,
      content: content,
      options: options,
      createdAt: DateTime.now(),
    );
    await _supabase.sendSupportMessage(msg);
  }

  Future<void> closeSession() async {
    if (conversationId.isNotEmpty) {
      await _supabase.closeSupportConversation(conversationId.value);
    }
  }
}
