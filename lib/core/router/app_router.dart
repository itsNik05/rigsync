import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/finance/presentation/screens/finance_screen.dart';
import '../../features/family/presentation/screens/family_screen.dart';
import '../../features/location/presentation/screens/location_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/legal_screens.dart';
import '../widgets/app_shell.dart';

class AppRouter {
  AppRouter._();

  static const String login = '/login';
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String finance = '/finance';
  static const String family = '/family';
  static const String location = '/location';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';

  static final router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Legal routes — outside shell (no bottom nav)
      GoRoute(
        path: privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: termsOfService,
        builder: (context, state) => const TermsOfServiceScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: home,
            redirect: (context, state) => calendar,
          ),
          GoRoute(
            path: calendar,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CalendarScreen(),
            ),
          ),
          GoRoute(
            path: finance,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FinanceScreen(),
            ),
          ),
          GoRoute(
            path: family,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FamilyScreen(),
            ),
          ),
          GoRoute(
            path: location,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LocationScreen(),
            ),
          ),
          GoRoute(
            path: settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}