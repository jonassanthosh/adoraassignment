import 'package:flutter/material.dart';

import '../bloc/location_state.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({super.key, required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (state) {
          LocationIdle() => _row(
              icon: Icons.location_searching,
              title: 'No location yet',
              subtitle: 'Tap Start to begin tracking.',
              theme: theme,
            ),
          LocationLoading() => Row(
              children: const [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Locating…'),
              ],
            ),
          LocationTracking(:final last) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current location', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(
                  '${last.latitude.toStringAsFixed(5)}, '
                  '${last.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Accuracy: ±${last.accuracy.toStringAsFixed(1)} m'
                  '${last.source != null ? '  •  ${last.source}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Updated: ${_formatTime(last.timestamp)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          LocationFailure(:final message) => _row(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              subtitle: message,
              theme: theme,
              color: theme.colorScheme.error,
            ),
        },
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    Color? color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }
}
