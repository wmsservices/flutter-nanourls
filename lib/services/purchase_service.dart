import 'package:purchases_flutter/purchases_flutter.dart';

/// Serviço responsável por gerenciar a comunicação com o RevenueCat para compras e assinaturas.
class PurchaseService {
  /// Obtém os produtos/ofertas disponíveis no RevenueCat.
  static Future<Offerings> fetchOfferings() async {
    return await Purchases.getOfferings();
  }
}
