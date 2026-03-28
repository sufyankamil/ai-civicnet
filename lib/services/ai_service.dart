import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_net/services/logger_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  GenerativeModel? _embeddingModel;
  GenerativeModel? _chatModel;
  bool _isInitialized = false;

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.e('AiService: GEMINI_API_KEY not found in .env');
      return;
    }

    // Embedding model for vector search
    _embeddingModel = GenerativeModel(
      model: 'gemini-embedding-001',
      apiKey: apiKey,
    );

    // Chat model for RAG and interaction
    _chatModel = GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
    );

    _isInitialized = true;
    logger.i('AiService: Initialized with Gemini Embedding and Flash models');
  }

  /// Generates a 768-dimension vector for the given text.
  Future<List<double>?> generateEmbedding(String text, {TaskType? taskType}) async {
    if (!_isInitialized || _embeddingModel == null) {
      if (!_isInitialized) initialize(); 
      if (!_isInitialized) throw Exception('AI Service failed to initialize. Check GEMINI_API_KEY in .env');
    }

    try {
      final content = Content.text(text);
      // Specifying taskType helps the model optimize the embedding
      final result = await _embeddingModel!.embedContent(
        content,
        taskType: taskType,
      );
      
      if (result.embedding.values.isNotEmpty) {
        logger.d('AiService: Generated embedding for text (${text.length} chars)');
        return result.embedding.values.take(768).map((e) => e.toDouble()).toList();
      }

      return null;
    } catch (e) {
      logger.e('AiService: Error generating embedding', error: e);
      throw Exception('AI Error: $e');
    }
  }

  /// Helper to generate a combined embedding for a help request.
  Future<List<double>?> generateRequestEmbedding(String title, String description, String category, {bool isQuery = false}) async {
    final combinedText = 'Title: $title\nCategory: $category\nDescription: $description';
    return generateEmbedding(
      combinedText, 
      taskType: isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument
    );
  }

  /// Helper to generate a combined embedding for a user profile.
  Future<List<double>?> generateProfileEmbedding(String name, List<String> skills, {bool isQuery = false}) async {
    final combinedText = 'Name: $name\nSkills: ${skills.join(", ")}';
    return generateEmbedding(
      combinedText, 
      taskType: isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument
    );
  }

  /// Generates a search query for the RAG system based on the user's message.
  Future<String> generateSearchQuery(String userMessage) async {
    if (!_isInitialized || _chatModel == null) initialize();
    
    final systemPrompt = 'You are the CivicNet AI Assistant. Helping a community networking app.\n\n';
    final prompt = '$systemPrompt'
        'Given this user message, extract 2-4 key search keywords '
        'or a short descriptive phrase that can be used to find relevant community content (help requests, events, news). '
        'Output ONLY the keywords/phrase, nothing else.\n\n'
        'User Message: $userMessage';
        
    final response = await _chatModel!.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? userMessage;
  }

  /// Generates a chat response using RAG context.
  Future<String> generateChatResponse({
    required String query,
    required String context,
    List<Content>? history,
  }) async {
    if (!_isInitialized || _chatModel == null) initialize();

    final systemPrompt = 'You are the CivicNet AI Assistant, a helpful and friendly guide for a local community networking app. '
        'Your goal is to help users find help, discover events, and stay informed about their neighborhood. '
        'Use the following context to give accurate and relevant answers. '
        'Always be polite, encouraging, and focus on fostering community spirit.\n\n';

    final prompt = '$systemPrompt'
        'Context from the CivicNet community:\n'
        '$context\n\n'
        'User Question: $query\n\n'
        'Instructions: Use the community context provided above to answer the user question. '
        'If the answer is not in the context, use your general knowledge but mention that this is general information. '
        'Keep the response concise, helpful, and community-oriented.';

    final content = [Content.text(prompt)];
    
    // We can use startChat if history is provided
    if (history != null && history.isNotEmpty) {
      final chat = _chatModel!.startChat(history: history);
      final response = await chat.sendMessage(Content.text(prompt));
      return response.text ?? 'I apologize, but I am unable to generate a response at the moment.';
    } else {
      final response = await _chatModel!.generateContent(content);
      return response.text ?? 'I apologize, but I am unable to generate a response at the moment.';
    }
  }

  /// Categorizes a help request based on its title and description.
  Future<String?> categorizeRequest(String title, String description) async {
    if (!_isInitialized || _chatModel == null) initialize();

    final systemPrompt = 'You are an AI assistant for a local community networking app (CivicNet). '
        'Your task is to categorize a user\'s help request into exactly one of the following categories:\n'
        '- ERRANDS\n'
        '- TECHSUPPORT\n'
        '- EMERGENCY\n'
        '- EDUCATION\n'
        '- TRANSPORT\n'
        '- HOUSEHOLD\n'
        '- HEALTH\n'
        '- OTHER\n\n'
        'Analyze the title and description of the request and respond ONLY with the exact category name in all caps. '
        'Do not provide any explanation or extra text.';

    final prompt = '$systemPrompt\n\n'
        'Title: $title\n'
        'Description: $description';

    try {
      final response = await _chatModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim().toUpperCase();
    } catch (e) {
      logger.e('AiService: Error categorizing request', error: e);
      return null;
    }
  }
}

