import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../../services/logger_service.dart';
import '../../../../core/utils/timeout_extension.dart';

String _parseAuthExceptionMessage(String message) {
  try {
    // Supabase sometimes returns a JSON string in the AuthException message
    if (message.startsWith('{') && message.endsWith('}')) {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        message = decoded['message'].toString();
      }
    }
  } catch (_) {
    // Ignore parsing errors
  }

  // Catch unhandled network texts that leak from gotrue
  if (message.contains('SocketException') || message.contains('ClientException') || message.contains('Failed host lookup') || message.contains('Connection timed out')) {
    return 'Unable to reach server. Please check your internet connection and try again.';
  }

  return message;
}

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> deleteUserAccount();
  Stream<sb.User?> get authStateChanges;
  UserModel? getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sb.SupabaseClient supabaseClient;
  AuthRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Stream<sb.User?> get authStateChanges => supabaseClient.auth.onAuthStateChange.map((event) => event.session?.user);

  @override
  UserModel? getCurrentUser() {
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      return UserModel.fromSupabaseUser(user);
    }
    return null;
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      ).withServerTimeout();
      if (response.user == null) {
        throw const ServerException('Login failed');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_parseAuthExceptionMessage(e.message));
    } on SocketException catch (e) {
      logger.e('Network error during login: $e');
      throw const ServerException('Network connection error. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        logger.e('Network error during login: $e');
        throw const ServerException('A network error occurred. Please check your internet connection.');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUp(String email, String password, String name) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      ).withServerTimeout();
      if (response.user == null) {
        throw const ServerException('Signup failed');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_parseAuthExceptionMessage(e.message));
    } on SocketException catch (e) {
      logger.e('Network error during signup: $e');
      throw const ServerException('Network connection error. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        logger.e('Network error during signup: $e');
        throw const ServerException('A network error occurred. Please check your internet connection.');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut().withServerTimeout();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      const webClientId = '283190655136-dhb3i7mfvpv97ssa3tjmne9484vircsc.apps.googleusercontent.com';

      const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
        clientId: iosClientId, 
      );

      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const AuthException('Google auth ID Token missing');
      }

      final authorization = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
        'openid', // Required to use signInWithIdToken with Supabase securely
      ]);
      final accessToken = authorization.accessToken;

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      ).withServerTimeout();

      await _upsertOAuthProfile(response.user);
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_parseAuthExceptionMessage(e.message));
    } on SocketException catch (e) {
      logger.e('Network error during Google sign-in: $e');
      throw const ServerException('Network connection error. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        logger.e('Network error during Google sign-in: $e');
        throw const ServerException('A network error occurred. Please check your internet connection.');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) throw const AuthException('Apple identity token missing');

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      ).withServerTimeout();

      await _upsertOAuthProfile(response.user);
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(_parseAuthExceptionMessage(e.message));
    } on SocketException catch (e) {
      logger.e('Network error during Apple sign-in: $e');
      throw const ServerException('Network connection error. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        logger.e('Network error during Apple sign-in: $e');
        throw const ServerException('A network error occurred. Please check your internet connection.');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://privacypolicy-ruddy.vercel.app/reset',
      ).withServerTimeout();
    } on sb.AuthException catch (e) {
      // Provide a friendly error message for rate limiting
      if (e.message.contains('For security purposes, you can only request this after')) {
        throw const AuthException('Please wait a moment before requesting another reset link.');
      }
      throw AuthException(_parseAuthExceptionMessage(e.message));
    } on SocketException catch (e) {
      logger.e('Network error during password reset: $e');
      throw const ServerException('Network connection error. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        logger.e('Network error during password reset: $e');
        throw const ServerException('A network error occurred. Please check your internet connection.');
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteUserAccount() async {
    try {
      await supabaseClient.rpc('delete_user_account').withServerTimeout();
      await signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> _upsertOAuthProfile(sb.User? user) async {
    if (user == null) return;
    final meta = user.userMetadata ?? {};
    final name = meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'User';
    final avatar = meta['avatar_url'] ?? meta['picture'] ?? '';
    try {
      await supabaseClient.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'avatar_url': avatar,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'id').withServerTimeout();
    } catch (e) {
      logger.e('Failed to upsert OAuth profile: $e');
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final secureRandom = Random.secure();
    final random = List.generate(length, (_) => charset[secureRandom.nextInt(charset.length)]);
    return random.join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
