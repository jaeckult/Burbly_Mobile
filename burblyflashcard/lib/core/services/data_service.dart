import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/deck_pack.dart';
import '../models/note.dart';
import '../models/pet.dart';
import '../models/study_session.dart';

class DataService {
  static const String _decksBoxName = 'decks';
  static const String _flashcardsBoxName = 'flashcards';
  static const String _deckPacksBoxName = 'deck_packs';
  static const String _notesBoxName = 'notes';
  static const String _studySessionsBoxName = 'study_sessions';
  
  // Singleton instance
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();
  
  late Box<Deck> _decksBox;
  late Box<Flashcard> _flashcardsBox;
  late Box<DeckPack> _deckPacksBox;
  late Box<Note> _notesBox;
  late Box<StudySession> _studySessionsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitialized = false;

  // Initialize Hive boxes
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations
    
    try {
      // Check if Hive is already initialized
      if (!Hive.isBoxOpen(_decksBoxName)) {
        await Hive.initFlutter();
        
        // Register adapters only if not already registered
        if (!Hive.isAdapterRegistered(0)) {
          Hive.registerAdapter(DeckAdapter());
        }
        if (!Hive.isAdapterRegistered(1)) {
          Hive.registerAdapter(FlashcardAdapter());
        }
        if (!Hive.isAdapterRegistered(2)) {
          Hive.registerAdapter(DeckPackAdapter());
        }
        if (!Hive.isAdapterRegistered(3)) {
          Hive.registerAdapter(NoteAdapter());
        }
        if (!Hive.isAdapterRegistered(4)) {
          Hive.registerAdapter(StudySessionAdapter());
        }
        if (!Hive.isAdapterRegistered(5)) {
          Hive.registerAdapter(PetAdapter());
        }
        if (!Hive.isAdapterRegistered(6)) {
          Hive.registerAdapter(PetTypeAdapter());
        }
        if (!Hive.isAdapterRegistered(7)) {
          Hive.registerAdapter(PetMoodAdapter());
        }
        if (!Hive.isAdapterRegistered(8)) {
          Hive.registerAdapter(PetStageAdapter());
        }
      }
      
      // Open boxes - this will preserve existing data
      _decksBox = await Hive.openBox<Deck>(_decksBoxName);
      _flashcardsBox = await Hive.openBox<Flashcard>(_flashcardsBoxName);
      _deckPacksBox = await Hive.openBox<DeckPack>(_deckPacksBoxName);
      _notesBox = await Hive.openBox<Note>(_notesBoxName);
      _studySessionsBox = await Hive.openBox<StudySession>(_studySessionsBoxName);
      
      _isInitialized = true;
      
      // Log data status for debugging
      print('DataService initialized successfully');
      print('Decks: ${_decksBox.length}');
      print('Flashcards: ${_flashcardsBox.length}');
      print('Deck Packs: ${_deckPacksBox.length}');
      print('Notes: ${_notesBox.length}');
      print('Study Sessions: ${_studySessionsBox.length}');
      
      // Check if this might be a hot restart
      if (kDebugMode) {
        await _handlePotentialHotRestart();
      }
    } catch (e) {
      _isInitialized = false;
      print('Error initializing DataService: $e');
      throw Exception('Failed to initialize DataService: ${e.toString()}');
    }
  }

  // Handle potential hot restart scenarios
  Future<void> _handlePotentialHotRestart() async {
    try {
      // Check if we have data but it seems like a fresh start
      final totalItems = _decksBox.length + _flashcardsBox.length + _deckPacksBox.length + _notesBox.length + _studySessionsBox.length;
      
      if (totalItems == 0) {
        print('⚠️  WARNING: No data found after initialization. This might indicate:');
        print('   - First app launch');
        print('   - Data was cleared manually');
        print('   - Hot restart issue');
        print('   - Storage permission issue');
        
        // Try to check if this is really the first launch
        final prefs = await SharedPreferences.getInstance();
        final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
        
        if (isFirstLaunch) {
          print('✅ This appears to be the first app launch');
          await prefs.setBool('isFirstLaunch', false);
        } else {
          print('❌ This is NOT the first launch but no data found - potential issue!');
        }
      } else {
        print('✅ Data found: $totalItems items - persistence working correctly');
      }
    } catch (e) {
      print('Error handling hot restart check: $e');
    }
  }

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Check if boxes are accessible
  bool get areBoxesAccessible => _isInitialized && _decksBox.isOpen && _flashcardsBox.isOpen && _deckPacksBox.isOpen && _notesBox.isOpen && _studySessionsBox.isOpen;

  // Force reinitialize if needed
  Future<void> reinitialize() async {
    if (_isInitialized) {
      // Safely close existing boxes first
      await _safeCloseBoxes();
    }
    _isInitialized = false;
    await initialize();
  }

  // Safely close all boxes
  Future<void> _safeCloseBoxes() async {
    try {
      if (_decksBox.isOpen) await _decksBox.close();
      if (_flashcardsBox.isOpen) await _flashcardsBox.close();
      if (_deckPacksBox.isOpen) await _deckPacksBox.close();
      if (_notesBox.isOpen) await _notesBox.close();
      if (_studySessionsBox.isOpen) await _studySessionsBox.close();
    } catch (e) {
      print('Error closing boxes: $e');
    }
  }

  // Method to check data integrity
  Future<Map<String, int>> getDataCounts() async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    return {
      'decks': _decksBox.length,
      'flashcards': _flashcardsBox.length,
      'deckPacks': _deckPacksBox.length,
      'notes': _notesBox.length,
      'studySessions': _studySessionsBox.length,
    };
  }

  // Method to verify data persistence
  Future<bool> verifyDataPersistence() async {
    try {
      final counts = await getDataCounts();
      final totalItems = counts.values.reduce((a, b) => a + b);
      
      print('Data persistence verification:');
      print('Total items: $totalItems');
      counts.forEach((key, value) => print('$key: $value'));
      
      return totalItems > 0; // Return true if we have any data
    } catch (e) {
      print('Error verifying data persistence: $e');
      return false;
    }
  }

  // Method to check data integrity and provide recovery info
  Future<Map<String, dynamic>> checkDataIntegrity() async {
    try {
      final counts = await getDataCounts();
      final totalItems = counts.values.reduce((a, b) => a + b);
      
      // Check if boxes are accessible
      final boxesAccessible = areBoxesAccessible;
      
      // Check if we're in debug mode
      final isDebugMode = kDebugMode;
      
      // Check if this might be a hot restart
      final isHotRestart = isDebugMode && totalItems == 0;
      
      final result = {
        'totalItems': totalItems,
        'boxesAccessible': boxesAccessible,
        'isDebugMode': isDebugMode,
        'isHotRestart': isHotRestart,
        'counts': counts,
        'status': totalItems > 0 ? 'healthy' : 'empty',
        'recommendation': totalItems > 0 ? 'Data looks good' : 'Check for data loss'
      };
      
      print('=== DATA INTEGRITY CHECK ===');
      print('Total items: $totalItems');
      print('Boxes accessible: $boxesAccessible');
      print('Debug mode: $isDebugMode');
      print('Potential hot restart: $isHotRestart');
      print('Status: ${result['status']}');
      print('Recommendation: ${result['recommendation']}');
      print('=============================');
      
      return result;
    } catch (e) {
      print('Error checking data integrity: $e');
      return {
        'error': e.toString(),
        'status': 'error'
      };
    }
  }

  // Method to attempt data recovery
  Future<Map<String, dynamic>> attemptDataRecovery() async {
    try {
      print('=== ATTEMPTING DATA RECOVERY ===');
      
      // Check if boxes are accessible
      if (!areBoxesAccessible) {
        print('❌ Boxes not accessible - attempting reinitialization');
        await reinitialize();
      }
      
      // Check data counts again
      final counts = await getDataCounts();
      final totalItems = counts.values.reduce((a, b) => a + b);
      
      if (totalItems > 0) {
        print('✅ Data recovery successful! Found $totalItems items');
        return {
          'success': true,
          'message': 'Data recovery successful',
          'totalItems': totalItems,
          'counts': counts
        };
      } else {
        print('❌ No data found after recovery attempt');
        
        // Check if this might be a storage permission issue
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('test_key', 'test_value');
          final testValue = prefs.getString('test_key');
          if (testValue == 'test_value') {
            print('✅ SharedPreferences working - storage permissions OK');
          } else {
            print('❌ SharedPreferences not working - storage permission issue');
          }
        } catch (e) {
          print('❌ Storage permission test failed: $e');
        }
        
        return {
          'success': false,
          'message': 'No data found after recovery attempt',
          'totalItems': 0,
          'counts': counts
        };
      }
    } catch (e) {
      print('❌ Data recovery failed: $e');
      return {
        'success': false,
        'message': 'Recovery failed: $e',
        'error': e.toString()
      };
    }
  }

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isGuestMode') ?? false;
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ===== DECK OPERATIONS =====

  // Create a new deck
  Future<Deck> createDeck(String name, String description, {String? coverColor}) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final now = DateTime.now();
    final deck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      coverColor: coverColor,
    );

    // Save locally only
    await _decksBox.put(deck.id, deck);

    return deck;
  }

  // Get all decks
  Future<List<Deck>> getDecks() async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    return _decksBox.values.toList();
  }

  // Update deck
  Future<void> updateDeck(Deck deck) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final updatedDeck = deck.copyWith(updatedAt: DateTime.now());
    await _decksBox.put(deck.id, updatedDeck);
  }

  // Delete deck
  Future<void> deleteDeck(String deckId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    // Delete all flashcards in the deck
    final flashcards = _flashcardsBox.values.where((card) => card.deckId == deckId).toList();
    for (final card in flashcards) {
      await _flashcardsBox.delete(card.id);
    }

    // Delete deck locally
    await _decksBox.delete(deckId);
  }

  // ===== SPACED REPETITION LOGIC (SM2 Algorithm) =====

  // Update flashcard with proper SM2 spaced repetition algorithm
  Future<void> updateFlashcardWithReview(Flashcard flashcard, int quality) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    final now = DateTime.now();
    int newInterval;
    double newEaseFactor;

    // SM2 Algorithm Implementation
    if (quality >= 3) {
      // Successful recall (Good/Easy)
      if (flashcard.interval == 1) {
        // First successful review after failure
        newInterval = 6;
      } else {
        // Subsequent successful reviews
        newInterval = (flashcard.interval * flashcard.easeFactor).round();
      }
      
      // Adjust ease factor based on quality
      // Quality: 3=Hard, 4=Good, 5=Easy
      double qualityAdjustment;
      if (quality == 3) {
        // Hard - slight decrease in ease factor
        qualityAdjustment = -0.15;
      } else if (quality == 4) {
        // Good - minimal change
        qualityAdjustment = 0.0;
      } else {
        // Easy - slight increase in ease factor
        qualityAdjustment = 0.1;
      }
      
      newEaseFactor = flashcard.easeFactor + qualityAdjustment;
    } else {
      // Failed recall (Again) - reset to learning phase
      newInterval = 1;
      newEaseFactor = flashcard.easeFactor - 0.2;
    }

    // Ensure ease factor stays within reasonable bounds
    newEaseFactor = newEaseFactor.clamp(1.3, 2.5);

    // Calculate next review date
    final nextReview = now.add(Duration(days: newInterval));
    
    final updatedFlashcard = flashcard.copyWith(
      interval: newInterval,
      easeFactor: newEaseFactor,
      nextReview: nextReview,
      lastReviewed: now,
      reviewCount: flashcard.reviewCount + 1,
      updatedAt: now,
    );

    await _flashcardsBox.put(flashcard.id, updatedFlashcard);
  }

  // Get flashcards due for review today (SM2 scheduling)
  Future<List<Flashcard>> getDueFlashcards(String deckId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return _flashcardsBox.values
        .where((card) => 
            card.deckId == deckId && 
            (card.nextReview == null || 
             card.nextReview!.isBefore(today.add(const Duration(days: 1)))))
        .toList();
  }

  // Get flashcards due in the next X days
  Future<List<Flashcard>> getFlashcardsDueInDays(String deckId, int days) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));
    
    return _flashcardsBox.values
        .where((card) => 
            card.deckId == deckId && 
            card.nextReview != null &&
            card.nextReview!.isBefore(futureDate))
        .toList();
  }

  // Get learning cards (new cards or failed cards with interval = 1)
  Future<List<Flashcard>> getLearningCards(String deckId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    return _flashcardsBox.values
        .where((card) => 
            card.deckId == deckId && 
            card.interval == 1)
        .toList();
  }

  // Get review cards (cards with interval > 1)
  Future<List<Flashcard>> getReviewCards(String deckId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    return _flashcardsBox.values
        .where((card) => 
            card.deckId == deckId && 
            card.interval > 1)
        .toList();
  }



  // ===== FLASHCARD OPERATIONS =====

  // Create a new flashcard
  Future<Flashcard> createFlashcard(String deckId, String question, String answer) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final now = DateTime.now();
    final flashcard = Flashcard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deckId: deckId,
      question: question,
      answer: answer,
      createdAt: now,
      updatedAt: now,
    );

    // Save locally
    await _flashcardsBox.put(flashcard.id, flashcard);

    // Update deck card count
    final deck = _decksBox.get(deckId);
    if (deck != null) {
      await updateDeck(deck.copyWith(cardCount: deck.cardCount + 1));
    }

    return flashcard;
  }

  // Get flashcards for a deck
  Future<List<Flashcard>> getFlashcardsForDeck(String deckId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    return _flashcardsBox.values.where((card) => card.deckId == deckId).toList();
  }

  // Get all flashcards
  Future<List<Flashcard>> getAllFlashcards() async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    return _flashcardsBox.values.toList();
  }

  // Update flashcard
  Future<void> updateFlashcard(Flashcard flashcard) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final updatedFlashcard = flashcard.copyWith(updatedAt: DateTime.now());
    await _flashcardsBox.put(flashcard.id, updatedFlashcard);
  }

  // Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final flashcard = _flashcardsBox.get(flashcardId);
    if (flashcard != null) {
      await _flashcardsBox.delete(flashcardId);

      // Update deck card count
      final deck = _decksBox.get(flashcard.deckId);
      if (deck != null) {
        await updateDeck(deck.copyWith(cardCount: deck.cardCount - 1));
      }
    }
  }

  // ===== SYNC OPERATIONS =====

  // Manual backup to Firestore
  Future<void> backupToFirestore() async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    if (currentUserId == null) {
      throw Exception('You must be signed in to backup your data.');
    }

    try {
      print('Starting backup to Firestore...');
      
      // Backup all deck packs first (they contain deck relationships)
      final allDeckPacks = _deckPacksBox.values.toList();
      print('Backing up ${allDeckPacks.length} deck packs...');
      for (final deckPack in allDeckPacks) {
        await _saveDeckPackToFirestore(deckPack);
      }

      // Backup all decks
      final allDecks = _decksBox.values.toList();
      print('Backing up ${allDecks.length} decks...');
      for (final deck in allDecks) {
        await _saveDeckToFirestore(deck);
      }

      // Backup all flashcards
      final allFlashcards = _flashcardsBox.values.toList();
      print('Backing up ${allFlashcards.length} flashcards...');
      for (final flashcard in allFlashcards) {
        await _saveFlashcardToFirestore(flashcard);
      }

      // Backup all notes
      final allNotes = _notesBox.values.toList();
      print('Backing up ${allNotes.length} notes...');
      for (final note in allNotes) {
        await _saveNoteToFirestore(note);
      }

      // Backup all study sessions
      final allStudySessions = _studySessionsBox.values.toList();
      print('Backing up ${allStudySessions.length} study sessions...');
      for (final session in allStudySessions) {
        await _saveStudySessionToFirestore(session);
      }

      // Backup relevant preferences (streaks, notifications)
      await _backupPreferencesToFirestore();

      print('Backup completed successfully!');
    } catch (e) {
      print('Backup failed: $e');
      throw Exception('Backup failed: ${e.toString()}');
    }
  }

  // Sync local data to Firestore when user signs in
  Future<void> syncLocalDataToFirestore() async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    if (currentUserId == null) return;

    print('Syncing local data to Firestore...');

    // Sync deck packs
    final localDeckPacks = _deckPacksBox.values.toList();
    for (final deckPack in localDeckPacks) {
      await _saveDeckPackToFirestore(deckPack);
    }

    // Sync decks
    final localDecks = _decksBox.values.toList();
    for (final deck in localDecks) {
      await _saveDeckToFirestore(deck);
    }

    // Sync flashcards
    final localFlashcards = _flashcardsBox.values.toList();
    for (final flashcard in localFlashcards) {
      await _saveFlashcardToFirestore(flashcard);
    }

    // Sync notes
    final localNotes = _notesBox.values.toList();
    for (final note in localNotes) {
      await _saveNoteToFirestore(note);
    }

    // Sync study sessions
    final localStudySessions = _studySessionsBox.values.toList();
    for (final session in localStudySessions) {
      await _saveStudySessionToFirestore(session);
    }

    print('Local data sync completed!');
  }

  // Load data from Firestore
  Future<void> loadDataFromFirestore() async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    if (currentUserId == null) return;

    print('Loading data from Firestore...');

    // Load deck packs first (they contain deck relationships)
    final deckPacksSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('deck_packs')
        .get();

    for (final doc in deckPacksSnapshot.docs) {
      final deckPack = DeckPack.fromMap(doc.data());
      await _deckPacksBox.put(deckPack.id, deckPack);
    }
    print('Loaded ${deckPacksSnapshot.docs.length} deck packs');

    // Load decks
    final decksSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('decks')
        .get();

    for (final doc in decksSnapshot.docs) {
      final deck = Deck.fromMap(doc.data());
      await _decksBox.put(deck.id, deck);
    }
    print('Loaded ${decksSnapshot.docs.length} decks');

    // Load flashcards
    final flashcardsSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcards')
        .get();

    for (final doc in flashcardsSnapshot.docs) {
      final flashcard = Flashcard.fromMap(doc.data());
      await _flashcardsBox.put(flashcard.id, flashcard);
    }
    print('Loaded ${flashcardsSnapshot.docs.length} flashcards');

    // Load notes
    final notesSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notes')
        .get();

    for (final doc in notesSnapshot.docs) {
      final note = Note.fromMap(doc.data());
      await _notesBox.put(note.id, note);
    }
    print('Loaded ${notesSnapshot.docs.length} notes');

    // Load study sessions
    final studySessionsSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('study_sessions')
        .get();

    for (final doc in studySessionsSnapshot.docs) {
      final session = StudySession.fromJson(doc.data());
      await _studySessionsBox.put(session.id, session);
    }
    print('Loaded ${studySessionsSnapshot.docs.length} study sessions');

    print('Data loading completed!');

    // Restore preferences after data
    try {
      await _loadPreferencesFromFirestore();
    } catch (e) {
      // Non-fatal
    }
  }

  // ===== FIRESTORE OPERATIONS =====

  Future<void> _saveDeckToFirestore(Deck deck) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('decks')
        .doc(deck.id)
        .set(deck.toMap());
  }

  Future<void> _saveFlashcardToFirestore(Flashcard flashcard) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcards')
        .doc(flashcard.id)
        .set(flashcard.toMap());
  }

  Future<void> _saveDeckPackToFirestore(DeckPack deckPack) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('deck_packs')
        .doc(deckPack.id)
        .set(deckPack.toMap());
  }

  Future<void> _saveNoteToFirestore(Note note) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notes')
        .doc(note.id)
        .set(note.toMap());
  }

  Future<void> _saveStudySessionToFirestore(StudySession session) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('study_sessions')
        .doc(session.id)
        .set(session.toJson());
  }

  // ===== PREFERENCES SYNC (streaks, notifications) =====

  Future<void> _backupPreferencesToFirestore() async {
    if (currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{
        'current_streak': prefs.getInt('current_streak'),
        'last_study_date': prefs.getString('last_study_date'),
        'last_streak_celebration': prefs.getString('last_streak_celebration'),
        'overdue_reminders_enabled': prefs.getBool('overdue_reminders_enabled'),
        'streak_reminders_enabled': prefs.getBool('streak_reminders_enabled'),
        'reminder_hour': prefs.getInt('reminder_hour'),
        'reminder_minute': prefs.getInt('reminder_minute'),
        'reminder_days': prefs.getStringList('reminder_days'),
        'last_overdue_check': prefs.getString('last_overdue_check'),
        'last_reminder_check': prefs.getString('last_reminder_check'),
      };
      // Remove nulls to avoid overwriting with null
      data.removeWhere((key, value) => value == null);
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meta')
          .doc('preferences')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error backing up preferences: $e');
    }
  }

  Future<void> _loadPreferencesFromFirestore() async {
    if (currentUserId == null) return;
    try {
      final prefsDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('meta')
          .doc('preferences')
          .get();
      if (!prefsDoc.exists) return;
      final data = prefsDoc.data() ?? {};
      final prefs = await SharedPreferences.getInstance();

      // Write only known keys
      if (data.containsKey('current_streak')) {
        await prefs.setInt('current_streak', (data['current_streak'] as num).toInt());
      }
      if (data.containsKey('last_study_date')) {
        await prefs.setString('last_study_date', data['last_study_date'] as String);
      }
      if (data.containsKey('last_streak_celebration')) {
        await prefs.setString('last_streak_celebration', data['last_streak_celebration'] as String);
      }
      if (data.containsKey('overdue_reminders_enabled')) {
        await prefs.setBool('overdue_reminders_enabled', data['overdue_reminders_enabled'] as bool);
      }
      if (data.containsKey('streak_reminders_enabled')) {
        await prefs.setBool('streak_reminders_enabled', data['streak_reminders_enabled'] as bool);
      }
      if (data.containsKey('reminder_hour')) {
        await prefs.setInt('reminder_hour', (data['reminder_hour'] as num).toInt());
      }
      if (data.containsKey('reminder_minute')) {
        await prefs.setInt('reminder_minute', (data['reminder_minute'] as num).toInt());
      }
      if (data.containsKey('reminder_days')) {
        final days = (data['reminder_days'] as List).map((e) => e.toString()).toList();
        await prefs.setStringList('reminder_days', days);
      }
      if (data.containsKey('last_overdue_check')) {
        await prefs.setString('last_overdue_check', data['last_overdue_check'] as String);
      }
      if (data.containsKey('last_reminder_check')) {
        await prefs.setString('last_reminder_check', data['last_reminder_check'] as String);
      }
    } catch (e) {
      print('Error loading preferences from Firestore: $e');
    }
  }

  Future<void> _deleteDeckFromFirestore(String deckId) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('decks')
        .doc(deckId)
        .delete();
  }

  Future<void> _deleteFlashcardFromFirestore(String flashcardId) async {
    if (currentUserId == null) return;
    
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcards')
        .doc(flashcardId)
        .delete();
  }

  // ===== DECK PACK OPERATIONS =====

  // Create a new deck pack
  Future<DeckPack> createDeckPack(String name, String description, {String? coverColor}) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final now = DateTime.now();
    final pack = DeckPack(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      coverColor: coverColor ?? 'FF9800',
    );

    await _deckPacksBox.put(pack.id, pack);
    return pack;
  }

  // Get all deck packs
  Future<List<DeckPack>> getDeckPacks() async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    return _deckPacksBox.values.toList();
  }

  // Update deck pack
  Future<void> updateDeckPack(DeckPack pack) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final updatedPack = pack.copyWith(updatedAt: DateTime.now());
    await _deckPacksBox.put(pack.id, updatedPack);
  }

  // Delete deck pack
  Future<void> deleteDeckPack(String packId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    // Remove pack ID from all decks in this pack
    final decksInPack = _decksBox.values.where((deck) => deck.packId == packId).toList();
    for (final deck in decksInPack) {
      await updateDeck(deck.copyWith(packId: null));
    }

    await _deckPacksBox.delete(packId);
  }

  // Add deck to pack
  Future<void> addDeckToPack(String deckId, String packId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final deck = _decksBox.get(deckId);
    if (deck != null) {
      await updateDeck(deck.copyWith(packId: packId));
      
      // Update pack deck count
      final pack = _deckPacksBox.get(packId);
      if (pack != null) {
        final updatedDeckIds = List<String>.from(pack.deckIds)..add(deckId);
        await updateDeckPack(pack.copyWith(
          deckIds: updatedDeckIds,
          deckCount: updatedDeckIds.length,
        ));
      }
    }
  }

  // Remove deck from pack
  Future<void> removeDeckFromPack(String deckId, String packId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final deck = _decksBox.get(deckId);
    if (deck != null) {
      await updateDeck(deck.copyWith(packId: null));
      
      // Update pack deck count
      final pack = _deckPacksBox.get(packId);
      if (pack != null) {
        final updatedDeckIds = List<String>.from(pack.deckIds)..remove(deckId);
        await updateDeckPack(pack.copyWith(
          deckIds: updatedDeckIds,
          deckCount: updatedDeckIds.length,
        ));
      }
    }
  }

  // ===== NOTE OPERATIONS =====

  // Create a new note
  Future<Note> createNote(String title, String content, {
    String? linkedCardId,
    String? linkedDeckId,
    String? linkedPackId,
    List<String>? tags,
  }) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final now = DateTime.now();
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      linkedCardId: linkedCardId,
      linkedDeckId: linkedDeckId,
      linkedPackId: linkedPackId,
      tags: tags ?? [],
    );

    await _notesBox.put(note.id, note);
    return note;
  }

  // Get all notes
  Future<List<Note>> getNotes() async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    return _notesBox.values.toList();
  }

  // Get notes linked to a specific item
  Future<List<Note>> getNotesForItem({
    String? cardId,
    String? deckId,
    String? packId,
  }) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    return _notesBox.values.where((note) {
      if (cardId != null && note.linkedCardId == cardId) return true;
      if (deckId != null && note.linkedDeckId == deckId) return true;
      if (packId != null && note.linkedPackId == packId) return true;
      return false;
    }).toList();
  }

  // Update note
  Future<void> updateNote(Note note) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    await _notesBox.put(note.id, updatedNote);
  }

  // Delete note
  Future<void> deleteNote(String noteId) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }
    
    await _notesBox.delete(noteId);
  }

  // ===== SEARCH OPERATIONS =====

  // Search across decks, flashcards, and notes
  Future<Map<String, dynamic>> searchAll(String query) async {
    if (!_isInitialized) {
      throw Exception('DataService has not been initialized. Please call initialize() first.');
    }

    final lowercaseQuery = query.toLowerCase();
    final results = <String, dynamic>{};

    // Search decks
    final matchingDecks = _decksBox.values
        .where((deck) => 
            deck.name.toLowerCase().contains(lowercaseQuery) ||
            deck.description.toLowerCase().contains(lowercaseQuery))
        .toList();
    results['decks'] = matchingDecks;

    // Search flashcards
    final matchingFlashcards = _flashcardsBox.values
        .where((card) => 
            card.question.toLowerCase().contains(lowercaseQuery) ||
            card.answer.toLowerCase().contains(lowercaseQuery))
        .toList();
    results['flashcards'] = matchingFlashcards;

    // Search notes (title, content, tags)
    final matchingNotes = _notesBox.values
        .where((note) {
          final inTitle = note.title.toLowerCase().contains(lowercaseQuery);
          final inContent = note.content.toLowerCase().contains(lowercaseQuery);
          final inTags = note.tags.any((t) => t.toLowerCase().contains(lowercaseQuery));
          return inTitle || inContent || inTags;
        })
        .toList();
    results['notes'] = matchingNotes;

    return results;
  }

  // ===== STATS OPERATIONS =====

  // Save study session
  Future<void> saveStudySession(StudySession session) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    await _studySessionsBox.put(session.id, session);
  }

  // Get study sessions for a deck
  Future<List<StudySession>> getStudySessionsForDeck(String deckId) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    return _studySessionsBox.values
        .where((session) => session.deckId == deckId)
        .toList();
  }

  // Get all study sessions
  Future<List<StudySession>> getAllStudySessions() async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    return _studySessionsBox.values.toList();
  }

  // Get study statistics for a deck
  Future<Map<String, dynamic>> getDeckStats(String deckId) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final sessions = await getStudySessionsForDeck(deckId);
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageScore': 0.0,
        'totalStudyTime': 0,
        'bestScore': 0.0,
        'cardsStudied': 0,
      };
    }

    final totalSessions = sessions.length;
    final averageScore = sessions.map((s) => s.averageScore).reduce((a, b) => a + b) / totalSessions;
    final totalStudyTime = sessions.map((s) => s.studyTimeSeconds).reduce((a, b) => a + b);
    final bestScore = sessions.map((s) => s.averageScore).reduce((a, b) => a > b ? a : b);
    final cardsStudied = sessions.map((s) => s.totalCards).reduce((a, b) => a + b);

    return {
      'totalSessions': totalSessions,
      'averageScore': averageScore,
      'totalStudyTime': totalStudyTime,
      'bestScore': bestScore,
      'cardsStudied': cardsStudied,
    };
  }

  // Get overall statistics
  Future<Map<String, dynamic>> getOverallStats() async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final sessions = await getAllStudySessions();
    final decks = await getDecks();
    
    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDecks': decks.length,
        'totalCards': decks.fold(0, (sum, deck) => sum + deck.cardCount),
        'averageScore': 0.0,
        'totalStudyTime': 0,
      };
    }

    final totalSessions = sessions.length;
    final totalDecks = decks.length;
    final totalCards = decks.fold(0, (sum, deck) => sum + deck.cardCount);
    
    // Calculate averages only if there are sessions
    double averageScore = 0.0;
    int totalStudyTime = 0;
    
    if (sessions.isNotEmpty) {
      averageScore = sessions.map((s) => s.averageScore).reduce((a, b) => a + b) / totalSessions;
      totalStudyTime = sessions.map((s) => s.studyTimeSeconds).reduce((a, b) => a + b);
    }

    return {
      'totalSessions': totalSessions,
      'totalDecks': totalDecks,
      'totalCards': totalCards,
      'averageScore': averageScore,
      'totalStudyTime': totalStudyTime,
    };
  }

  // Get study sessions for the last N days
  Future<List<StudySession>> getStudySessionsForDays(int days) async {
    if (!areBoxesAccessible) {
      throw Exception('DataService has not been initialized or boxes are not accessible. Please call initialize() first.');
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    return _studySessionsBox.values
        .where((session) => session.date.isAfter(cutoffDate))
        .toList();
  }

  // Check if there's data to backup
  Future<Map<String, int>> getBackupStats() async {
    if (!_isInitialized) {
      return {};
    }

    return {
      'deck_packs': _deckPacksBox.length,
      'decks': _decksBox.length,
      'flashcards': _flashcardsBox.length,
      'notes': _notesBox.length,
      'study_sessions': _studySessionsBox.length,
    };
  }

  // Close boxes
  Future<void> dispose() async {
    await _decksBox.close();
    await _flashcardsBox.close();
    await _deckPacksBox.close();
    await _notesBox.close();
    await _studySessionsBox.close();
  }

  Future<String?> getDeckPackName(String s) async {
  if (!_isInitialized) {
    throw Exception('DataService has not been initialized. Please call initialize() first.');
  }

  final pack = _deckPacksBox.get(s);
  return pack?.name;
}
}
