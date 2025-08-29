import '../../../core/models/flashcard.dart';
import '../../../core/models/study_result.dart';
import 'data_service.dart';
import '../../../core/models/study_session.dart';

class FSRSStudyService {
  static final FSRSStudyService _instance = FSRSStudyService._internal();
  factory FSRSStudyService() => _instance;
  FSRSStudyService._internal();

  final DataService _dataService = DataService();

  // FSRS-inspired intervals (more aggressive than traditional SM2)
  static const Map<int, int> _intervals = {
    1: 1,    // Learning: 1 day
    2: 2,    // 2 days
    3: 4,    // 4 days
    4: 8,    // 1 week
    5: 16,   // 2 weeks
    6: 32,   // 1 month
    7: 64,   // 2 months
    8: 128,  // 4 months
    9: 256,  // 8 months
  };

  // Ease factor adjustments (more aggressive than traditional)
  static const double _easyBonus = 0.20;
  static const double _goodBonus = 0.15;
  static const double _hardPenalty = 0.25;
  static const double _againPenalty = 0.35;

  /// Get cards that are due for study using FSRS-inspired algorithm
  Future<List<Flashcard>> getDueCards(String deckId) async {
    try {
      final allCards = await _dataService.getFlashcardsForDeck(deckId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return allCards.where((card) {
        // New cards (never studied) are always due
        if (card.lastReviewed == null) return true;
        
        // Cards with nextReview set
        if (card.nextReview != null) {
          final reviewDate = DateTime(
            card.nextReview!.year,
            card.nextReview!.month,
            card.nextReview!.day,
          );
          return reviewDate.isBefore(today) || reviewDate.isAtSameMomentAs(today);
        }

        // Fallback: cards that haven't been reviewed in their interval
        final daysSinceReview = now.difference(card.lastReviewed!).inDays;
        return daysSinceReview >= card.interval;
      }).toList();
    } catch (e) {
      print('Error getting due cards: $e');
      return [];
    }
  }

  /// Get cards for a study session using FSRS-inspired prioritization
  Future<List<Flashcard>> getCardsForStudySession(String deckId, {int maxCards = 20}) async {
    try {
      final dueCards = await getDueCards(deckId);
      
      // Prioritize cards using FSRS-inspired algorithm
      dueCards.sort((a, b) {
        final aPriority = _getFSRSPriority(a);
        final bPriority = _getFSRSPriority(b);
        return bPriority.compareTo(aPriority); // Higher priority first
      });

      // Limit the number of cards for a session
      return dueCards.take(maxCards).toList();
    } catch (e) {
      print('Error getting cards for study session: $e');
      return [];
    }
  }

  /// Calculate FSRS-inspired priority for a card
  double _getFSRSPriority(Flashcard card) {
    if (card.lastReviewed == null) return 100.0; // New cards highest priority
    
    final now = DateTime.now();
    final daysOverdue = now.difference(card.nextReview ?? card.lastReviewed!).inDays;
    
    if (daysOverdue > 0) {
      // Overdue cards get higher priority based on how overdue they are
      return 90.0 + daysOverdue;
    } else if (daysOverdue == 0) {
      // Due today
      return 80.0;
    } else {
      // Future due cards - prioritize based on difficulty
      final difficulty = _getCardDifficulty(card);
      return 70.0 - daysOverdue.abs() + difficulty;
    }
  }

  /// Get card difficulty score (0-10)
  double _getCardDifficulty(Flashcard card) {
    if (card.lastReviewed == null) return 0.0;
    
    // Higher difficulty for cards with low ease factor
    if (card.easeFactor < 1.5) return 10.0;
    if (card.easeFactor < 1.8) return 7.0;
    if (card.easeFactor < 2.0) return 5.0;
    if (card.easeFactor < 2.2) return 3.0;
    return 1.0;
  }

  /// Process study result using FSRS-inspired algorithm
  Future<StudyResult> processStudyResult(Flashcard card, StudyRating rating) async {
    try {
      final now = DateTime.now();
      final oldInterval = card.interval;
      final oldEaseFactor = card.easeFactor;
      
      // Calculate new interval and ease factor
      final newInterval = _calculateNewInterval(card, rating);
      final newEaseFactor = _calculateNewEaseFactor(card, rating);
      
      // Calculate next review date
      final nextReview = _calculateNextReview(now, newInterval);
      
      // Update card
      final updatedCard = card.copyWith(
        interval: newInterval,
        easeFactor: newEaseFactor,
        nextReview: nextReview,
        lastReviewed: now,
        reviewCount: card.reviewCount + 1,
        updatedAt: now,
      );

      await _dataService.updateFlashcard(updatedCard);

      // Create study result
      return StudyResult(
        cardId: card.id,
        oldInterval: oldInterval,
        newInterval: newInterval,
        oldEaseFactor: oldEaseFactor,
        newEaseFactor: newEaseFactor,
        rating: rating,
        nextReview: nextReview,
        isNewCard: card.lastReviewed == null,
      );
    } catch (e) {
      print('Error processing study result: $e');
      rethrow;
    }
  }

  /// Calculate new interval based on rating (FSRS-inspired)
  int _calculateNewInterval(Flashcard card, StudyRating rating) {
    switch (rating) {
      case StudyRating.again:
        return 1; // Reset to learning
      case StudyRating.hard:
        // Reduce interval but don't reset completely
        final newInterval = (card.interval * 0.6).round();
        return newInterval < 1 ? 1 : newInterval;
      case StudyRating.good:
        // Normal progression
        return _getNextInterval(card.interval);
      case StudyRating.easy:
        // Accelerate progression (more aggressive than traditional)
        final nextInterval = _getNextInterval(card.interval);
        return _getNextInterval(nextInterval);
    }
  }

  /// Get the next interval in the sequence
  int _getNextInterval(int currentInterval) {
    final intervals = _intervals.values.toList();
    final currentIndex = intervals.indexOf(currentInterval);
    
    if (currentIndex == -1 || currentIndex >= intervals.length - 1) {
      // If not found or at max, increase by 100%
      return (currentInterval * 2).round();
    }
    
    return intervals[currentIndex + 1];
  }

  /// Calculate new ease factor based on rating (FSRS-inspired)
  double _calculateNewEaseFactor(Flashcard card, StudyRating rating) {
    double newEaseFactor = card.easeFactor;
    
    switch (rating) {
      case StudyRating.again:
        newEaseFactor -= _againPenalty;
        break;
      case StudyRating.hard:
        newEaseFactor -= _hardPenalty;
        break;
      case StudyRating.good:
        newEaseFactor += _goodBonus;
        break;
      case StudyRating.easy:
        newEaseFactor += _easyBonus;
        break;
    }
    
    // Clamp ease factor between 1.3 and 2.5
    return newEaseFactor.clamp(1.3, 2.5);
  }

  /// Calculate next review date
  DateTime _calculateNextReview(DateTime now, int interval) {
    return now.add(Duration(days: interval));
  }

  /// Get study statistics for a deck using FSRS-inspired algorithm
  Future<Map<String, dynamic>> getStudyStats(String deckId) async {
    try {
      final allCards = await _dataService.getFlashcardsForDeck(deckId);
      final now = DateTime.now();
      
      // Calculate various statistics
      final totalCards = allCards.length;
      final newCards = allCards.where((card) => card.lastReviewed == null).length;
      final learningCards = allCards.where((card) => card.interval == 1).length;
      final reviewCards = allCards.where((card) => card.interval > 1).length;
      
      // Due cards
      final dueCards = allCards.where((card) {
        if (card.lastReviewed == null) return true;
        if (card.nextReview != null) {
          return card.nextReview!.isBefore(now);
        }
        final daysSinceReview = now.difference(card.lastReviewed!).inDays;
        return daysSinceReview >= card.interval;
      }).length;
      
      // Overdue cards
      final overdueCards = allCards.where((card) {
        if (card.nextReview == null || card.lastReviewed == null) return false;
        return card.nextReview!.isBefore(now);
      }).length;
      
      // Average ease factor
      final reviewedCards = allCards.where((card) => card.lastReviewed != null);
      final avgEaseFactor = reviewedCards.isEmpty 
          ? 2.5 
          : reviewedCards.fold<double>(0, (sum, card) => sum + card.easeFactor) / reviewedCards.length;
      
      // Average interval
      final avgInterval = allCards.isEmpty 
          ? 1 
          : allCards.fold<int>(0, (sum, card) => sum + card.interval) / allCards.length;
      
      // FSRS-inspired stats
      final avgDifficulty = _calculateAverageDifficulty(allCards);
      final avgStability = _calculateAverageStability(allCards);
      
      return {
        'totalCards': totalCards,
        'newCards': newCards,
        'learningCards': learningCards,
        'reviewCards': reviewCards,
        'dueCards': dueCards,
        'overdueCards': overdueCards,
        'avgEaseFactor': avgEaseFactor,
        'avgInterval': avgInterval,
        'avgDifficulty': avgDifficulty,
        'avgStability': avgStability,
        'algorithm': 'FSRS-Inspired',
      };
    } catch (e) {
      print('Error getting study stats: $e');
      return {};
    }
  }

  /// Calculate average difficulty across all cards
  double _calculateAverageDifficulty(List<Flashcard> cards) {
    if (cards.isEmpty) return 0.0;
    
    double totalDifficulty = 0.0;
    int count = 0;
    
    for (final card in cards) {
      if (card.lastReviewed != null) {
        totalDifficulty += _getCardDifficulty(card);
        count++;
      }
    }
    
    return count > 0 ? totalDifficulty / count : 0.0;
  }

  /// Calculate average stability across all cards
  double _calculateAverageStability(List<Flashcard> cards) {
    if (cards.isEmpty) return 0.0;
    
    double totalStability = 0.0;
    int count = 0;
    
    for (final card in cards) {
      if (card.lastReviewed != null) {
        // Stability increases with interval and ease factor
        final stability = (card.interval * card.easeFactor * 0.3).toDouble();
        totalStability += stability;
        count++;
      }
    }
    
    return count > 0 ? totalStability / count : 0.0;
  }

  /// Reset card progress (for relearning)
  Future<void> resetCardProgress(Flashcard card) async {
    try {
      final updatedCard = card.copyWith(
        interval: 1,
        easeFactor: 2.5,
        nextReview: DateTime.now(),
        lastReviewed: null,
        reviewCount: 0,
        updatedAt: DateTime.now(),
      );
      
      await _dataService.updateFlashcard(updatedCard);
    } catch (e) {
      print('Error resetting card progress: $e');
      rethrow;
    }
  }

  /// Get cards that need relearning using FSRS-inspired algorithm
  Future<List<Flashcard>> getRelearningCards(String deckId) async {
    try {
      final allCards = await _dataService.getFlashcardsForDeck(deckId);
      final now = DateTime.now();
      
      return allCards.where((card) {
        if (card.lastReviewed == null) return false;
        
        // Cards with very low ease factor (high difficulty)
        if (card.easeFactor < 1.5) return true;
        
        // Cards that are overdue by a significant amount
        if (card.nextReview != null && card.nextReview!.isBefore(now)) {
          final daysOverdue = now.difference(card.nextReview!).inDays;
          return daysOverdue > card.interval * 2;
        }
        
        return false;
      }).toList();
    } catch (e) {
      print('Error getting relearning cards: $e');
      return [];
    }
  }
}
