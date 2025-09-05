import '../../../core/models/deck.dart';
import '../../../core/models/flashcard.dart';
import '../../../core/models/study_result.dart';
import 'data_service.dart';

class DeckSchedulingService {
  static final DeckSchedulingService _instance = DeckSchedulingService._internal();
  factory DeckSchedulingService() => _instance;
  DeckSchedulingService._internal();

  final DataService _dataService = DataService();

  // Deck-level scheduling intervals in days
  static const Map<String, int> _deckIntervals = {
    'again': 1,      // Deck needs review again tomorrow
    'hard': 2,       // Deck needs review in 2 days
    'good': 4,       // Deck needs review in 4 days
    'easy': 7,       // Deck needs review in 1 week
  };

  /// Calculate the next review date for a deck based on study results
  Future<DateTime> calculateDeckNextReview(
    Deck deck,
    List<StudyResult> studyResults,
  ) async {
    if (studyResults.isEmpty) {
      // If no study results, use default interval
      return DateTime.now().add(const Duration(days: 7));
    }

    // Analyze the overall performance of the deck
    final deckPerformance = _analyzeDeckPerformance(studyResults);
    
    // Calculate the next review date based on performance
    final nextReviewDate = _calculateNextReviewDate(deckPerformance);
    
    return nextReviewDate;
  }

  /// Analyze the overall performance of a deck based on study results
  String _analyzeDeckPerformance(List<StudyResult> studyResults) {
    if (studyResults.isEmpty) return 'good';

    // Count ratings
    int againCount = 0;
    int hardCount = 0;
    int goodCount = 0;
    int easyCount = 0;

    for (final result in studyResults) {
      switch (result.rating) {
        case StudyRating.again:
          againCount++;
          break;
        case StudyRating.hard:
          hardCount++;
          break;
        case StudyRating.good:
          goodCount++;
          break;
        case StudyRating.easy:
          easyCount++;
          break;
      }
    }

    final totalCards = studyResults.length;
    
    // Calculate percentages
    final againPercentage = againCount / totalCards;
    final hardPercentage = hardCount / totalCards;
    final goodPercentage = goodCount / totalCards;
    final easyPercentage = easyCount / totalCards;

    // Determine deck performance based on majority and difficulty distribution
    if (againPercentage >= 0.4) {
      // If 40% or more cards were "again", deck needs immediate review
      return 'again';
    } else if (hardPercentage >= 0.3) {
      // If 30% or more cards were "hard", deck needs review soon
      return 'hard';
    } else if (easyPercentage >= 0.5) {
      // If 50% or more cards were "easy", deck can wait longer
      return 'easy';
    } else {
      // Default to good performance
      return 'good';
    }
  }

  /// Calculate the next review date based on deck performance
  DateTime _calculateNextReviewDate(String performance) {
    final now = DateTime.now();
    final interval = _deckIntervals[performance] ?? 4; // Default to 4 days
    
    return now.add(Duration(days: interval));
  }

  /// Apply deck-level scheduling to a deck
  Future<void> scheduleDeckReview(
    Deck deck,
    List<StudyResult> studyResults,
  ) async {
    try {
      // Calculate the next review date for the deck
      final nextReviewDate = await calculateDeckNextReview(deck, studyResults);
      
      // Update the deck with the new schedule
      final updatedDeck = deck.copyWith(
        scheduledReviewTime: nextReviewDate,
        scheduledReviewEnabled: true,
        updatedAt: DateTime.now(),
      );

      await _dataService.updateDeck(updatedDeck);
      
      print('Deck "${deck.name}" scheduled for review on ${nextReviewDate.toString()}');
    } catch (e) {
      print('Error scheduling deck review: $e');
      rethrow;
    }
  }

  /// Get decks that are due for review
  Future<List<Deck>> getDueDecks() async {
    try {
      final allDecks = await _dataService.getDecks();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return allDecks.where((deck) {
        // Only consider decks with spaced repetition enabled
        if (!deck.spacedRepetitionEnabled) return false;
        
        // Check if deck has a scheduled review time
        if (deck.scheduledReviewTime != null) {
          final reviewDate = DateTime(
            deck.scheduledReviewTime!.year,
            deck.scheduledReviewTime!.month,
            deck.scheduledReviewTime!.day,
          );
          return reviewDate.isBefore(today) || reviewDate.isAtSameMomentAs(today);
        }

        return false;
      }).toList();
    } catch (e) {
      print('Error getting due decks: $e');
      return [];
    }
  }

  /// Get overdue decks (past their scheduled review date)
  Future<List<Deck>> getOverdueDecks() async {
    try {
      final allDecks = await _dataService.getDecks();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return allDecks.where((deck) {
        // Only consider decks with spaced repetition enabled
        if (!deck.spacedRepetitionEnabled) return false;
        
        // Check if deck is overdue
        if (deck.scheduledReviewTime != null) {
          final reviewDate = DateTime(
            deck.scheduledReviewTime!.year,
            deck.scheduledReviewTime!.month,
            deck.scheduledReviewTime!.day,
          );
          return reviewDate.isBefore(today);
        }

        return false;
      }).toList();
    } catch (e) {
      print('Error getting overdue decks: $e');
      return [];
    }
  }

  /// Mark a deck as reviewed (clear the schedule)
  Future<void> markDeckAsReviewed(Deck deck) async {
    try {
      final updatedDeck = deck.copyWith(
        scheduledReviewTime: null,
        scheduledReviewEnabled: false,
        updatedAt: DateTime.now(),
      );

      await _dataService.updateDeck(updatedDeck);
      
      print('Deck "${deck.name}" marked as reviewed');
    } catch (e) {
      print('Error marking deck as reviewed: $e');
      rethrow;
    }
  }

  /// Get deck performance summary for display
  Map<String, dynamic> getDeckPerformanceSummary(List<StudyResult> studyResults) {
    if (studyResults.isEmpty) {
      return {
        'performance': 'good',
        'nextReview': '7 days',
        'againCount': 0,
        'hardCount': 0,
        'goodCount': 0,
        'easyCount': 0,
        'totalCards': 0,
      };
    }

    // Count ratings
    int againCount = 0;
    int hardCount = 0;
    int goodCount = 0;
    int easyCount = 0;

    for (final result in studyResults) {
      switch (result.rating) {
        case StudyRating.again:
          againCount++;
          break;
        case StudyRating.hard:
          hardCount++;
          break;
        case StudyRating.good:
          goodCount++;
          break;
        case StudyRating.easy:
          easyCount++;
          break;
      }
    }

    final totalCards = studyResults.length;
    final performance = _analyzeDeckPerformance(studyResults);
    final interval = _deckIntervals[performance] ?? 4;
    
    String nextReviewText;
    if (interval == 1) {
      nextReviewText = 'tomorrow';
    } else if (interval == 2) {
      nextReviewText = 'in 2 days';
    } else if (interval == 4) {
      nextReviewText = 'in 4 days';
    } else if (interval == 7) {
      nextReviewText = 'in 1 week';
    } else {
      nextReviewText = 'in $interval days';
    }

    return {
      'performance': performance,
      'nextReview': nextReviewText,
      'againCount': againCount,
      'hardCount': hardCount,
      'goodCount': goodCount,
      'easyCount': easyCount,
      'totalCards': totalCards,
    };
  }
}
