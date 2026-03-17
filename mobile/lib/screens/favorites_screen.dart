import 'package:flutter/material.dart';

import '../models/favorite_station.dart';
import '../services/settings_service.dart';
import 'station_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
      ),
      body: ListenableBuilder(
        listenable: SettingsService.instance,
        builder: (context, _) {
          final favorites = SettingsService.instance.favorites;
          if (favorites.isEmpty) {
            return _EmptyFavoritesView();
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return _FavoriteCard(
                fav: fav,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StationDetailScreen(
                      stationName: fav.station,
                      city: fav.city,
                      district: fav.district,
                      highlightFuelType: '',
                    ),
                  ),
                ),
                onDelete: () =>
                    SettingsService.instance.removeFavorite(fav),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alt widgetlar
// ---------------------------------------------------------------------------

class _FavoriteCard extends StatelessWidget {
  final FavoriteStation fav;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FavoriteCard({
    required this.fav,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(fav.toKey()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 1,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: cs.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fav.station,
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
                            '${fav.district}, ${fav.city.toUpperCase()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
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
              Icons.favorite_border,
              size: 64,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Favori yok',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'İstasyon detay ekranındaki kalp ikonuna\nbasarak favori ekleyebilirsiniz.',
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
