import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../../features/settings/presentation/cubits/purchase_cubit.dart';
import '../../features/settings/presentation/screens/paywall_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    (icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendar', path: AppRouter.calendar, requiresPro: false),
    (icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Finance', path: AppRouter.finance, requiresPro: true),
    (icon: Icons.people_outline, activeIcon: Icons.people, label: 'Family', path: AppRouter.family, requiresPro: true),
    (icon: Icons.location_on_outlined, activeIcon: Icons.location_on, label: 'Location', path: AppRouter.location, requiresPro: true),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', path: AppRouter.settings, requiresPro: false),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isPro = context.watch<PurchaseCubit>().state.isPro;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) {
          final tab = _tabs[i];
          if (tab.requiresPro && !isPro) {
            PaywallScreen.show(context, featureName: tab.label);
          } else {
            context.go(tab.path);
          }
        },
        destinations: _tabs.map((t) {
          final locked = t.requiresPro && !isPro;
          return NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(t.icon),
                if (locked)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock,
                          size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            selectedIcon: Icon(t.activeIcon),
            label: t.label,
          );
        }).toList(),
      ),
    );
  }
}