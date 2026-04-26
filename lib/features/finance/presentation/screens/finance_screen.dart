import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/cubits/worker_cubit.dart';
import '../../domain/entities/pay_period.dart';
import '../../domain/usecases/finance_usecases.dart';
import '../cubits/finance_cubit.dart';

import '../../data/datasources/finance_repository_impl.dart';
import '../../domain/usecases/finance_usecases.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _FinanceView();
  }
}

class _FinanceView extends StatefulWidget {
  const _FinanceView();

  @override
  State<_FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<_FinanceView> {
  @override
  void initState() {
    super.initState();
    // Load periods for currently selected worker on first open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workerId =
          context.read<WorkerCubit>().state.selectedWorkerId;
      if (workerId != null) {
        context.read<FinanceCubit>().loadPeriods(workerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkerCubit, WorkerState>(
      listenWhen: (prev, curr) =>
      prev.selectedWorkerId != curr.selectedWorkerId ||
          (curr.selectedWorkerId != null &&
              prev.status == WorkerStatus.loading &&
              curr.status == WorkerStatus.loaded),
      listener: (context, state) {
        if (state.selectedWorkerId != null) {
          context.read<FinanceCubit>().loadPeriods(state.selectedWorkerId!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          actions: [
            BlocBuilder<WorkerCubit, WorkerState>(
              builder: (context, ws) => IconButton(
                icon: const Icon(Icons.add),
                onPressed: ws.selectedWorker == null
                    ? null
                    : () => _showAddPeriodSheet(context),
                tooltip: 'Add pay period',
              ),
            ),
          ],
        ),
        body: BlocBuilder<FinanceCubit, FinanceState>(
          builder: (context, state) {
            if (state.status == FinanceStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _WorkerSelector()),
                SliverToBoxAdapter(
                  child: _YearSelector(
                    year: state.currentYear,
                    onPrev: () => context
                        .read<FinanceCubit>()
                        .changeYear(state.currentYear - 1),
                    onNext: () => context
                        .read<FinanceCubit>()
                        .changeYear(state.currentYear + 1),
                  ),
                ),
                SliverToBoxAdapter(child: _SummaryCards(state: state)),
                SliverToBoxAdapter(child: _EarningsChart(state: state)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: state.periodsForYear.isEmpty
                      ? SliverToBoxAdapter(
                    child: _EmptyState(
                      onAdd: () => _showAddPeriodSheet(context),
                    ),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, i) {
                        final sorted = [...state.periodsForYear]
                          ..sort((a, b) =>
                              b.periodStart.compareTo(a.periodStart));
                        return _PayPeriodTile(
                          period: sorted[i],
                          onMarkPaid: () =>
                              _showMarkPaidDialog(context, sorted[i]),
                          onDelete: () => context
                              .read<FinanceCubit>()
                              .deletePayPeriod(sorted[i].id),
                        );
                      },
                      childCount: state.periodsForYear.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddPeriodSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FinanceCubit>(),
        child: const _AddPayPeriodSheet(),
      ),
    );
  }

  void _showMarkPaidDialog(BuildContext context, PayPeriod period) {
    final controller = TextEditingController(
      text: period.calculatedExpected.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expected: \$${period.calculatedExpected.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual amount received',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ??
                  period.calculatedExpected;
              context.read<FinanceCubit>().markAsPaid(period.id, amount);
              Navigator.pop(ctx);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ── Worker selector ───────────────────────────────────────────────────────────

class _WorkerSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerCubit, WorkerState>(
      builder: (context, state) {
        if (state.workers.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: state.workers.map((w) {
              final isSelected = w.id == state.selectedWorkerId;
              final color = Color(int.parse(
                  'FF${w.colorHex.replaceAll('#', '')}',
                  radix: 16));
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(w.name),
                  selected: isSelected,
                  selectedColor: color.withOpacity(0.2),
                  onSelected: (_) =>
                      context.read<WorkerCubit>().selectWorker(w.id),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ── Year selector ─────────────────────────────────────────────────────────────

class _YearSelector extends StatelessWidget {
  const _YearSelector(
      {required this.year, required this.onPrev, required this.onNext});
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Earnings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrev,
              visualDensity: VisualDensity.compact),
          Text('$year',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
              visualDensity: VisualDensity.compact),
        ],
      ),
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});
  final FinanceState state;

  String _fmt(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Unpaid',
                  value: '\$${_fmt(state.totalExpectedYear)}',
                  color: theme.colorScheme.primary,
                  icon: Icons.schedule_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Received',
                  value: '\$${_fmt(state.totalActualYear)}',
                  color: AppTheme.hitchOn,
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Total earned',
                  value: '\$${_fmt(state.totalEarnedYear)}',
                  color: AppTheme.hitchTransit,
                  icon: Icons.trending_up_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Hitches paid',
                  value:
                  '${state.paidPeriodsCount} / ${state.periodsForYear.length}',
                  color: theme.colorScheme.secondary,
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style:
                  theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              )),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _EarningsChart extends StatelessWidget {
  const _EarningsChart({required this.state});
  final FinanceState state;
  static const _months = [
    'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expected = state.monthlyExpected;
    final actual = state.monthlyActual;
    final maxVal =
    [...expected, ...actual, 1.0].reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly breakdown',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(12, (i) {
                  final expH = expected[i] / maxVal * 100;
                  final actH = actual[i] / maxVal * 100;
                  final isCurrent = i + 1 == DateTime.now().month &&
                      state.currentYear == DateTime.now().year;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Container(
                                      height: expH,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.2),
                                        borderRadius:
                                        BorderRadius.circular(3),
                                      ),
                                    ),
                                    Container(
                                      height: actH,
                                      decoration: BoxDecoration(
                                        color: AppTheme.hitchOn
                                            .withOpacity(
                                            isCurrent ? 1.0 : 0.7),
                                        borderRadius:
                                        BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _months[i],
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendDot(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    label: 'Expected'),
                const SizedBox(width: 16),
                _LegendDot(color: AppTheme.hitchOn, label: 'Received'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
            BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

// ── Pay period tile ───────────────────────────────────────────────────────────

class _PayPeriodTile extends StatelessWidget {
  const _PayPeriodTile({
    required this.period,
    required this.onMarkPaid,
    required this.onDelete,
  });
  final PayPeriod period;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmt(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
    period.isPaid ? AppTheme.hitchOn : AppTheme.hitchTransit;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    period.isPaid ? 'Paid' : 'Pending',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${period.isPaid ? (period.totalActual ?? 0).toStringAsFixed(0) : period.calculatedExpected.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_fmt(period.periodStart)} – ${_fmt(period.periodEnd)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${period.durationDays} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                if (period.dailyRate != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.attach_money,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant),
                  Text('\$${period.dailyRate!.toStringAsFixed(0)}/day',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ],
            ),
            if (!period.isPaid) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMarkPaid,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark paid'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppTheme.hitchOn,
                        side: BorderSide(
                            color: AppTheme.hitchOn.withOpacity(0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('No pay periods yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Add your first hitch pay period to start tracking',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add pay period'),
          ),
        ],
      ),
    );
  }
}

// ── Add pay period sheet ──────────────────────────────────────────────────────

class _AddPayPeriodSheet extends StatefulWidget {
  const _AddPayPeriodSheet();

  @override
  State<_AddPayPeriodSheet> createState() => _AddPayPeriodSheetState();
}

class _AddPayPeriodSheetState extends State<_AddPayPeriodSheet> {
  DateTime _start = DateTime.now().subtract(const Duration(days: 14));
  DateTime _end = DateTime.now();
  final _rateController = TextEditingController(text: '250');
  bool _isLoading = false;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          if (_end.isBefore(_start)) _end = _start;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final rate = double.tryParse(_rateController.text);
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid daily rate')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await context.read<FinanceCubit>().addPayPeriod(
      start: _start,
      end: _end,
      dailyRate: rate,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _end.difference(_start).inDays + 1;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final expected = rate * days;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text('Add pay period',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start date',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                            '${_months[_start.month - 1]} ${_start.day}, ${_start.year}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border:
                      Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End date',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color:
                                theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                            '${_months[_end.month - 1]} ${_end.day}, ${_end.year}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Daily rate',
              prefixText: '\$ ',
              suffixText: '/ day',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '$days days × \$${rate.toStringAsFixed(0)}/day',
                    style: theme.textTheme.bodySmall),
                Text('\$${expected.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: const Text('Save pay period'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}