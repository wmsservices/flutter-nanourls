// Entity representing a User in the NanoUrls system
class User {
  final String userId;
  final String userName;
  final String email;
  final int planId;
  final bool enabled;
  final DateTime createdAt;
  final DateTime lastModified;

  User({
    required this.userId,
    required this.userName,
    required this.email,
    required this.planId,
    required this.enabled,
    required this.createdAt,
    required this.lastModified,
  });

  // Factory constructor to parse the User model from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      email: json['email'] ?? '',
      planId: json['planId'] ?? 0,
      enabled: json['enabled'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified']) 
          : DateTime.now(),
    );
  }

  // Convert the User instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'email': email,
      'planId': planId,
      'enabled': enabled,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
    };
  }
}
