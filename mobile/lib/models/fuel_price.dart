/// Tek bir akaryakit fiyat kaydi.
class FuelPrice {
  final String station;
  final String city;
  final String district;
  final String fuelType;
  final double price;
  final String date;

  const FuelPrice({
    required this.station,
    required this.city,
    required this.district,
    required this.fuelType,
    required this.price,
    required this.date,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) => FuelPrice(
        station: json['station'] as String,
        city: json['city'] as String,
        district: json['district'] as String,
        fuelType: json['fuel_type'] as String,
        price: (json['price'] as num).toDouble(),
        date: json['date'] as String? ?? '',
      );
}
