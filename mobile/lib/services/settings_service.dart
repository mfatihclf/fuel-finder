import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/fuel_types.dart';
import '../models/favorite_station.dart';

/// Uygulama ayarlarini ve favorileri yoneten singleton servis.
class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyThemeMode = 'theme_mode';
  static const _keyFuelType = 'default_fuel_type';
  static const _keyRadius = 'default_radius';
  static const _keyFavorites = 'favorites';

  ThemeMode _themeMode = ThemeMode.system;
  String _defaultFuelType = FuelTypes.all.first;
  int _defaultRadius = 10;
  final List<FavoriteStation> _favorites = [];

  ThemeMode get themeMode => _themeMode;
  String get defaultFuelType => _defaultFuelType;
  int get defaultRadius => _defaultRadius;
  List<FavoriteStation> get favorites => List.unmodifiable(_favorites);

  /// Uygulamada bir kez cagrilmali (main'de, runApp oncesinde).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeName = prefs.getString(_keyThemeMode) ?? 'system';
    _themeMode = _themeFromString(themeName);

    _defaultFuelType =
        prefs.getString(_keyFuelType) ?? FuelTypes.all.first;

    _defaultRadius = prefs.getInt(_keyRadius) ?? 10;

    final keys = prefs.getStringList(_keyFavorites) ?? [];
    _favorites
      ..clear()
      ..addAll(keys.map(FavoriteStation.fromKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, _themeToString(mode));
    notifyListeners();
  }

  Future<void> setDefaultFuelType(String fuelType) async {
    if (_defaultFuelType == fuelType) return;
    _defaultFuelType = fuelType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFuelType, fuelType);
    notifyListeners();
  }

  Future<void> setDefaultRadius(int radius) async {
    if (_defaultRadius == radius) return;
    _defaultRadius = radius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRadius, radius);
    notifyListeners();
  }

  bool isFavorite(String station, String city, String district) =>
      _favorites.any(
        (f) =>
            f.station == station && f.city == city && f.district == district,
      );

  Future<void> toggleFavorite(FavoriteStation fav) async {
    final idx = _favorites.indexWhere((f) => f == fav);
    if (idx >= 0) {
      _favorites.removeAt(idx);
    } else {
      _favorites.add(fav);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyFavorites,
      _favorites.map((f) => f.toKey()).toList(),
    );
    notifyListeners();
  }

  Future<void> removeFavorite(FavoriteStation fav) async {
    _favorites.remove(fav);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyFavorites,
      _favorites.map((f) => f.toKey()).toList(),
    );
    notifyListeners();
  }

  static ThemeMode _themeFromString(String s) => switch (s) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _themeToString(ThemeMode m) => switch (m) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}
