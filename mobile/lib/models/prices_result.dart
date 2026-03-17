import 'fuel_price.dart';

/// /api/prices endpoint'inin tam response'u.
class PricesResult {
  final String city;
  final String? fuelType;
  final int count;
  final List<FuelPrice> prices;
  final bool cached;
  final int? cacheAgeSeconds;

  const PricesResult({
    required this.city,
    required this.fuelType,
    required this.count,
    required this.prices,
    required this.cached,
    required this.cacheAgeSeconds,
  });

  factory PricesResult.fromJson(Map<String, dynamic> json) => PricesResult(
        city: json['city'] as String,
        fuelType: json['fuel_type'] as String?,
        count: json['count'] as int,
        prices: (json['prices'] as List)
            .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
            .toList(),
        cached: json['cached'] as bool,
        cacheAgeSeconds: json['cache_age_seconds'] as int?,
      );
}
