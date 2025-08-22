import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

class DataService {
  static const String _decksBoxName = 'decks';
  static const String _flashcardsBoxName = 'flashcards';
  
  late Box<Deck> _decksBox;
  late Box<Flashcard> _flashcardsBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize Hive boxes
  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(DeckAdapter());
    Hive.registerAdapter(FlashcardAdapter());
    
    // Open boxes
    _decksBox = await Hive.openBox<Deck>(_decksBoxName);
    _flashcardsBox = await Hive.openBox<Flashcard>(_flashcardsBoxName);
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
    final now = DateTime.now();
    final deck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      coverColor: coverColor,
    );

    // Save locally
    await _decksBox.put(deck.id, deck);

    // Save to Firestore if signed in
    if (!await isGuestMode() && currentUserId != null) {
      await _saveDeckToFirestore(deck);
    }

    return deck;
  }

  // Get all decks
  Future<List<Deck>> getDecks() async {
    return _decksBox.values.toList();
  }

  // Update deck
  Future<void> updateDeck(Deck deck) async {
    final updatedDeck = deck.copyWith(updatedAt: DateTime.now());
    await _decksBox.put(deck.id, updatedDeck);

    // Update in Firestore if signed in
    if (!await isGuestMode() && currentUserId != null) {
      await _saveDeckToFirestore(updatedDeck);
    }
  }

  // Delete deck
  Future<void> deleteDeck(String deckId) async {
    // Delete all flashcards in the deck
    final flashcards = _flashcardsBox.values.where((card) => card.deckId == deckId).toList();
    for (final card in flashcards) {
      await _flashcardsBox.delete(card.id);
    }

    // Delete deck locally
    await _decksBox.delete(deckId);

    // Delete from Firestore if signed in
    if (!await isGuestMode() && currentUserId != null) {
      await _deleteDeckFromFirestore(deckId);
    }
  }

  // ===== FLASHCARD OPERATIONS =====

  // Create a new flashcard
  Future<Flashcard> createFlashcard(String deckId, String question, String answer) async {
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

    // Save to Firestore if signed in
    if (!await isGuestMode() && currentUserId != null) {
      await _saveFlashcardToFirestore(flashcard);
    }

    return flashcard;
  }

  // Get flashcards for a deck
  Future<List<Flashcard>> getFlashcardsForDeck(String deckId) async {
    return _flashcardsBox.values.where((card) => card.deckId == deckId).toList();
  }

  // Update flashcard
  Future<void> updateFlashcard(Flashcard flashcard) async {
    final updatedFlashcard = flashcard.copyWith(updatedAt: DateTime.now());
    await _flashcardsBox.put(flashcard.id, updatedFlashcard);

    // Update in Firestore if signed in
    if (!await isGuestMode() && currentUserId != null) {
      await _saveFlashcardToFirestore(updatedFlashcard);
    }
  }

  // Delete flashcard
  Future<void> deleteFlashcard(String flashcardId) async {
    final flashcard = _flashcardsBox.get(flashcardId);
    if (flashcard != null) {
      await _flashcardsBox.delete(flashcardId);

      // Update deck card count
      final deck = _decksBox.get(flashcard.deckId);
      if (deck != null) {
        await updateDeck(deck.copyWith(cardCount: deck.cardCount - 1));
      }

      // Delete from Firestore if signed in
      if (!await isGuestMode() && currentUserId != null) {
        await _deleteFlashcardFromFirestore(flashcardId);
      }
    }
  }

  // ===== SYNC OPERATIONS =====

  // Sync local data to Firestore when user signs in
  Future<void> syncLocalDataToFirestore() async {
    if (currentUserId == null) return;

    // Sync decks
    final localDecks = _decksBox.values.where((deck) => !deck.isSynced).toList();
    for (final deck in localDecks) {
      await _saveDeckToFirestore(deck);
      await _decksBox.put(deck.id, deck.copyWith(isSynced: true));
    }

    // Sync flashcards
    final localFlashcards = _flashcardsBox.values.where((card) => !card.isSynced).toList();
    for (final flashcard in localFlashcards) {
      await _saveFlashcardToFirestore(flashcard);
      await _flashcardsBox.put(flashcard.id, flashcard.copyWith(isSynced: true));
    }
  }

  // Load data from Firestore
  Future<void> loadDataFromFirestore() async {
    if (currentUserId == null) return;

    // Load decks
    final decksSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('decks')
        .get();

    for (final doc in decksSnapshot.docs) {
      final deck = Deck.fromMap(doc.data());
      await _decksBox.put(deck.id, deck.copyWith(isSynced: true));
    }

    // Load flashcards
    final flashcardsSnapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('flashcards')
        .get();

    for (final doc in flashcardsSnapshot.docs) {
      final flashcard = Flashcard.fromMap(doc.data());
      await _flashcardsBox.put(flashcard.id, flashcard.copyWith(isSynced: true));
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

  // Close boxes
  Future<void> dispose() async {
    await _decksBox.close();
    await _flashcardsBox.close();
  }
}
