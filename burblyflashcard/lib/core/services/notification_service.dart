import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import 'data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DataService _dataService = DataService();

  // Notification IDs
  static const int dailyReminderId = 1000;
  static const int overdueCardsId = 2000;
  static const int studyStreakId = 3000;

  Future<void> initialize() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Android settings
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to appropriate screen
    // This will be implemented when we add navigation handling
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required List<int> daysOfWeek,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Study Reminders',
      channelDescription: 'Reminders to study your flashcards daily',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    for (int day in daysOfWeek) {
      await _notifications.zonedSchedule(
        dailyReminderId + day,
        'Time to Study! 📚',
        'You have flashcards waiting for review. Keep your streak going!',
        _nextInstanceOfDay(time, day),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    // Save reminder settings
    await _saveReminderSettings(time, daysOfWeek);
  }

  // Schedule overdue cards reminder
  Future<void> scheduleOverdueCardsReminder() async {
    final overdueCards = await getOverdueCards();
    
    if (overdueCards.isEmpty) return;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'overdue_cards_channel',
      'Overdue Cards',
      channelDescription: 'Reminders for cards that need review',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      overdueCardsId,
      'Cards Need Review! ⏰',
      'You have ${overdueCards.length} cards that are overdue for review.',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 2)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Schedule study streak reminder
  Future<void> scheduleStudyStreakReminder(int streakDays) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'study_streak_channel',
      'Study Streaks',
      channelDescription: 'Celebrate your study streaks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      studyStreakId,
      'Amazing Streak! 🔥',
      'You\'ve studied for $streakDays days in a row! Keep it up!',
      tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Check and schedule notifications for overdue cards
  Future<void> checkAndScheduleOverdueNotifications() async {
    final overdueCards = await getOverdueCards();
    
    if (overdueCards.isNotEmpty) {
      await scheduleOverdueCardsReminder();
    }
  }

  // Get overdue cards
  Future<List<Flashcard>> getOverdueCards() async {
    final now = DateTime.now();
    final allCards = await _dataService.getAllFlashcards();
    
    return allCards.where((card) {
      return card.nextReview != null && card.nextReview!.isBefore(now);
    }).toList();
  }

  // Get cards due today
  Future<List<Flashcard>> getCardsDueToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final allCards = await _dataService.getAllFlashcards();
    
    return allCards.where((card) {
      if (card.nextReview == null) return false;
      final reviewDate = DateTime(
        card.nextReview!.year,
        card.nextReview!.month,
        card.nextReview!.day,
      );
      return reviewDate.isAtSameMomentAs(today);
    }).toList();
  }

  // Get cards due in next 3 days
  Future<List<Flashcard>> getCardsDueSoon() async {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    
    final allCards = await _dataService.getAllFlashcards();
    
    return allCards.where((card) {
      return card.nextReview != null && 
             card.nextReview!.isAfter(now) && 
             card.nextReview!.isBefore(threeDaysFromNow);
    }).toList();
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Show immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'immediate_channel',
      'Immediate Notifications',
      channelDescription: 'Immediate notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Helper method to get next instance of a specific day and time
  tz.TZDateTime _nextInstanceOfDay(TimeOfDay time, int dayOfWeek) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    
    while (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  // Save reminder settings
  Future<void> _saveReminderSettings(TimeOfDay time, List<int> daysOfWeek) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
    await prefs.setStringList('reminder_days', daysOfWeek.map((d) => d.toString()).toList());
  }

  // Load reminder settings
  Future<Map<String, dynamic>?> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour');
    final minute = prefs.getInt('reminder_minute');
    final daysList = prefs.getStringList('reminder_days');
    
    if (hour == null || minute == null || daysList == null) {
      return null;
    }
    
    final days = daysList.map((d) => int.parse(d)).toList();
    return {
      'time': TimeOfDay(hour: hour, minute: minute),
      'daysOfWeek': days,
    };
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  // Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }
}
