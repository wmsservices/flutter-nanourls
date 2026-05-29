// Data Transfer Object representing Referrer Traffic Sources
class ReferrerItemDto {
  final String source;
  final int clicks;
  final String trend;
  final bool trendPositive;
  final String icon;

  ReferrerItemDto({
    required this.source,
    required this.clicks,
    required this.trend,
    required this.trendPositive,
    required this.icon,
  });

  factory ReferrerItemDto.fromJson(Map<String, dynamic> json) {
    return ReferrerItemDto(
      source: json['source'] ?? '',
      clicks: json['clicks'] ?? 0,
      trend: json['trend'] ?? '',
      trendPositive: json['trendPositive'] ?? true,
      icon: json['icon'] ?? 'link',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'clicks': clicks,
      'trend': trend,
      'trendPositive': trendPositive,
      'icon': icon,
    };
  }
}

// Data Transfer Object representing Location statistics (Countries)
class LocationItemDto {
  final String country;
  final int percentage;
  final String flagCode;

  LocationItemDto({
    required this.country,
    required this.percentage,
    required this.flagCode,
  });

  factory LocationItemDto.fromJson(Map<String, dynamic> json) {
    return LocationItemDto(
      country: json['country'] ?? '',
      percentage: json['percentage'] ?? 0,
      flagCode: json['flagCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'percentage': percentage,
      'flagCode': flagCode,
    };
  }
}

// Data Transfer Object representing City statistics
class CityStatDto {
  final String city;
  final int count;
  final double percentage;

  CityStatDto({
    required this.city,
    required this.count,
    required this.percentage,
  });

  factory CityStatDto.fromJson(Map<String, dynamic> json) {
    return CityStatDto(
      city: json['city'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'count': count,
      'percentage': percentage,
    };
  }
}

// Main Data Transfer Object containing full dashboard and analytics data for a URL
class DashboardDataDto {
  final String shortCode;
  final String targetUrl;
  final String shortGoUrl;
  final String shortMeUrl;
  final String description;
  final String userId;
  final DateTime createdDate;
  final int totalClicks;
  final int clicksToday;
  final int uniqueVisitors;
  final List<String> chartLabels;
  final List<int> chartValues;
  final List<String> hourlyChartLabels;
  final List<int> hourlyChartValues;
  final List<ReferrerItemDto> referrers;
  final List<LocationItemDto> locations;
  final List<CityStatDto> topCities;
  final String totalClicksTrend;
  final String clicksTodayTrend;
  final String uniqueVisitorsTrend;

  DashboardDataDto({
    required this.shortCode,
    required this.targetUrl,
    required this.shortGoUrl,
    required this.shortMeUrl,
    required this.description,
    required this.userId,
    required this.createdDate,
    required this.totalClicks,
    required this.clicksToday,
    required this.uniqueVisitors,
    required this.chartLabels,
    required this.chartValues,
    required this.hourlyChartLabels,
    required this.hourlyChartValues,
    required this.referrers,
    required this.locations,
    required this.topCities,
    required this.totalClicksTrend,
    required this.clicksTodayTrend,
    required this.uniqueVisitorsTrend,
  });

  factory DashboardDataDto.fromJson(Map<String, dynamic> json) {
    return DashboardDataDto(
      shortCode: json['shortCode'] ?? '',
      targetUrl: json['targetUrl'] ?? '',
      shortGoUrl: json['shortGoUrl'] ?? '',
      shortMeUrl: json['shortMeUrl'] ?? '',
      description: json['description'] ?? '',
      userId: json['userId'] ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      totalClicks: json['totalClicks'] ?? 0,
      clicksToday: json['clicksToday'] ?? 0,
      uniqueVisitors: json['uniqueVisitors'] ?? 0,
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
      chartValues: List<int>.from(json['chartValues'] ?? []),
      hourlyChartLabels: List<String>.from(json['hourlyChartLabels'] ?? []),
      hourlyChartValues: List<int>.from(json['hourlyChartValues'] ?? []),
      referrers: (json['referrers'] as List?)
              ?.map((item) => ReferrerItemDto.fromJson(item))
              .toList() ??
          [],
      locations: (json['locations'] as List?)
              ?.map((item) => LocationItemDto.fromJson(item))
              .toList() ??
          [],
      topCities: (json['topCities'] as List?)
              ?.map((item) => CityStatDto.fromJson(item))
              .toList() ??
          [],
      totalClicksTrend: json['totalClicksTrend'] ?? '0%',
      clicksTodayTrend: json['clicksTodayTrend'] ?? '0%',
      uniqueVisitorsTrend: json['uniqueVisitorsTrend'] ?? '0%',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shortCode': shortCode,
      'targetUrl': targetUrl,
      'shortGoUrl': shortGoUrl,
      'shortMeUrl': shortMeUrl,
      'description': description,
      'userId': userId,
      'createdDate': createdDate.toIso8601String(),
      'totalClicks': totalClicks,
      'clicksToday': clicksToday,
      'uniqueVisitors': uniqueVisitors,
      'chartLabels': chartLabels,
      'chartValues': chartValues,
      'hourlyChartLabels': hourlyChartLabels,
      'hourlyChartValues': hourlyChartValues,
      'referrers': referrers.map((e) => e.toJson()).toList(),
      'locations': locations.map((e) => e.toJson()).toList(),
      'topCities': topCities.map((e) => e.toJson()).toList(),
      'totalClicksTrend': totalClicksTrend,
      'clicksTodayTrend': clicksTodayTrend,
      'uniqueVisitorsTrend': uniqueVisitorsTrend,
    };
  }
}
