import 'package:flutter/material.dart';

import '../models/fuel_price.dart';
import '../services/api_service.dart';
import '../services/exceptions.dart';
import '../widgets/station_map.dart';
import 'station_detail_screen.dart';

enum _SortMode { cheapest, byDistrict }

enum _ViewMode { list, map }

class ResultsScreen extends StatefulWidget {
  final String city;
  final String fuelType;
  final int radiusKm;

  const ResultsScreen({
    super.key,
    required this.city,
    required this.fuelType,
    required this.radiusKm,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _api = ApiService();
  List<FuelPrice> _prices = [];
  bool _isLoading = true;
  String? _error;
  _SortMode _sortMode = _SortMode.cheapest;
  _ViewMode _viewMode = _ViewMode.list;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _fetchPrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.getPrices(
        widget.city,
        fuelType: widget.fuelType,
      );
      if (!mounted) return;
      setState(() {
        _prices = result.prices;
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

  List<FuelPrice> get _sortedPrices {
    final sorted = List<FuelPrice>.from(_prices);
    if (_sortMode == _SortMode.cheapest) {
      sorted.sort((a, b) => a.price.compareTo(b.price));
    } else {
      sorted.sort((a, b) => a.district.compareTo(b.district));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.city.toUpperCase()),
            Text(
              '${widget.fuelType} • ${widget.radiusKm} km',
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
        actions: [
          if (!_isLoading && _error == null && _prices.isNotEmpty)
            IconButton(
              onPressed: () => setState(() {
                _viewMode =
                    _viewMode == _ViewMode.list ? _ViewMode.map : _ViewMode.list;
              }),
              icon: Icon(
                _viewMode == _ViewMode.list ? Icons.map : Icons.list,
              ),
              tooltip: _viewMode == _ViewMode.list
                  ? 'Haritada Goster'
                  : 'Listede Goster',
            ),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _fetchPrices);
    }
    if (_prices.isEmpty) {
      return _EmptyView(city: widget.city, fuelType: widget.fuelType);
    }
    return IndexedStack(
      index: _viewMode == _ViewMode.list ? 0 : 1,
      children: [
        Column(
          children: [
            _SortBar(
              current: _sortMode,
              onChanged: (mode) => setState(() => _sortMode = mode),
              count: _prices.length,
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: _sortedPrices.length,
                itemBuilder: (context, index) {
                  final p = _sortedPrices[index];
                  return _StationCard(
                    price: p,
                    rank: _sortMode == _SortMode.cheapest ? index + 1 : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StationDetailScreen(
                          stationName: p.station,
                          city: widget.city,
                          district: p.district,
                          highlightFuelType: p.fuelType,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        StationMap(prices: _prices, city: widget.city),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _SortBar extends StatelessWidget {
  final _SortMode current;
  final ValueChanged<_SortMode> onChanged;
  final int count;

  const _SortBar({
    required this.current,
    required this.onChanged,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$count istasyon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const Spacer(),
          SegmentedButton<_SortMode>(
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment<_SortMode>(
                value: _SortMode.cheapest,
                label: Text('En Ucuz'),
                icon: Icon(Icons.attach_money, size: 16),
              ),
              ButtonSegment<_SortMode>(
                value: _SortMode.byDistrict,
                label: Text('İlçeye Göre'),
                icon: Icon(Icons.location_city, size: 16),
              ),
            ],
            selected: {current},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final FuelPrice price;
  final int? rank;
  final VoidCallback? onTap;

  const _StationCard({required this.price, this.rank, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            if (rank != null) ...[
              _rankBadge(rank!, cs),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.station,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 13,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        price.district,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  if (price.date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      price.date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${price.price.toStringAsFixed(2)} ₺',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                Text(
                  price.fuelType,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _rankBadge(int rank, ColorScheme cs) {
    final Color color;
    final Color textColor;
    if (rank == 1) {
      color = const Color(0xFFFFD700);
      textColor = Colors.black87;
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0);
      textColor = Colors.black87;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32);
      textColor = Colors.black87;
    } else {
      color = cs.secondaryContainer;
      textColor = cs.onSecondaryContainer;
    }
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: textColor,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.error,
                  ),
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

class _EmptyView extends StatelessWidget {
  final String city;
  final String fuelType;

  const _EmptyView({required this.city, required this.fuelType});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Sonuc Bulunamadi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${city.toUpperCase()} için $fuelType fiyati bulunamadi.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
