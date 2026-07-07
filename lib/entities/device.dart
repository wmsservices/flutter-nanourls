class Device {
  final String deviceId;
  final String userId;
  final String tokenFcm;

  Device({
    required this.deviceId,
    required this.userId,
    required this.tokenFcm
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      userId: json['userId'] ?? '',
      deviceId: json['deviceId'] ?? '',
      tokenFcm: json['tokenFcm'] ?? ''
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'tokenFcm': tokenFcm
    };
  }
}