import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Serviço responsável por gerenciar a comunicação com o RevenueCat para compras e assinaturas.
class PurchaseService {
  /// Obtém os produtos/ofertas disponíveis no RevenueCat.
  static Future<Offerings> fetchOfferings() async {
    return await Purchases.getOfferings();
  }
  static Future<void> showManageSubscriptions() async {
    try {
      // 1. Pega as informações de compras do usuário diretamente do RevenueCat
      final customerInfo = await Purchases.getCustomerInfo();
      final managementUrl = customerInfo.managementURL;

      // 2. Se a URL existir (ele tem uma assinatura vinculada a uma loja)
      if (managementUrl != null && managementUrl.isNotEmpty) {
        final uri = Uri.parse(managementUrl);

        // 3. Abre o painel nativo da loja correspondente (App Store ou Google Play)
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // Em caso de falha (ex: sem internet ou simulador limitando a abertura da loja)
    }
  }
}
