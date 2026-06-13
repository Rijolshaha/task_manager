import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/task.dart';
import 'session_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Har necha soatda eslatma yuboriladi.
  static const Duration reminderInterval = Duration(hours: 5);

  /// Faqat shu kunlar ichidagi muddatli vazifalar eslatma oladi.
  static const int reminderWeekDays = 7;

  /// Har bir vazifa uchun maksimal eslatmalar soni (7 kun / 5 soat).
  static const int maxSlotsPerTask = 40;

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  static Future<void> init() async {
    if (!isSupported) return;
    if (_inited) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tashkent'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    _inited = true;
  }

  static Future<void> requestPermissionIfNeeded() async {
    if (!isSupported) return;
    await init();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static int notificationIdForKey(dynamic key, [int slot = 0]) {
    final base = key is int ? key : key.hashCode;
    return base * 100 + slot;
  }

  /// Muddati bugundan keyingi 7 kun ichida bo‘lgan, bajarilmagan vazifalar.
  static bool isTaskEligibleForReminders(Task task) {
    if (task.isCompleted) return false;

    final today = _dayStart(DateTime.now());
    final weekEnd = today.add(const Duration(days: reminderWeekDays));
    final due = task.safeDueDate;

    return !due.isBefore(today) && !due.isAfter(weekEnd);
  }

  /// Vazifa uchun har 5 soatda keladigan eslatma vaqtlari ro‘yxati.
  static List<DateTime> reminderTimesForTask(Task task) {
    if (!isTaskEligibleForReminders(task)) return [];

    final now = DateTime.now();
    final dueEnd = _dayStart(task.safeDueDate).add(const Duration(days: 1));
    final weekLimit = _dayStart(
      DateTime.now(),
    ).add(const Duration(days: reminderWeekDays + 1));
    final until = dueEnd.isBefore(weekLimit) ? dueEnd : weekLimit;

    final times = <DateTime>[];
    var next = now.add(reminderInterval);

    for (var slot = 0; slot < maxSlotsPerTask && next.isBefore(until); slot++) {
      times.add(next);
      next = next.add(reminderInterval);
    }

    return times;
  }

  static Future<String> _reminderTitleForLocale() async {
    final code = await SessionService.getLocaleCode() ?? 'en';
    return lookupAppLocalizations(Locale(code)).taskReminderTitle;
  }

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!isSupported) return;
    await init();

    if (dateTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Tasks',
          channelDescription: 'Task reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> scheduleForTask({
    required Task task,
    required dynamic hiveKey,
    String? reminderTitle,
  }) async {
    if (!isSupported) return;
    if (!await SessionService.areNotificationsEnabled()) return;

    await requestPermissionIfNeeded();
    await cancelForKey(hiveKey);

    if (!isTaskEligibleForReminders(task)) return;

    final title = reminderTitle ?? await _reminderTitleForLocale();
    final times = reminderTimesForTask(task);

    for (var slot = 0; slot < times.length; slot++) {
      await schedule(
        id: notificationIdForKey(hiveKey, slot),
        title: title,
        body: task.title,
        dateTime: times[slot],
      );
    }
  }

  static Future<void> cancelForKey(dynamic key) async {
    if (!isSupported) return;
    await init();
    for (var slot = 0; slot < maxSlotsPerTask; slot++) {
      await _plugin.cancel(notificationIdForKey(key, slot));
    }
  }

  static Future<void> cancel(int id) async {
    if (!isSupported) return;
    await init();
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (!isSupported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Ilova ishga tushganda yoki bildirishnomalar yoqilganda barcha vazifalarni qayta rejalashtiradi.
  static Future<void> rescheduleAllTasks({String? reminderTitle}) async {
    if (!isSupported) return;
    if (!await SessionService.areNotificationsEnabled()) return;

    await init();
    await requestPermissionIfNeeded();

    final title = reminderTitle ?? await _reminderTitleForLocale();
    final box = Hive.box<Task>('tasks');

    await cancelAll();

    for (var i = 0; i < box.length; i++) {
      final task = box.getAt(i);
      final key = box.keyAt(i);
      if (task == null) continue;

      await scheduleForTask(
        task: task,
        hiveKey: key,
        reminderTitle: title,
      );
    }
  }
}
