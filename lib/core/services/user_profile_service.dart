import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static const String _profilePictureKey = 'user_profile_picture';
  static const String _profileNameKey = 'user_profile_name';
  static const String _profileEmailKey = 'user_profile_email';
  static const String _lastUpdatedKey = 'profile_last_updated';

  // Store user profile information in local storage
  Future<void> storeUserProfile({
    required String? photoURL,
    required String? displayName,
    required String? email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      
      // Store profile data
      if (photoURL != null) {
        await prefs.setString(_profilePictureKey, photoURL);
      }
      if (displayName != null) {
        await prefs.setString(_profileNameKey, displayName);
      }
      if (email != null) {
        await prefs.setString(_profileEmailKey, email);
      }
      await prefs.setString(_lastUpdatedKey, now);
      
      print('User profile stored successfully: $displayName ($email)');
    } catch (e) {
      print('Error storing user profile: $e');
    }
  }

  // Get stored profile picture URL
  Future<String?> getStoredProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profilePictureKey);
    } catch (e) {
      print('Error getting stored profile picture: $e');
      return null;
    }
  }

  // Get stored profile name
  Future<String?> getStoredProfileName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileNameKey);
    } catch (e) {
      print('Error getting stored profile name: $e');
      return null;
    }
  }

  // Get stored profile email
  Future<String?> getStoredProfileEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileEmailKey);
    } catch (e) {
      print('Error getting stored profile email: $e');
      return null;
    }
  }

  // Get last update timestamp
  Future<String?> getLastUpdated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUpdatedKey);
    } catch (e) {
      print('Error getting last updated: $e');
      return null;
    }
  }

  // Check if profile data is stale (older than 24 hours)
  Future<bool> isProfileDataStale() async {
    try {
      final lastUpdated = await getLastUpdated();
      if (lastUpdated == null) return true;
      
      final lastUpdateTime = DateTime.parse(lastUpdated);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);
      
      // Consider stale if older than 24 hours
      return difference.inHours > 24;
    } catch (e) {
      print('Error checking if profile data is stale: $e');
      return true;
    }
  }

  // Store profile from Firebase User
  Future<void> storeProfileFromFirebaseUser(User user) async {
    await storeUserProfile(
      photoURL: user.photoURL,
      displayName: user.displayName,
      email: user.email,
    );
  }

  // Clear stored profile data (useful for sign out)
  Future<void> clearStoredProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilePictureKey);
      await prefs.remove(_profileNameKey);
      await prefs.remove(_profileEmailKey);
      await prefs.remove(_lastUpdatedKey);
      print('Stored profile data cleared');
    } catch (e) {
      print('Error clearing stored profile: $e');
    }
  }

  // Get profile picture with fallback logic
  Future<String?> getProfilePictureWithFallback() async {
    // First try to get from Firebase Auth (most current)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.photoURL != null) {
      // Store it for future use
      await storeProfileFromFirebaseUser(currentUser!);
      return currentUser.photoURL;
    }
    
    // Fallback to stored profile picture
    final storedPicture = await getStoredProfilePicture();
    if (storedPicture != null) {
      return storedPicture;
    }
    
    // Return null to indicate no profile picture available
    return null;
  }

  // Get profile name with fallback logic
  Future<String?> getProfileNameWithFallback() async {
    // First try to get from Firebase Auth (most current)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null) {
      // Store it for future use
      await storeProfileFromFirebaseUser(currentUser!);
      return currentUser.displayName;
    }
    
    // Fallback to stored profile name
    final storedName = await getStoredProfileName();
    if (storedName != null) {
      return storedName;
    }
    
    // Fallback to email
    return currentUser?.email;
  }

  // Get profile email with fallback logic
  Future<String?> getProfileEmailWithFallback() async {
    // First try to get from Firebase Auth (most current)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.email != null) {
      // Store it for future use
      await storeProfileFromFirebaseUser(currentUser!);
      return currentUser.email;
    }
    
    // Fallback to stored profile email
    final storedEmail = await getStoredProfileEmail();
    if (storedEmail != null) {
      return storedEmail;
    }
    
    return null;
  }
}
