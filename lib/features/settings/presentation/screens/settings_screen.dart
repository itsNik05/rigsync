import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import 'legal_screens.dart';
import '../cubits/settings_cubit.dart';
import '../../../../features/calendar/data/datasources/app_database.dart';
import '../../../../core/di/injection.dart';
import '../../data/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            children: [
              _SectionHeader(label: 'Appearance'),
              _SettingsTile(
                icon: Icons.brightness_6_outlined,
                title: 'Theme',
                subtitle: _themeName(state.themeMode),
                onTap: () => _showThemePicker(context, state.themeMode),
              ),
              _SettingsTile(
                icon: Icons.calendar_today_outlined,
                title: 'First day of week',
                subtitle: state.firstDayOfWeek == DateTime.sunday
                    ? 'Sunday'
                    : 'Monday',
                onTap: () =>
                    _showFirstDayPicker(context, state.firstDayOfWeek),
              ),
              _SettingsTile(
                icon: Icons.attach_money,
                title: 'Currency',
                subtitle: state.currency,
                onTap: () => _showCurrencyPicker(context, state.currency),
              ),
              const Divider(height: 1),
              _SectionHeader(label: 'Notifications'),
              _SwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Enable notifications',
                subtitle: 'Rotation reminders and alerts',
                value: state.notificationsEnabled,
                onChanged: (v) => context
                    .read<SettingsCubit>()
                    .setNotificationsEnabled(v),
              ),
              if (state.notificationsEnabled) ...[
                _SettingsTile(
                  icon: Icons.schedule_outlined,
                  title: 'Rotation reminder',
                  subtitle:
                  '${state.rotationReminderDays} day${state.rotationReminderDays == 1 ? '' : 's'} before',
                  onTap: () => _showReminderDaysPicker(
                      context, state.rotationReminderDays),
                ),
                _SwitchTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Paycheck reminder',
                  subtitle: 'Alert when pay period ends unpaid',
                  value: state.paycheckReminderEnabled,
                  onChanged: (v) => context
                      .read<SettingsCubit>()
                      .setPaycheckReminderEnabled(v),
                ),
              ],
              const Divider(height: 1),
              _SectionHeader(label: 'Backup & data'),
              /**_SwitchTile(
                icon: Icons.cloud_upload_outlined,
                title: 'Auto backup',
                subtitle: 'Backup to Google Drive when on Wi-Fi',
                value: state.autoBackupEnabled,
                onChanged: (v) =>
                    context.read<SettingsCubit>().setAutoBackup(v),
              ),**/
              _SettingsTile(
                icon: Icons.backup_outlined,
                title: 'Back up now',
                subtitle: state.lastBackupDate != null
                    ? 'Last backup: ${_formatDate(state.lastBackupDate!)}'
                    : 'Never backed up',
                onTap: () => _runBackup(context),
              ),
              _SettingsTile(
                icon: Icons.restore_outlined,
                title: 'Restore from backup',
                subtitle: 'Restore data from Google Drive',
                onTap: () => _showRestoreDialog(context),
              ),
              const Divider(height: 1),
              _SectionHeader(label: 'Data'),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Clear all data',
                subtitle: 'Delete all workers, hitches and pay periods',
                titleColor: Theme.of(context).colorScheme.error,
                onTap: () => _showClearDataDialog(context),
              ),
              const Divider(height: 1),
              _SectionHeader(label: 'About'),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'App version',
                subtitleBuilder: (_) => _VersionText(),
              ),
              _SettingsTile(
                icon: Icons.business_outlined,
                title: 'Developer',
                subtitle: 'NuvioLabs',
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Terms of service',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'RigSync by NuvioLabs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: _PickerSheet(
          title: 'Theme',
          options: const [
            (Icons.brightness_auto, 'System default',
            'Follows device setting'),
            (Icons.light_mode_outlined, 'Light', 'Always light'),
            (Icons.dark_mode_outlined, 'Dark', 'Always dark'),
          ],
          selectedIndex: ThemeMode.values.indexOf(current),
          onSelected: (i) => context
              .read<SettingsCubit>()
              .setThemeMode(ThemeMode.values[i]),
        ),
      ),
    );
  }

  void _showFirstDayPicker(BuildContext context, int current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: _PickerSheet(
          title: 'First day of week',
          options: const [
            (Icons.calendar_view_week, 'Sunday',
            'Week starts on Sunday'),
            (Icons.calendar_view_week, 'Monday',
            'Week starts on Monday'),
          ],
          selectedIndex: current == DateTime.sunday ? 0 : 1,
          onSelected: (i) => context
              .read<SettingsCubit>()
              .setFirstDayOfWeek(
              i == 0 ? DateTime.sunday : DateTime.monday),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, String current) {
    const currencies = [
      ('USD', 'US Dollar', '\$'),
      ('CAD', 'Canadian Dollar', 'CA\$'),
      ('AUD', 'Australian Dollar', 'A\$'),
      ('GBP', 'British Pound', '£'),
      ('INR', 'Indian Rupee', '₹'),
      ('AED', 'UAE Dirham', 'د.إ'),
      ('SAR', 'Saudi Riyal', '﷼'),
      ('NOK', 'Norwegian Krone', 'kr'),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Currency',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: currencies.map((c) {
                    final isSelected = c.$1 == current;
                    return ListTile(
                      leading: Text(c.$3,
                          style: const TextStyle(fontSize: 20)),
                      title: Text(c.$1),
                      subtitle: Text(c.$2),
                      trailing: isSelected
                          ? Icon(Icons.check,
                          color: Theme.of(context)
                              .colorScheme
                              .primary)
                          : null,
                      onTap: () {
                        context
                            .read<SettingsCubit>()
                            .setCurrency(c.$1);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminderDaysPicker(BuildContext context, int current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsCubit>(),
        child: _PickerSheet(
          title: 'Rotation reminder',
          options: const [
            (Icons.notifications_outlined, 'Same day',
            'Notify on rotation day'),
            (Icons.notifications_outlined, '1 day before',
            'Notify the day before'),
            (Icons.notifications_outlined, '2 days before',
            'Notify 2 days before'),
            (Icons.notifications_outlined, '3 days before',
            'Notify 3 days before'),
          ],
          selectedIndex: current.clamp(0, 3),
          onSelected: (i) => context
              .read<SettingsCubit>()
              .setRotationReminderDays(i),
        ),
      ),
    );
  }

  Future<void> _runBackup(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final service = BackupService(getIt<AppDatabase>());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Preparing backup...'),
          ],
        ),
        duration: Duration(seconds: 60),
      ),
    );

    final result = await service.exportBackup();

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.cancelled) return;

      if (result.success) {
        await cubit.recordBackup();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backed up: ${result.workerCount} workers, '
                  '${result.hitchCount} hitches, '
                  '${result.payPeriodCount} pay periods',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup'),
        content: const Text(
          'This will import data from a RigSync backup file. '
              'Existing data will not be deleted — imported records '
              'will be merged with your current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _runRestore(context);
            },
            child: const Text('Choose file'),
          ),
        ],
      ),
    );
  }

  Future<void> _runRestore(BuildContext context) async {
    final service = BackupService(getIt<AppDatabase>());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Restoring...'),
          ],
        ),
        duration: Duration(seconds: 60),
      ),
    );

    final result = await service.importBackup();

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.cancelled) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Restored: ${result.workerCount} workers, '
                  '${result.hitchCount} hitches, '
                  '${result.payPeriodCount} pay periods. '
                  'Restart the app to see all changes.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 6),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will permanently delete all workers, hitch schedules, and pay periods. This cannot be undone. You should BACKUP the data before clearing.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<SettingsCubit>().clearAllData(getIt<AppDatabase>());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared — restart the app'),
                    backgroundColor: Color(0xFF2E7D32),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor:
                Theme.of(context).colorScheme.error),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System default',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleBuilder,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final WidgetBuilder? subtitleBuilder;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: titleColor ?? theme.colorScheme.onSurfaceVariant),
      title: Text(title,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: titleColor, fontWeight: FontWeight.w500)),
      subtitle: subtitleBuilder != null
          ? subtitleBuilder!(context)
          : subtitle != null
          ? Text(subtitle!,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

// ── Switch tile ───────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      secondary:
      Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(title,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
    );
  }
}

// ── Picker sheet ──────────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final String title;
  final List<(IconData, String, String)> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          ...options.asMap().entries.map((e) {
            final i = e.key;
            final opt = e.value;
            final isSelected = i == selectedIndex;
            return ListTile(
              leading: Icon(opt.$1,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant),
              title: Text(opt.$2,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : null,
                  )),
              subtitle: Text(opt.$3,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              trailing: isSelected
                  ? Icon(Icons.check,
                  color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                onSelected(i);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Version text ──────────────────────────────────────────────────────────────

class _VersionText extends StatefulWidget {
  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(
              () => _version = '${info.version} (${info.buildNumber})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_version,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
            Theme.of(context).colorScheme.onSurfaceVariant));
  }
}