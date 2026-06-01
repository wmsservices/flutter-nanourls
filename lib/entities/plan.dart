// Entity representing a user plan mapping the backend Plan model
class Plan {
  final int id;
  final String name;
  final int maxLinks;
  final int maxAnalytics;
  final bool hasCustomDomain;
  final bool hasDetailedAnalytics;
  final bool hasCustomQrCode;
  final bool hasApiAccess;
  final double price;
  final double yearPrice;
  final bool enabled;

  Plan({
    required this.id,
    required this.name,
    required this.maxLinks,
    required this.maxAnalytics,
    required this.hasCustomDomain,
    required this.hasDetailedAnalytics,
    required this.hasCustomQrCode,
    required this.hasApiAccess,
    required this.price,
    required this.yearPrice,
    required this.enabled,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      maxLinks: json['maxLinks'] ?? 0,
      maxAnalytics: json['maxAnalytics'] ?? 0,
      hasCustomDomain: json['hasCustomDomain'] ?? false,
      hasDetailedAnalytics: json['hasDetailedAnalytics'] ?? false,
      hasCustomQrCode: json['hasCustomQrCode'] ?? false,
      hasApiAccess: json['hasApiAccess'] ?? false,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      yearPrice: (json['yearPrice'] as num?)?.toDouble() ?? 0.0,
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'maxLinks': maxLinks,
      'maxAnalytics': maxAnalytics,
      'hasCustomDomain': hasCustomDomain,
      'hasDetailedAnalytics': hasDetailedAnalytics,
      'hasCustomQrCode': hasCustomQrCode,
      'hasApiAccess': hasApiAccess,
      'price': price,
      'yearPrice': yearPrice,
      'enabled': enabled,
    };
  }
}
