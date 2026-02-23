import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:civic_net/services/logger_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Uploads an avatar image to the 'avatars' storage bucket.
  /// Generates a unique filename based on the user ID and timestamp.
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadAvatar(File imageFile, String userId) async {
    try {
      final ext = imageFile.path.split('.').last;
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = fileName;

      logger.i('Uploading avatar to path: $path');

      await _client.storage.from('avatars').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      // Let's rely on the unique filename to bust the cache instead of a query parameter
      // since query parameters can cause 400 Bad Request errors on Supabase public buckets
      final cacheBustedUrl = publicUrl;

      logger.i('Avatar uploaded successfully. Public URL: $cacheBustedUrl');
      
      return cacheBustedUrl;
    } on StorageException catch (se) {
      logger.e('Storage Exception: ${se.message}\nThis often means the "avatars" bucket is missing or RLS policies deny upload.');
      return null;
    } catch (e) {
      logger.e('Error uploading avatar: $e');
      return null;
    }
  }
}
