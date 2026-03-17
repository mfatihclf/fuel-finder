import 'package:flutter/material.dart';

/// Adim 6'da tam olarak doldurulacak ekran.
/// Su an arama parametrelerini gosterir.
class ResultsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(city.toUpperCase()),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              fuelType,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$radiusKm km yaricap • ${city.toUpperCase()}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Sonuc listesi Adim 6\'da gelecek'),
          ],
        ),
      ),
    );
  }
}
