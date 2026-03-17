import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fuel_price.dart';
import '../services/api_service.dart';
import '../services/exceptions.dart';

class StationDetailScreen extends StatefulWidget {
  final String stationName;
  final String city;
  final String district;

  /// Sonuc listesindeki arama yakit turu — bu satir vurgulenir.
  final String highlightFuelType;

  const StationDetailScreen({
    super.key,
    required this.stationName,
    required this.city,
    required this.district,
    required this.highlightFuelType,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  final _api = ApiService();
  List<FuelPrice> _prices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Sehirdeki tum yakit turlerini cek, sonra bu istasyona filtrele
      final result = await _api.getPrices(widget.city);
      if (!mounted) return;
      final filtered = result.prices
          .where(
            (p) =>
                p.station == widget.stationName &&
                p.district == widget.district,
          )
          .toList()
        ..sort((a, b) => a.fuelType.compareTo(b.fuelType));
      setState(() {
        _prices = filtered;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Beklenmeyen bir hata olustu';
        _isLoading = false;
      });
    }
  }

  Future<void> _openNavigation() async {
    final query = Uri.encodeComponent(
      '${widget.stationName} ${widget.district} ${widget.city}',
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita uygulamasi acilamadi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.stationName),
            Text(
              widget.district,
              style: TextStyle(
                fontSize: 12,
                color: cs.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetchAll);
    }
    if (_prices.isEmpty) {
      return const Center(
        child: Text('Bu istasyon icin fiyat bilgisi bulunamadi.'),
      );
    }

    final cheapest = _prices.reduce((a, b) => a.price < b.price ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandHeader(
            stationName: widget.stationName,
            city: widget.city,
            district: widget.district,
            cheapestPrice: cheapest.price,
            cheapestFuelType: cheapest.fuelType,
            date: _prices.first.date,
          ),
          const SizedBox(height: 16),
          _PriceTable(
            prices: _prices,
            highlightFuelType: widget.highlightFuelType,
          ),
          const SizedBox(height: 24),
          _NavigationButton(onPressed: _openNavigation),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Marka stil yardimcisi
// ---------------------------------------------------------------------------

(Color, String) _brandStyle(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('opet')) return (const Color(0xFFE65100), 'OP');
  if (lower.contains('bp')) return (const Color(0xFF2E7D32), 'BP');
  if (lower.contains('shell')) return (const Color(0xFFF9A825), 'SH');
  if (lower.contains('petrol')) return (const Color(0xFF1565C0), 'PO');
  if (lower.contains('total')) return (const Color(0xFFC62828), 'TE');
  if (lower.contains('aytemiz')) return (const Color(0xFF6A1B9A), 'AY');
  if (lower.contains('tp') || lower.contains('turk')) {
    return (const Color(0xFF00695C), 'TP');
  }
  final abbr = name.substring(0, min(2, name.length)).toUpperCase();
  return (const Color(0xFF546E7A), abbr);
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _BrandHeader extends StatelessWidget {
  final String stationName;
  final String city;
  final String district;
  final double cheapestPrice;
  final String cheapestFuelType;
  final String date;

  const _BrandHeader({
    required this.stationName,
    required this.city,
    required this.district,
    required this.cheapestPrice,
    required this.cheapestFuelType,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final (brandColor, abbr) = _brandStyle(stationName);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: brandColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                abbr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationName,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '$district, ${city.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'En ucuz: ${cheapestPrice.toStringAsFixed(2)} ₺'
                      '  ($cheapestFuelType)',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Guncelleme: $date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceTable extends StatelessWidget {
  final List<FuelPrice> prices;
  final String highlightFuelType;

  const _PriceTable({
    required this.prices,
    required this.highlightFuelType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Yakit Fiyatlari',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const Divider(height: 1),
          ...prices.map((p) {
            final isHighlighted = p.fuelType == highlightFuelType;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: isHighlighted
                    ? cs.primaryContainer.withValues(alpha: 0.45)
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      size: 18,
                      color: isHighlighted
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.fuelType,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isHighlighted
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isHighlighted ? cs.primary : null,
                        ),
                      ),
                    ),
                    Text(
                      '${p.price.toStringAsFixed(2)} ₺',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? cs.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NavigationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.navigation),
        label: const Text(
          'Yol Tarifi Al',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.error),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
