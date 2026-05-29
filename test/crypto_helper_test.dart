import 'package:flutter_test/flutter_test.dart';
import 'package:nanourls/helpers/crypto_helper.dart';

void main() {
  group('CryptoHelper Tests', () {
    const key = 'my-super-secret-key-32-chars-long-!!!';
    const plainText = 'Hello, World! Este é um teste com acentos e caracteres especiais.';

    test('AES Encryption and Decryption', () {
      final encrypted = CryptoHelper.encrypt(plainText, key);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));

      final decrypted = CryptoHelper.decrypt(encrypted, key);
      expect(decrypted, equals(plainText));
    });

    test('AES Deterministic Encryption and Decryption', () {
      final encrypted1 = CryptoHelper.encryptDeterministic(plainText, key);
      final encrypted2 = CryptoHelper.encryptDeterministic(plainText, key);
      
      // Deterministic encryption must produce the exact same cipher text for the same inputs
      expect(encrypted1, equals(encrypted2));

      final decrypted = CryptoHelper.decryptDeterministic(encrypted1, key);
      expect(decrypted, equals(plainText));
    });

    test('Password Hashing and Verification', () {
      const password = 'mySecurePassword123!';
      final hashed = CryptoHelper.hashPassword(password);
      
      expect(hashed, isNotEmpty);
      expect(hashed, isNot(equals(password)));

      // Verifying correct password
      final verified = CryptoHelper.verifyPassword(password, hashed);
      expect(verified, isTrue);

      // Verifying incorrect password
      final incorrectVerified = CryptoHelper.verifyPassword('wrongPassword', hashed);
      expect(incorrectVerified, isFalse);
    });
  });
}
