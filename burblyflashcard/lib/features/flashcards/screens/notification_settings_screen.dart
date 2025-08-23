import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0); // Default 9:00 AM
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // All days by default
  bool _notificationsEnabled = false;
  bool _dailyRemindersEnabled = false;
  bool _overdueRemindersEnabled = false;
  bool _streakRemindersEnabled = false;
  bool _isLoading = true;

  final List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
    'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      _notificationsEnabled = await _notificationService.areNotificationsEnabled();
      
      final settings = await _notificationService.getReminderSettings();
      if (settings != null) {
        _selectedTime = settings['time'] as TimeOfDay;
        _selectedDays = List<int>.from(settings['daysOfWeek']);
        _dailyRemindersEnabled = true;
      }
      
      // Load other settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _overdueRemindersEnabled = prefs.getBool('overdue_reminders_enabled') ?? true;
      _streakRemindersEnabled = prefs.getBool('streak_reminders_enabled') ?? true;
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (_dailyRemindersEnabled) {
        await _notificationService.scheduleDailyReminder(
          time: _selectedTime,
          daysOfWeek: _selectedDays,
        );
      } else {
        // Cancel daily reminders
        for (int day = 1; day <= 7; day++) {
          await _notificationService.cancelNotification(
            NotificationService.dailyReminderId + day
          );
        }
      }

      // Save other settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('overdue_reminders_enabled', _overdueRemindersEnabled);
      await prefs.setBool('streak_reminders_enabled', _streakRemindersEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestNotificationPermissions();
    setState(() => _notificationsEnabled = granted);
    
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable notifications in your device settings.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      await _saveSettings();
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
    });
    _saveSettings();
  }

  void _toggleDailyReminders(bool value) {
    setState(() => _dailyRemindersEnabled = value);
    _saveSettings();
  }

  void _toggleOverdueReminders(bool value) {
    setState(() => _overdueRemindersEnabled = value);
    _saveSettings();
  }

  void _toggleStreakReminders(bool value) {
    setState(() => _streakRemindersEnabled = value);
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Permission Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
                          color: _notificationsEnabled ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Notification Permissions',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _notificationsEnabled 
                        ? 'Notifications are enabled'
                        : 'Notifications are disabled',
                      style: TextStyle(
                        color: _notificationsEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                    if (!_notificationsEnabled) ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _requestPermissions,
                        child: const Text('Enable Notifications'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Daily Reminders Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
  children: [
    const Icon(Icons.schedule, color: Colors.blue),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        'Daily Study Reminders',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis, // ensures text doesn’t overflow
      ),
    ),
    Switch(
      value: _dailyRemindersEnabled,
      onChanged: _notificationsEnabled ? _toggleDailyReminders : null,
    ),
  ],
),

                    
                    if (_dailyRemindersEnabled) ...[
                      const SizedBox(height: 16),
                      
                      // Time Selection
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Reminder Time'),
                        subtitle: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _selectTime,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Days Selection
                      const Text(
                        'Reminder Days',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
  spacing: 8,
  runSpacing: 8,
  children: List.generate(7, (index) {
    final day = index + 1;
    final isSelected = _selectedDays.contains(day);

    return GestureDetector(
      onTap: () => _toggleDay(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          _dayNames[index],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ),
    );
  }),
)

                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Overdue Cards Reminders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overdue Cards Reminders',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Get notified when cards are overdue for review',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _overdueRemindersEnabled,
                          onChanged: _notificationsEnabled ? _toggleOverdueReminders : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Study Streak Reminders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Colors.red),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Study Streak Celebrations',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Get celebrated for maintaining study streaks',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _streakRemindersEnabled,
                          onChanged: _notificationsEnabled ? _toggleStreakReminders : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Test Notification Button
            if (_notificationsEnabled)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _notificationService.showImmediateNotification(
                      title: 'Test Notification',
                      body: 'This is a test notification from Burbly Flashcard!',
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Send Test Notification'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
