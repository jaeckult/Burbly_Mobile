# Streak and Daily Reminder Fixes

## Issues Identified and Fixed

### 1. **Streak Calculation Bug** 🐛

**Problem**: The streak was incrementing every time the user studied, even on the same day, causing the streak to increase indefinitely.

**Root Cause**: In `background_service.dart`, the `updateStudyStreak()` method had this logic:
```dart
if (daysSinceLastStudy == 0) {
  // Same day, increment streak  ← WRONG!
  final currentStreak = prefs.getInt('current_streak') ?? 0;
  await prefs.setInt('current_streak', currentStreak + 1);
}
```

**Fix Applied**: Changed the logic to maintain the current streak on the same day:
```dart
if (daysSinceLastStudy == 0) {
  // Same day - don't increment streak, just keep current value
  // This prevents the streak from increasing multiple times per day
  print('Same day study - maintaining current streak');
}
```

**How It Works Now**:
- **Same day**: Streak stays the same (no increment)
- **Consecutive day**: Streak increases by 1
- **Break in streak**: Streak resets to 1

### 2. **Daily Reminder Scheduling Issues** ⏰

**Problem**: Daily reminders were not being scheduled correctly due to flawed logic in the `_nextInstanceOfDay` method.

**Root Cause**: The method was adding 7 days when the time had passed, which could cause scheduling issues.

**Fix Applied**: Improved the scheduling logic:
```dart
tz.TZDateTime _nextInstanceOfDay(TimeOfDay time, int dayOfWeek) {
  tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  
  // Start with today at the specified time
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local, 
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

  print('Scheduling reminder for day $dayOfWeek at ${time.hour}:${time.minute} - Next occurrence: ${scheduledDate.toString()}');
  return scheduledDate;
}
```

**How It Works Now**:
1. Start with today at the specified time
2. If time has passed, move to tomorrow
3. Find the next occurrence of the specified day of the week
4. Schedule the notification for that exact time

## Testing the Fixes

### **Debug Tools Added**

The notification settings screen now includes debug tools (only visible in debug mode):

1. **Trigger Daily Reminders** - Manually triggers daily reminder scheduling
2. **Test Notification** - Sends a test notification
3. **Schedule for Today** - Schedules a reminder for today at the selected time (if time hasn't passed)
4. **Reset Streak** - Resets the study streak to 0
5. **Set Streak to 5** - Sets the study streak to 5 for testing

### **Testing Today's Reminders**

The system now includes today in the reminder scheduling if the time hasn't passed yet:

- **If time hasn't passed today**: Reminder will be scheduled for today
- **If time has passed today**: Reminder will be scheduled for the next occurrence
- **"Schedule for Today" button**: Automatically enables/disables based on whether the time can be scheduled for today
- **Immediate testing**: You can test notifications without waiting for the next scheduled day

### **Console Logging**

Added comprehensive logging to track:
- Streak calculation logic
- Daily reminder scheduling
- Notification service operations
- Background service execution

## How to Test

### **1. Test Streak Calculation**
1. Open the app and go to notification settings
2. Use the debug tools to reset and set streaks
3. Study some flashcards
4. Check the console logs for streak updates
5. Verify the streak only increases on consecutive days

### **2. Test Daily Reminders**
1. Set a daily reminder for a time that hasn't passed yet
2. Use "Trigger Daily Reminders" to manually schedule
3. Check console logs for scheduling information
4. Wait for the scheduled time to see if notification appears

### **3. Monitor Background Service**
1. Check console logs every 30 minutes
2. Look for "Background service execution" messages
3. Verify overdue cards detection
4. Check study streak celebrations

## Expected Behavior

### **Streak Calculation**
- **Day 1**: First study = streak 1
- **Day 1 (later)**: Additional study = streak still 1
- **Day 2**: Study = streak 2
- **Day 3**: Study = streak 3
- **Day 5**: Study = streak resets to 1 (break in streak)

### **Daily Reminders**
- Reminders scheduled for exact times on specified days
- If time has passed today, scheduled for next occurrence
- Notifications appear at the exact scheduled time
- Automatic rescheduling when needed

## Troubleshooting

### **If Streaks Still Wrong**
1. Check console logs for streak calculation messages
2. Use debug tools to reset and test streaks
3. Verify the `last_study_date` is being updated correctly
4. Check if multiple study sessions are happening on the same day

### **If Daily Reminders Not Working**
1. Check console logs for scheduling messages
2. Verify notification permissions are granted
3. Use "Trigger Daily Reminders" to manually test
4. Check if the scheduled time has already passed
5. Verify the selected days include today

### **Common Issues**
1. **Time zone problems**: Ensure device time zone is correct
2. **Permission issues**: Check notification permissions in device settings
3. **Background restrictions**: Some devices may restrict background services
4. **Battery optimization**: Disable battery optimization for the app

## Code Changes Summary

### **Files Modified**:
1. `background_service.dart` - Fixed streak calculation logic
2. `notification_service.dart` - Improved daily reminder scheduling
3. `notification_settings_screen.dart` - Added debug tools

### **Key Methods Fixed**:
- `updateStudyStreak()` - Streak calculation logic
- `_nextInstanceOfDay()` - Daily reminder scheduling
- Added debug methods for testing

### **New Features**:
- Debug tools for testing
- Comprehensive logging
- Manual reminder triggering
- Streak management tools

## Conclusion

The streak calculation and daily reminder scheduling should now work correctly. The system properly tracks consecutive study days and schedules notifications for the exact times and days specified by the user. Use the debug tools to test and verify the fixes are working as expected.
