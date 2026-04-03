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

  /// Helper to generate a combined embedding for a community asset.
  Future<List<double>?> generateAssetEmbedding(String title, String description, String category, {bool isQuery = false}) async {
    final combinedText = 'Asset: $title\nCategory: $category\nDescription: $description';
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
      final response = await _chatModel!.generateContent(
          [Content.text(prompt)]);
      return response.text?.trim().toUpperCase();
    } catch (e) {
      if (e.toString().contains('503') || e.toString().contains('SERVICE_UNAVAILABLE')) {
        // Simple retry once after 2 seconds for 503 during categorization
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResponse = await _chatModel!.generateContent([Content.text(prompt)]);
          return retryResponse.text?.trim().toUpperCase();
        } catch (_) { /* fall through */ }
      }
      logger.e('AiService: Error categorizing request', error: e);
      return null;
    }
  }

  /// Generates a local fallback briefing if the AI is unavailable.
  String generateLocalBriefing({
    required List<dynamic> requests,
    required List<dynamic> events,
    required dynamic user,
  }) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour < 21) {
      greeting = 'Good evening';
    } else {
      greeting = 'Hello there';
    }

    final requestCount = requests.length;
    final eventCount = events.length;

    return '$greeting! Your community is active today. '
        'Currently, there are $requestCount neighbors looking for help nearby, and $eventCount upcoming events in your guilds.\n\n'
        'Check out "${requests.isNotEmpty ? requests.first.title : 'the map'}" to see how your expertise can make an impact. '
        'Every act of kindness helps you reach your next community milestone!\n\n'
        'Keep up the great work—you have already impacted ${user.neighborsImpacted} neighbors across the network.';
  }

  String _getTimeOfDayContext() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning (a fresh start)';
    if (hour >= 12 && hour < 17) return 'Afternoon (active and buzzing)';
    if (hour >= 17 && hour < 21) return 'Evening (winding down but still engaged)';
    return 'Night (peaceful and reflective, planning for tomorrow)';
  }

  /// Generates a personalized community briefing.
  Future<String> generateCommunityBriefing({
    required List<dynamic> requests,
    required List<dynamic> events,
    required dynamic user,
  }) async {
    if (!_isInitialized || _chatModel == null) initialize();

    final timeOfDay = _getTimeOfDayContext();
    final requestsText = requests.take(3).map((r) => 
      '- ${r.title} (${r.category.toString().split('.').last}) at ${r.distance ?? 'nearby'}'
    ).join('\n');

    final eventsText = events.isEmpty 
        ? 'No upcoming guild events today.' 
        : events.take(2).map((e) => '- ${e.title} in your joined guild').join('\n');

    final userStats = 'Points: ${user.points}, People Helped: ${user.helpCount}, Level: ${user.karmaLevel}';

    final systemPrompt = 'You are the "CivicNet Scribe," a friendly and inspiring community AI. '
        'Your goal is to write a short, personalized briefing for a user in a neighborhood networking app. '
        'The current time of day is: $timeOfDay.\n\n'
        'Keep it to exactly 3 short, punchy paragraphs in a professional magazine style. '
        'Paragraph 1: Warm neighborhood greeting appropriate for the current time ($timeOfDay) and a summary of the current vibe. '
        'Paragraph 2: Highlight 1-2 ways they could help today (or plan for tomorrow if it is night) based on the requests provided. '
        'Paragraph 3: A boost of encouragement based on their impact stats and a clear call to action.\n\n';

    final prompt = '$systemPrompt'
        'Community Data:\n'
        'Requests nearby:\n$requestsText\n\n'
        'Events:\n$eventsText\n\n'
        'User Stats: $userStats\n\n'
        'Write the briefing now. Use friendly but professional language. Avoid using "Dear [Name]" at the start, just start with an appropriate greeting like "Good morning", "Good evening", or "Hello, neighbor".';

    try {
      final response = await _chatModel!.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? generateLocalBriefing(requests: requests, events: events, user: user);
    } catch (e) {
      if (e.toString().contains('503') || e.toString().contains('SERVICE_UNAVAILABLE')) {
        // Automatic retry once for the briefing
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResponse = await _chatModel!.generateContent([Content.text(prompt)]);
          return retryResponse.text?.trim() ?? generateLocalBriefing(requests: requests, events: events, user: user);
        } catch (_) { /* fall through */ }
      }
      logger.e('AiService: Error generating community briefing', error: e);
      return generateLocalBriefing(requests: requests, events: events, user: user);
    }
  }
}

