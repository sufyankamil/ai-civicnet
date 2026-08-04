import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/api.dart' hide Padding;

/// Per-conversation AES encryption with RSA-OAEP wrap keys.
///
/// Legacy dual-read: messages encrypted with the old global [ENCRYPTION_KEY]
/// can still be decrypted via [decryptLegacy] during the migration window.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  static const _privateKeyStorageKey = 'civicnet_rsa_private_pem';
  static const _publicKeyStorageKey = 'civicnet_rsa_public_pem';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;
  encrypt.Encrypter? _legacyEncrypter;
  bool _legacyAvailable = false;

  String? get publicWrapKeyPem => _encodePublicPem(_publicKey);

  /// Sync bootstrap: optional legacy key for dual-read of old ciphertext.
  void initialize() {
    final keyString = dotenv.env['ENCRYPTION_KEY'];
    if (keyString == null || keyString.isEmpty) {
      _legacyAvailable = false;
      return;
    }
    var normalized = keyString;
    if (normalized.length < 32) {
      normalized = normalized.padRight(32, '0');
    } else if (normalized.length > 32) {
      normalized = normalized.substring(0, 32);
    }
    final key = encrypt.Key.fromUtf8(normalized);
    _legacyEncrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    _legacyAvailable = true;
  }

  /// Ensures an RSA identity keypair exists in secure storage.
  /// Returns the PEM public key to upload to `profiles.public_wrap_key`.
  Future<String> ensureIdentityKeys() async {
    final existingPub = await _secureStorage.read(key: _publicKeyStorageKey);
    final existingPriv = await _secureStorage.read(key: _privateKeyStorageKey);

    if (existingPub != null &&
        existingPriv != null &&
        existingPub.isNotEmpty &&
        existingPriv.isNotEmpty) {
      _publicKey = encrypt.RSAKeyParser().parse(existingPub) as RSAPublicKey;
      _privateKey = encrypt.RSAKeyParser().parse(existingPriv) as RSAPrivateKey;
      return existingPub;
    }

    final pair = _generateRsaKeyPair();
    _publicKey = pair.publicKey as RSAPublicKey;
    _privateKey = pair.privateKey as RSAPrivateKey;

    final pubPem = _encodePublicPem(_publicKey)!;
    final privPem = _encodePrivatePem(_privateKey)!;

    await _secureStorage.write(key: _publicKeyStorageKey, value: pubPem);
    await _secureStorage.write(key: _privateKeyStorageKey, value: privPem);

    return pubPem;
  }

  /// Generates a fresh 256-bit conversation key.
  Uint8List generateConversationKey() {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(32, (_) => random.nextInt(256)));
  }

  /// Wraps a conversation key for a recipient using their PEM public key.
  String wrapConversationKey(Uint8List conversationKey, String recipientPublicPem) {
    final publicKey =
        encrypt.RSAKeyParser().parse(recipientPublicPem) as RSAPublicKey;
    final encrypter = encrypt.Encrypter(
      encrypt.RSA(
        publicKey: publicKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ),
    );
    return encrypter.encryptBytes(conversationKey).base64;
  }

  /// Unwraps a conversation key with this device's private key.
  Uint8List unwrapConversationKey(String wrappedKeyBase64) {
    if (_privateKey == null) {
      throw StateError('Identity keys not loaded. Call ensureIdentityKeys first.');
    }
    final encrypter = encrypt.Encrypter(
      encrypt.RSA(
        privateKey: _privateKey,
        encoding: encrypt.RSAEncoding.OAEP,
        digest: encrypt.RSADigest.SHA256,
      ),
    );
    return Uint8List.fromList(
      encrypter.decryptBytes(encrypt.Encrypted.fromBase64(wrappedKeyBase64)),
    );
  }

  /// Encrypts plaintext with a per-conversation AES-256-CBC key.
  /// Returns base64(IV || ciphertext).
  String encryptWithKey(String plainText, Uint8List keyBytes) {
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return base64Encode(iv.bytes + encrypted.bytes);
  }

  /// Decrypts base64(IV || ciphertext) with a per-conversation key.
  String decryptWithKey(String encryptedBase64, Uint8List keyBytes) {
    final decodedBytes = base64Decode(encryptedBase64);
    if (decodedBytes.length < 16) {
      throw const FormatException('Ciphertext too short');
    }
    final iv = encrypt.IV(Uint8List.fromList(decodedBytes.sublist(0, 16)));
    final cipher = encrypt.Encrypted(
        Uint8List.fromList(decodedBytes.sublist(16)));
    final key = encrypt.Key(keyBytes);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(cipher, iv: iv);
  }

  /// Dual-read helper: try per-conversation key, then legacy global key.
  String decryptPayload(String encryptedBase64, {Uint8List? conversationKey}) {
    if (conversationKey != null) {
      try {
        return decryptWithKey(encryptedBase64, conversationKey);
      } catch (_) {
        // Fall through to legacy.
      }
    }
    return decryptLegacy(encryptedBase64);
  }

  /// Decrypts ciphertext produced by the old app-wide ENCRYPTION_KEY.
  String decryptLegacy(String encryptedBase64) {
    if (!_legacyAvailable || _legacyEncrypter == null) {
      return encryptedBase64;
    }
    try {
      final decodedBytes = base64Decode(encryptedBase64);
      if (decodedBytes.length < 16) return encryptedBase64;
      final iv = encrypt.IV(Uint8List.fromList(decodedBytes.sublist(0, 16)));
      final cipher = encrypt.Encrypted(
          Uint8List.fromList(decodedBytes.sublist(16)));
      return _legacyEncrypter!.decrypt(cipher, iv: iv);
    } catch (_) {
      return encryptedBase64;
    }
  }

  /// @Deprecated — use [encryptWithKey] with a conversation key.
  @Deprecated('Use encryptWithKey with a per-conversation key')
  String encryptPayload(String plainText) {
    throw UnsupportedError(
      'Global encryptPayload is disabled. Use per-conversation encryptWithKey.',
    );
  }

  AsymmetricKeyPair<PublicKey, PrivateKey> _generateRsaKeyPair() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)));
    secureRandom.seed(KeyParameter(seed));

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        secureRandom,
      ));
    return keyGen.generateKeyPair();
  }

  String? _encodePublicPem(RSAPublicKey? key) {
    if (key == null) return null;
    final modulusBytes = _bigIntToBytes(key.modulus!);
    final exponentBytes = _bigIntToBytes(key.exponent!);

    // PKCS#1 RSAPublicKey SEQUENCE { n, e }
    final sequence = _asn1Sequence([
      _asn1Integer(modulusBytes),
      _asn1Integer(exponentBytes),
    ]);

    // wrap in SubjectPublicKeyInfo for "BEGIN PUBLIC KEY"
    final algorithmIdentifier = _asn1Sequence([
      _asn1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1]), // rsaEncryption
      Uint8List.fromList([0x05, 0x00]), // NULL
    ]);
    final spki = _asn1Sequence([
      algorithmIdentifier,
      _asn1BitString(sequence),
    ]);

    final b64 = base64Encode(spki);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----';
  }

  String? _encodePrivatePem(RSAPrivateKey? key) {
    if (key == null) return null;
    final n = key.modulus!;
    final d = key.privateExponent!;
    final p = key.p!;
    final q = key.q!;
    final e = key.publicExponent!;
    final dP = d % (p - BigInt.one);
    final dQ = d % (q - BigInt.one);
    final qInv = q.modInverse(p);

    // PKCS#1 RSAPrivateKey
    final sequence = _asn1Sequence([
      _asn1Integer(_bigIntToBytes(BigInt.zero)), // version
      _asn1Integer(_bigIntToBytes(n)),
      _asn1Integer(_bigIntToBytes(e)),
      _asn1Integer(_bigIntToBytes(d)),
      _asn1Integer(_bigIntToBytes(p)),
      _asn1Integer(_bigIntToBytes(q)),
      _asn1Integer(_bigIntToBytes(dP)),
      _asn1Integer(_bigIntToBytes(dQ)),
      _asn1Integer(_bigIntToBytes(qInv)),
    ]);

    final b64 = base64Encode(sequence);
    final lines = <String>[];
    for (var i = 0; i < b64.length; i += 64) {
      lines.add(b64.substring(i, i + 64 > b64.length ? b64.length : i + 64));
    }
    return '-----BEGIN RSA PRIVATE KEY-----\n${lines.join('\n')}\n-----END RSA PRIVATE KEY-----';
  }

  Uint8List _bigIntToBytes(BigInt number) {
    var hex = number.toRadixString(16);
    if (hex.length % 2 != 0) hex = '0$hex';
    // Ensure positive integer bit string (leading 0x00 if high bit set)
    final bytes = Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]);
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
      return Uint8List.fromList([0x00, ...bytes]);
    }
    return bytes;
  }

  Uint8List _asn1Length(int length) {
    if (length < 128) return Uint8List.fromList([length]);
    final lenBytes = <int>[];
    var n = length;
    while (n > 0) {
      lenBytes.insert(0, n & 0xff);
      n >>= 8;
    }
    return Uint8List.fromList([0x80 | lenBytes.length, ...lenBytes]);
  }

  Uint8List _asn1Integer(Uint8List content) {
    return Uint8List.fromList([0x02, ..._asn1Length(content.length), ...content]);
  }

  Uint8List _asn1Sequence(List<Uint8List> elements) {
    final content = Uint8List.fromList(elements.expand((e) => e).toList());
    return Uint8List.fromList([0x30, ..._asn1Length(content.length), ...content]);
  }

  Uint8List _asn1BitString(Uint8List content) {
    final body = Uint8List.fromList([0x00, ...content]);
    return Uint8List.fromList([0x03, ..._asn1Length(body.length), ...body]);
  }

  Uint8List _asn1ObjectIdentifier(List<int> oid) {
    // Encode OID nodes
    final first = 40 * oid[0] + oid[1];
    final rest = <int>[];
    for (var i = 2; i < oid.length; i++) {
      var v = oid[i];
      if (v < 128) {
        rest.add(v);
      } else {
        final stack = <int>[];
        stack.add(v & 0x7f);
        v >>= 7;
        while (v > 0) {
          stack.add(0x80 | (v & 0x7f));
          v >>= 7;
        }
        rest.addAll(stack.reversed);
      }
    }
    final content = Uint8List.fromList([first, ...rest]);
    return Uint8List.fromList([0x06, ..._asn1Length(content.length), ...content]);
  }
}
