import '../../../core/models/flashcard.dart';
import '../../../core/models/study_session.dart';
import '../../../core/models/study_result.dart';
import 'data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyService {
  static final StudyService _instance = StudyService._internal();
  factory StudyService() => _instance;
  StudyService._internal();

  final DataService _dataService = DataService();

  // Study intervals in days - more reasonable than the current system
  static const Map<int, int> _intervals = {
    1: 1,    // Learning: 1 day
    2: 3,    // 3 days
    3: 7,    // 1 week
    4: 14,   // 2 weeks
    5: 30,   // 1 month
    6: 60,   // 2 months
    7: 90,   // 3 months
    8: 180,  // 6 months
    9: 365,  // 1 year
  };

  // Ease factor adjustments
  static const double _easyBonus = 0.15;
  static const double _goodBonus = 0.10;
  static const double _hardPenalty = 0.20;
  static const double _againPenalty = 0.30;

  /// Get cards that are due for study
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

  /// Get cards for a study session
  Future<List<Flashcard>> getCardsForStudySession(String deckId, {int maxCards = 20}) async {
    try {
      final dueCards = await getDueCards(deckId);
      
      // Prioritize cards: overdue first, then due today, then new cards
      dueCards.sort((a, b) {
        final aPriority = _getCardPriority(a);
        final bPriority = _getCardPriority(b);
        return bPriority.compareTo(aPriority); // Higher priority first
      });

      // Limit the number of cards for a session
      return dueCards.take(maxCards).toList();
    } catch (e) {
      print('Error getting cards for study session: $e');
      return [];
    }
  }

  /// Get card priority for sorting (higher number = higher priority)
  int _getCardPriority(Flashcard card) {
    if (card.lastReviewed == null) return 100; // New cards highest priority
    
    final now = DateTime.now();
    final daysOverdue = now.difference(card.nextReview ?? card.lastReviewed!).inDays;
    
    if (daysOverdue > 0) return 90 + daysOverdue; // Overdue cards
    if (daysOverdue == 0) return 80; // Due today
    return 70 - daysOverdue.abs(); // Future due cards
  }

  /// Calculate study result without applying changes
  StudyResult calculateStudyResult(Flashcard card, StudyRating rating) {
    final now = DateTime.now();
    final oldInterval = card.interval;
    final oldEaseFactor = card.easeFactor;
    
    // Calculate new interval and ease factor
    final newInterval = _calculateNewInterval(card, rating);
    final newEaseFactor = _calculateNewEaseFactor(card, rating);
    
    // Calculate next review date
    final nextReview = _calculateNextReview(now, newInterval);
    
    // Create study result without updating the card
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
  }

  /// Apply study results to cards
  Future<void> applyStudyResults(List<StudyResult> studyResults, List<Flashcard> flashcards) async {
    try {
      final now = DateTime.now();
      
      for (final result in studyResults) {
        final card = flashcards.firstWhere((c) => c.id == result.cardId);
        
        // Update card with the calculated values
        final updatedCard = card.copyWith(
          interval: result.newInterval,
          easeFactor: result.newEaseFactor,
          nextReview: result.nextReview,
          lastReviewed: now,
          reviewCount: card.reviewCount + 1,
          updatedAt: now,
        );

        await _dataService.updateFlashcard(updatedCard);
      }
    } catch (e) {
      print('Error applying study results: $e');
      rethrow;
    }
  }

  /// Process study result and update card (legacy method)
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

  /// Calculate new interval based on rating
  int _calculateNewInterval(Flashcard card, StudyRating rating) {
    switch (rating) {
      case StudyRating.again:
        return 1; // Reset to learning
      case StudyRating.hard:
        // Reduce interval but don't reset completely
        final newInterval = (card.interval * 0.7).round();
        return newInterval < 1 ? 1 : newInterval;
      case StudyRating.good:
        // Normal progression
        return _getNextInterval(card.interval);
      case StudyRating.easy:
        // Accelerate progression
        final nextInterval = _getNextInterval(card.interval);
        return _getNextInterval(nextInterval);
    }
  }

  /// Get the next interval in the sequence
  int _getNextInterval(int currentInterval) {
    final intervals = _intervals.values.toList();
    final currentIndex = intervals.indexOf(currentInterval);
    
    if (currentIndex == -1 || currentIndex >= intervals.length - 1) {
      // If not found or at max, increase by 50%
      return (currentInterval * 1.5).round();
    }
    
    return intervals[currentIndex + 1];
  }

  /// Calculate new ease factor based on rating
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

  /// Get study statistics for a deck
  Future<Map<String, dynamic>> getStudyStats(String deckId) async {
    try {
      final allCards = await _dataService.getFlashcardsForDeck(deckId);
      final studySessions = await _dataService.getStudySessionsForDeck(deckId);
      final now = DateTime.now();
      
      // Calculate various statistics
      final totalCards = allCards.length;
      final newCards = allCards.where((card) => card.lastReviewed == null).length;
      final learningCards = allCards.where((card) => card.interval == 1).length;
      final reviewCards = allCards.where((card) => card.interval > 1).length;
      
      // Due cards calculation
      final dueCards = allCards.where((card) {
        if (card.lastReviewed == null) return true;
        if (card.nextReview != null) {
          return card.nextReview!.isBefore(now);
        }
        final daysSinceReview = now.difference(card.lastReviewed!).inDays;
        return daysSinceReview >= card.interval;
      }).length;
      
      // Overdue cards calculation
      final overdueCards = allCards.where((card) {
        if (card.nextReview == null || card.lastReviewed == null) return false;
        return card.nextReview!.isBefore(now);
      }).length;
      
      // Due tomorrow calculation
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dueTomorrowCards = allCards.where((card) {
        if (card.nextReview == null) return false;
        final reviewDate = DateTime(
          card.nextReview!.year,
          card.nextReview!.month,
          card.nextReview!.day,
        );
        return reviewDate.isAtSameMomentAs(tomorrow);
      }).length;
      
      // Due this week calculation
      final endOfWeek = now.add(const Duration(days: 7));
      final dueThisWeekCards = allCards.where((card) {
        if (card.nextReview == null) return false;
        return card.nextReview!.isAfter(now) && card.nextReview!.isBefore(endOfWeek);
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
      
      // Total reviews across all cards
      final totalReviews = allCards.fold<int>(0, (sum, card) => sum + card.reviewCount);
      
      // Cards with reviews
      final cardsWithReviews = allCards.where((card) => card.reviewCount > 0).length;
      
      // Study session statistics
      final totalSessions = studySessions.length;
      final totalStudyTime = studySessions.fold<int>(0, (sum, session) => sum + session.studyTimeSeconds);
      final avgStudyTime = totalSessions > 0 ? totalStudyTime / totalSessions : 0;
      
      // Accuracy statistics
      final avgAccuracy = totalSessions > 0 
          ? studySessions.fold<double>(0, (sum, session) => sum + session.averageScore) / totalSessions 
          : 0.0;
      
      final bestScore = totalSessions > 0 
          ? studySessions.map((s) => s.averageScore).reduce((a, b) => a > b ? a : b)
          : 0.0;
      
      // Recent activity (last 7 days)
      final recentCards = allCards.where((card) => 
          card.lastReviewed != null && 
          card.lastReviewed!.isAfter(now.subtract(const Duration(days: 7)))).length;
      
      // Study streak calculation
      final studyStreak = _calculateStudyStreak(studySessions);
      
      // Interval distribution
      final Map<int, int> intervalDistribution = {};
      for (final card in allCards) {
        final interval = card.interval;
        intervalDistribution[interval] = (intervalDistribution[interval] ?? 0) + 1;
      }
      
      // Performance trends (last 5 sessions)
      final recentSessions = studySessions
        ..sort((a, b) => b.date.compareTo(a.date));
      final recentScores = recentSessions.take(5).map((s) => s.averageScore).toList();
      
      return {
        'totalCards': totalCards,
        'newCards': newCards,
        'learningCards': learningCards,
        'reviewCards': reviewCards,
        'dueCards': dueCards,
        'overdueCards': overdueCards,
        'dueTomorrowCards': dueTomorrowCards,
        'dueThisWeekCards': dueThisWeekCards,
        'avgEaseFactor': avgEaseFactor,
        'avgInterval': avgInterval,
        'totalReviews': totalReviews,
        'cardsWithReviews': cardsWithReviews,
        'totalSessions': totalSessions,
        'totalStudyTime': totalStudyTime,
        'avgStudyTime': avgStudyTime,
        'avgAccuracy': avgAccuracy,
        'bestScore': bestScore,
        'recentCards': recentCards,
        'studyStreak': studyStreak,
        'intervalDistribution': intervalDistribution,
        'recentScores': recentScores,
        'lastUpdated': now.toIso8601String(),
      };
    } catch (e) {
      print('Error getting study stats: $e');
      return {};
    }
  }
  
  /// Calculate study streak based on study sessions
  int _calculateStudyStreak(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;
    
    final sortedSessions = List<StudySession>.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int streak = 0;
    DateTime currentDate = today;
    
    for (final session in sortedSessions) {
      final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
      if (sessionDate.isAtSameMomentAs(currentDate)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (sessionDate.isBefore(currentDate)) {
        break;
      }
    }
    
    return streak;
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

  /// Get cards that need relearning (failed multiple times)
  Future<List<Flashcard>> getRelearningCards(String deckId) async {
    try {
      final allCards = await _dataService.getFlashcardsForDeck(deckId);
      final now = DateTime.now();
      
      return allCards.where((card) {
        // Cards with very low ease factor
        if (card.easeFactor < 1.5) return true;
        
        // Cards that are overdue by a significant amount
        if (card.nextReview != null && card.nextReview!.isBefore(now)) {
          final daysOverdue = now.difference(card.nextReview!).inDays;
          return daysOverdue > card.interval * 2; // Overdue by more than 2x interval
        }
        
        return false;
      }).toList();
    } catch (e) {
      print('Error getting relearning cards: $e');
      return [];
    }
  }
}

