import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Helper class for cryptographic operations matching the .NET implementation.
class CryptoHelper {
  static const int _aesKeySize = 32; // AES-256 (32 bytes)
  static const int _aesIvSize = 16;  // AES block size is 128 bits (16 bytes)
  static const int _pbkdf2Iterations = 350000;
  static const int _saltSize = 16; // 128 bits (16 bytes)
  static const int _hashSize = 32; // 256 bits (32 bytes)

  // Encodes to base64url without padding
  static String _base64UrlEncode(Uint8List bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  // Decodes from base64url without padding
  static Uint8List _base64UrlDecode(String input) {
    var paddingLength = (4 - (input.length % 4)) % 4;
    var normalized = input + ('=' * paddingLength);
    return base64Url.decode(normalized);
  }

  static Uint8List _getKeyBytes(String keyString) {
    final padded = keyString.padRight(_aesKeySize, '\u0000');
    final substring = padded.substring(0, _aesKeySize);
    return Uint8List.fromList(utf8.encode(substring));
  }

  static Uint8List _generateRandomBytes(int size) {
    final random = Random.secure();
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List _aesCbc(bool encrypt, Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESEngine()),
    );
    cipher.init(
      encrypt,
      PaddedBlockCipherParameters<CipherParameters, CipherParameters>(
        ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
        null,
      ),
    );
    return cipher.process(data);
  }

  /// Encrypts text using AES-256-CBC with a random IV.
  /// Result is prefixed with the IV and encoded as Base64Url.
  static String encrypt(String plainText, String keyString) {
    final key = _getKeyBytes(keyString);
    final iv = _generateRandomBytes(_aesIvSize);
    final plainBytes = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = _aesCbc(true, plainBytes, key, iv);

    // Prepend IV to the ciphertext
    final result = Uint8List(iv.length + encrypted.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, encrypted);

    return _base64UrlEncode(result);
  }

  /// Decrypts text that was encrypted using [encrypt].
  static String decrypt(String encryptedText, String keyString) {
    final key = _getKeyBytes(keyString);
    final decodedBytes = _base64UrlDecode(encryptedText);

    if (decodedBytes.length < _aesIvSize) {
      throw ArgumentError("Invalid encrypted text format.");
    }

    final iv = Uint8List.sublistView(decodedBytes, 0, _aesIvSize);
    final cipherText = Uint8List.sublistView(decodedBytes, _aesIvSize);

    final decrypted = _aesCbc(false, cipherText, key, iv);
    return utf8.decode(decrypted);
  }

  /// Encrypts text using AES-256-CBC with a fixed zero-filled IV for deterministic searching.
  static String encryptDeterministic(String plainText, String keyString) {
    final key = _getKeyBytes(keyString);
    final iv = Uint8List(_aesIvSize); // Fixed zero-filled IV
    final plainBytes = Uint8List.fromList(utf8.encode(plainText));
    final encrypted = _aesCbc(true, plainBytes, key, iv);

    return _base64UrlEncode(encrypted);
  }

  /// Decrypts text that was encrypted deterministically.
  static String decryptDeterministic(String encryptedText, String keyString) {
    final key = _getKeyBytes(keyString);
    final iv = Uint8List(_aesIvSize); // Fixed zero-filled IV
    final decodedBytes = _base64UrlDecode(encryptedText);
    final decrypted = _aesCbc(false, decodedBytes, key, iv);

    return utf8.decode(decrypted);
  }

  /// Hashes a password using PBKDF2 (HMAC-SHA512) with 350,000 iterations.
  /// Result is salt + hash encoded as Base64Url.
  static String hashPassword(String password) {
    final salt = _generateRandomBytes(_saltSize);
    
    // PBKDF2 key derivator using HMAC-SHA512
    final derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    derivator.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _hashSize));
    final hash = derivator.process(Uint8List.fromList(utf8.encode(password)));

    final result = Uint8List(_saltSize + _hashSize);
    result.setRange(0, _saltSize, salt);
    result.setRange(_saltSize, result.length, hash);

    return _base64UrlEncode(result);
  }

  /// Verifies a password against a hash created by [hashPassword].
  static bool verifyPassword(String password, String hashedPassword) {
    final decodedBytes = _base64UrlDecode(hashedPassword);
    if (decodedBytes.length != _saltSize + _hashSize) return false;

    final salt = Uint8List.sublistView(decodedBytes, 0, _saltSize);
    final storedHash = Uint8List.sublistView(decodedBytes, _saltSize, _saltSize + _hashSize);

    final derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), 128));
    derivator.init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _hashSize));
    final computedHash = derivator.process(Uint8List.fromList(utf8.encode(password)));

    // Fixed-time comparison to prevent timing attacks
    return _fixedTimeEquals(storedHash, computedHash);
  }

  static bool _fixedTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
