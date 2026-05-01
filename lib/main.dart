import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/data/datasources/app_database.dart';
import 'features/calendar/presentation/cubits/calendar_cubit.dart';
import 'features/calendar/presentation/cubits/worker_cubit.dart';
import 'features/family/data/datasources/family_repository_impl.dart';
import 'features/family/presentation/cubits/family_cubit.dart';
import 'features/finance/data/datasources/finance_repository_impl.dart';
import 'features/finance/domain/usecases/finance_usecases.dart';
import 'features/finance/presentation/cubits/finance_cubit.dart';
import 'features/location/presentation/cubits/location_cubit.dart';
import 'features/notifications/data/notification_scheduler.dart';
import 'features/settings/presentation/cubits/purchase_cubit.dart';
import 'features/settings/presentation/cubits/settings_cubit.dart';
import 'firebase_options.dart';
import 'features/calendar/domain/entities/hitch.dart';
import 'features/calendar/data/datasources/app_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);
  tz.initializeTimeZones();
  await NotificationScheduler.initialize();
  await configureDependencies();

  runApp(const RigSyncApp());
}

class RigSyncApp extends StatelessWidget {
  const RigSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = getIt<AppDatabase>();
    final financeRepo = FinanceRepositoryImpl(db);
    final familyRepo = FamilyRepositoryImpl();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PurchaseCubit()..initialize(),
        ),
        BlocProvider(
          create: (_) => SettingsCubit()..loadSettings(),
        ),
        BlocProvider(
          create: (_) => WorkerCubit(getIt())..loadWorkers(),
        ),
        BlocProvider(
          create: (_) => CalendarCubit(
            getHitches: getIt(),
            addHitch: getIt(),
            updateHitch: getIt(),
            deleteHitch: getIt(),
            generateFromPattern: getIt(),
          ),
        ),
        BlocProvider(
          create: (_) => FinanceCubit(
            getPayPeriods: GetPayPeriodsUseCase(financeRepo),
            addPayPeriod: AddPayPeriodUseCase(financeRepo),
            updatePayPeriod: UpdatePayPeriodUseCase(financeRepo),
            deletePayPeriod: DeletePayPeriodUseCase(financeRepo),
          ),
        ),
        BlocProvider(
          create: (_) => FamilyCubit(familyRepo)..initialize(),
        ),
        BlocProvider(
          create: (_) => LocationCubit()..initialize(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyCubit, FamilyState>(
      listenWhen: (prev, curr) =>
      prev.household == null && curr.household != null && curr.isOwner,
      listener: (context, familyState) {
        // Household just created — sync all existing hitches immediately
        final hitches = context.read<CalendarCubit>().state.hitches;
        if (hitches.isEmpty) return;
        final hitchMaps = hitches
            .map((h) => {
          'id': h.id,
          'workerId': h.workerId,
          'startDate': h.startDate.toIso8601String(),
          'endDate': h.endDate.toIso8601String(),
          'type': h.type == HitchType.on
              ? 'on'
              : h.type == HitchType.off
              ? 'off'
              : 'transit',
          'rigName': h.rigName,
          'colorHex': h.colorHex,
          'notes': h.notes,
        })
            .toList();
        context.read<FamilyCubit>().syncExistingHitches(hitchMaps);
      },
        child: BlocListener<CalendarCubit, CalendarState>(
      listenWhen: (prev, curr) => prev.hitches != curr.hitches,
      listener: (context, calendarState) {
        // Schedule notifications
        final settings = context.read<SettingsCubit>().state;
        NotificationScheduler.scheduleFromHitches(
          hitches: calendarState.hitches,
          reminderDaysBefore: settings.rotationReminderDays,
          notificationsEnabled: settings.notificationsEnabled,
          paycheckReminderEnabled: settings.paycheckReminderEnabled,
        );

        // Sync hitches to Firestore for family sharing
        final familyState = context.read<FamilyCubit>().state;
        if (familyState.hasHousehold && familyState.isOwner) {
          _syncAllWorkers(context);
        }
      },
      child: BlocListener<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) =>
        prev.notificationsEnabled != curr.notificationsEnabled ||
            prev.rotationReminderDays != curr.rotationReminderDays ||
            prev.paycheckReminderEnabled != curr.paycheckReminderEnabled,
        listener: (context, settingsState) {
          final hitches = context.read<CalendarCubit>().state.hitches;
          NotificationScheduler.scheduleFromHitches(
            hitches: hitches,
            reminderDaysBefore: settingsState.rotationReminderDays,
            notificationsEnabled: settingsState.notificationsEnabled,
            paycheckReminderEnabled: settingsState.paycheckReminderEnabled,
          );
        },
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
          builder: (context, settings) {
            return MaterialApp.router(
              title: 'RigSync',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    )
    );
  }

  Future<void> _syncAllWorkers(BuildContext context) async {
    final familyState = context.read<FamilyCubit>().state;
    if (!familyState.hasHousehold || !familyState.isOwner) return;

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

    await context.read<FamilyCubit>().syncExistingHitches(allHitchMaps);
  }
}