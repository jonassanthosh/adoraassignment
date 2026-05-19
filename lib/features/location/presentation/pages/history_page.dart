import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../storage/location_database.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<_Fix>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_Fix>> _load() async {
    final rows = await getIt<LocationDatabase>().recent(limit: 200);
    return rows.map(_Fix.fromRow).toList();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Recent fixes')),
      body: SafeArea(
        child: FutureBuilder<List<_Fix>>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final fixes = snapshot.data!;
            if (fixes.isEmpty) {
              return _Empty(theme: theme);
            }
            final grouped = _groupByDay(fixes);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: grouped.length,
                itemBuilder: (context, i) {
                  final section = grouped[i];
                  return _DaySection(section: section);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No fixes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start tracking on the home screen — fixes will land here as they arrive.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.section});
  final _DayGroup section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Text(
                section.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${section.fixes.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var i = 0; i < section.fixes.length; i++) ...[
                _FixTile(fix: section.fixes[i]),
                if (i != section.fixes.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: 64,
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FixTile extends StatelessWidget {
  const _FixTile({required this.fix});
  final _Fix fix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SourceAvatar(source: fix.source),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fix.lat.toStringAsFixed(5)}, ${fix.lon.toStringAsFixed(5)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatTime(fix.timestamp)} · ±${fix.accuracy.toStringAsFixed(0)} m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceAvatar extends StatelessWidget {
  const _SourceAvatar({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (source) {
      'background' => (Icons.layers_rounded, AppTheme.trackingGreen),
      'slc' => (Icons.travel_explore_rounded, AppTheme.idleAmber),
      _ => (Icons.my_location_rounded, Theme.of(context).colorScheme.primary),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _Fix {
  _Fix({
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.timestamp,
    required this.source,
  });

  final double lat;
  final double lon;
  final double accuracy;
  final DateTime timestamp;
  final String source;

  static _Fix fromRow(Map<String, Object?> r) => _Fix(
        lat: (r['lat']! as num).toDouble(),
        lon: (r['lon']! as num).toDouble(),
        accuracy: (r['accuracy']! as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(r['ts']! as int),
        source: (r['source'] as String?) ?? 'unknown',
      );
}

class _DayGroup {
  _DayGroup({required this.label, required this.fixes});
  final String label;
  final List<_Fix> fixes;
}

List<_DayGroup> _groupByDay(List<_Fix> fixes) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final groups = <String, List<_Fix>>{};
  final order = <String>[];

  for (final f in fixes) {
    final local = f.timestamp.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    String label;
    if (day == today) {
      label = 'Today';
    } else if (day == yesterday) {
      label = 'Yesterday';
    } else {
      label = _formatDate(day);
    }
    if (!groups.containsKey(label)) {
      groups[label] = [];
      order.add(label);
    }
    groups[label]!.add(f);
  }

  return [for (final l in order) _DayGroup(label: l, fixes: groups[l]!)];
}

String _formatTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}';
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
