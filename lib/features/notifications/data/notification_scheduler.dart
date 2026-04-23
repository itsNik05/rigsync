import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../calendar/domain/entities/hitch.dart';

class NotificationScheduler {
  NotificationScheduler._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'rigsync_reminders';
  static const _channelName = 'Rotation Reminders';

  // ── Init ───────────────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Rotation and pay period reminders',
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  // ── Schedule all reminders from hitch list ─────────────────────────────────

  static Future<void> scheduleFromHitches({
    required List<Hitch> hitches,
    required int reminderDaysBefore,
    required bool notificationsEnabled,
    required bool paycheckReminderEnabled,
  }) async {
    if (!notificationsEnabled) {
      await cancelAll();
      return;
    }

    await cancelAll();

    final now = DateTime.now();
    int notifId = 100;

    for (final hitch in hitches) {
      // Skip past hitches
      if (hitch.endDate.isBefore(now)) continue;

      // Rotation reminder — notify X days before start
      final reminderDate = hitch.startDate
          .subtract(Duration(days: reminderDaysBefore));

      if (reminderDate.isAfter(now)) {
        final isReturningHome = hitch.type == HitchType.off;
        await _scheduleNotification(
          id: notifId++,
          scheduledDate: reminderDate,
          title: isReturningHome
              ? 'Heading home soon!'
              : 'Back to the rig soon!',
          body: isReturningHome
              ? 'Your time off ends ${_fmt(hitch.startDate)}. Enjoy the last days!'
              : 'Your hitch starts ${_fmt(hitch.startDate)}. Get ready!',
        );
      }

      // Day-of notification
      if (hitch.startDate.isAfter(now)) {
        await _scheduleNotification(
          id: notifId++,
          scheduledDate: hitch.startDate,
          title: hitch.type == HitchType.on
              ? 'Hitch starts today'
              : 'Welcome home!',
          body: hitch.type == HitchType.on
              ? (hitch.rigName != null
              ? 'Reporting to ${hitch.rigName} today. Safe travels!'
              : 'Your hitch begins today. Safe travels!')
              : 'Your time off starts today. Rest up!',
        );
      }

      // Paycheck reminder — notify when ON hitch ends (pay period complete)
      if (paycheckReminderEnabled &&
          hitch.type == HitchType.on &&
          hitch.endDate.isAfter(now)) {
        await _scheduleNotification(
          id: notifId++,
          scheduledDate: hitch.endDate,
          title: 'Pay period complete',
          body: hitch.rigName != null
              ? 'Your hitch at ${hitch.rigName} ended. Mark your pay period when received.'
              : 'Your hitch ended. Mark your pay period when you receive payment.',
        );
      }
    }
  }

  // ── Individual notification ────────────────────────────────────────────────

  static Future<void> _scheduleNotification({
    required int id,
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Rotation and pay period reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // Silently skip if scheduling fails
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}