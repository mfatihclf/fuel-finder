/// API baglanti sabitleri.
///
/// Android emulator icin host loopback adresi 10.0.2.2'dir.
/// iOS simulator icin 127.0.0.1 kullanilabilir.
/// Gercek cihazda bilgisayarin yerel ag IP'si gerekir.
class ApiConstants {
  ApiConstants._();

  /// Gelistirme ortami base URL (Android emulator)
  static const String devBaseUrl = 'http://10.0.2.2:8000';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 15);
}
