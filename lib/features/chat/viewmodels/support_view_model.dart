import 'package:get/get.dart';
import '../../../models/models.dart';
import '../../../services/supabase_service.dart';
import '../../../services/logger_service.dart';
import '../../../services/bug_report_service.dart';

class SupportViewModel extends GetxController {
  final SupabaseService _supabase = SupabaseService();
  
  final RxString conversationId = ''.obs;
  final RxList<SupportMessage> messages = <SupportMessage>[].obs;
  final RxBool isLoading = false.obs;
  
  // Decision tree state
  final RxString currentNode = 'root'.obs;
  final RxBool isTyping = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isWaitingForInput = false.obs;
  final RxBool isFeedbackState = false.obs;
  final RxBool isSessionFinished = false.obs;

  final Map<String, Map<String, dynamic>> _decisionTree = {
    'root': {
      'message': 'Hello!\nThank you for connecting to chat support! How can I help you today?',
      'options': ['Account Issues', 'Technical Problem', 'Feedback', 'Other', 'Exit'],
    },
    'Account Issues': {
      'message': 'What kind of account issue are you having?',
      'options': ['Forgot Password', 'Change Email', 'Delete Account', 'Back', 'Exit'],
    },
    'Technical Problem': {
      'message': 'I\'m sorry to hear that. Could you specify?',
      'options': ['App Crashing', 'Slow Performance', 'Feature Not Working', 'Back', 'Exit'],
    },
    'Feedback': {
      'message': 'We love hearing from you! What would you like to share?',
      'options': ['New Feature Suggestion', 'Bug Report', 'General Praise', 'Back', 'Exit'],
    },
    'Other': {
      'message': 'Please tell us more about your issue.',
      'options': ['Back', 'Exit'],
      'requiresInput': true,
    },
    'New Feature Suggestion': {
      'message': 'Great! We love hearing new ideas. What feature would you like to see?',
      'options': ['Back', 'Exit'],
      'requiresInput': true,
    },
    'Bug Report': {
      'message': 'I\'m sorry you encountered a bug. Please describe it in detail.',
      'options': ['Back', 'Exit'],
      'requiresInput': true,
    },
    'General Praise': {
      'message': 'Thank you! We love hearing positive feedback. What did you enjoy?',
      'options': ['Back', 'Exit'],
      'requiresInput': true,
    },
    'Feature Not Working': {
      'message': 'I\'m sorry to hear that. Which feature is giving you trouble?',
      'options': ['Back', 'Exit'],
      'requiresInput': true,
    },
    'Forgot Password': {
      'message': 'You can reset your password from the login screen using the "Forgot Password" link.',
      'options': ['Back', 'Exit'],
    },
    'Change Email': {
      'message': 'Currently, you need to contact an admin to change your email. Would you like to proceed with a ticket?',
      'options': ['Yes, proceed', 'Back'],
    },
    'Delete Account': {
      'message': 'You can delete your account from Profile Settings. Warning: This action is permanent.',
      'options': ['Back', 'Exit'],
    },
  };


  Future<void> startNewSession() async {
    logger.i('Starting new support session...');
    messages.clear();
    currentNode.value = 'root';
    isTyping.value = false;
    isWaitingForInput.value = false;
    isFeedbackState.value = false;
    isSessionFinished.value = false;
    conversationId.value = '';
    
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final id = await _supabase.createSupportConversation();
      logger.i('Conversation created with ID: $id');
      conversationId.value = id;
      
      // Listen to messages
      logger.i('Subscribing to messages stream...');
      _supabase.getSupportMessagesStream(id).listen((newMessages) {
        logger.i('Stream update: ${newMessages.length} messages received');
        messages.value = newMessages;
      }, onError: (err) {
        logger.e('Stream error: $err');
        errorMessage.value = 'Real-time connection failed. Please ensure tables exist.';
      });

      // Send initial greeting
      await Future.delayed(const Duration(milliseconds: 800));
      logger.i('Sending initial bot greeting...');
      await _sendBotMessage('root');
      logger.i('Initial greeting sent.');
    } catch (e) {
      logger.e('Error starting support session: $e');
      errorMessage.value = 'Could not start chat. Please ensure the support tables exist in Supabase and you have run the updated SQL script.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectOption(String option) async {
    isWaitingForInput.value = false;
    
    if (option == 'Back') {
      // Simple back logic (to root for now, or keep a stack)
      currentNode.value = 'root';
      await _sendUserMessage(option);
      await _sendBotMessageContent(
        "Sure! What else can I help you with?",
        options: _decisionTree['root']!['options'] as List<String>,
      );
      return;
    }

    if (option == 'Back to Chat') {
      cancelFeedback();
      return;
    }

    if (option == 'Exit' || option == 'Just Exit') {
      if (option == 'Just Exit') {
        isSessionFinished.value = true;
      }
      return;
    }

    await _sendUserMessage(option);

    if (_decisionTree.containsKey(option)) {
      currentNode.value = option;
      final node = _decisionTree[option]!;
      await _sendBotMessage(option);

      if (node['requiresInput'] == true) {
        isWaitingForInput.value = true;
      }
    } else {
      // Terminal node or unhandled
      await _sendBotMessageContent(
        "I've noted that. Is there anything else I can help with?",
        options: ['Back', 'Exit'],
      );
    }
  }

  Future<void> sendFreeTextMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    isWaitingForInput.value = false;
    
    Map<String, dynamic>? metadata;
    if (currentNode.value == 'Bug Report') {
      // Show immediate feedback to user
      await _sendBotMessageContent(
        "Hang on a second, I'm gathering technical details for your report...",
        options: [],
      );
      
      metadata = await BugReportService().collectMetadata();
    }
    
    await _sendUserMessage(text, metadata: metadata);
    
    // After text input, usually a generic acknowledgment or further questions
    await _sendBotMessageContent(
      "Thank you for sharing that with us! I've recorded your message. Is there anything else you'd like to discuss?",
      options: ['Back', 'Exit'],
    );
  }

  Future<void> prepareFeedbackSession() async {
    isWaitingForInput.value = true;
    isFeedbackState.value = true;
    
    // Send a bot message asking for feedback
    await _sendBotMessageContent(
      "Thank you for reaching out to CivicNet Support! Before you go, we'd love to hear about your experience. How was your interaction today?",
      options: ['Back to Chat', 'Just Exit'],
    );
  }

  Future<void> submitExitFeedback(String feedback) async {
    if (feedback.trim().isEmpty) return;
    
    isLoading.value = true;
    try {
      if (conversationId.isNotEmpty) {
        await _supabase.updateSupportFeedback(conversationId.value, feedback);
        await _sendUserMessage("Feedback provided: $feedback");
        await _sendBotMessageContent("Thank you for your valuable feedback! It helps us improve our support experience. Have a great day!", options: []);
        
        // Final close
        await closeSession();
        
        // Signal UI to redirect after a delay
        isSessionFinished.value = true;
      }
    } catch (e) {
      logger.e('Error submitting feedback: $e');
      errorMessage.value = 'Failed to submit feedback. Closing anyway.';
      await closeSession();
    } finally {
      isLoading.value = false;
      isFeedbackState.value = false;
      isWaitingForInput.value = false;
    }
  }

  void cancelFeedback() {
    isFeedbackState.value = false;
    isWaitingForInput.value = false;
    // Potentially send them back to root or stay where they were
    currentNode.value = 'root';
    _sendBotMessage('root');
  }

  Future<void> _sendUserMessage(String content, {Map<String, dynamic>? metadata}) async {
    final msg = SupportMessage(
      id: '', // Generated by DB
      conversationId: conversationId.value,
      senderType: SupportSenderType.user,
      content: content,
      metadata: metadata,
      createdAt: DateTime.now(),
    );
    await _supabase.sendSupportMessage(msg);
  }

  Future<void> _sendBotMessage(String nodeKey) async {
    final node = _decisionTree[nodeKey];
    if (node == null) return;

    isTyping.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final msg = SupportMessage(
      id: '',
      conversationId: conversationId.value,
      senderType: SupportSenderType.bot,
      content: node['message'] as String,
      options: List<String>.from(node['options'] as List),
      createdAt: DateTime.now(),
    );
    await _supabase.sendSupportMessage(msg);
    isTyping.value = false;
  }

  Future<void> _sendBotMessageContent(String content, {List<String>? options}) async {
    isTyping.value = true;
    await Future.delayed(const Duration(seconds: 1));

    final msg = SupportMessage(
      id: '',
      conversationId: conversationId.value,
      senderType: SupportSenderType.bot,
      content: content,
      options: options,
      createdAt: DateTime.now(),
    );
    await _supabase.sendSupportMessage(msg);
    isTyping.value = false;
  }

  Future<void> closeSession() async {
    if (conversationId.isNotEmpty) {
      await _supabase.closeSupportConversation(conversationId.value);
    }
  }
}
