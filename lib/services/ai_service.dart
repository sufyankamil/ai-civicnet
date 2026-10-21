import 'dart:convert';
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
    _chatModel = GenerativeModel(model: 'gemini-flash-latest', apiKey: apiKey);

    _isInitialized = true;
    logger.i('AiService: Initialized with Gemini Embedding and Flash models');
  }

  /// Generates a 768-dimension vector for the given text.
  Future<List<double>?> generateEmbedding(
    String text, {
    TaskType? taskType,
  }) async {
    if (!_isInitialized || _embeddingModel == null) {
      if (!_isInitialized) initialize();
      if (!_isInitialized) {
        throw Exception(
          'AI Service failed to initialize. Check GEMINI_API_KEY in .env',
        );
      }
    }

    try {
      final content = Content.text(text);
      // Specifying taskType helps the model optimize the embedding
      final result = await _embeddingModel!.embedContent(
        content,
        taskType: taskType,
      );

      if (result.embedding.values.isNotEmpty) {
        logger.d(
          'AiService: Generated embedding for text (${text.length} chars)',
        );
        return result.embedding.values
            .take(768)
            .map((e) => e.toDouble())
            .toList();
      }

      return null;
    } catch (e) {
      logger.e('AiService: Error generating embedding', error: e);
      throw Exception('AI Error: $e');
    }
  }

  /// Helper to generate a combined embedding for a help request.
  Future<List<double>?> generateRequestEmbedding(
    String title,
    String description,
    String category, {
    bool isQuery = false,
  }) async {
    final combinedText =
        'Title: $title\nCategory: $category\nDescription: $description';
    return generateEmbedding(
      combinedText,
      taskType: isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument,
    );
  }

  /// Helper to generate a combined embedding for a user profile.
  Future<List<double>?> generateProfileEmbedding(
    String name,
    List<String> skills, {
    bool isQuery = false,
  }) async {
    final combinedText = 'Name: $name\nSkills: ${skills.join(", ")}';
    return generateEmbedding(
      combinedText,
      taskType: isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument,
    );
  }

  /// Helper to generate a combined embedding for a community asset.
  Future<List<double>?> generateAssetEmbedding(
    String title,
    String description,
    String category, {
    bool isQuery = false,
  }) async {
    final combinedText =
        'Asset: $title\nCategory: $category\nDescription: $description';
    return generateEmbedding(
      combinedText,
      taskType: isQuery ? TaskType.retrievalQuery : TaskType.retrievalDocument,
    );
  }

  /// Generates a search query for the RAG system based on the user's message.
  Future<String> generateSearchQuery(String userMessage) async {
    if (!_isInitialized || _chatModel == null) initialize();

    final systemPrompt =
        'You are the CivicNet AI Assistant. Helping a community networking app.\n\n';
    final prompt =
        '$systemPrompt'
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

    final systemPrompt =
        'You are the CivicNet AI Assistant, a helpful and friendly guide for a local community networking app. '
        'Your goal is to help users find help, discover events, and stay informed about their neighborhood. '
        'Use the following context to give accurate and relevant answers. '
        'Always be polite, encouraging, and focus on fostering community spirit.\n\n';

    final prompt =
        '$systemPrompt'
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
      return response.text ??
          'I apologize, but I am unable to generate a response at the moment.';
    } else {
      final response = await _chatModel!.generateContent(content);
      return response.text ??
          'I apologize, but I am unable to generate a response at the moment.';
    }
  }

  /// Categorizes a help request based on its title and description.
  Future<String?> categorizeRequest(String title, String description) async {
    if (!_isInitialized || _chatModel == null) initialize();

    final systemPrompt =
        'You are an AI assistant for a local community networking app (CivicNet). '
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

    final prompt =
        '$systemPrompt\n\n'
        'Title: $title\n'
        'Description: $description';

    try {
      final response = await _chatModel!.generateContent([
        Content.text(prompt),
      ]);
      return response.text?.trim().toUpperCase();
    } catch (e) {
      if (e.toString().contains('503') ||
          e.toString().contains('SERVICE_UNAVAILABLE')) {
        // Simple retry once after 2 seconds for 503 during categorization
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResponse = await _chatModel!.generateContent([
            Content.text(prompt),
          ]);
          return retryResponse.text?.trim().toUpperCase();
        } catch (_) {
          /* fall through */
        }
      }
      logger.e('AiService: Error categorizing request', error: e);
      return null;
    }
  }

  /// Parses a spoken voice note into a structured help request (Title, Description, Category, Urgency).
  /// Uses Gemini Flash when available, with a resilient local heuristic fallback.
  Future<ParsedVoiceTask> parseVoiceTask(String transcript) async {
    final cleanTranscript = transcript.trim();
    if (cleanTranscript.isEmpty) {
      return const ParsedVoiceTask(
        title: '',
        description: '',
        categoryString: 'OTHER',
        urgencyString: 'MEDIUM',
        usedAi: false,
      );
    }

    if (!_isInitialized || _chatModel == null) {
      initialize();
    }

    if (_isInitialized && _chatModel != null) {
      try {
        final prompt =
            'You are the CivicNet AI Assistant for a community help platform.\n'
            'A neighbor just spoke this help request:\n'
            '"""$cleanTranscript"""\n\n'
            'Analyze what they need and format your response as pure JSON matching this exact structure:\n'
            '{\n'
            '  "title": "Short title max 6 words summarizing the need",\n'
            '  "description": "Clear and polite request description",\n'
            '  "category": "ERRANDS" | "TECHSUPPORT" | "EMERGENCY" | "EDUCATION" | "TRANSPORT" | "HOUSEHOLD" | "HEALTH" | "OTHER",\n'
            '  "urgency": "LOW" | "MEDIUM" | "HIGH" | "CRITICAL",\n'
            '  "suggested_tools": ["tool1", "tool2"]\n'
            '}\n'
            'Important: Output ONLY the valid JSON string. Do not wrap in markdown or add explanations.';

        final response = await _chatModel!.generateContent([
          Content.text(prompt),
        ]);
        final text = response.text?.trim() ?? '';

        String jsonString = text;
        if (jsonString.startsWith('```')) {
          final lines = jsonString.split('\n');
          jsonString = lines
              .where((line) => !line.trim().startsWith('```'))
              .join('\n')
              .trim();
        }

        final Map<String, dynamic> data = jsonDecode(jsonString);
        final title = (data['title'] as String?)?.trim() ?? '';
        final description =
            (data['description'] as String?)?.trim() ?? cleanTranscript;
        final category =
            (data['category'] as String?)?.trim().toUpperCase() ?? 'OTHER';
        final urgency =
            (data['urgency'] as String?)?.trim().toUpperCase() ?? 'MEDIUM';
        final tools =
            (data['suggested_tools'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        if (title.isNotEmpty) {
          logger.i(
            'AiService: Voice task parsed successfully with Gemini Flash',
          );
          return ParsedVoiceTask(
            title: title,
            description: description,
            categoryString: category,
            urgencyString: urgency,
            suggestedTools: tools,
            usedAi: true,
          );
        }
      } catch (e) {
        logger.w(
          'AiService: Gemini voice parse failed, using local heuristic fallback',
          error: e,
        );
      }
    }

    return _parseVoiceTaskHeuristics(cleanTranscript);
  }

  /// Rule-based keyword heuristic for voice tasks when Gemini is offline or unconfigured.
  ParsedVoiceTask _parseVoiceTaskHeuristics(String transcript) {
    final lower = transcript.toLowerCase();
    String category = 'OTHER';
    String urgency = 'MEDIUM';
    final List<String> tools = [];

    if (lower.contains('emergency') ||
        lower.contains('fire') ||
        lower.contains('hurt') ||
        lower.contains('bleeding') ||
        lower.contains('accident') ||
        lower.contains('danger') ||
        lower.contains('ambulance')) {
      category = 'EMERGENCY';
      urgency = 'CRITICAL';
    } else if (lower.contains('leak') ||
        lower.contains('burst') ||
        lower.contains('pipe') ||
        lower.contains('sink') ||
        lower.contains('plumb') ||
        lower.contains('toilet') ||
        lower.contains('water')) {
      category = 'HOUSEHOLD';
      urgency = 'HIGH';
      tools.addAll(['Wrench', 'Bucket', 'Plumber Tape']);
    } else if (lower.contains('power') ||
        lower.contains('fuse') ||
        lower.contains('wire') ||
        lower.contains('electric') ||
        lower.contains('spark') ||
        lower.contains('socket')) {
      category = 'HOUSEHOLD';
      urgency = 'HIGH';
      tools.addAll(['Voltage Tester', 'Insulated Screwdriver']);
    } else if (lower.contains('clean') ||
        lower.contains('move') ||
        lower.contains('heavy') ||
        lower.contains('furniture') ||
        lower.contains('couch') ||
        lower.contains('table') ||
        lower.contains('yard') ||
        lower.contains('lawn')) {
      category = 'HOUSEHOLD';
      urgency = 'MEDIUM';
    } else if (lower.contains('wifi') ||
        lower.contains('internet') ||
        lower.contains('computer') ||
        lower.contains('laptop') ||
        lower.contains('phone') ||
        lower.contains('printer') ||
        lower.contains('software')) {
      category = 'TECHSUPPORT';
      urgency = 'MEDIUM';
    } else if (lower.contains('car') ||
        lower.contains('ride') ||
        lower.contains('drive') ||
        lower.contains('battery') ||
        lower.contains('jump start') ||
        lower.contains('flat tire') ||
        lower.contains('transport')) {
      category = 'TRANSPORT';
      urgency = 'HIGH';
      if (lower.contains('battery') || lower.contains('jump')) {
        tools.add('Jumper Cables');
      }
      if (lower.contains('tire')) {
        tools.addAll(['Jack', 'Lug Wrench', 'Spare Tire']);
      }
    } else if (lower.contains('grocery') ||
        lower.contains('groceries') ||
        lower.contains('store') ||
        lower.contains('pick up') ||
        lower.contains('deliver') ||
        lower.contains('errand')) {
      category = 'ERRANDS';
      urgency = 'LOW';
    } else if (lower.contains('medicine') ||
        lower.contains('pharmacy') ||
        lower.contains('doctor') ||
        lower.contains('fever') ||
        lower.contains('prescription')) {
      category = 'HEALTH';
      urgency = 'HIGH';
    } else if (lower.contains('tutor') ||
        lower.contains('homework') ||
        lower.contains('math') ||
        lower.contains('exam') ||
        lower.contains('teach')) {
      category = 'EDUCATION';
      urgency = 'LOW';
    }

    final words = transcript.split(RegExp(r'\s+'));
    final titleWords = words.take(6).join(' ');
    final title = titleWords.isNotEmpty
        ? '${titleWords[0].toUpperCase()}${titleWords.substring(1)}'
        : 'Community Help Request';

    return ParsedVoiceTask(
      title: title,
      description: transcript,
      categoryString: category,
      urgencyString: urgency,
      suggestedTools: tools,
      usedAi: false,
    );
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
    if (hour >= 17 && hour < 21) {
      return 'Evening (winding down but still engaged)';
    }
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
    final requestsText = requests
        .take(3)
        .map(
          (r) =>
              '- ${r.title} (${r.category.toString().split('.').last}) at ${r.distance ?? 'nearby'}',
        )
        .join('\n');

    final eventsText = events.isEmpty
        ? 'No upcoming guild events today.'
        : events
              .take(2)
              .map((e) => '- ${e.title} in your joined guild')
              .join('\n');

    final userStats =
        'Points: ${user.points}, People Helped: ${user.helpCount}, Level: ${user.karmaLevel}';

    final systemPrompt =
        'You are the "CivicNet Scribe," a friendly and inspiring community AI. '
        'Your goal is to write a short, personalized briefing for a user in a neighborhood networking app. '
        'The current time of day is: $timeOfDay.\n\n'
        'Keep it to exactly 3 short, punchy paragraphs in a professional magazine style. '
        'Paragraph 1: Warm neighborhood greeting appropriate for the current time ($timeOfDay) and a summary of the current vibe. '
        'Paragraph 2: Highlight 1-2 ways they could help today (or plan for tomorrow if it is night) based on the requests provided. '
        'Paragraph 3: A boost of encouragement based on their impact stats and a clear call to action.\n\n';

    final prompt =
        '$systemPrompt'
        'Community Data:\n'
        'Requests nearby:\n$requestsText\n\n'
        'Events:\n$eventsText\n\n'
        'User Stats: $userStats\n\n'
        'Write the briefing now. Use friendly but professional language. Avoid using "Dear [Name]" at the start, just start with an appropriate greeting like "Good morning", "Good evening", or "Hello, neighbor".';

    try {
      final response = await _chatModel!.generateContent([
        Content.text(prompt),
      ]);
      return response.text?.trim() ??
          generateLocalBriefing(requests: requests, events: events, user: user);
    } catch (e) {
      if (e.toString().contains('503') ||
          e.toString().contains('SERVICE_UNAVAILABLE')) {
        // Automatic retry once for the briefing
        await Future.delayed(const Duration(seconds: 2));
        try {
          final retryResponse = await _chatModel!.generateContent([
            Content.text(prompt),
          ]);
          return retryResponse.text?.trim() ??
              generateLocalBriefing(
                requests: requests,
                events: events,
                user: user,
              );
        } catch (_) {
          /* fall through */
        }
      }
      logger.e('AiService: Error generating community briefing', error: e);
      return generateLocalBriefing(
        requests: requests,
        events: events,
        user: user,
      );
    }
  }

  /// Generates a conversational response for CivicNet AI Support Chat.
  /// Uses Gemini Flash with context memory when available, and falls back to a smart local FAQ knowledge base.
  Future<AiSupportResponse> generateSupportChatResponse({
    required String userQuery,
    List<Content>? history,
  }) async {
    final cleanQuery = userQuery.trim();
    if (cleanQuery.isEmpty) {
      return const AiSupportResponse(
        message:
            'How can I assist you today? Feel free to ask about requests, matching, or community guidelines.',
        suggestedActions: [
          'How matching works',
          'Create a Request',
          'Safety Tips',
        ],
        usedAi: false,
      );
    }

    if (!_isInitialized || _chatModel == null) {
      initialize();
    }

    if (_isInitialized && _chatModel != null) {
      try {
        final systemPrompt =
            'You are the CivicNet AI Support Assistant & Community Guide.\n'
            'CivicNet is a community-driven platform connecting neighbors in need with neighbors who can help.\n\n'
            'Platform Knowledge Base:\n'
            '1. Opportunity Matching: Uses an AI Relevance Score combining GPS proximity (Haversine formula), skillset vector similarity (Gemini embeddings matched via Supabase pgvector), and urgency weighting.\n'
            '2. Creating Requests: Tap "+" on the home screen or use the Voice AI assistant to speak naturally and auto-fill details.\n'
            '3. Volunteering & Helping: Browse the Discover tab or Home urgent matches. When a helper accepts a request, private messaging is unlocked.\n'
            '4. Karma & Badges: Helping others earns Karma points and badges (e.g. Quick Responder, Top Helper, Neighborhood Hero).\n'
            '5. Safety & Trust: In life-threatening emergencies, immediately call official local emergency services (911/112). Users can report or block inappropriate behavior.\n'
            '6. Account & Technical Support: Password reset is on the login screen. Profile and skills can be edited in Settings.\n\n'
            'Instructions:\n'
            '- Be concise, friendly, and empowering.\n'
            '- Format with clear bullet points where helpful.\n'
            '- End with a helpful, friendly closing tone.\n\n';

        final prompt = '$systemPrompt\nUser Question: $cleanQuery';

        String rawResponse;
        if (history != null && history.isNotEmpty) {
          final chat = _chatModel!.startChat(history: history);
          final response = await chat.sendMessage(Content.text(prompt));
          rawResponse = response.text?.trim() ?? '';
        } else {
          final response =
              await _chatModel!.generateContent([Content.text(prompt)]);
          rawResponse = response.text?.trim() ?? '';
        }

        if (rawResponse.isNotEmpty) {
          final suggested = _extractSuggestedActions(cleanQuery, rawResponse);
          return AiSupportResponse(
            message: rawResponse,
            suggestedActions: suggested,
            usedAi: true,
          );
        }
      } catch (e) {
        logger.w(
          'AiService: Error calling Gemini for support chat, falling back to heuristics: $e',
        );
      }
    }

    // Local knowledge base fallback
    return _generateSupportResponseHeuristic(cleanQuery);
  }

  AiSupportResponse _generateSupportResponseHeuristic(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('match') ||
        lower.contains('relevance') ||
        lower.contains('score') ||
        lower.contains('algorithm')) {
      return const AiSupportResponse(
        message:
            '**How CivicNet AI Matching Works:**\n\n'
            'Our matching engine calculates an **AI Relevance Score** for every request using 3 factors:\n'
            '• **Proximity**: GPS location & real-time distance via the Haversine formula.\n'
            '• **Skill Vector Similarity**: Google Gemini embeddings matched against user skills via Supabase `pgvector`.\n'
            '• **Urgency Weighting**: Emergency requests receive high priority in neighbor alerts.',
        suggestedActions: [
          'Create a Request',
          'How to help others',
          'Safety Tips',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('create') ||
        lower.contains('post') ||
        lower.contains('ask for help') ||
        lower.contains('new request')) {
      return const AiSupportResponse(
        message:
            '**How to Create a Help Request:**\n\n'
            '1. Tap the **"+"** button at the bottom navigation bar or click **New Request**.\n'
            '2. You can type manually or tap **"AI Voice Assistant"** to describe what you need in your own words—it will auto-detect the title, category, and urgency!\n'
            '3. Confirm your location and tap **Post Request**. Nearby qualified neighbors will be alerted instantly.',
        suggestedActions: [
          'Voice AI Assistant',
          'How matching works',
          'Urgency Levels',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('volunteer') ||
        lower.contains('help') ||
        lower.contains('neighbor') ||
        lower.contains('offer')) {
      return const AiSupportResponse(
        message:
            '**How to Help Others in CivicNet:**\n\n'
            '• Explore the **Discover** tab to view open help requests categorized by Errands, Household, Tech Support, and more.\n'
            '• Check your **Home** feed for urgent needs nearby.\n'
            '• Tap **"Offer Help"** on any request. Once the requester accepts, a private chat unlocks so you can coordinate safely.\n'
            '• Every completed task earns you **Karma points** and unlocks civic badges!',
        suggestedActions: [
          'Karma & Badges',
          'Safety Guidelines',
          'Update Skills',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('emergency') ||
        lower.contains('urgent') ||
        lower.contains('danger') ||
        lower.contains('911')) {
      return const AiSupportResponse(
        message:
            '⚠️ **Emergency Notice:**\n\n'
            'CivicNet is a community mutual-aid network and **not a replacement for emergency services**.\n\n'
            '• If you or someone else is in immediate danger or requires urgent medical attention, **please call 911 (or your local emergency services) immediately**.\n'
            '• For urgent community tasks (like water leaks or power issues), set the Urgency slider to **Critical** to alert nearby neighbors quickly.',
        suggestedActions: [
          'Safety Guidelines',
          'Create a Request',
          'Contact Admin',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('karma') ||
        lower.contains('badge') ||
        lower.contains('reward') ||
        lower.contains('points')) {
      return const AiSupportResponse(
        message:
            '**Karma & Community Badges:**\n\n'
            '• **Karma Points** reflect your reliability and contributions to your neighborhood.\n'
            '• You earn Karma by completing help requests, participating in community events, and receiving positive ratings.\n'
            '• You can unlock badges like **Quick Responder**, **Community Pillar**, and **Top Contributor** on your profile!',
        suggestedActions: [
          'How to help others',
          'Create a Request',
          'Safety Guidelines',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('password') ||
        lower.contains('email') ||
        lower.contains('login') ||
        lower.contains('account')) {
      return const AiSupportResponse(
        message:
            '**Account & Security Help:**\n\n'
            '• **Forgot Password**: You can reset your password using the "Forgot Password" link on the Login screen.\n'
            '• **Edit Profile**: Go to Profile > Edit Profile to update your name, bio, and volunteer skills.\n'
            '• **Security**: CivicNet supports biometric login (Face ID / Fingerprint) configured in Settings.',
        suggestedActions: [
          'Safety Guidelines',
          'How matching works',
          'Contact Admin',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('location') ||
        lower.contains('privacy') ||
        lower.contains('gps')) {
      return const AiSupportResponse(
        message:
            '**Location & Privacy:**\n\n'
            '• Your exact GPS coordinates are **never shared publicly** with other users.\n'
            '• We calculate rough distances (e.g. "0.5 miles away") to help connect neighbors close to each other.\n'
            '• You can change your location permission anytime in device Settings.',
        suggestedActions: [
          'Safety Guidelines',
          'How matching works',
          'Create a Request',
        ],
        usedAi: false,
      );
    }

    if (lower.contains('agent') ||
        lower.contains('human') ||
        lower.contains('admin') ||
        lower.contains('ticket')) {
      return const AiSupportResponse(
        message:
            '**Contact Human Support:**\n\n'
            'Your conversation is recorded in our support logs. Our team reviews unresolved tickets and community reports promptly.\n\n'
            'Please describe what you need assistance with, or submit feedback upon closing this chat.',
        suggestedActions: [
          'How matching works',
          'Create a Request',
          'Safety Guidelines',
        ],
        usedAi: false,
      );
    }

    // General fallback
    return const AiSupportResponse(
      message:
          'Hello! I am your **CivicNet AI Assistant & Community Guide**.\n\n'
          'I can help you with:\n'
          '• Finding and posting help requests\n'
          '• Understanding our AI opportunity matching\n'
          '• Volunteering and earning Karma points\n'
          '• Community safety guidelines and account help\n\n'
          'What would you like to know?',
      suggestedActions: [
        'How matching works',
        'Create a Request',
        'How to help others',
        'Safety Guidelines',
      ],
      usedAi: false,
    );
  }

  List<String> _extractSuggestedActions(String query, String response) {
    final lower = '$query $response'.toLowerCase();
    final actions = <String>[];

    if (lower.contains('request') || lower.contains('post')) {
      actions.add('Create a Request');
    }
    if (lower.contains('match') || lower.contains('score')) {
      actions.add('How matching works');
    }
    if (lower.contains('volunteer') || lower.contains('help')) {
      actions.add('How to help others');
    }
    if (lower.contains('emergency') || lower.contains('urgent')) {
      actions.add('Safety Guidelines');
    }
    if (lower.contains('karma') || lower.contains('badge')) {
      actions.add('Karma & Badges');
    }

    if (actions.isEmpty) {
      actions.addAll([
        'Create a Request',
        'How matching works',
        'Safety Guidelines',
      ]);
    }
    return actions.take(3).toList();
  }
}

/// Data container for AI Support Chat responses and suggested follow-up chips.
class AiSupportResponse {
  final String message;
  final List<String> suggestedActions;
  final bool usedAi;

  const AiSupportResponse({
    required this.message,
    this.suggestedActions = const [],
    this.usedAi = true,
  });
}

/// Data container for voice recognition and AI task extraction.
class ParsedVoiceTask {
  final String title;
  final String description;
  final String categoryString;
  final String urgencyString;
  final List<String> suggestedTools;
  final bool usedAi;

  const ParsedVoiceTask({
    required this.title,
    required this.description,
    required this.categoryString,
    required this.urgencyString,
    this.suggestedTools = const [],
    this.usedAi = false,
  });
}
