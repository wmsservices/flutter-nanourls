import 'dashboard_data_dto.dart';

// Data Transfer Object representing a daily click series for one NanoUrl (comparison chart)
class ComparisonSeriesDto {
  final String shortCode;
  final List<int> values;
  final int total;

  ComparisonSeriesDto({
    required this.shortCode,
    required this.values,
    required this.total,
  });

  factory ComparisonSeriesDto.fromJson(Map<String, dynamic> json) {
    return ComparisonSeriesDto(
      shortCode: json['shortCode'] ?? '',
      values: List<int>.from(json['values'] ?? []),
      total: json['total'] ?? 0,
    );
  }
}

// Data Transfer Object representing a selectable NanoUrl option for the comparison filter
class NanoUrlOptionDto {
  final String shortCode;
  final String glyph;
  final String description;
  final int totalClicks;
  final bool selected;

  NanoUrlOptionDto({
    required this.shortCode,
    required this.glyph,
    required this.description,
    required this.totalClicks,
    required this.selected,
  });

  factory NanoUrlOptionDto.fromJson(Map<String, dynamic> json) {
    return NanoUrlOptionDto(
      shortCode: json['shortCode'] ?? '',
      glyph: json['glyph'] ?? 'link',
      description: json['description'] ?? '',
      totalClicks: json['totalClicks'] ?? 0,
      selected: json['selected'] ?? false,
    );
  }
}

// Data Transfer Object representing one row of the performance ranking
class UrlComparisonItemDto {
  final int rank;
  final String shortCode;
  final String goLink;
  final String glyph;
  final String description;
  final int clicksInPeriod;
  final int totalClicks;
  final int uniqueVisitors;
  final String trend;
  final bool trendPositive;
  final String topCountry;
  final String topCountryFlag;
  final String topReferrer;
  final double sharePercentage;
  final DateTime? lastClickAt;

  UrlComparisonItemDto({
    required this.rank,
    required this.shortCode,
    required this.goLink,
    required this.glyph,
    required this.description,
    required this.clicksInPeriod,
    required this.totalClicks,
    required this.uniqueVisitors,
    required this.trend,
    required this.trendPositive,
    required this.topCountry,
    required this.topCountryFlag,
    required this.topReferrer,
    required this.sharePercentage,
    required this.lastClickAt,
  });

  factory UrlComparisonItemDto.fromJson(Map<String, dynamic> json) {
    return UrlComparisonItemDto(
      rank: json['rank'] ?? 0,
      shortCode: json['shortCode'] ?? '',
      goLink: json['goLink'] ?? '',
      glyph: json['glyph'] ?? 'link',
      description: json['description'] ?? '',
      clicksInPeriod: json['clicksInPeriod'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      uniqueVisitors: json['uniqueVisitors'] ?? 0,
      trend: json['trend'] ?? '0%',
      trendPositive: json['trendPositive'] ?? true,
      topCountry: json['topCountry'] ?? '',
      topCountryFlag: json['topCountryFlag'] ?? 'xx',
      topReferrer: json['topReferrer'] ?? '',
      sharePercentage: (json['sharePercentage'] as num?)?.toDouble() ?? 0.0,
      lastClickAt: json['lastClickAt'] != null ? DateTime.tryParse(json['lastClickAt']) : null,
    );
  }
}

// Data Transfer Object representing device type statistics (parsed from User-Agent)
class DeviceStatDto {
  final String device;
  final int count;
  final double percentage;

  DeviceStatDto({
    required this.device,
    required this.count,
    required this.percentage,
  });

  factory DeviceStatDto.fromJson(Map<String, dynamic> json) {
    return DeviceStatDto(
      device: json['device'] ?? 'Unknown',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Main Data Transfer Object for the multi-URL comparison dashboard (Analytics Hub)
class MyAnalyticsDto {
  // Mirror of NanoUrls.Domain MyAnalyticsDto.MaxComparisonUrls
  static const int maxComparisonUrls = 20;

  final int analyticsUrlsCount;
  final int selectedUrlsCount;
  final int totalClicks;
  final String totalClicksTrend;
  final int uniqueVisitors;
  final String uniqueVisitorsTrend;
  final String? bestPerformerShortCode;
  final int bestPerformerClicks;
  final List<String> chartLabels;
  final List<ComparisonSeriesDto> series;
  final List<NanoUrlOptionDto> availableUrls;
  final List<UrlComparisonItemDto> urls;
  final List<LocationItemDto> locations;
  final List<CityStatDto> topCities;
  final List<ReferrerItemDto> referrers;
  final List<DeviceStatDto> devices;

  MyAnalyticsDto({
    required this.analyticsUrlsCount,
    required this.selectedUrlsCount,
    required this.totalClicks,
    required this.totalClicksTrend,
    required this.uniqueVisitors,
    required this.uniqueVisitorsTrend,
    required this.bestPerformerShortCode,
    required this.bestPerformerClicks,
    required this.chartLabels,
    required this.series,
    required this.availableUrls,
    required this.urls,
    required this.locations,
    required this.topCities,
    required this.referrers,
    required this.devices,
  });

  factory MyAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return MyAnalyticsDto(
      analyticsUrlsCount: json['analyticsUrlsCount'] ?? 0,
      selectedUrlsCount: json['selectedUrlsCount'] ?? 0,
      totalClicks: json['totalClicks'] ?? 0,
      totalClicksTrend: json['totalClicksTrend'] ?? '0%',
      uniqueVisitors: json['uniqueVisitors'] ?? 0,
      uniqueVisitorsTrend: json['uniqueVisitorsTrend'] ?? '0%',
      bestPerformerShortCode: json['bestPerformerShortCode'],
      bestPerformerClicks: json['bestPerformerClicks'] ?? 0,
      chartLabels: List<String>.from(json['chartLabels'] ?? []),
      series: (json['series'] as List?)
              ?.map((item) => ComparisonSeriesDto.fromJson(item))
              .toList() ??
          [],
      availableUrls: (json['availableUrls'] as List?)
              ?.map((item) => NanoUrlOptionDto.fromJson(item))
              .toList() ??
          [],
      urls: (json['urls'] as List?)
              ?.map((item) => UrlComparisonItemDto.fromJson(item))
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
      referrers: (json['referrers'] as List?)
              ?.map((item) => ReferrerItemDto.fromJson(item))
              .toList() ??
          [],
      devices: (json['devices'] as List?)
              ?.map((item) => DeviceStatDto.fromJson(item))
              .toList() ??
          [],
    );
  }
}
