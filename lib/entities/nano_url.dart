// Entity representing a shortened URL (NanoUrl) in the application, updated to match API contracts
class NanoUrl {
  final String userId;
  final String shortUrl;
  final String? glyph;
  final String description;
  final String realUrl;
  final String password;
  final DateTime createdAt;
  final DateTime lastModified;
  final DateTime? expiresAt;
  final int clicks;
  final bool enabled;
  final bool analytics;
  
  // Fields returned directly by the URLs API
  final String goLink;
  final String? meLink;
  final String? qrCodeSvgUrl;
  final String? qrCodePngUrl;
  final bool hasPassword;

  NanoUrl({
    required this.userId,
    required this.shortUrl,
    this.glyph,
    required this.description,
    required this.realUrl,
    required this.password,
    required this.createdAt,
    required this.lastModified,
    this.expiresAt,
    required this.clicks,
    required this.enabled,
    required this.analytics,
    required this.goLink,
    this.meLink,
    this.qrCodeSvgUrl,
    this.qrCodePngUrl,
    required this.hasPassword,
  });

  // Check if the link has already expired based on current local time
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  // Factory constructor to deserialize a NanoUrl model from JSON map
  factory NanoUrl.fromJson(Map<String, dynamic> json) {
    return NanoUrl(
      userId: json['userId'] ?? '',
      shortUrl: json['shortUrl'] ?? '',
      glyph: json['glyph'],
      description: json['description'] ?? '',
      realUrl: json['realUrl'] ?? '',
      password: json['password'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      clicks: json['clicks'] ?? 0,
      enabled: json['enabled'] ?? true,
      analytics: json['analytics'] ?? false,
      goLink: json['goLink'] ?? '',
      meLink: json['meLink'],
      qrCodeSvgUrl: json['qrCodeSvgUrl'],
      qrCodePngUrl: json['qrCodePngUrl'],
      hasPassword: json['hasPassword'] ?? (json['password'] != null && (json['password'] as String).trim().isNotEmpty),
    );
  }

  // Convert the NanoUrl instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'shortUrl': shortUrl,
      'glyph': glyph,
      'description': description,
      'realUrl': realUrl,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'clicks': clicks,
      'enabled': enabled,
      'analytics': analytics,
      'goLink': goLink,
      'meLink': meLink,
      'qrCodeSvgUrl': qrCodeSvgUrl,
      'qrCodePngUrl': qrCodePngUrl,
      'hasPassword': hasPassword,
    };
  }
}
