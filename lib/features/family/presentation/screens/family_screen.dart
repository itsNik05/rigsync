import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/family_event.dart';
import '../cubits/family_cubit.dart';
import '../../domain/entities/household.dart';
import 'dart:async';
import '../../../calendar/presentation/cubits/calendar_cubit.dart';
import '../../../calendar/domain/entities/hitch.dart';
import '../../../../core/di/injection.dart';
import '../../../calendar/data/datasources/app_database.dart';
import '../../../calendar/presentation/cubits/worker_cubit.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FamilyCubit, FamilyState>(
      builder: (context, state) {
        if (state.status == FamilyStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!state.isSignedIn) return const _SignInView();
        if (!state.hasHousehold) return const _SetupView();
        return const _HouseholdView();
      },
    );
  }
}

// ── Sign in view ──────────────────────────────────────────────────────────────

class _SignInView extends StatelessWidget {
  const _SignInView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline,
                size: 72,
                color: theme.colorScheme.primary.withOpacity(0.7)),
            const SizedBox(height: 24),
            Text('Share your schedule',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(
              'Sign in to create a family household and share your hitch schedule with loved ones in real time.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () =>
                  context.read<FamilyCubit>().signInWithGoogle(),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.read<FamilyCubit>().signInAnonymously(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continue as guest'),
            ),
            const SizedBox(height: 12),
            Text('Guest accounts cannot share schedules',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Setup view (no household yet) ─────────────────────────────────────────────

class _SetupView extends StatefulWidget {
  const _SetupView();

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  bool _showJoin = false;
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<FamilyCubit>().state;

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.userName != null) ...[
              Text('Welcome, ${state.userName}!',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
            ],

            // Toggle tabs
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showJoin = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showJoin
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Create household',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: !_showJoin
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          )),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showJoin = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showJoin
                            ? theme.colorScheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Join household',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _showJoin
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          )),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (!_showJoin) ...[
              // Create household
              Text('Your name',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. John Smith',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A unique invite code will be generated that family members can use to join.',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) return;
                  context.read<FamilyCubit>().createHousehold(name);
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text('Create household'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ] else ...[
              // Join household
              Text('Invite code',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Enter 6-character code',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                        color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  final code = _codeController.text.trim();
                  if (code.length < 6) return;
                  context.read<FamilyCubit>().joinHousehold(code);
                },
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('Join household'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Household view (main family screen) ───────────────────────────────────────

class _HouseholdView extends StatelessWidget {
  const _HouseholdView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCubit>().state;
    final household = state.household!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventSheet(context),
            tooltip: 'Add family event',
          ),
          // Only owner sees sync button
          if (context.read<FamilyCubit>().state.isOwner)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync schedule to family',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing schedule...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                final workers = context.read<WorkerCubit>().state.workers;
                final db = getIt<AppDatabase>();
                final now = DateTime.now();
                final allHitchMaps = <Map<String, dynamic>>[];

                for (final worker in workers) {
                  final hitches = await db.getHitchesForWorker(
                    workerId: worker.id,
                    from: DateTime(now.year - 1),
                    to: DateTime(now.year + 3),
                  );
                  allHitchMaps.addAll(hitches.map((h) => {
                    'id': h.id,
                    'workerId': h.workerId,
                    'workerName': worker.name,
                    'workerColor': worker.colorHex,
                    'startDate': h.startDate.toIso8601String(),
                    'endDate': h.endDate.toIso8601String(),
                    'type': h.type,
                    'rigName': h.rigName,
                    'colorHex': h.colorHex ?? worker.colorHex,
                    'notes': h.notes,
                  }));
                }
                await context
                    .read<FamilyCubit>()
                    .syncExistingHitches(allHitchMaps);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Schedule synced to family'),
                      backgroundColor: Color(0xFF2E7D32),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'leave') {
                _confirmLeave(context);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 18),
                    SizedBox(width: 8),
                    Text('Leave household'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Invite code card ────────────────────────────────────────────
          _InviteCodeCard(
            code: household.inviteCode,
            memberCount: household.memberIds.length,
            ownerName: household.ownerName,
          ),
          const SizedBox(height: 16),

          // ── Status board ────────────────────────────────────────────────
          _StatusBoard(household: household),
          const SizedBox(height: 16),
          _SharedSchedule(householdId: household.id),
          const SizedBox(height: 16),

          // ── Upcoming family events ──────────────────────────────────────
          _FamilyEventsList(
            events: state.familyEvents,
            onDelete: state.isOwner || true
                ? (id) => context.read<FamilyCubit>().deleteFamilyEvent(id)
                : null,
          ),
        ],
      ),
    );
  }

  void _showAddEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<FamilyCubit>(),
        child: const _AddEventSheet(),
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave household?'),
        content: const Text(
            'You will no longer see shared schedules or family events.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<FamilyCubit>().leaveHousehold();
    }
  }
}

// ── Invite code card ──────────────────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.code,
    required this.memberCount,
    required this.ownerName,
  });
  final String code;
  final int memberCount;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_outlined,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('$ownerName\'s household',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$memberCount member${memberCount == 1 ? '' : 's'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Invite code',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Row(
            children: [
              // Code display
              ...code.split('').map((c) => Container(
                margin: const EdgeInsets.only(right: 6),
                width: 40,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: theme.colorScheme.outline),
                ),
                child: Center(
                  child: Text(c,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      )),
                ),
              )),
              const Spacer(),
              // Copy button
              IconButton.filled(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite code copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy code',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Share this code with family members. They enter it in the Family tab to join.',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Status board ──────────────────────────────────────────────────────────────

class _StatusBoard extends StatelessWidget {
  const _StatusBoard({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status board',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                theme.colorScheme.primary.withOpacity(0.15),
                child: Text(
                  household.ownerName.isNotEmpty
                      ? household.ownerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(household.ownerName,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    // Status pulled from calendar data
                    // TODO: wire to actual hitch state
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Schedule synced',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Family events list ────────────────────────────────────────────────────────

class _FamilyEventsList extends StatelessWidget {
  const _FamilyEventsList({
    required this.events,
    this.onDelete,
  });
  final List<FamilyEvent> events;
  final ValueChanged<String>? onDelete;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = events
        .where((e) => !e.date.isBefore(
        DateTime.now().subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Family events',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (events.isNotEmpty)
              Text('${upcoming.length} upcoming',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.celebration_outlined,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant
                        .withOpacity(0.5)),
                const SizedBox(height: 8),
                Text('No upcoming events',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Add birthdays, appointments, or other events',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ...upcoming.map((e) {
            final color = e.colorHex != null
                ? Color(int.parse(
                'FF${e.colorHex!.replaceAll('#', '')}',
                radix: 16))
                : theme.colorScheme.secondary;
            final daysUntil =
                e.date.difference(DateTime.now()).inDays;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${e.date.day}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                      Text(
                        _months[e.date.month - 1],
                        style: TextStyle(
                            fontSize: 10, color: color),
                      ),
                    ],
                  ),
                ),
                title: Text(e.title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  daysUntil == 0
                      ? 'Today!'
                      : daysUntil == 1
                      ? 'Tomorrow'
                      : 'In $daysUntil days',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: daysUntil <= 3
                          ? color
                          : theme.colorScheme.onSurfaceVariant),
                ),
                trailing: onDelete != null
                    ? IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error),
                  onPressed: () => onDelete!(e.id),
                )
                    : null,
              ),
            );
          }),
      ],
    );
  }
}

// ── Add event sheet ───────────────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet();

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  String _color = '#AD1457';
  bool _isLoading = false;

  static const _colors = [
    ('#AD1457', 'Pink'),
    ('#1565C0', 'Blue'),
    ('#2E7D32', 'Green'),
    ('#E65100', 'Orange'),
    ('#6A1B9A', 'Purple'),
    ('#00695C', 'Teal'),
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    await context.read<FamilyCubit>().addFamilyEvent(
      title: _titleController.text.trim(),
      date: _date,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      colorHex: _color,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
      EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            Text('Add family event',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Event title',
                hintText: "e.g. Emma's birthday, Doctor appointment",
                prefixIcon: const Icon(Icons.celebration_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border:
                  Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_months[_date.month - 1]} ${_date.day}, ${_date.year}',
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
            const SizedBox(height: 16),

            // Description (optional)
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            // Color
            Text('Color',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Row(
              children: _colors.map((c) {
                final isSelected = _color == c.$1;
                final color = Color(int.parse(
                    'FF${c.$1.replaceAll('#', '')}',
                    radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _color = c.$1),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                          color: theme.colorScheme.onSurface,
                          width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                        color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add),
              label: const Text('Add event'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared hitch schedule for family members ───────────────────────────────

class _SharedSchedule extends StatefulWidget {
  const _SharedSchedule({required this.householdId});
  final String householdId;

  @override
  State<_SharedSchedule> createState() => _SharedScheduleState();
}

class _SharedScheduleState extends State<_SharedSchedule> {
  List<Map<String, dynamic>> _hitches = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadHitches();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _loadHitches() {
    _sub = context
        .read<FamilyCubit>()
        .watchHitches(widget.householdId)
        .listen(
          (result) {
        if (!mounted) return;
        result.fold(
              (failure) {
            debugPrint('Hitch watch error: ${failure.message}');
            setState(() => _loading = false);
          },
              (hitches) {
            debugPrint('Hitches received: ${hitches.length}');
            setState(() {
              _hitches = hitches;
              _loading = false;
            });
          },
        );
      },
      onError: (e) {
        debugPrint('Stream error: $e');
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find today's and upcoming hitches
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = _hitches.where((h) {
      final end = DateTime.parse(h['endDate'] as String);
      return !end.isBefore(today);
    }).toList()
      ..sort((a, b) => DateTime.parse(a['startDate'] as String)
          .compareTo(DateTime.parse(b['startDate'] as String)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hitch schedule',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (upcoming.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No upcoming hitches synced yet.\n'
                  'The worker needs to add their schedule first.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...upcoming.take(5).map((h) {
            final start = DateTime.parse(h['startDate'] as String);
            final end = DateTime.parse(h['endDate'] as String);
            final type = h['type'] as String;
            final isOn = type == 'on';
            final workerColorHex = h['workerColor'] as String? ??
                (isOn ? '#2E7D32' : '#C62828');
            final color = Color(
                int.parse('FF${workerColorHex.replaceAll('#', '')}',
                    radix: 16));
            final daysUntil = start.difference(today).inDays;
            const months = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isOn ? Icons.work_outline : Icons.home_outlined,
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  isOn
                      ? (h['rigName'] != null
                      ? '${h['workerName'] ?? 'Worker'} — ${h['rigName']}'
                      : '${h['workerName'] ?? 'Worker'} on hitch')
                      : '${h['workerName'] ?? 'Worker'} off hitch',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${months[start.month - 1]} ${start.day} – '
                      '${months[end.month - 1]} ${end.day}',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil < 0
                        ? 'Active'
                        : 'In $daysUntil days',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: color),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}