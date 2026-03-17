import 'package:flutter/material.dart';

import '../constants/fuel_types.dart';
import '../services/location_service.dart';
import '../services/settings_service.dart';
import 'favorites_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _locationService = LocationService();
  final _cityController = TextEditingController(text: 'istanbul');

  String _selectedFuelType = FuelTypes.all.first;
  int _selectedRadius = 10;
  bool _isLocating = false;
  LocationStatus _permissionStatus = LocationStatus.denied;
  LocationResult? _locationResult;

  @override
  void initState() {
    super.initState();
    _selectedFuelType = SettingsService.instance.defaultFuelType;
    _selectedRadius = SettingsService.instance.defaultRadius;
    _fetchLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLocating = true);
    try {
      final status = await _locationService.checkAndRequestPermission();
      if (!mounted) return;
      setState(() => _permissionStatus = status);

      if (status == LocationStatus.granted) {
        final result = await _locationService.getCurrentLocation();
        if (!mounted) return;
        setState(() {
          _locationResult = result;
          if (result.cityKey != null) _cityController.text = result.cityKey!;
        });
      }
    } catch (_) {
      // GPS erisim hatasi — manuel giris aktif kalir
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _search() {
    final city = (_locationResult?.cityKey ?? _cityController.text).trim();
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lutfen bir sehir girin veya konumunuzu etkinlestirin'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          city: city,
          fuelType: _selectedFuelType,
          radiusKm: _selectedRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station, size: 22),
            SizedBox(width: 8),
            Text('Fuel Finder'),
          ],
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoriler',
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LocationCard(
              isLocating: _isLocating,
              permissionStatus: _permissionStatus,
              locationResult: _locationResult,
              cityController: _cityController,
              onRefresh: _fetchLocation,
              onCityChanged: () => setState(() => _locationResult = null),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Yakit Turu'),
            const SizedBox(height: 10),
            _FuelTypeChips(
              fuelTypes: FuelTypes.all,
              selected: _selectedFuelType,
              onSelected: (ft) => setState(() => _selectedFuelType = ft),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Arama Yaricapi'),
            const SizedBox(height: 10),
            _RadiusChips(
              options: FuelTypes.radiusOptions,
              selected: _selectedRadius,
              onSelected: (r) => setState(() => _selectedRadius = r),
            ),
            const SizedBox(height: 36),
            _SearchButton(onPressed: _search),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _LocationCard extends StatelessWidget {
  final bool isLocating;
  final LocationStatus permissionStatus;
  final LocationResult? locationResult;
  final TextEditingController cityController;
  final VoidCallback onRefresh;
  final VoidCallback onCityChanged;

  const _LocationCard({
    required this.isLocating,
    required this.permissionStatus,
    required this.locationResult,
    required this.cityController,
    required this.onRefresh,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Widget content;

    if (isLocating) {
      content = const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Konum aliniyor...'),
        ],
      );
    } else if (permissionStatus == LocationStatus.granted &&
        locationResult != null) {
      final cityKey = locationResult!.cityKey ?? 'bilinmiyor';
      content = Row(
        children: [
          Icon(Icons.location_on, color: cs.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cityKey.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Konumu yenile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
    } else {
      final isServiceOff = permissionStatus == LocationStatus.serviceDisabled;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isServiceOff ? Icons.location_off : Icons.location_disabled,
                size: 18,
                color: cs.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isServiceOff
                      ? 'GPS kapali — sehir secin'
                      : 'Konum izni yok — sehir girin',
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: onRefresh,
                child: const Text('Izin Ver'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: cityController,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Sehir (orn: istanbul)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.location_city, size: 20),
            ),
            onChanged: (_) => onCityChanged(),
          ),
        ],
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(14), child: content),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
    );
  }
}

class _FuelTypeChips extends StatelessWidget {
  final List<String> fuelTypes;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FuelTypeChips({
    required this.fuelTypes,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fuelTypes
          .map(
            (ft) => ChoiceChip(
              label: Text(ft),
              selected: ft == selected,
              onSelected: (_) => onSelected(ft),
            ),
          )
          .toList(),
    );
  }
}

class _RadiusChips extends StatelessWidget {
  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelected;

  const _RadiusChips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options
          .map(
            (r) => ChoiceChip(
              label: Text('$r km'),
              selected: r == selected,
              onSelected: (_) => onSelected(r),
            ),
          )
          .toList(),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SearchButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.search),
        label: const Text(
          'Akaryakit Ara',
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
