import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hitch.dart';
import '../cubits/calendar_cubit.dart';
import '../cubits/worker_cubit.dart';
import '../widgets/add_hitch_sheet.dart';
import '../widgets/add_worker_sheet.dart';
import '../widgets/workers_bar.dart';
import '../widgets/hitch_detail_sheet.dart';
import '../widgets/countdown_card.dart';
import '../../../../features/settings/presentation/cubits/purchase_cubit.dart';
import '../../../../features/settings/presentation/screens/paywall_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CalendarView();
  }
}

// ── Convert to StatefulWidget to track calendar format ────────────────────────

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  void _openAddWorker(BuildContext context) {
    final isPro = context.read<PurchaseCubit>().state.isPro;
    final workerCount = context.read<WorkerCubit>().state.workers.length;

    if (!isPro && workerCount >= 1) {
      PaywallScreen.show(context, featureName: 'Multiple workers');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<WorkerCubit>(),
        child: const AddWorkerSheet(),
      ),
    );
  }

  void _openAddHitch(BuildContext context, String? workerId) {
    // Resolve worker ID from state if not passed
    final resolvedId =
        workerId ?? context.read<WorkerCubit>().state.selectedWorker?.id;

    if (resolvedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a worker first before scheduling a hitch'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CalendarCubit>(),
        child: AddHitchSheet(workerId: resolvedId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RigSync'),
        actions: [
          BlocBuilder<WorkerCubit, WorkerState>(
            builder: (context, workerState) => IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _openAddHitch(
                context,
                workerState.selectedWorker?.id,
              ),
              tooltip: 'Add hitch',
            ),
          ),
        ],
      ),
      body: BlocListener<WorkerCubit, WorkerState>(
        listenWhen: (prev, curr) =>
        prev.selectedWorkerId != curr.selectedWorkerId,
        listener: (context, state) {
          if (state.selectedWorkerId != null) {
            context
                .read<CalendarCubit>()
                .loadHitches(state.selectedWorkerId!);
          }
        },
        child: Column(
          children: [
            // ── Workers bar ───────────────────────────────────────────────
            WorkersBar(
              onWorkerSelected: (id) {
                context.read<WorkerCubit>().selectWorker(id);
              },
              onAddWorker: () => _openAddWorker(context),
            ),

            // ── Calendar body ─────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<CalendarCubit, CalendarState>(
                builder: (context, state) {
                  if (state.status == CalendarStatus.loading &&
                      state.hitches.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  return Column(
                    children: [
                      // Countdown card
                      CountdownCard(
                        hitches: state.hitches,
                        onAddHitch: () => _openAddHitch(
                          context,
                          context.read<WorkerCubit>().state.selectedWorker?.id,
                        ),
                      ),

                      // Error banner
                      if (state.errorMessage != null)
                        MaterialBanner(
                          content: Text(state.errorMessage!),
                          actions: [
                            TextButton(
                              onPressed: () {
                                final id = context
                                    .read<WorkerCubit>()
                                    .state
                                    .selectedWorkerId;
                                if (id != null) {
                                  context
                                      .read<CalendarCubit>()
                                      .loadHitches(id);
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),

                      // Calendar
                      Expanded(
                        child: TableCalendar<Hitch>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay:
                          state.focusedDay ?? DateTime.now(),
                          selectedDayPredicate: (day) =>
                              isSameDay(day, state.selectedDay),
                          eventLoader: (day) =>
                              state.hitchesForDay(day),

                          // ── Fix 1: wire format to state ───────────────
                          calendarFormat: _calendarFormat,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          onFormatChanged: (format) {
                            setState(() => _calendarFormat = format);
                          },

                          onDaySelected: (selected, focused) =>
                              context
                                  .read<CalendarCubit>()
                                  .onDaySelected(selected, focused),
                          onPageChanged: (focused) => context
                              .read<CalendarCubit>()
                              .onPageChanged(focused),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, _) {
                              final hitches =
                              state.hitchesForDay(day);
                              if (hitches.isEmpty) return null;
                              return _HitchDayCell(
                                day: day,
                                hitch: hitches.first,
                                isSelected: false,
                                isToday:
                                isSameDay(day, DateTime.now()),
                              );
                            },
                            selectedBuilder: (context, day, _) {
                              final hitches =
                              state.hitchesForDay(day);
                              return _HitchDayCell(
                                day: day,
                                hitch: hitches.isEmpty
                                    ? null
                                    : hitches.first,
                                isSelected: true,
                                isToday:
                                isSameDay(day, DateTime.now()),
                              );
                            },
                            todayBuilder: (context, day, _) {
                              final hitches =
                              state.hitchesForDay(day);
                              return _HitchDayCell(
                                day: day,
                                hitch: hitches.isEmpty
                                    ? null
                                    : hitches.first,
                                isSelected: false,
                                isToday: true,
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          calendarStyle: const CalendarStyle(
                            outsideDaysVisible: false,
                            markerSize: 0,
                          ),
                        ),
                      ),

                      // Selected day detail panel
                      if (state.selectedDay != null)
                        HitchDetailSheet(
                          day: state.selectedDay!,
                          hitches: state
                              .hitchesForDay(state.selectedDay!),
                          onDelete: (hitchId) => context
                              .read<CalendarCubit>()
                              .deleteHitch(hitchId),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Colored day cell ──────────────────────────────────────────────────────────

class _HitchDayCell extends StatelessWidget {
  const _HitchDayCell({
    required this.day,
    required this.hitch,
    required this.isSelected,
    required this.isToday,
  });

  final DateTime day;
  final Hitch? hitch;
  final bool isSelected;
  final bool isToday;

  Color _hitchColor() {
    if (hitch == null) return Colors.transparent;

    // ── Fix 3: use colorHex when available ──────────────────────────────
    if (hitch!.colorHex != null && hitch!.colorHex!.isNotEmpty) {
      final baseColor = Color(
        int.parse(
            'FF${hitch!.colorHex!.replaceAll('#', '')}',
            radix: 16),
      );
      // Use same color for both on/off but different opacity
      return baseColor.withOpacity(hitch!.isOnShift ? 0.45 : 0.20);
    }

    // Fallback to default green/red only if no color set
    return switch (hitch!.type) {
      HitchType.on => AppTheme.hitchOn.withOpacity(0.35),
      HitchType.off => AppTheme.hitchOff.withOpacity(0.18),
      HitchType.transit => AppTheme.hitchTransit.withOpacity(0.25),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _hitchColor();

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : isToday
            ? Border.all(
          color:
          theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        )
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isToday || isSelected
                ? FontWeight.w700
                : FontWeight.w400,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}