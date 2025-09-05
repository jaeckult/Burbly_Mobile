import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'data_service.dart';
import 'pet_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();

  // Start background service
  Future<void> start() async {
    // Check every 30 minutes for better responsiveness
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      _checkNotifications();
    });

    // Also check when app starts
    await _checkNotifications();
  }

  // Stop background service
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // Main notification check method
  Future<void> _checkNotifications() async {
    try {
      // Check if notifications are enabled
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      if (!notificationsEnabled) return;

      // Check overdue cards
      await _checkOverdueCards();
      
      // Check study streak
      await _checkStudyStreak();
      
      // Check if we need to reschedule daily reminders
      await _checkDailyReminders();
      
      // Check pet notifications
      await _checkPetNotifications();
    } catch (e) {
      print('Error in background service: $e');
    }
  }

  // Check for overdue cards and schedule notifications
  Future<void> _checkOverdueCards() async {
    try {
      // Check if overdue reminders are enabled
      final prefs = await SharedPreferences.getInstance();
      final overdueRemindersEnabled = prefs.getBool('overdue_reminders_enabled') ?? true;
      
      if (!overdueRemindersEnabled) return;

      // Get overdue cards
      final overdueCards = await _notificationService.getOverdueCards();
      
      if (overdueCards.isNotEmpty) {
        // Check if we already have a scheduled reminder
        final lastOverdueCheck = prefs.getString('last_overdue_check');
        final now = DateTime.now();
        
        final hoursSince = lastOverdueCheck == null
            ? 999
            : now.difference(DateTime.parse(lastOverdueCheck)).inHours;

        // Daily alarm for overdue: schedule once per day when overdue exists
        if (hoursSince >= 24) {
          await _notificationService.scheduleOverdueCardsReminder();
          await prefs.setString('last_overdue_check', now.toIso8601String());
          print('Scheduled daily overdue reminder for ${overdueCards.length} cards');
        }
      }
    } catch (e) {
      print('Error checking overdue cards: $e');
    }
  }

  // Check study streak and schedule celebration notification
  Future<void> _checkStudyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakRemindersEnabled = prefs.getBool('streak_reminders_enabled') ?? true;
      
      if (!streakRemindersEnabled) return;

      // Get current streak
      final currentStreak = prefs.getInt('current_streak') ?? 0;
      final lastStudyDate = prefs.getString('last_study_date');
      
      if (currentStreak > 0 && lastStudyDate != null) {
        final lastStudy = DateTime.parse(lastStudyDate);
        final today = DateTime.now();
        final daysSinceLastStudy = today.difference(lastStudy).inDays;
        
        // If user has maintained streak for multiple days, celebrate
        if (daysSinceLastStudy == 0 && currentStreak >= 3) {
          // Check if we already celebrated today
          final lastCelebration = prefs.getString('last_streak_celebration');
          if (lastCelebration == null || 
              !today.isAtSameMomentAs(DateTime.parse(lastCelebration))) {
            await _notificationService.scheduleStudyStreakReminder(currentStreak);
            await prefs.setString('last_streak_celebration', today.toIso8601String());
            print('Scheduled study streak celebration for $currentStreak days');
          }
        }
      }
    } catch (e) {
      print('Error checking study streak: $e');
    }
  }

  // Check if daily reminders need to be rescheduled
  Future<void> _checkDailyReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastReminderCheck = prefs.getString('last_reminder_check');
      final now = DateTime.now();
      
      // Check once per day
      if (lastReminderCheck == null || 
          now.difference(DateTime.parse(lastReminderCheck)).inDays >= 1) {
        
        await _notificationService.checkAndRescheduleNotifications();
        await prefs.setString('last_reminder_check', now.toIso8601String());
        print('Checked and rescheduled daily reminders');
      }
    } catch (e) {
      print('Error checking daily reminders: $e');
    }
  }

  // Check pet notifications
  Future<void> _checkPetNotifications() async {
    try {
      final petService = PetService();
      await petService.initialize();
      final currentPet = petService.getCurrentPet();
      
      if (currentPet != null) {
        final stats = petService.getPetStats(currentPet);
        final hoursSinceLastVisit = stats['hoursSincePlayed'] as int;
        
        // Send pet notification if user hasn't visited for a while
        if (hoursSinceLastVisit >= 6) {
          final message = petService.getPersonalizedNotificationMessage(currentPet);
          await _notificationService.schedulePetNotification(message, delayHours: 1);
        }
        
        // Send status-based notifications
        if (stats['hunger'] > 70 || stats['happiness'] < 30) {
          final statusMessage = petService.getPetStatusMessage(currentPet);
          await _notificationService.schedulePetNotification(statusMessage, delayHours: 2);
        }
      }
    } catch (e) {
      print('Error checking pet notifications: $e');
    }
  }

  // Update study streak when user studies
  Future<void> updateStudyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayString = today.toIso8601String();
      final lastStudyDate = prefs.getString('last_study_date');
      
      if (lastStudyDate != null) {
        final lastStudy = DateTime.parse(lastStudyDate);
        final daysSinceLastStudy = today.difference(lastStudy).inDays;
        
        if (daysSinceLastStudy == 0) {
          // Same day - don't increment streak, just keep current value
          // This prevents the streak from increasing multiple times per day
          print('Same day study - maintaining current streak');
        } else if (daysSinceLastStudy == 1) {
          // Consecutive day - increment streak
          final currentStreak = prefs.getInt('current_streak') ?? 0;
          final newStreak = currentStreak + 1;
          await prefs.setInt('current_streak', newStreak);
          print('Consecutive day study - streak increased from $currentStreak to $newStreak');
        } else {
          // Break in streak - reset to 1
          await prefs.setInt('current_streak', 1);
          print('Break in streak - reset to 1');
        }
      } else {
        // First study session
        await prefs.setInt('current_streak', 1);
        print('First study session - streak set to 1');
      }
      
      await prefs.setString('last_study_date', todayString);
      
      // Trigger notification check after updating streak
      _checkNotifications();
    } catch (e) {
      print('Error updating study streak: $e');
    }
  }

  // Get current study streak
  Future<int> getCurrentStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('current_streak') ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  // Get last study date
  Future<DateTime?> getLastStudyDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastStudyDate = prefs.getString('last_study_date');
      if (lastStudyDate != null) {
        return DateTime.parse(lastStudyDate);
      }
      return null;
    } catch (e) {
      print('Error getting last study date: $e');
      return null;
    }
  }

  // Method to manually trigger notification check
  Future<void> triggerNotificationCheck() async {
    await _checkNotifications();
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final overdueRemindersEnabled = prefs.getBool('overdue_reminders_enabled') ?? true;
      final streakRemindersEnabled = prefs.getBool('streak_reminders_enabled') ?? true;
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      
      return {
        'notificationsEnabled': notificationsEnabled,
        'overdueRemindersEnabled': overdueRemindersEnabled,
        'streakRemindersEnabled': streakRemindersEnabled,
        'currentStreak': await getCurrentStreak(),
        'lastStudyDate': await getLastStudyDate(),
      };
    } catch (e) {
      print('Error getting notification stats: $e');
      return {};
    }
  }

  // Debug method to reset study streak (only for testing)
  Future<void> resetStudyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_streak');
      await prefs.remove('last_study_date');
      await prefs.remove('last_streak_celebration');
      print('Study streak reset successfully');
    } catch (e) {
      print('Error resetting study streak: $e');
    }
  }

  // Debug method to set a specific streak value (only for testing)
  Future<void> setStudyStreak(int streak) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_streak', streak);
      print('Study streak set to $streak');
    } catch (e) {
      print('Error setting study streak: $e');
    }
  }
}
