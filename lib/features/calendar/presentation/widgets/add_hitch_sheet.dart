import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/hitch.dart';
import '../cubits/calendar_cubit.dart';
import '../../../../core/utils/hitch_date_utils.dart';

import '../../domain/usecases/calendar_usecases.dart';

class AddHitchSheet extends StatefulWidget {
  const AddHitchSheet({super.key, required this.workerId});

  final String workerId;

  @override
  State<AddHitchSheet> createState() => _AddHitchSheetState();
}

class _AddHitchSheetState extends State<AddHitchSheet> {
  // Selected pattern
  HitchTemplate _selectedPattern = HitchDateUtils.commonPatterns[1]; // 14/14 default
  bool _useCustom = false;
  int _customDaysOn = 14;
  int _customDaysOff = 14;

  // Start date
  DateTime _startDate = DateTime.now();

  // Rig name
  final _rigController = TextEditingController();

  // How many months to generate
  int _months = 12;

  // Color picker
  String _selectedColor = '#2E7D32'; // green default

  static const _colors = [
    ('#2E7D32', 'Green'),
    ('#1565C0', 'Blue'),
    ('#E65100', 'Orange'),
    ('#6A1B9A', 'Purple'),
    ('#AD1457', 'Pink'),
    ('#00695C', 'Teal'),
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _rigController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Select first day ON hitch',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);

    final daysOn = _useCustom ? _customDaysOn : _selectedPattern.daysOn;
    final daysOff = _useCustom ? _customDaysOff : _selectedPattern.daysOff;

    await context.read<CalendarCubit>().generatePattern(
      GeneratePatternParams(
        workerId: widget.workerId,
        startDate: _startDate,
        daysOn: daysOn,
        daysOff: daysOff,
        months: _months,
        rigName: _rigController.text.trim().isEmpty
            ? null
            : _rigController.text.trim(),
      ),
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
            // Handle bar
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
              'Add hitch schedule',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // ── Pattern selection ─────────────────────────────────────────
            Text('Rotation pattern',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 10),

            // Preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...HitchDateUtils.commonPatterns.map((p) {
                  final selected =
                      !_useCustom && _selectedPattern.label == p.label;
                  return ChoiceChip(
                    label: Text(p.label),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedPattern = p;
                      _useCustom = false;
                    }),
                  );
                }),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _useCustom,
                  onSelected: (_) => setState(() => _useCustom = true),
                ),
              ],
            ),

            // Custom inputs
            if (_useCustom) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      label: 'Days ON',
                      value: _customDaysOn,
                      onChanged: (v) => setState(() => _customDaysOn = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _NumberField(
                      label: 'Days OFF',
                      value: _customDaysOff,
                      onChanged: (v) => setState(() => _customDaysOff = v),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // ── Start date ────────────────────────────────────────────────
            Text('First day ON hitch',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 10),

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_startDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Rig name ──────────────────────────────────────────────────
            Text('Rig / job name (optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 10),

            TextField(
              controller: _rigController,
              decoration: InputDecoration(
                hintText: 'e.g. Rig 47 — Permian Basin',
                prefixIcon: const Icon(Icons.oil_barrel_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),

            // ── Months to generate ────────────────────────────────────────
            Row(
              children: [
                Text('Generate for',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const Spacer(),
                Text('$_months months',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
            Slider(
              value: _months.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              label: '$_months mo',
              onChanged: (v) => setState(() => _months = v.round()),
            ),

            const SizedBox(height: 24),

            // ── Color picker ──────────────────────────────────────────────
            Text('Hitch color',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 10),

            Row(
              children: _colors.map((c) {
                final hex = c.$1;
                final isSelected = _selectedColor == hex;
                final color = Color(
                    int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                          color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Generate button ───────────────────────────────────────────
            FilledButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: _isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isLoading ? 'Generating...' : 'Generate schedule'),
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Helper widget: number stepper ─────────────────────────────────────────────

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        Row(
          children: [
            _StepBtn(
              icon: Icons.remove,
              onTap: value > 1 ? () => onChanged(value - 1) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Center(
                child: Text(
                  '$value',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StepBtn(
              icon: Icons.add,
              onTap: value < 90 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }
}