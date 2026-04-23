import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../settings/presentation/cubits/purchase_cubit.dart';
import '../settings/presentation/cubits/paywall_screen.dart';

/// Wrap any widget with ProGate to lock it behind the paywall.
/// If the user is Pro, renders [child] normally.
/// If not, renders a locked placeholder with a tap-to-unlock prompt.
class ProGate extends StatelessWidget {
  const ProGate({
    super.key,
    required this.featureName,
    required this.child,
    this.lockedChild,
  });

  final String featureName;
  final Widget child;

  /// Optional custom locked UI. If null, shows default locked card.
  final Widget? lockedChild;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        if (state.isPro) return child;

        if (lockedChild != null) return lockedChild!;

        return _LockedPlaceholder(
          featureName: featureName,
          onUnlock: () =>
              PaywallScreen.show(context, featureName: featureName),
        );
      },
    );
  }
}

class _LockedPlaceholder extends StatelessWidget {
  const _LockedPlaceholder({
    required this.featureName,
    required this.onUnlock,
  });

  final String featureName;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                featureName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'This feature is part of RigSync Pro. Unlock once and keep it forever.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Unlock Pro'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Use this to check pro status inline without wrapping a full screen.
/// Example: show add button only if pro, else show paywall on tap.
class ProButton extends StatelessWidget {
  const ProButton({
    super.key,
    required this.featureName,
    required this.child,
    required this.onPro,
  });

  final String featureName;
  final Widget child;
  final VoidCallback onPro;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: state.isPro
              ? onPro
              : () => PaywallScreen.show(context,
              featureName: featureName),
          child: child,
        );
      },
    );
  }
}