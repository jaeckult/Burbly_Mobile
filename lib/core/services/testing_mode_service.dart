import 'package:shared_preferences/shared_preferences.dart';

class TestingModeService {
  static final TestingModeService _instance = TestingModeService._internal();
  factory TestingModeService() => _instance;
  TestingModeService._internal();

  bool _isTestingMode = false;
  final List<Function(bool)> _listeners = [];

  bool get isTestingMode => _isTestingMode;

  // Add listener for testing mode changes
  void addListener(Function(bool) listener) {
    _listeners.add(listener);
  }

  // Remove listener
  void removeListener(Function(bool) listener) {
    _listeners.remove(listener);
  }

  // Set testing mode and notify listeners
  Future<void> setTestingMode(bool enabled) async {
    _isTestingMode = enabled;
    
    // Save to preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('testing_mode_enabled', enabled);
    } catch (e) {
      print('Error saving testing mode: $e');
    }
    
    // Notify all listeners
    for (final listener in _listeners) {
      try {
        listener(enabled);
      } catch (e) {
        print('Error notifying testing mode listener: $e');
      }
    }
  }

  // Load testing mode from preferences
  Future<void> loadTestingMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTestingMode = prefs.getBool('testing_mode_enabled') ?? false;
    } catch (e) {
      print('Error loading testing mode: $e');
      _isTestingMode = false;
    }
  }

  // Get testing intervals
  Duration get notificationInterval => _isTestingMode 
      ? const Duration(minutes: 1) 
      : const Duration(hours: 2);

  Duration get widgetDismissalInterval => _isTestingMode 
      ? const Duration(minutes: 2) 
      : const Duration(hours: 4);

  Duration get periodicRefreshInterval => _isTestingMode 
      ? const Duration(minutes: 1) 
      : const Duration(minutes: 15);

  Duration get notNowDismissalInterval => _isTestingMode 
      ? const Duration(minutes: 1) 
      : const Duration(hours: 1);

  Duration get mixedStudyRefreshInterval => _isTestingMode 
      ? const Duration(seconds: 30) 
      : const Duration(minutes: 5);
}


