import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.notificationsEnabled = true,
    this.rotationReminderDays = 1,
    this.paycheckReminderEnabled = true,
    this.firstDayOfWeek = DateTime.sunday,
    this.currency = 'USD',
    this.autoBackupEnabled = false,
    this.lastBackupDate,
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final int rotationReminderDays; // days before rotation to notify
  final bool paycheckReminderEnabled;
  final int firstDayOfWeek; // DateTime.monday or DateTime.sunday
  final String currency;
  final bool autoBackupEnabled;
  final DateTime? lastBackupDate;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    int? rotationReminderDays,
    bool? paycheckReminderEnabled,
    int? firstDayOfWeek,
    String? currency,
    bool? autoBackupEnabled,
    DateTime? lastBackupDate,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      rotationReminderDays: rotationReminderDays ?? this.rotationReminderDays,
      paycheckReminderEnabled:
      paycheckReminderEnabled ?? this.paycheckReminderEnabled,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      currency: currency ?? this.currency,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    notificationsEnabled,
    rotationReminderDays,
    paycheckReminderEnabled,
    firstDayOfWeek,
    currency,
    autoBackupEnabled,
    lastBackupDate,
  ];
}

// ── Keys ──────────────────────────────────────────────────────────────────────

class _Keys {
  static const themeMode = 'settings_theme_mode';
  static const notificationsEnabled = 'settings_notifications';
  static const rotationReminderDays = 'settings_rotation_days';
  static const paycheckReminder = 'settings_paycheck_reminder';
  static const firstDayOfWeek = 'settings_first_day';
  static const currency = 'settings_currency';
  static const autoBackup = 'settings_auto_backup';
  static const lastBackup = 'settings_last_backup';
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState());

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_Keys.themeMode) ?? 0;
    final lastBackupMs = prefs.getInt(_Keys.lastBackup);

    emit(SettingsState(
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, 2)],
      notificationsEnabled:
      prefs.getBool(_Keys.notificationsEnabled) ?? true,
      rotationReminderDays:
      prefs.getInt(_Keys.rotationReminderDays) ?? 1,
      paycheckReminderEnabled:
      prefs.getBool(_Keys.paycheckReminder) ?? true,
      firstDayOfWeek:
      prefs.getInt(_Keys.firstDayOfWeek) ?? DateTime.sunday,
      currency: prefs.getString(_Keys.currency) ?? 'USD',
      autoBackupEnabled: prefs.getBool(_Keys.autoBackup) ?? false,
      lastBackupDate: lastBackupMs != null
          ? DateTime.fromMillisecondsSinceEpoch(lastBackupMs)
          : null,
    ));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_Keys.themeMode, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.notificationsEnabled, enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setRotationReminderDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_Keys.rotationReminderDays, days);
    emit(state.copyWith(rotationReminderDays: days));
  }

  Future<void> setPaycheckReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.paycheckReminder, enabled);
    emit(state.copyWith(paycheckReminderEnabled: enabled));
  }

  Future<void> setFirstDayOfWeek(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_Keys.firstDayOfWeek, day);
    emit(state.copyWith(firstDayOfWeek: day));
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_Keys.currency, currency);
    emit(state.copyWith(currency: currency));
  }

  Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.autoBackup, enabled);
    emit(state.copyWith(autoBackupEnabled: enabled));
  }

  Future<void> recordBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt(_Keys.lastBackup, now.millisecondsSinceEpoch);
    emit(state.copyWith(lastBackupDate: now));
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    emit(const SettingsState());
  }
}