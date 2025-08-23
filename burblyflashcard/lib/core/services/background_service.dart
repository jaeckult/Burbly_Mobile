import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'data_service.dart';

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final DataService _dataService = DataService();

  // Start background service
  Future<void> start() async {
    // Check every hour
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkOverdueCards();
    });

    // Also check when app starts
    await _checkOverdueCards();
  }

  // Stop background service
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // Check for overdue cards and schedule notifications
  Future<void> _checkOverdueCards() async {
    try {
      // Check if overdue reminders are enabled
      final prefs = await SharedPreferences.getInstance();
      final overdueRemindersEnabled = prefs.getBool('overdue_reminders_enabled') ?? true;
      
      if (!overdueRemindersEnabled) return;

      // Check if notifications are enabled
      final notificationsEnabled = await _notificationService.areNotificationsEnabled();
      if (!notificationsEnabled) return;

      // Get overdue cards
      final overdueCards = await _notificationService.getOverdueCards();
      
      if (overdueCards.isNotEmpty) {
        // Schedule overdue cards reminder
        await _notificationService.scheduleOverdueCardsReminder();
      }

      // Check for study streak
      await _checkStudyStreak();
    } catch (e) {
      print('Error in background service: $e');
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
          await _notificationService.scheduleStudyStreakReminder(currentStreak);
        }
      }
    } catch (e) {
      print('Error checking study streak: $e');
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
          // Same day, increment streak
          final currentStreak = prefs.getInt('current_streak') ?? 0;
          await prefs.setInt('current_streak', currentStreak + 1);
        } else if (daysSinceLastStudy == 1) {
          // Consecutive day, increment streak
          final currentStreak = prefs.getInt('current_streak') ?? 0;
          await prefs.setInt('current_streak', currentStreak + 1);
        } else {
          // Break in streak, reset to 1
          await prefs.setInt('current_streak', 1);
        }
      } else {
        // First study session
        await prefs.setInt('current_streak', 1);
      }
      
      await prefs.setString('last_study_date', todayString);
    } catch (e) {
      print('Error updating study streak: $e');
    }
  }

  // Get current study streak
  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('current_streak') ?? 0;
  }

  // Get last study date
  Future<DateTime?> getLastStudyDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStudyDate = prefs.getString('last_study_date');
    if (lastStudyDate != null) {
      return DateTime.parse(lastStudyDate);
    }
    return null;
  }
}
