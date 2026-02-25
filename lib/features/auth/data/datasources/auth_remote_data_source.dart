import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../../services/logger_service.dart';

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
      );
      if (response.user == null) {
        throw const ServerException('Login failed');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
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
      );
      if (response.user == null) {
        throw const ServerException('Signup failed');
      }
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      const webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID'; // TODO: replace
      const iosClientId = 'YOUR_GOOGLE_IOS_CLIENT_ID'; // TODO: replace

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('Google sign-in cancelled');

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw const AuthException('Google auth tokens missing');
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      await _upsertOAuthProfile(response.user);
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
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
      );

      await _upsertOAuthProfile(response.user);
      return UserModel.fromSupabaseUser(response.user!);
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteUserAccount() async {
    try {
      await supabaseClient.rpc('delete_user_account');
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
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
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
