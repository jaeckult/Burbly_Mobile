import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import 'data_service.dart';
import 'package:flutter/material.dart';
import '../../features/flashcards/screens/mixed_study_screen.dart';
import '../../features/flashcards/screens/deck_detail_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DataService _dataService = DataService();
  // Global navigator to handle navigation on notification taps
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Store the detected timezone
  tz.Location? _detectedTimezone;

  // Notification IDs
  static const int dailyReminderId = 1000;
  static const int overdueCardsId = 2000;
  static const int studyStreakId = 3000;

  // Channel IDs
  static const String dailyReminderChannelId = 'daily_reminder_channel';
  static const String overdueCardsChannelId = 'overdue_cards_channel';
  static const String studyStreakChannelId = 'study_streak_channel';
  static const String petNotificationChannelId = 'pet_notification_channel';
  static const String immediateChannelId = 'immediate_channel';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Force timezone detection to device's actual timezone
    await _detectAndSetTimezone();

    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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

    // Create notification channels for Android
    await _createNotificationChannels();
    
    await _requestPermissions();
  }

  Future<void> _detectAndSetTimezone() async {
    try {
      // Get device's current timezone offset
      final now = DateTime.now();
      final utcOffset = now.timeZoneOffset;
      
      // Find a timezone that matches this offset
      final timezoneNames = tz.timeZoneDatabase.locations.keys.toList();
      String? bestMatch;
      
      for (final timezoneName in timezoneNames) {
        try {
          final timezone = tz.getLocation(timezoneName);
          final tzNow = tz.TZDateTime.now(timezone);
          if (tzNow.timeZoneOffset == utcOffset) {
            bestMatch = timezoneName;
            break;
          }
        } catch (e) {
          // Skip invalid timezones
        }
      }
      
      if (bestMatch != null) {
        _detectedTimezone = tz.getLocation(bestMatch);
        print('Detected timezone: $bestMatch (offset: ${utcOffset.inHours} hours)');
        print('Stored timezone: ${_detectedTimezone?.name}');
      } else {
        print('Could not detect timezone, using device offset: ${utcOffset.inHours} hours');
        // Fallback to UTC
        _detectedTimezone = tz.UTC;
      }
    } catch (e) {
      print('Error detecting timezone: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      // Daily reminder channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          dailyReminderChannelId,
          'Daily Study Reminders',
          description: 'Reminders to study your flashcards daily',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Overdue cards channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          overdueCardsChannelId,
          'Overdue Cards',
          description: 'Reminders for cards that need review',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Study streak channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          studyStreakChannelId,
          'Study Streaks',
          description: 'Celebrate your study streaks',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Pet notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          petNotificationChannelId,
          'Pet Notifications',
          description: 'Notifications from your study pet',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Immediate notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          immediateChannelId,
          'Immediate Notifications',
          description: 'Immediate notifications',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Scheduled review channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'scheduled_review_channel',
          'Scheduled Review',
          description: 'Notifications for scheduled deck reviews',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Review now channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'review_now_channel',
          'Review Now',
          description: 'Notifications for cards due for review',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Overdue cards channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'overdue_cards_channel',
          'Overdue Cards',
          description: 'Notifications for overdue cards',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Card review channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'card_review_channel',
          'Card Review',
          description: 'Notifications for scheduled card reviews',
          importance: Importance.defaultImportance,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
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
    try {
      final payload = response.payload ?? '';
      print('Notification tapped: $payload');
      final nav = navigatorKey.currentState;
      if (nav == null) {
        print('Navigator not ready; cannot navigate from notification');
        return;
      }

      if (payload.startsWith('scheduled_review_')) {
        final deckId = payload.replaceFirst('scheduled_review_', '');
        _navigateToDeck(nav, deckId);
        return;
      }
      if (payload.startsWith('card_review_')) {
        // For simplicity, navigate to Mixed Study for now
        _navigateToMixed(nav);
        return;
      }

      switch (payload) {
        case 'study_reminder':
          _navigateToMixed(nav);
          break;
        case 'review_now':
          _navigateToMixed(nav);
          break;
        case 'overdue_card':
          _navigateToMixed(nav);
          break;
        default:
          // no-op
          break;
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  void _navigateToMixed(NavigatorState nav) {
    nav.push(MaterialPageRoute(builder: (_) => const MixedStudyScreen()));
  }

  Future<void> _navigateToDeck(NavigatorState nav, String deckId) async {
    try {
      final deck = await _dataService.getDeck(deckId);
      if (deck != null) {
        nav.push(MaterialPageRoute(builder: (_) => DeckDetailScreen(deck: deck)));
      } else {
        _navigateToMixed(nav);
      }
    } catch (e) {
      print('Error navigating to deck: $e');
      _navigateToMixed(nav);
    }
  }

  // Daily reminders
  Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required List<int> daysOfWeek,
  }) async {
    try {
      // Cancel existing daily reminders first
      await _cancelDailyReminders();

      if (daysOfWeek.isEmpty) return;

      final androidDetails = AndroidNotificationDetails(
        dailyReminderChannelId,
        'Daily Study Reminders',
        channelDescription: 'Reminders to study your flashcards daily',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      for (final day in daysOfWeek) {
        print('Processing day $day (${_getDayName(day)})...');
        final scheduledTime = _nextInstanceOfDay(time, day);
        
        print('Final scheduled time for day $day: ${scheduledTime.toString()}');
        
        // Check if this is today
        final now = tz.TZDateTime.now(tz.local);
        final today = now.weekday;
        final isToday = day == today;
        
        if (isToday) {
          // For today, use immediate scheduling without recurring components
          await _notifications.zonedSchedule(
            dailyReminderId + day,
            'Time to Study! 📚',
            'You have flashcards waiting for review. Keep your streak going!',
            scheduledTime,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            // No matchDateTimeComponents for today
            payload: 'study_reminder',
          );
          print('Scheduled TODAY reminder for day $day (${_getDayName(day)}) at ${scheduledTime.toString()}');
        } else {
          // For future days, use recurring scheduling
          await _notifications.zonedSchedule(
            dailyReminderId + day,
            'Time to Study! 📚',
            'You have flashcards waiting for review. Keep your streak going!',
            scheduledTime,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: 'study_reminder',
          );
          print('Scheduled FUTURE reminder for day $day (${_getDayName(day)}) at ${scheduledTime.toString()}');
        }
        
        print('Successfully scheduled daily reminder for day $day (${_getDayName(day)}) at ${scheduledTime.toString()}');
      }

      await _saveReminderSettings(time, daysOfWeek);
    } catch (e) {
      print('Error scheduling daily reminders: $e');
      rethrow;
    }
  }

  Future<void> _cancelDailyReminders() async {
    for (int day = 1; day <= 7; day++) {
      await _notifications.cancel(dailyReminderId + day);
    }
  }

  Future<void> scheduleOverdueCardsReminder() async {
    try {
      // Cancel existing overdue reminder
      await _notifications.cancel(overdueCardsId);

      final overdueCards = await getOverdueCards();
      if (overdueCards.isEmpty) return;

      final androidDetails = AndroidNotificationDetails(
        overdueCardsChannelId,
        'Overdue Cards',
        channelDescription: 'Reminders for cards that need review',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for 2 hours from now
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));
      
      await _notifications.zonedSchedule(
        overdueCardsId,
        'Cards Need Review! ⏰',
        'You have ${overdueCards.length} overdue cards waiting for review.',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'overdue_card',
      );
      
      print('Scheduled overdue cards reminder for ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling overdue cards reminder: $e');
    }
  }

  Future<void> scheduleStudyStreakReminder(int streakDays) async {
    try {
      // Cancel existing streak reminder
      await _notifications.cancel(studyStreakId);

      final androidDetails = AndroidNotificationDetails(
        studyStreakChannelId,
        'Study Streaks',
        channelDescription: 'Celebrate your study streaks',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for 1 hour from now
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 1));
      
      await _notifications.zonedSchedule(
        studyStreakId,
        'Amazing Streak! 🔥',
        'You\'ve studied for $streakDays days in a row! Keep it up!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'streak_reminder',
      );
      
      print('Scheduled study streak reminder for ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling study streak reminder: $e');
    }
  }

  // Pet notification methods
  Future<void> schedulePetNotification(String message, {int delayHours = 2}) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        petNotificationChannelId,
        'Pet Notifications',
        channelDescription: 'Notifications from your study pet',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for specified delay from now
      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(hours: delayHours));
      
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _notifications.zonedSchedule(
        notificationId,
        'Your Pet Misses You! 🐾',
        message,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('Scheduled pet notification for ${scheduledTime.toString()}: $message');
    } catch (e) {
      print('Error scheduling pet notification: $e');
    }
  }

  Future<void> showPetNotification(String message) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        petNotificationChannelId,
        'Pet Notifications',
        channelDescription: 'Notifications from your study pet',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _notifications.show(
        notificationId,
        'Your Pet Misses You! 🐾',
        message,
        details,
      );
      
      print('Showed pet notification: $message');
    } catch (e) {
      print('Error showing pet notification: $e');
    }
  }

  Future<void> showStudyReminderNotification(String title, String body) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        overdueCardsChannelId,
        'Overdue Cards',
        channelDescription: 'Reminders for cards that need review',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
        ongoing: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'STUDY_REMINDER',
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: 'study_reminder',
      );
      
      print('Showed study reminder notification: $title - $body');
    } catch (e) {
      print('Error showing study reminder notification: $e');
    }
  }

  Future<void> scheduleStudyReminderNotification({
    required TimeOfDay time,
    required List<int> daysOfWeek,
  }) async {
    try {
      // Cancel existing study reminder notifications first
      await _cancelStudyReminderNotifications();

      if (daysOfWeek.isEmpty) return;

      final androidDetails = AndroidNotificationDetails(
        overdueCardsChannelId,
        'Overdue Cards',
        channelDescription: 'Reminders for cards that need review',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
        autoCancel: true,
        ongoing: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'STUDY_REMINDER',
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for each selected day
      for (final dayOfWeek in daysOfWeek) {
        final scheduledTime = _nextInstanceOfDay(time, dayOfWeek);
        
        await _notifications.zonedSchedule(
          studyStreakId + dayOfWeek, // Unique ID for each day
          'Study Reminder 📚',
          'Time to review your flashcards!',
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'study_reminder',
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        
        print('Scheduled study reminder for ${scheduledTime.toString()}: ${time.hour}:${time.minute.toString().padLeft(2, '0')} on day $dayOfWeek');
      }
    } catch (e) {
      print('Error scheduling study reminder notifications: $e');
    }
  }

  Future<void> _cancelStudyReminderNotifications() async {
    try {
      // Cancel all study reminder notifications (IDs 3001-3007 for each day of week)
      for (int i = 1; i <= 7; i++) {
        await _notifications.cancel(studyStreakId + i);
      }
      print('Cancelled all study reminder notifications');
    } catch (e) {
      print('Error cancelling study reminder notifications: $e');
    }
  }

  // Helpers - Updated for deck-level scheduling
  Future<List<Flashcard>> getOverdueCards() async {
    try {
      // With deck-level scheduling, individual cards no longer have nextReview dates
      // This method is kept for backward compatibility but returns empty list
      // Overdue functionality is now handled at the deck level
      return [];
    } catch (e) {
      print('Error getting overdue cards: $e');
      return [];
    }
  }

  Future<List<Flashcard>> getCardsDueToday() async {
    try {
      // With deck-level scheduling, individual cards no longer have nextReview dates
      // This method is kept for backward compatibility but returns empty list
      // Due functionality is now handled at the deck level
      return [];
    } catch (e) {
      print('Error getting cards due today: $e');
      return [];
    }
  }

  Future<List<Flashcard>> getCardsDueSoon() async {
    try {
      // With deck-level scheduling, individual cards no longer have nextReview dates
      // This method is kept for backward compatibility but returns empty list
      // Due functionality is now handled at the deck level
      return [];
    } catch (e) {
      print('Error getting cards due soon: $e');
      return [];
    }
  }

  Future<void> cancelAllNotifications() async => await _notifications.cancelAll();
  Future<void> cancelNotification(int id) async => await _notifications.cancel(id);

  // Remove the showImmediateNotification method as it's not needed for production

  tz.TZDateTime _nextInstanceOfDay(TimeOfDay time, int dayOfWeek) {
    // Use detected timezone or fallback to local
    final timezone = _detectedTimezone ?? tz.local;
    tz.TZDateTime now = tz.TZDateTime.now(timezone);
    final today = now.weekday;
    
    // If today is the target day and time hasn't passed, schedule for today
    if (today == dayOfWeek) {
      final todayScheduledTime = tz.TZDateTime(
        timezone, 
        now.year, 
        now.month, 
        now.day, 
        time.hour, 
        time.minute
      );
      
      if (todayScheduledTime.isAfter(now)) {
        print('Scheduling reminder for TODAY (day $dayOfWeek) at ${time.hour}:${time.minute} - Time: ${todayScheduledTime.toString()}');
        return todayScheduledTime;
      }
    }
    
    // Start with today at the specified time
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      timezone, 
      now.year, 
      now.month, 
      now.day, 
      time.hour, 
      time.minute
    );

    // If the time has already passed today, start from tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Find the next occurrence of the specified day of the week
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print('Scheduling reminder for day $dayOfWeek (${_getDayName(dayOfWeek)}) at ${time.hour}:${time.minute} - Next occurrence: ${scheduledDate.toString()}');
    return scheduledDate;
  }

  String _getDayName(int day) {
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return dayNames[day - 1];
  }

  Future<void> _saveReminderSettings(TimeOfDay time, List<int> daysOfWeek) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('reminder_hour', time.hour);
      await prefs.setInt('reminder_minute', time.minute);
      await prefs.setStringList('reminder_days', daysOfWeek.map((d) => d.toString()).toList());
      print('Saved reminder settings: ${time.hour}:${time.minute} on days $daysOfWeek');
    } catch (e) {
      print('Error saving reminder settings: $e');
    }
  }

  Future<Map<String, dynamic>?> getReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('reminder_hour');
      final minute = prefs.getInt('reminder_minute');
      final daysList = prefs.getStringList('reminder_days');
      if (hour == null || minute == null || daysList == null) return null;
      final days = daysList.map((d) => int.parse(d)).toList();
      return {'time': TimeOfDay(hour: hour, minute: minute), 'daysOfWeek': days};
    } catch (e) {
      print('Error getting reminder settings: $e');
      return null;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  Future<bool> requestNotificationPermissions() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Method to check and reschedule notifications if needed
  Future<void> checkAndRescheduleNotifications() async {
    try {
      final settings = await getReminderSettings();
      if (settings != null) {
        print('Rescheduling daily reminders with settings: ${settings['time']} on days ${settings['daysOfWeek']}');
        await scheduleDailyReminder(
          time: settings['time'] as TimeOfDay,
          daysOfWeek: List<int>.from(settings['daysOfWeek']),
        );
      } else {
        print('No reminder settings found - skipping reschedule');
      }
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  // Method to manually trigger daily reminders for testing
  Future<void> triggerDailyReminders() async {
    try {
      final settings = await getReminderSettings();
      if (settings != null) {
        print('Manually triggering daily reminders...');
        await scheduleDailyReminder(
          time: settings['time'] as TimeOfDay,
          daysOfWeek: List<int>.from(settings['daysOfWeek']),
        );
      } else {
        print('No reminder settings found');
      }
    } catch (e) {
      print('Error triggering daily reminders: $e');
    }
  }

  // Method to cancel and reschedule all daily reminders (for testing)
  Future<void> cancelAndRescheduleDailyReminders() async {
    try {
      print('Cancelling all daily reminders...');
      await _cancelDailyReminders();
      
      final settings = await getReminderSettings();
      if (settings != null) {
        print('Rescheduling daily reminders...');
        await scheduleDailyReminder(
          time: settings['time'] as TimeOfDay,
          daysOfWeek: List<int>.from(settings['daysOfWeek']),
        );
      } else {
        print('No reminder settings found');
      }
    } catch (e) {
      print('Error cancelling and rescheduling daily reminders: $e');
    }
  }

  // Method to schedule a reminder for today at a specific time (for testing)
  Future<void> scheduleReminderForToday(TimeOfDay time) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      final today = now.weekday;
      
      // Check if the time has already passed today
      final scheduledTime = tz.TZDateTime(
        tz.local, 
        now.year, 
        now.month, 
        now.day, 
        time.hour, 
        time.minute
      );
      
      if (scheduledTime.isBefore(now)) {
        print('Time ${time.hour}:${time.minute} has already passed today. Scheduling for tomorrow.');
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        dailyReminderChannelId,
        'Daily Study Reminders',
        channelDescription: 'Reminders to study your flashcards daily',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for today
      await _notifications.zonedSchedule(
        dailyReminderId + today,
        'Time to Study! 📚',
        'You have flashcards waiting for review. Keep your streak going!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('Scheduled reminder for TODAY at ${time.hour}:${time.minute} - Time: ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling reminder for today: $e');
    }
  }

  // Helper method to check if a time can be scheduled for today
  bool canScheduleForToday(TimeOfDay time) {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return scheduledTime.isAfter(now);
  }

  // Debug method to get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Debug method to print all pending notifications
  Future<void> printPendingNotifications() async {
    try {
      final pending = await getPendingNotifications();
      print('=== PENDING NOTIFICATIONS ===');
      if (pending.isEmpty) {
        print('No pending notifications');
      } else {
        for (final notification in pending) {
          print('ID: ${notification.id}, Title: ${notification.title}, Body: ${notification.body}');
        }
      }
      print('=============================');
    } catch (e) {
      print('Error printing pending notifications: $e');
    }
  }

  // Debug method to check notification channel status
  Future<void> checkNotificationChannels() async {
    try {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        print('=== NOTIFICATION CHANNELS ===');
        
        // Check if channels exist
        final channels = await androidPlugin.getNotificationChannels();
        if (channels != null && channels.isNotEmpty) {
          for (final channel in channels) {
            print('Channel: ${channel.id} - ${channel.name}');
            print('  Importance: ${channel.importance}');
            print('  Sound: ${channel.playSound}');
            print('  Vibration: ${channel.enableVibration}');
            print('  Show Badge: ${channel.showBadge}');
          }
        } else {
          print('No notification channels found');
        }
        
        // Check notification permissions
        final areEnabled = await androidPlugin.areNotificationsEnabled();
        print('Notifications enabled: $areEnabled');
        
        print('=============================');
      }
    } catch (e) {
      print('Error checking notification channels: $e');
    }
  }

  // Debug method to test basic notification functionality
  Future<void> testBasicNotificationSystem() async {
    try {
      print('=== TESTING BASIC NOTIFICATION SYSTEM ===');
      
      // Check permissions
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final areEnabled = await androidPlugin.areNotificationsEnabled();
        print('Android notifications enabled: $areEnabled');
        
        if (areEnabled == false) {
          print('❌ NOTIFICATIONS ARE DISABLED - This is the problem!');
          print('Please enable notifications in device settings');
          return;
        }
      }
      
      // Check channels
      await checkNotificationChannels();
      
      // Test immediate notification
      print('Testing immediate notification...');
      await testNotification();
      
      // Check if immediate notification worked
      await Future.delayed(const Duration(seconds: 2));
      print('Immediate notification test completed');
      
      print('=== END BASIC TEST ===');
    } catch (e) {
      print('❌ Error in basic notification test: $e');
    }
  }

  // Debug method to test notifications (only use during development)
  Future<void> testNotification() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        immediateChannelId,
        'Immediate Notifications',
        channelDescription: 'Immediate notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Test Notification',
        'This is a test notification to verify the system works!',
        details,
      );
      
      print('Test notification sent successfully');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Debug method to test scheduled notifications with a short delay
  Future<void> testScheduledNotification() async {
    try {
      print('=== TESTING SCHEDULED NOTIFICATION ===');
      
      final androidDetails = AndroidNotificationDetails(
        dailyReminderChannelId,
        'Daily Study Reminders',
        channelDescription: 'Reminders to study your flashcards daily',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Schedule for 1 minute from now
      final now = tz.TZDateTime.now(tz.local);
      final scheduledTime = now.add(const Duration(minutes: 1));
      
      print('Current time: ${now.toString()}');
      print('Scheduled time: ${scheduledTime.toString()}');
      print('Time difference: ${scheduledTime.difference(now).inMinutes} minutes');
      
      await _notifications.zonedSchedule(
        9999, // Use a unique ID
        'Test Scheduled Notification',
        'This notification should appear in 1 minute!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('Scheduling completed successfully');
      print('Test scheduled notification set for ${scheduledTime.toString()} (1 minute from now)');
      
      // Verify it was scheduled
      final pending = await getPendingNotifications();
      final testNotification = pending.where((n) => n.id == 9999).firstOrNull;
      if (testNotification != null) {
        print('✅ Test notification successfully scheduled and found in pending list');
      } else {
        print('❌ Test notification NOT found in pending list - scheduling failed');
      }
      
      print('=== END TEST ===');
    } catch (e) {
      print('❌ Error scheduling test notification: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Debug method to manually set timezone for testing
  Future<void> setTimezoneForTesting(String timezoneName) async {
    try {
      print('=== SETTING TIMEZONE FOR TESTING ===');
      print('Attempting to set timezone to: $timezoneName');
      
      final timezone = tz.getLocation(timezoneName);
      _detectedTimezone = timezone; // Store the timezone
      
      final now = tz.TZDateTime.now(timezone);
      final utcNow = tz.TZDateTime.now(tz.UTC);
      
      print('New local time: ${now.toString()}');
      print('UTC time: ${utcNow.toString()}');
      print('Timezone: ${timezone.name}');
      print('Offset: ${now.timeZoneOffset.inHours} hours');
      print('Timezone stored successfully!');
      
      print('=== END TIMEZONE SET ===');
    } catch (e) {
      print('Error setting timezone: $e');
    }
  }

  // Debug method to show time calculations
  Future<void> debugTimeCalculations(TimeOfDay time) async {
    try {
      print('=== DEBUG TIME CALCULATIONS ===');
      
      final timezone = _detectedTimezone ?? tz.local;
      final now = tz.TZDateTime.now(timezone);
      final utcNow = tz.TZDateTime.now(tz.UTC);
      print('Current local time: ${now.toString()}');
      print('Current UTC time: ${utcNow.toString()}');
      print('Detected timezone: ${timezone.name}');
      print('UTC timezone: ${tz.UTC.name}');
      print('Target time: ${time.hour}:${time.minute}');
      
      // Test each day of the week
      for (int day = 1; day <= 7; day++) {
        final scheduledTime = _nextInstanceOfDay(time, day);
        print('Day $day (${_getDayName(day)}): ${scheduledTime.toString()}');
        print('  Is in future: ${scheduledTime.isAfter(now)}');
        print('  Time until: ${scheduledTime.difference(now).inMinutes} minutes');
      }
      
      print('=== END DEBUG ===');
    } catch (e) {
      print('Error in time calculations: $e');
    }
  }

  // Scheduled Review Notification Methods
  Future<void> scheduleDeckReviewNotification(Deck deck) async {
    if (deck.scheduledReviewEnabled != true) {
      return;
    }
    if (deck.scheduledReviewTime == null) {
      return;
    }

    try {
      final timezone = _detectedTimezone ?? tz.local;
      final scheduledTime = tz.TZDateTime.from(deck.scheduledReviewTime!, timezone);
      
      // Don't schedule if the time has already passed
      if (scheduledTime.isBefore(tz.TZDateTime.now(timezone))) {
        print('Scheduled review time has already passed for deck: ${deck.name}');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'scheduled_review_channel',
        'Scheduled Review',
        channelDescription: 'Notifications for scheduled deck reviews',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2196F3),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Use deck ID as notification ID to avoid duplicates
      final notificationId = 5000 + (deck.id.hashCode % 1000);

      await _notifications.zonedSchedule(
        notificationId,
        'Time to Review: ${deck.name}',
        'Your scheduled review for "${deck.name}" is due now!',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'scheduled_review_${deck.id}',
      );

      print('Scheduled review notification set for deck "${deck.name}" at ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling deck review notification: $e');
    }
  }

  Future<void> cancelDeckReviewNotification(Deck deck) async {
    try {
      // Use the same ID generation logic as in scheduleDeckReviewNotification
      final notificationId = 5000 + (deck.id.hashCode % 1000);
      await _notifications.cancel(notificationId);
      print('Cancelled scheduled review notification for deck: ${deck.name}');
    } catch (e) {
      print('Error cancelling deck review notification: $e');
    }
  }

  Future<void> updateDeckReviewNotification(Deck deck) async {
    // Cancel existing notification and schedule new one
    await cancelDeckReviewNotification(deck);
    await scheduleDeckReviewNotification(deck);
  }

  // Method to check and schedule all deck review notifications
  Future<void> scheduleAllDeckReviewNotifications() async {
    try {
      final decks = await _dataService.getDecks();
      for (final deck in decks) {
        if (deck.scheduledReviewEnabled == true && deck.scheduledReviewTime != null) {
          await scheduleDeckReviewNotification(deck);
        }
      }
      print('Scheduled review notifications updated for all decks');
    } catch (e) {
      print('Error scheduling all deck review notifications: $e');
    }
  }

  // Show review now notification
  Future<void> showReviewNowNotification(String deckName, String question) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'review_now_channel',
        'Review Now',
        channelDescription: 'Notifications for cards due for review',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Review Now: $deckName',
        'Time to review: ${question.length > 50 ? question.substring(0, 50) + '...' : question}',
        details,
        payload: 'review_now',
      );
    } catch (e) {
      print('Error showing review now notification: $e');
    }
  }

  // Show overdue card notification
  Future<void> showOverdueCardNotification(String deckName, String question) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'overdue_cards_channel',
        'Overdue Cards',
        channelDescription: 'Notifications for overdue cards',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF5722),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Card Overdue: $deckName',
        'Time to review: ${question.length > 50 ? question.substring(0, 50) + '...' : question}',
        details,
        payload: 'overdue_card',
      );
    } catch (e) {
      print('Error showing overdue card notification: $e');
    }
  }

  // Schedule notification for next card review
  Future<void> scheduleCardReviewNotification(Flashcard flashcard, Deck deck, DateTime nextReview) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'card_review_channel',
        'Card Review',
        channelDescription: 'Notifications for scheduled card reviews',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Use flashcard ID as notification ID
      final notificationId = 6000 + (flashcard.id.hashCode % 1000);

      final timezone = _detectedTimezone ?? tz.local;
      final scheduledTime = tz.TZDateTime.from(nextReview, timezone);

      await _notifications.zonedSchedule(
        notificationId,
        'Review Due: ${deck.name}',
        'Time to review: ${flashcard.question.length > 50 ? flashcard.question.substring(0, 50) + '...' : flashcard.question}',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'card_review_${flashcard.id}',
      );

      print('Scheduled card review notification for ${flashcard.id} at ${scheduledTime.toString()}');
    } catch (e) {
      print('Error scheduling card review notification: $e');
    }
  }
}
