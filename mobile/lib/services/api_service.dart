import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/models.dart';
import 'exceptions.dart';

/// FastAPI backend ile haberlesme servisi.
class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConstants.devBaseUrl,
        _client = client ?? http.Client();

  /// [city] sehrine ait akaryakit fiyatlarini ceker.
  /// [fuelType] verilirse sadece o yakit turunu filtreler.
  Future<PricesResult> getPrices(String city, {String? fuelType}) async {
    final params = <String, String>{'city': city};
    if (fuelType != null) params['fuel_type'] = fuelType;
    final uri =
        Uri.parse('$baseUrl/api/prices').replace(queryParameters: params);
    final response = await _get(uri, timeout: ApiConstants.requestTimeout);
    return PricesResult.fromJson(jsonDecode(response) as Map<String, dynamic>);
  }

  /// Desteklenen tum illeri ceker.
  Future<List<City>> getCities() async {
    final uri = Uri.parse('$baseUrl/api/cities');
    final response = await _get(uri, timeout: ApiConstants.shortTimeout);
    return (jsonDecode(response) as List)
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Desteklenen yakit turlerini ceker.
  Future<List<String>> getFuelTypes() async {
    final uri = Uri.parse('$baseUrl/api/fuel-types');
    final response = await _get(uri, timeout: ApiConstants.shortTimeout);
    return (jsonDecode(response) as List).cast<String>();
  }

  Future<String> _get(Uri uri, {required Duration timeout}) async {
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode == 200) {
        return response.body;
      }
      if (response.statusCode == 404) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          body['detail'] as String? ?? 'Bulunamadi',
          statusCode: 404,
        );
      }
      throw ApiException('Sunucu hatasi', statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    }
  }

  void dispose() => _client.close();
}
