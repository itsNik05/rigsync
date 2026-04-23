import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/worker_cubit.dart';

class AddWorkerSheet extends StatefulWidget {
  const AddWorkerSheet({super.key});

  @override
  State<AddWorkerSheet> createState() => _AddWorkerSheetState();
}

class _AddWorkerSheetState extends State<AddWorkerSheet> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  String _selectedColor = '#1565C0';
  bool _isLoading = false;

  static const _colors = [
    ('#1565C0', 'Blue'),
    ('#2E7D32', 'Green'),
    ('#AD1457', 'Pink'),
    ('#6A1B9A', 'Purple'),
    ('#E65100', 'Orange'),
    ('#00695C', 'Teal'),
    ('#C62828', 'Red'),
    ('#F57F17', 'Amber'),
  ];

  static const _rolePresets = [
    'Driller',
    'Roughneck',
    'Tool Pusher',
    'Company Man',
    'Mud Engineer',
    'Derrickman',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await context.read<WorkerCubit>().addWorker(
      name: name,
      colorHex: _selectedColor,
      role: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Add worker',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Track schedules for yourself or a family member',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // ── Preview avatar ────────────────────────────────────────────
            Center(
              child: _AvatarPreview(
                name: _nameController.text,
                colorHex: _selectedColor,
              ),
            ),
            const SizedBox(height: 24),

            // ── Name ──────────────────────────────────────────────────────
            Text('Full name',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. John Smith',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // ── Role ──────────────────────────────────────────────────────
            Text('Job role (optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: _roleController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Driller',
                prefixIcon: const Icon(Icons.work_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Role quick-pick chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _rolePresets
                  .map((r) => ActionChip(
                label: Text(r),
                onPressed: () {
                  _roleController.text = r;
                  setState(() {});
                },
                visualDensity: VisualDensity.compact,
              ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // ── Color ─────────────────────────────────────────────────────
            Text('Calendar color',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colors.map((c) {
                final hex = c.$1;
                final isSelected = _selectedColor == hex;
                final color = Color(
                    int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                        color: theme.colorScheme.onSurface,
                        width: 3,
                      )
                          : Border.all(
                        color: Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.person_add_alt_1),
              label:
              Text(_isLoading ? 'Saving...' : 'Add worker'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar preview ────────────────────────────────────────────────────────────

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.name, required this.colorHex});
  final String name;
  final String colorHex;

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final color =
    Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: color,
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name.isEmpty ? 'Preview' : name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}