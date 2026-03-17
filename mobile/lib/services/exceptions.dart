/// API hata tipleri.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'ApiException[$statusCode]: $message'
      : 'ApiException: $message';
}

/// Ag baglantisi kurulamadiginda firlatilir.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Sunucuya ulasilamadi']);
}

/// Istek zaman asimina ugradigi zaman firlatilir.
class RequestTimeoutException extends ApiException {
  const RequestTimeoutException(
      [super.message = 'Istek zaman asimina ugradi']);
}
