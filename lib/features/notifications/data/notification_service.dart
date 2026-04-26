import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const _channelId = 'rigsync_reminders';
  static const _channelName = 'Rotation Reminders';

  Future<void> init() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    await _createChannel();
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for upcoming hitch rotations',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Schedule a reminder [daysBefore] days before [hitchDate].
  Future<void> scheduleRotationReminder({
    required int id,
    required DateTime hitchDate,
    required bool isReturning,
    int daysBefore = 1,
  }) async {
    final scheduledDate = hitchDate.subtract(Duration(days: daysBefore));
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final title = isReturning ? 'Heading home tomorrow!' : 'Back to the rig tomorrow!';
    final body = isReturning
        ? 'Your hitch ends ${_fmt(hitchDate)}. Safe travels!'
        : 'Your hitch starts ${_fmt(hitchDate)}. Get ready!';

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Rotation reminders',
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
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> cancel(int id) => _plugin.cancel(id);

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}