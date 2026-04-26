import 'package:flutter/material.dart';
import '../../domain/entities/hitch.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/hitch_date_utils.dart';

// ── HitchDayMarker ────────────────────────────────────────────────────────────

class HitchDayMarker extends StatelessWidget {
  const HitchDayMarker({super.key, required this.hitches});
  final List<Hitch> hitches;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // replaced by _HitchDayCell in calendar
  }
}

// ── HitchDetailSheet ──────────────────────────────────────────────────────────

class HitchDetailSheet extends StatelessWidget {
  const HitchDetailSheet({
    super.key,
    required this.day,
    required this.hitches,
    this.onDelete,
  });

  final DateTime day;
  final List<Hitch> hitches;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _formatDate(day),
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (hitches.isEmpty)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'No hitch scheduled for this day',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: hitches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) => _HitchTile(
                  hitch: hitches[i],
                  onDelete: onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _HitchTile extends StatelessWidget {
  const _HitchTile({required this.hitch, this.onDelete});
  final Hitch hitch;
  final ValueChanged<String>? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hitch.colorHex != null
        ? Color(
        int.parse('FF${hitch.colorHex!.replaceAll('#', '')}', radix: 16))
        : switch (hitch.type) {
      HitchType.on => AppTheme.hitchOn,
      HitchType.off => AppTheme.hitchOff,
      HitchType.transit => AppTheme.hitchTransit,
    };

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withOpacity(0.2),
        child: Icon(_iconFor(hitch.type), size: 14, color: color),
      ),
      title: Text(
        hitch.rigName ?? _labelFor(hitch.type),
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${_fmt(hitch.startDate)} – ${_fmt(hitch.endDate)} · ${hitch.durationDays} days',
        style: theme.textTheme.bodySmall,
      ),
      trailing: onDelete != null
          ? IconButton(
        icon: Icon(Icons.delete_outline,
            size: 18, color: theme.colorScheme.error),
        onPressed: () => _confirmDelete(context),
      )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete hitch?'),
        content: const Text(
            'This will remove this hitch period from the calendar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete?.call(hitch.id);
  }

  IconData _iconFor(HitchType t) => switch (t) {
    HitchType.on => Icons.work_outline,
    HitchType.off => Icons.home_outlined,
    HitchType.transit => Icons.directions_car_outlined,
  };

  String _labelFor(HitchType t) => switch (t) {
    HitchType.on => 'On hitch',
    HitchType.off => 'Off hitch',
    HitchType.transit => 'In transit',
  };

  String _fmt(DateTime d) => '${d.month}/${d.day}';
}

// ── CountdownCard ─────────────────────────────────────────────────────────────

class CountdownCard extends StatelessWidget {
  const CountdownCard({super.key, required this.hitches});
  final List<Hitch> hitches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();

    // Find the period today falls in
    Hitch? current;
    for (final h in hitches) {
      final start =
      DateTime(h.startDate.year, h.startDate.month, h.startDate.day);
      final end = DateTime(h.endDate.year, h.endDate.month, h.endDate.day);
      final now = DateTime(today.year, today.month, today.day);
      if (!now.isBefore(start) && !now.isAfter(end)) {
        current = h;
        break;
      }
    }

    if (current == null) {
      // No hitch today — find next upcoming ON hitch
      Hitch? next;
      for (final h in hitches) {
        if (h.type == HitchType.on &&
            h.startDate.isAfter(today)) {
          next = h;
          break;
        }
      }

      if (next == null) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text('Tap + to add your hitch schedule',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      }

      final daysUntil =
          next.startDate.difference(today).inDays;
      return _card(
        theme: theme,
        isOnShift: false,
        icon: Icons.schedule_outlined,
        status: 'Currently home',
        detail: 'Next hitch in $daysUntil days',
        color: AppTheme.hitchOff,
      );
    }

    final daysLeft =
        DateTime(current.endDate.year, current.endDate.month,
            current.endDate.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays +
            1;

    final isOn = current.type == HitchType.on;
    return _card(
      theme: theme,
      isOnShift: isOn,
      icon: isOn ? Icons.work_outline : Icons.home_outlined,
      status: isOn ? 'Currently on hitch' : 'Currently home',
      detail:
      '$daysLeft day${daysLeft == 1 ? '' : 's'} until ${isOn ? 'home' : 'departure'}',
      color: isOn ? AppTheme.hitchOn : AppTheme.hitchOff,
      subtitle: current.rigName,
    );
  }

  Widget _card({
    required ThemeData theme,
    required bool isOnShift,
    required IconData icon,
    required String status,
    required String detail,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                Text(detail,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                if (subtitle != null)
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}