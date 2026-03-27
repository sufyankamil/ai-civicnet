import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:civic_net/services/logger_service.dart';

class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  GenerativeModel? _model;
  bool _isInitialized = false;

  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      logger.e('AiService: GEMINI_API_KEY not found in .env');
      return;
    }

    // We use the gemini-embedding-001 model for generating 768-dimension vectors
    _model = GenerativeModel(
      model: 'gemini-embedding-001',
      apiKey: apiKey,
    );

    _isInitialized = true;
    logger.i('AiService: Initialized with Gemini gemini-embedding-001');

  }

  /// Generates a 768-dimension vector for the given text.
  Future<List<double>?> generateEmbedding(String text, {TaskType? taskType}) async {
    if (!_isInitialized || _model == null) {
      initialize();
      if (!_isInitialized) throw Exception('AI Service failed to initialize. Check GEMINI_API_KEY in .env');
    }

    try {
      final content = Content.text(text);
      // Specifying taskType helps the model optimize the embedding
      final result = await _model!.embedContent(
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
}

