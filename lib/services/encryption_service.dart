import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:civic_net/services/logger_service.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;

  void initialize() {
    // 32-byte key from .env. If missing, use a fallback 32-byte key for local dev.
    String keyString = dotenv.env['ENCRYPTION_KEY'] ?? 'my32charsecretkeeperfallback1234';
    if (keyString.length < 32) {
      keyString = keyString.padRight(32, '0');
    } else if (keyString.length > 32) {
      keyString = keyString.substring(0, 32);
    }
    _key = encrypt.Key.fromUtf8(keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
  }

  /// Encrypts the payload string. 
  /// In debug mode (Option B), it logs the unencrypted format beautifully.
  String encryptPayload(String plainText) {
    if (kDebugMode) {
      logger.i('🔒 [EncryptionService] Encrypting (Option B Visibility):\n$plainText');
    }
    
    // For CBC mode, we must prepend the IV to the encrypted text so we can decrypt it later.
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    
    // Return Base64 combination of IV + CipherText
    final result = base64Encode(iv.bytes + encrypted.bytes);
    
    if (kDebugMode) {
      logger.d('🔒 [EncryptionService] Generated Cipher: $result');
    }
    return result;
  }

  /// Decrypts a payload string that contains IV + CipherText encoded in base64.
  String decryptPayload(String encryptedBase64) {
    try {
      final decodedBytes = base64Decode(encryptedBase64);
      if (decodedBytes.length < 16) return encryptedBase64; // Fallback if it's plainly unencrypted or corrupted

      final ivBytes = decodedBytes.sublist(0, 16);
      final cipherBytes = decodedBytes.sublist(16);

      final iv = encrypt.IV(ivBytes);
      final encrypted = encrypt.Encrypted(cipherBytes);

      final decrypted = _encrypter.decrypt(encrypted, iv: iv);
      
      // Optionally log decrypted stuff or only on explicit errors
      return decrypted;
    } catch (e) {
      // If decryption fails, it might be unencrypted legacy data. Just return it!
      return encryptedBase64;
    }
  }
}
