import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Konum izin durumu.
enum LocationStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

/// Konum sorgusu sonucu.
class LocationResult {
  final Position position;

  /// API'nin bekledigii normalized sehir anahtari (orn: "istanbul").
  /// Reverse geocoding basarisiz olursa null.
  final String? cityKey;

  const LocationResult({required this.position, this.cityKey});
}

/// Geolocator tabanli konum servisi.
class LocationService {
  /// Konum servisini ve izinleri kontrol eder, gerekirse izin ister.
  Future<LocationStatus> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationStatus.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse =>
        LocationStatus.granted,
      LocationPermission.deniedForever => LocationStatus.deniedForever,
      _ => LocationStatus.denied,
    };
  }

  /// Kullanicinin mevcut konumunu ve sehir adini dondurur.
  Future<LocationResult> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final cityKey = await _resolveCityKey(position.latitude, position.longitude);
    return LocationResult(position: position, cityKey: cityKey);
  }

  /// Koordinat ciftinden normalize edilmis sehir anahtarini dondurur.
  Future<String?> _resolveCityKey(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final area = placemarks.first.administrativeArea;
      return normalizeCityName(area);
    } catch (_) {
      return null;
    }
  }

  /// Iki koordinat arasindaki mesafeyi metre cinsinden dondurur.
  static double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  /// Iki koordinat arasindaki mesafeyi kilometre cinsinden dondurur.
  static double distanceBetweenKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) =>
      distanceBetween(lat1, lon1, lat2, lon2) / 1000.0;

  /// Turkce il adini API anahtarina donusturur.
  /// Orn: "İstanbul" → "istanbul", "Ankara İli" → "ankara"
  static String? normalizeCityName(String? name) {
    if (name == null || name.isEmpty) return null;

    var s = name.trim().toLowerCase();

    // Turkce karakter donusumu
    const replacements = {
      'ı': 'i', 'i̇': 'i', 'ğ': 'g', 'ü': 'u',
      'ş': 's', 'ö': 'o', 'ç': 'c',
    };
    for (final entry in replacements.entries) {
      s = s.replaceAll(entry.key, entry.value);
    }

    // "ili", "province", "il" gibi ekleri kaldir
    s = s
        .replaceAll(' ili', '')
        .replaceAll(' province', '')
        .replaceAll(' il', '')
        .replaceAll(' ', '');

    return s.isEmpty ? null : s;
  }

  /// Haversine formulu ile iki nokta arasi kuşuçuşu mesafe (km).
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180;
}
