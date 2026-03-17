/// Favori olarak kaydedilen istasyon.
class FavoriteStation {
  final String station;
  final String city;
  final String district;

  const FavoriteStation({
    required this.station,
    required this.city,
    required this.district,
  });

  /// Seri hale getirme anahtarı: "station|city|district"
  String toKey() => '$station|$city|$district';

  factory FavoriteStation.fromKey(String key) {
    final parts = key.split('|');
    return FavoriteStation(
      station: parts[0],
      city: parts[1],
      district: parts[2],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FavoriteStation &&
      other.station == station &&
      other.city == city &&
      other.district == district;

  @override
  int get hashCode => Object.hash(station, city, district);
}
