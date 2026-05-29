import '../helpers/crypto_helper.dart';
import '../settings/crypto_settings.dart';

class CryptoService {
  String encryptEmail(String email) {
    return CryptoHelper.encryptDeterministic(email, CryptoSettings.cryptoEmailKey);
  }

  String decryptEmail(String encryptedEmail) {
    return CryptoHelper.decryptDeterministic(encryptedEmail, CryptoSettings.cryptoEmailKey);
  }

  String encryptIpAddress(String ipAddress) {
    return CryptoHelper.encryptDeterministic(ipAddress, CryptoSettings.cryptoIpAddressKey);
  }

  String decryptIpAddress(String encryptedIpAddress) {
    return CryptoHelper.decryptDeterministic(encryptedIpAddress, CryptoSettings.cryptoIpAddressKey);
  }

  String encryptPassword(String password) {
    return CryptoHelper.encryptDeterministic(password, CryptoSettings.cryptoPassKey);
  }

  String decryptPassword(String encryptedPassword) {
    return CryptoHelper.decryptDeterministic(encryptedPassword, CryptoSettings.cryptoPassKey);
  }
}
