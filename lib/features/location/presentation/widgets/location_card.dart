import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/location_entities.dart';
import '../bloc/location_state.dart';

/// The hero card on the home screen. Top strip shows a status dot, label
/// and source badge; the body changes shape depending on the BLoC state.
class LocationCard extends StatelessWidget {
  const LocationCard({super.key, required this.state});

  final LocationState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusColor, statusLabel) = switch (state) {
      LocationIdle() => (AppTheme.idleAmber, 'Idle'),
      LocationLoading() => (scheme.primary, 'Locating'),
      LocationTracking() => (AppTheme.trackingGreen, 'Live'),
      LocationFailure() => (AppTheme.errorRed, 'Problem'),
    };

    final body = switch (state) {
      LocationIdle() => const _Idle(),
      LocationLoading() => const _Loading(),
      LocationTracking(:final last) => _Tracking(fix: last),
      LocationFailure(:final message) => _Failure(message: message),
    };

    final isTracking = state is LocationTracking;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isTracking
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.55),
                  scheme.surfaceContainerLow,
                ],
              )
            : null,
        color: isTracking ? null : scheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusStrip(
              color: statusColor,
              label: statusLabel,
              sourceBadge: state is LocationTracking
                  ? (state as LocationTracking).last.source
                  : null,
            ),
            const SizedBox(height: 18),
            body,
          ],
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.color,
    required this.label,
    this.sourceBadge,
  });

  final Color color;
  final String label;
  final String? sourceBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _PulsingDot(color: color),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (sourceBadge != null) _SourceChip(source: sourceBadge!),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.18 + 0.18 * t),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        source,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No fix yet',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Press Start tracking to capture your location and begin a session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Waiting on the first GPS fix…',
            style: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _Tracking extends StatelessWidget {
  const _Tracking({required this.fix});
  final LocationEntity fix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatCoord(fix.latitude),
          style: theme.textTheme.displaySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
          ),
        ),
        Text(
          _formatCoord(fix.longitude),
          style: theme.textTheme.displaySmall?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Stat(
              label: 'Accuracy',
              value: '±${fix.accuracy.toStringAsFixed(0)} m',
            ),
            _Stat(
              label: 'Updated',
              value: _formatTime(fix.timestamp),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking is blocked',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

String _formatCoord(double value) {
  final sign = value >= 0 ? '' : '-';
  return '$sign${value.abs().toStringAsFixed(5)}°';
}

String _formatTime(DateTime t) {
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
}
