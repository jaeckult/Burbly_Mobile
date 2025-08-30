# Profile Picture Storage Implementation

This document describes the implementation of profile picture storage in local storage with fallback functionality.

## Overview

When users sign in with Google, their profile picture, display name, and email are automatically stored in local storage (SharedPreferences) for faster retrieval and offline access.

## Features

- **Automatic Storage**: Profile data is stored when signing in with Google
- **Smart Fallback**: Falls back to stored data when Firebase Auth data is unavailable
- **Automatic Cleanup**: Profile data is cleared when signing out
- **Fallback Icons**: Shows user initials or default person icon when no profile picture is available
- **Data Freshness**: Automatically updates stored data when fresh data is available

## Components

### 1. UserProfileService (`lib/core/services/user_profile_service.dart`)

Core service that handles:
- Storing profile data in SharedPreferences
- Retrieving stored profile data
- Managing data freshness (24-hour staleness check)
- Clearing profile data on sign out

**Key Methods:**
- `storeProfileFromFirebaseUser(User user)` - Store profile from Firebase User
- `getProfilePictureWithFallback()` - Get profile picture with smart fallback
- `getProfileNameWithFallback()` - Get profile name with fallback
- `clearStoredProfile()` - Clear all stored profile data

### 2. ProfileAvatar Widget (`lib/core/widgets/profile_avatar.dart`)

Reusable widget that:
- Automatically loads profile pictures
- Handles loading states
- Provides fallback to user initials or default icon
- Supports custom styling (borders, colors, sizes)

**Widget Types:**
- `ProfileAvatar` - Generic profile avatar with custom fallback
- `UserProfileAvatar` - Specialized avatar that shows user initials as fallback

### 3. AuthService Integration

The `AuthService` has been updated to:
- Automatically store profile data when signing in with Google
- Clear profile data when signing out
- Maintain data consistency between Firebase Auth and local storage

## Usage Examples

### Basic Profile Avatar
```dart
UserProfileAvatar(
  radius: 30,
  backgroundColor: Colors.white,
)
```

### Custom Profile Avatar
```dart
ProfileAvatar(
  radius: 40,
  showBorder: true,
  borderColor: Colors.blue,
  borderWidth: 3,
  fallbackIcon: Icon(Icons.account_circle),
)
```

### Direct Service Usage
```dart
final userProfileService = UserProfileService();

// Store profile data
await userProfileService.storeProfileFromFirebaseUser(user);

// Get profile picture with fallback
final profilePicture = await userProfileService.getProfilePictureWithFallback();

// Clear stored data
await userProfileService.clearStoredProfile();
```

## Data Storage Keys

Profile data is stored in SharedPreferences with these keys:
- `user_profile_picture` - Profile picture URL
- `user_profile_name` - Display name
- `user_profile_email` - Email address
- `profile_last_updated` - Timestamp of last update

## Fallback Strategy

1. **Primary**: Firebase Auth current user data (most fresh)
2. **Secondary**: Stored local data (cached)
3. **Tertiary**: User initials (derived from name/email)
4. **Final**: Default person icon

## Testing

A `ProfileDemoScreen` is available for testing the profile functionality:

- **Access**: Available in the app bar of HomeScreen and in drawer menus
- **Features**: 
  - View current Firebase user data
  - View stored profile data
  - Test profile avatar widgets
  - Refresh/clear profile data
  - Test different avatar sizes and styles

## Implementation Notes

### Performance
- Profile data is loaded asynchronously to avoid blocking UI
- Network images are cached and have error handling
- Data staleness is checked to ensure freshness

### Error Handling
- Graceful fallbacks when network images fail to load
- Safe storage operations with try-catch blocks
- Automatic cleanup of invalid data

### Security
- Profile data is stored locally only
- No sensitive information is exposed
- Data is cleared on sign out

## Future Enhancements

1. **Image Caching**: Implement proper image caching for offline access
2. **Multiple Sizes**: Support different profile picture sizes
3. **Custom Avatars**: Allow users to upload custom profile pictures
4. **Sync**: Sync profile data across devices via Firestore
5. **Compression**: Optimize stored image sizes

## Debug Features

The following debug features are available (remove in production):
- Profile Demo screen accessible from multiple locations
- Console logging for profile operations
- Manual profile data refresh/clear options

## Dependencies

- `shared_preferences` - Local storage
- `firebase_auth` - User authentication
- `google_sign_in` - Google authentication

## Files Modified

- `lib/core/services/user_profile_service.dart` - New service
- `lib/core/widgets/profile_avatar.dart` - New widgets
- `lib/core/widgets/profile_demo_screen.dart` - Debug screen
- `lib/features/auth/auth_service.dart` - Integration
- `lib/core/core.dart` - Exports
- Various screen files - UI integration

## Testing Checklist

- [ ] Sign in with Google stores profile data
- [ ] Profile avatars display correctly
- [ ] Fallback to initials works
- [ ] Fallback to default icon works
- [ ] Profile data persists across app restarts
- [ ] Profile data clears on sign out
- [ ] Network image errors are handled gracefully
- [ ] Profile demo screen works correctly
- [ ] Different avatar sizes display properly
- [ ] Custom styling options work
