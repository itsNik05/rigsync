import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/worker.dart';
import '../cubits/worker_cubit.dart';

class WorkersBar extends StatelessWidget {
  const WorkersBar({
    super.key,
    required this.onWorkerSelected,
    required this.onAddWorker,
  });

  final ValueChanged<String> onWorkerSelected;
  final VoidCallback onAddWorker;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerCubit, WorkerState>(
      builder: (context, state) {
        if (state.status == WorkerStatus.loading) {
          return const SizedBox(height: 72);
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              // Worker chips
              ...state.workers.map((w) => _WorkerChip(
                worker: w,
                isSelected: w.id == state.selectedWorkerId,
                onTap: () => onWorkerSelected(w.id),
                onDelete: state.workers.length > 1
                    ? () => _confirmDelete(context, w)
                    : null,
              )),

              // Add worker button
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _AddWorkerBtn(onTap: onAddWorker),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Worker worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${worker.name}?'),
        content: const Text(
            'This will delete all their hitch data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<WorkerCubit>().deleteWorker(worker.id);
    }
  }
}

// ── Worker chip ───────────────────────────────────────────────────────────────

class _WorkerChip extends StatelessWidget {
  const _WorkerChip({
    required this.worker,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  final Worker worker;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  String get _initials {
    final parts = worker.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?';
  }

  Color get _color => Color(
      int.parse('FF${worker.colorHex.replaceAll('#', '')}', radix: 16));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? _color.withOpacity(0.15)
                : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: isSelected ? _color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: _color,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Name + role
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    worker.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? _color
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (worker.role != null)
                    Text(
                      worker.role!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              // Selected indicator dot
              if (isSelected) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add worker button ─────────────────────────────────────────────────────────

class _AddWorkerBtn extends StatelessWidget {
  const _AddWorkerBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: theme.colorScheme.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              'Add worker',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}