# Offline Push Notifications Setup

This document explains how to set up and use the offline push notification system for the Burbly Flashcard app.

## Features

The notification system provides the following features:

1. **Daily Study Reminders** - Schedule reminders at specific times on selected days
2. **Overdue Cards Notifications** - Get notified when cards are overdue for review
3. **Study Streak Celebrations** - Celebrate maintaining study streaks
4. **Offline Support** - All notifications work without internet connection

## Setup Instructions

### 1. Install Dependencies

The following dependencies have been added to `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
```

Run `flutter pub get` to install the dependencies.

### 2. Android Permissions

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### 3. iOS Permissions

For iOS, the permissions are automatically requested when the app starts.

## Usage

### Accessing Notification Settings

1. Navigate to the notification settings screen:
   ```dart
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => const NotificationSettingsScreen(),
     ),
   );
   ```

2. Or use the notification widget that appears on the home screen when there are overdue cards.

### Configuring Notifications

#### Daily Reminders
- Set the time for daily reminders
- Select which days of the week to receive reminders
- Toggle daily reminders on/off

#### Overdue Cards
- Get notified when cards are overdue for review
- Notifications are scheduled automatically when cards become overdue

#### Study Streaks
- Celebrate maintaining study streaks
- Notifications are sent for streaks of 3+ days

### Adding Notification Widget to Screens

Add the notification widget to any screen to show overdue cards:

```dart
import 'package:your_app/features/flashcards/widgets/notification_widget.dart';

// In your widget build method:
Column(
  children: [
    const NotificationWidget(),
    // Your other widgets...
  ],
)
```

### Background Service

The background service automatically:
- Checks for overdue cards every hour
- Schedules notifications based on user preferences
- Tracks study streaks
- Updates streak data when users study

### Manual Notification Testing

Test notifications by calling:

```dart
await NotificationService().showImmediateNotification(
  title: 'Test Notification',
  body: 'This is a test notification!',
);
```

## API Reference

### NotificationService

#### Methods

- `initialize()` - Initialize the notification service
- `scheduleDailyReminder(time, daysOfWeek)` - Schedule daily reminders
- `scheduleOverdueCardsReminder()` - Schedule overdue cards notification
- `scheduleStudyStreakReminder(streakDays)` - Schedule streak celebration
- `getOverdueCards()` - Get list of overdue cards
- `getCardsDueToday()` - Get cards due today
- `getCardsDueSoon()` - Get cards due in next 3 days
- `showImmediateNotification(title, body)` - Show immediate notification
- `cancelAllNotifications()` - Cancel all scheduled notifications

### BackgroundService

#### Methods

- `start()` - Start the background service
- `stop()` - Stop the background service
- `updateStudyStreak()` - Update study streak when user studies
- `getCurrentStreak()` - Get current study streak
- `getLastStudyDate()` - Get last study date

## Troubleshooting

### Notifications Not Appearing

1. Check if notifications are enabled in device settings
2. Verify app permissions are granted
3. Check if notification settings are configured in the app
4. Ensure the background service is running

### Permissions Issues

1. For Android: Check if all required permissions are in AndroidManifest.xml
2. For iOS: Ensure notification permissions are granted when prompted
3. Restart the app after granting permissions

### Scheduling Issues

1. Check if the device supports exact alarm scheduling
2. Verify timezone settings are correct
3. Ensure the app is not being killed by the system

## Best Practices

1. **Request permissions early** - Ask for notification permissions when the app first starts
2. **Provide clear settings** - Make notification settings easily accessible
3. **Respect user preferences** - Allow users to disable specific notification types
4. **Test thoroughly** - Test notifications on both Android and iOS devices
5. **Handle edge cases** - Consider timezone changes and device restarts

## Offline Functionality

All notifications work offline because they use local notifications scheduled on the device. The system:

- Stores notification preferences locally
- Schedules notifications using the device's local notification system
- Works without internet connection
- Persists through app restarts

This ensures users always receive their study reminders, even when offline.
