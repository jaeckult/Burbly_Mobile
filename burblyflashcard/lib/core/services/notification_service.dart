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
    // TODO: Handle navigation when user taps a notification
    // For now, we'll just log the tap
    print('Notification tapped: ${response.payload}');
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

  // Helpers
  Future<List<Flashcard>> getOverdueCards() async {
    try {
      final now = DateTime.now();
      final allCards = await _dataService.getAllFlashcards();
      return allCards.where((c) => c.nextReview != null && c.nextReview!.isBefore(now)).toList();
    } catch (e) {
      print('Error getting overdue cards: $e');
      return [];
    }
  }

  Future<List<Flashcard>> getCardsDueToday() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final allCards = await _dataService.getAllFlashcards();
      return allCards.where((c) {
        if (c.nextReview == null) return false;
        final reviewDate = DateTime(c.nextReview!.year, c.nextReview!.month, c.nextReview!.day);
        return reviewDate.isAtSameMomentAs(today);
      }).toList();
    } catch (e) {
      print('Error getting cards due today: $e');
      return [];
    }
  }

  Future<List<Flashcard>> getCardsDueSoon() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      final allCards = await _dataService.getAllFlashcards();
      return allCards.where((c) => c.nextReview != null && c.nextReview!.isAfter(now) && c.nextReview!.isBefore(threeDaysFromNow)).toList();
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
}
