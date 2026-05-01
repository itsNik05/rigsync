import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/purchase_cubit.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.featureName});

  final String? featureName;

  static Future<void> show(BuildContext context,
      {String? featureName}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PurchaseCubit>(),
        child: PaywallScreen(featureName: featureName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 24),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium_outlined,
                size: 36, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'RigSync Pro',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (featureName != null)
            Text(
              '$featureName is a Pro feature',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: 24),

          // Features list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: const [
                _ProFeature(
                  icon: Icons.people_outline,
                  title: 'Unlimited workers',
                  subtitle: 'Track schedules for the whole crew',
                ),
                _ProFeature(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Finance tracking',
                  subtitle: 'Pay periods, earnings charts, mark paid',
                ),
                _ProFeature(
                  icon: Icons.location_on_outlined,
                  title: 'Rig location & weather',
                  subtitle: 'Map, travel estimator, live weather',
                ),
                _ProFeature(
                  icon: Icons.people_outline,
                  title: 'Family sharing',
                  subtitle: 'Real-time sync with household members',
                ),
                _ProFeature(
                  icon: Icons.notifications_outlined,
                  title: 'Smart notifications',
                  subtitle: 'Rotation reminders and pay alerts',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Price + buy button
          BlocBuilder<PurchaseCubit, PurchaseState>(
            builder: (context, state) {
              final price = state.productDetails?.price ?? '₹299';

              return Column(
                children: [
                  FilledButton(
                    onPressed: state.status == ProStatus.loading
                        ? null
                        : () => context.read<PurchaseCubit>().buyPro(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: state.status == ProStatus.loading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : Text(
                      'Unlock Pro — $price',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // REMOVE BEFORE RELEASE
                  TextButton(
                    onPressed: () async {
                      await context.read<PurchaseCubit>().unlockProForTesting();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      '[DEV] Unlock Pro for testing',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),

                  TextButton(
                    onPressed: state.isRestoring
                        ? null
                        : () => context
                        .read<PurchaseCubit>()
                        .restorePurchases(),
                    child: Text(
                      state.isRestoring
                          ? 'Restoring...'
                          : 'Restore previous purchase',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'One-time purchase · No subscription · No recurring fees',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
        ),
    );
  }
}

class _ProFeature extends StatelessWidget {
  const _ProFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.check_circle,
              size: 18, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}