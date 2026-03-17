import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/fuel_types.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: ListenableBuilder(
        listenable: SettingsService.instance,
        builder: (context, _) => _SettingsBody(),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final svc = SettingsService.instance;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Tema ──────────────────────────────────────────────────────────
        _SectionHeader('Tema'),
        const SizedBox(height: 10),
        _ThemeSegment(current: svc.themeMode),
        const SizedBox(height: 28),

        // ── Varsayilan yakit turu ─────────────────────────────────────────
        _SectionHeader('Varsayilan Yakit Turu'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FuelTypes.all
              .map(
                (ft) => ChoiceChip(
                  label: Text(ft),
                  selected: ft == svc.defaultFuelType,
                  onSelected: (_) => svc.setDefaultFuelType(ft),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),

        // ── Varsayilan yaricap ────────────────────────────────────────────
        _SectionHeader('Varsayilan Arama Yaricapi'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: FuelTypes.radiusOptions
              .map(
                (r) => ChoiceChip(
                  label: Text('$r km'),
                  selected: r == svc.defaultRadius,
                  onSelected: (_) => svc.setDefaultRadius(r),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 28),

        // ── Favoriler bilgi satiri ────────────────────────────────────────
        Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.favorite, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${svc.favorites.length} favori istasyon kaydedildi.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _VersionCard(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  final ThemeMode current;
  const _ThemeSegment({required this.current});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('Sistem'),
          icon: Icon(Icons.brightness_auto, size: 16),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Açık'),
          icon: Icon(Icons.light_mode, size: 16),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Koyu'),
          icon: Icon(Icons.dark_mode, size: 16),
        ),
      ],
      selected: {current},
      onSelectionChanged: (sel) =>
          SettingsService.instance.setThemeMode(sel.first),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final label = snapshot.hasData
            ? 'Fuel Finder v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : 'Fuel Finder';
        return Card(
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: cs.onSurface.withValues(alpha: 0.5),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }
}
