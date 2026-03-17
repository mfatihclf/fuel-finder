import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fuel_price.dart';

class StationMap extends StatefulWidget {
  final List<FuelPrice> prices;
  final String city;

  const StationMap({super.key, required this.prices, required this.city});

  @override
  State<StationMap> createState() => _StationMapState();
}

class _StationMapState extends State<StationMap> {
  final _mapController = MapController();

  /// Türkiye coğrafi merkezi — şehir geocode sonucu gelince güncellenir.
  LatLng _center = const LatLng(39.0, 35.0);

  /// İlçe adı → koordinat haritası.
  final Map<String, LatLng> _districtCoords = {};

  bool _isGeocoding = true;

  @override
  void initState() {
    super.initState();
    _geocodeAll();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _geocodeAll() async {
    // Şehir merkezini bul
    try {
      final locs = await locationFromAddress('${widget.city}, Türkiye');
      if (locs.isNotEmpty && mounted) {
        final center = LatLng(locs.first.latitude, locs.first.longitude);
        setState(() => _center = center);
        _mapController.move(center, 11);
      }
    } catch (_) {}

    // Benzersiz ilçeleri paralel geocode et
    final districts = widget.prices.map((p) => p.district).toSet().toList();
    await Future.wait(
      districts.map((d) async {
        try {
          final locs = await locationFromAddress('$d, ${widget.city}, Türkiye');
          if (locs.isNotEmpty && mounted) {
            setState(
              () => _districtCoords[d] =
                  LatLng(locs.first.latitude, locs.first.longitude),
            );
          }
        } catch (_) {}
      }),
    );

    if (mounted) setState(() => _isGeocoding = false);
  }

  Future<void> _openNavigation(LatLng point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulamasi acilamadi')),
        );
      }
    }
  }

  void _showDistrictSheet(String district, LatLng point) {
    final stations = widget.prices
        .where((p) => p.district == district)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DistrictSheet(
        district: district,
        stations: stations,
        point: point,
        onNavigate: _openNavigation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // İlçe başına en ucuz fiyatı hesapla
    final cheapestByDistrict = <String, FuelPrice>{};
    for (final p in widget.prices) {
      final existing = cheapestByDistrict[p.district];
      if (existing == null || p.price < existing.price) {
        cheapestByDistrict[p.district] = p;
      }
    }

    final markers = _districtCoords.entries.map((e) {
      final cheapest = cheapestByDistrict[e.key];
      return Marker(
        point: e.value,
        width: 76,
        height: 52,
        child: GestureDetector(
          onTap: () => _showDistrictSheet(e.key, e.value),
          child: _PriceMarker(price: cheapest?.price, cs: cs),
        ),
      );
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 11,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.fuelfinder',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        if (_isGeocoding)
          Positioned(
            top: 8,
            right: 8,
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Konumlar aliniyor...',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _PriceMarker extends StatelessWidget {
  final double? price;
  final ColorScheme cs;

  const _PriceMarker({required this.price, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            price != null ? '${price!.toStringAsFixed(2)} ₺' : '?',
            style: TextStyle(
              color: cs.onPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Icon(Icons.location_pin, color: cs.primary, size: 22),
      ],
    );
  }
}

class _DistrictSheet extends StatelessWidget {
  final String district;
  final List<FuelPrice> stations;
  final LatLng point;
  final Future<void> Function(LatLng) onNavigate;

  const _DistrictSheet({
    required this.district,
    required this.stations,
    required this.point,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: cs.primary, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    district,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => onNavigate(point),
                  icon: const Icon(Icons.navigation, size: 16),
                  label: const Text('Yol Tarifi'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: stations.length,
                itemBuilder: (ctx, i) {
                  final s = stations[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.station,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${s.price.toStringAsFixed(2)} ₺',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
