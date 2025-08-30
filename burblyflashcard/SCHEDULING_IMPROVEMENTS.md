# Scheduling Improvements: Early Review Handling

## Overview

This document describes the improvements made to the flashcard scheduling system to handle cases where users review cards before their scheduled review time.

## Problem Statement

Previously, when a user reviewed a card before its scheduled review time, the system would calculate the new interval based on the previously scheduled time, which could lead to confusing scheduling behavior and didn't reflect the user's actual study session timing.

## Solution

The system now:
1. **Captures the previously scheduled review time** when calculating study results
2. **Calculates new schedules starting from `now()`** instead of the previously scheduled time
3. **Shows the previously planned time with a strike-through** in the consent screen
4. **Provides clear visual feedback** about early reviews

## Technical Changes

### 1. StudyResult Model Updates

Added a new field to track previously scheduled review times:

```dart
class StudyResult {
  // ... existing fields ...
  final DateTime? previouslyScheduledReview; // New field
}
```

### 2. Study Service Updates

Both `StudyService` and `FSRSStudyService` now:
- Capture the previously scheduled review time before calculating new intervals
- Calculate new review dates starting from `DateTime.now()` instead of the previous schedule
- Include the previously scheduled time in the study result

**Before:**
```dart
// Old behavior - calculated from previous schedule
final nextReview = _calculateNextReview(card.nextReview ?? now, newInterval);
```

**After:**
```dart
// New behavior - always calculate from now()
final previouslyScheduledReview = card.nextReview;
final nextReview = _calculateNextReview(now, newInterval);
```

### 3. Consent Dialog Enhancements

The scheduling consent dialog now:
- Shows an orange info box when cards were reviewed early
- Displays previously scheduled times with strike-through formatting
- Shows the new review date clearly
- Provides visual context about the scheduling changes

**Visual Elements:**
- **Info Box**: "Some cards were reviewed early! New schedules start from now."
- **Strike-through**: Previously scheduled dates are shown with line-through styling
- **New Dates**: New review dates are prominently displayed in green/red

## User Experience

### Before the Change
- Users might be confused about why their next review was scheduled far in the future
- No clear indication that they reviewed a card early
- Scheduling seemed inconsistent with actual study timing

### After the Change
- Users see exactly when they were supposed to review the card
- Clear indication that new schedules start from the current study session
- Transparent scheduling that matches actual study behavior
- Visual feedback helps users understand the impact of early reviews

## Example Scenario

**Card State:**
- Card scheduled for review on January 15th
- User reviews the card on January 10th (5 days early)
- User rates the card as "Good"

**Old Behavior:**
- New interval: 14 days
- Next review: January 24th (calculated from January 15th)

**New Behavior:**
- New interval: 14 days  
- Next review: January 24th (calculated from January 10th)
- Consent screen shows: ~~January 15th~~ → January 24th

## Benefits

1. **Transparency**: Users can see exactly when they were supposed to review cards
2. **Consistency**: New schedules always start from the actual study session
3. **User Control**: Clear understanding of how early reviews affect scheduling
4. **Better Learning**: Schedules that reflect actual study timing
5. **Visual Clarity**: Strike-through formatting makes early reviews obvious

## Implementation Details

### Files Modified
- `lib/core/models/study_result.dart` - Added `previouslyScheduledReview` field
- `lib/core/services/study_service.dart` - Updated calculation logic
- `lib/core/services/fsrs_study_service.dart` - Updated calculation logic  
- `lib/core/widgets/scheduling_consent_dialog.dart` - Enhanced UI display

### Backward Compatibility
- The new field is optional, so existing code continues to work
- Legacy methods have been updated to maintain consistency
- No breaking changes to existing APIs

### Testing
The feature can be tested by:
1. Creating a card with a future scheduled review time
2. Reviewing the card before the scheduled time
3. Checking the consent screen for strike-through formatting
4. Verifying that new schedules start from the current time

## Future Enhancements

Potential improvements could include:
- Statistics tracking for early vs. on-time reviews
- User preferences for early review handling
- More detailed explanations of scheduling changes
- Historical view of scheduling adjustments
