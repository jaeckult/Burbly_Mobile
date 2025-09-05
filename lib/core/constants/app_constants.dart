class AppConstants {
  // App Information
  static const String appName = 'Burbly Flashcard';
  static const String appVersion = '1.0.0';
  
  // Hive Box Names
  static const String decksBoxName = 'decks';
  static const String flashcardsBoxName = 'flashcards';
  static const String deckPacksBoxName = 'deck_packs';
  static const String notesBoxName = 'notes';
  static const String studySessionsBoxName = 'study_sessions';
  
  // Hive Type IDs
  static const int deckTypeId = 0;
  static const int flashcardTypeId = 1;
  static const int deckPackTypeId = 2;
  static const int noteTypeId = 3;
  static const int studySessionTypeId = 4;
  
  // Default Values
  static const String defaultDeckColor = '2196F3';
  static const String defaultDeckPackColor = 'FF9800';
  static const int defaultTimerDuration = 30;
  static const double defaultEaseFactor = 2.5;
  static const int defaultInterval = 1;
  
  // Timer Options
  static const List<int> timerDurations = [5, 10, 15, 20, 30, 45, 60];
  
  // Deck Pack Colors
  static const List<String> deckPackColors = [
    'FF9800', // Orange
    '2196F3', // Blue
    '4CAF50', // Green
    'F44336', // Red
    '9C27B0', // Purple
    'FF5722', // Deep Orange
    '3F51B5', // Indigo
    '009688', // Teal
    '795548', // Brown
    '607D8B', // Blue Grey
  ];
  
  // Spaced Repetition Quality Ratings
  static const Map<int, String> qualityRatings = {
    1: 'Again',
    2: 'Hard',
    3: 'Good',
    4: 'Easy',
    5: 'Perfect',
  };
  
  // Study Session Constants
  static const int defaultStudyDays = 15;
  static const int maxStudyDays = 30;
  
  // UI Constants
  static const double cardElevation = 4.0;
  static const double cardBorderRadius = 16.0;
  static const double avatarRadius = 25.0;
  static const double chartHeight = 300.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Error Messages
  static const String initializationError = 'Failed to initialize DataService';
  static const String backupError = 'Backup failed';
  static const String signInRequired = 'You must be signed in to backup your data';
  static const String boxesNotAccessible = 'DataService has not been initialized or boxes are not accessible';
}
