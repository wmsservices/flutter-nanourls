// Entity representing a user plan mapping the backend Plan model
class Plan {
  final int planId;
  final String package;
  final String name;
  final int linksPerMonth;
  final int maxAnalytics;
  final bool hasDetailedAnalytics;
  final bool isAnnual;
  final bool enabeld;
  final double price;
  final bool showAds;
  final bool fullWebAccess;

  Plan({
    required this.planId,
    required this.package,
    required this.name,
    required this.linksPerMonth,
    required this.maxAnalytics,
    required this.hasDetailedAnalytics,
    required this.isAnnual,
    required this.enabeld,
    required this.price,
    required this.showAds,
    required this.fullWebAccess,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      planId: json['planId'] ?? 0,
      package: json['package'] ?? '',
      name: json['name'] ?? '',
      linksPerMonth: json['linksPerMonth'] ?? 0,
      maxAnalytics: json['maxAnalytics'] ?? 0,
      hasDetailedAnalytics: json['hasDetailedAnalytics'] ?? false,
      isAnnual: json['isAnnual'] ?? false,
      enabeld: json['enabeld'] ?? true,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      showAds: json['showAds'] ?? (json['planId'] == 1),
      fullWebAccess: json['fullWebAccess'] ?? (json['planId'] > 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package': package,
      'name': name,
      'linksPerMonth': linksPerMonth,
      'maxAnalytics': maxAnalytics,
      'hasDetailedAnalytics': hasDetailedAnalytics,
      'isAnnual': isAnnual,
      'enabeld': enabeld,
      'price': price,
    };
  }
}
