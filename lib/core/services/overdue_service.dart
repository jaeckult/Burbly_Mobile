import 'dart:async';
import '../models/flashcard.dart';
import '../models/deck.dart';
import 'data_service.dart';
import 'notification_service.dart';

class OverdueService {
  static final OverdueService _instance = OverdueService._internal();
  factory OverdueService() => _instance;
  OverdueService._internal();

  final DataService _dataService = DataService();
  final NotificationService _notificationService = NotificationService();
  Timer? _overdueCheckTimer;
  static const Duration _overdueCheckInterval = Duration(minutes: 1);
  static const Duration _reviewNowDuration = Duration(minutes: 10);
  static const Duration _overdueTagDuration = Duration(minutes: 10);
  static const Duration _reviewedTagDuration = Duration(minutes: 10);

  // Start monitoring overdue cards
  void startOverdueMonitoring() {
    _overdueCheckTimer?.cancel();
    _overdueCheckTimer = Timer.periodic(_overdueCheckInterval, (_) {
      _checkAndUpdateOverdueCards();
    });
  }

  // Stop monitoring overdue cards
  void stopOverdueMonitoring() {
    _overdueCheckTimer?.cancel();
  }

  // Check and update overdue status for all decks and their cards
  Future<void> _checkAndUpdateOverdueCards() async {
    try {
      final decks = await _dataService.getDecks();
      for (final deck in decks) {
        if (deck.spacedRepetitionEnabled) {
          await _updateDeckTagState(deck);
          await _updateDeckOverdueStatus(deck);
        }
      }
    } catch (e) {
      print('Error checking overdue cards: $e');
    }
  }

  // Update overdue status for a specific deck
  Future<void> _updateDeckTagState(Deck deck) async {
    try {
      final now = DateTime.now();
      Deck updated = deck;

      // Only handle deck-level scheduling
      final scheduled = (deck.scheduledReviewEnabled == true) ? deck.scheduledReviewTime : null;
      if (scheduled != null) {
        // If user changed the scheduled time away from previous window, clear transient tags
        final scheduledChanged = deck.scheduledReviewTime != scheduled;
        if (scheduledChanged && (updated.deckIsReviewNow == true || updated.deckIsOverdue == true)) {
          updated = updated.copyWith(
            deckIsReviewNow: false,
            deckReviewNowStartTime: null,
            deckIsOverdue: false,
            deckOverdueStartTime: null,
          );
        }
        
        if (now.isBefore(scheduled)) {
          final minutesUntil = scheduled.difference(now).inMinutes;
          if (minutesUntil <= 10 && minutesUntil >= 0) {
            // Enter Review Now window (10 minutes before scheduled time)
            if (updated.deckIsReviewNow != true) {
              updated = updated.copyWith(
                deckIsReviewNow: true,
                deckReviewNowStartTime: now,
                deckIsOverdue: false,
                deckOverdueStartTime: null,
                deckIsReviewed: false,
                deckReviewedStartTime: null,
              );
              
              // Send review now notification
              await _notificationService.showReviewNowNotification(
                deck.name,
                'Time to review your deck!',
                deckId: deck.id,
              );
              
              print('Deck ${deck.name} entered Review Now window at ${now.toString()}');
            }
          } else {
            // Outside pre-window - clear Review Now
            if (updated.deckIsReviewNow == true) {
              updated = updated.copyWith(
                deckIsReviewNow: false,
                deckReviewNowStartTime: null,
              );
            }
            // Not overdue before scheduled time
            if (updated.deckIsOverdue == true) {
              updated = updated.copyWith(deckIsOverdue: false);
            }
          }
                 } else {
           // Scheduled time has passed: show Overdue ONLY if not reviewed after schedule
           final reviewedAfterSchedule =
               (updated.deckReviewedStartTime != null && updated.deckReviewedStartTime!.isAfter(
  scheduled.add(const Duration(minutes: 10)),
)
);
           if (updated.deckIsOverdue != true && !reviewedAfterSchedule) {
             updated = updated.copyWith(
               deckIsReviewNow: false,
               deckReviewNowStartTime: null,
               deckIsOverdue: true,
               deckOverdueStartTime: now,
             );
             
             print('Deck ${deck.name} marked as Overdue at ${now.toString()}');
           } else {
             // Always clear Review Now after schedule passes
             if (updated.deckIsReviewNow == true) {
               updated = updated.copyWith(
                 deckIsReviewNow: false,
                 deckReviewNowStartTime: null,
               );
             }
           }
         }
      }

      // Expire Reviewed after 10 minutes (keep timestamp to show "Reviewed X ago")
      if (updated.deckIsReviewed == true && updated.deckReviewedStartTime != null) {
        final diff = now.difference(updated.deckReviewedStartTime!);
        if (diff.inMinutes >= 10) {
          updated = updated.copyWith(
            deckIsReviewed: false,
            // keep deckReviewedStartTime for relative time display
          );
          print('Deck ${deck.name} Reviewed tag expired at ${now.toString()}');
        }
      }

      if (updated != deck) {
        await _dataService.updateDeck(updated);
        print('Updated deck-level tags for ${deck.name}: ReviewNow=${updated.deckIsReviewNow}, Overdue=${updated.deckIsOverdue}, Reviewed=${updated.deckIsReviewed}');
      }
    } catch (e) {
      print('Error updating deck tag state for deck ${deck.name}: $e');
    }
  }

  Future<void> _updateDeckOverdueStatus(Deck deck) async {
    try {
      final flashcards = await _dataService.getFlashcardsForDeck(deck.id);
      final now = DateTime.now();
      
      // Only handle deck-level scheduling - no card-level scheduling
      // Clear any existing card-level tags since we only use deck-level
      for (final flashcard in flashcards) {
        // Clear any card-level review tags since we only use deck-level
        if (flashcard.isReviewNow == true || flashcard.isOverdue == true || flashcard.isReviewed == true) {
          final updatedFlashcard = flashcard.copyWith(
            isReviewNow: false,
            reviewNowStartTime: null,
            isOverdue: false,
            overdueStartTime: null,
            isReviewed: false,
            reviewedStartTime: null,
          );
          await _dataService.updateFlashcard(updatedFlashcard);
        }
      }
      
      // Deck-level tags are handled in _updateDeckTagState method
      // This method now only ensures card-level tags are cleared
      print('Cleared card-level tags for deck ${deck.name} - using deck-level scheduling only');
    } catch (e) {
      print('Error updating overdue status for deck ${deck.name}: $e');
    }
  }

  // Mark card as studied and update overdue status
  Future<void> markCardAsStudied(Flashcard flashcard, int quality) async {
    try {
      final now = DateTime.now();
      
      // Calculate next review time using SM2 algorithm
      final nextReview = _calculateNextReview(flashcard, quality);
      
      // Update flashcard with new review data (no card-level tags)
      final updatedFlashcard = flashcard.copyWith(
        lastReviewed: now,
        nextReview: nextReview,
        reviewCount: flashcard.reviewCount + 1,
        // Clear any card-level tags since we only use deck-level
        isOverdue: false,
        overdueStartTime: null,
        isReviewNow: false,
        reviewNowStartTime: null,
        isReviewed: false, // No card-level reviewed tag
        reviewedStartTime: null,
        updatedAt: now,
      );
      
      await _dataService.updateFlashcard(updatedFlashcard);

      // Update deck-level tags to Reviewed (for 10 minutes) and clear others
      final deck = await _dataService.getDeck(flashcard.deckId);
      if (deck != null) {
        final updatedDeck = deck.copyWith(
          deckIsReviewNow: false,
          deckReviewNowStartTime: null,
          deckIsOverdue: false,
          deckOverdueStartTime: null,
          deckIsReviewed: true,
          deckReviewedStartTime: now,
        );
        await _dataService.updateDeck(updatedDeck);
        print('Deck ${deck.name} marked as Reviewed after studying card');
      }
      
      // No individual card notifications - only deck-level scheduling
    } catch (e) {
      print('Error marking card as studied: $e');
    }
  }

  // Calculate next review time using SM2 algorithm
  DateTime _calculateNextReview(Flashcard flashcard, int quality) {
    final now = DateTime.now();
    
    if (quality < 3) {
      // Failed - reset to 1 day
      return now.add(const Duration(days: 1));
    } else {
      // Passed - calculate interval
      double newEaseFactor = flashcard.easeFactor;
      int newInterval;
      
      if (quality == 3) {
        // Hard - decrease ease factor slightly
        newEaseFactor = (newEaseFactor - 0.15).clamp(1.3, 2.5);
        newInterval = (flashcard.interval * 1.2).round();
      } else if (quality == 4) {
        // Good - maintain ease factor
        newInterval = (flashcard.interval * newEaseFactor).round();
      } else {
        // Easy - increase ease factor
        newInterval = (flashcard.interval * newEaseFactor).round();
      }
      
      // Ensure minimum interval of 1 day
      newInterval = newInterval.clamp(1, 365);
      
      return now.add(Duration(days: newInterval));
    }
  }

  // No individual card notifications - only deck-level scheduling
  // This method is removed since we only use deck-level scheduling

  // Get overdue statistics for a deck
  Future<Map<String, dynamic>> getOverdueStats(String deckId) async {
    try {
      final flashcards = await _dataService.getFlashcardsForDeck(deckId);
      final now = DateTime.now();
      
      int totalOverdue = 0;
      int totalOverdueMinutes = 0;
      List<Flashcard> overdueCards = [];
      
      for (final flashcard in flashcards) {
        if (flashcard.isOverdue == true && flashcard.overdueStartTime != null) {
          totalOverdue++;
          overdueCards.add(flashcard);
          
          // Calculate how long it's been overdue
          final overdueDuration = now.difference(flashcard.overdueStartTime!);
          totalOverdueMinutes += overdueDuration.inMinutes;
        }
      }
      
      return {
        'totalOverdue': totalOverdue,
        'totalOverdueMinutes': totalOverdueMinutes,
        'overdueCards': overdueCards,
        'averageOverdueMinutes': totalOverdue > 0 ? totalOverdueMinutes / totalOverdue : 0,
      };
    } catch (e) {
      print('Error getting overdue stats: $e');
      return {
        'totalOverdue': 0,
        'totalOverdueMinutes': 0,
        'overdueCards': [],
        'averageOverdueMinutes': 0,
      };
    }
  }

  // Get all overdue cards across all decks
  Future<List<Flashcard>> getAllOverdueCards() async {
    try {
      // With deck-level scheduling, individual cards no longer have nextReview dates
      // This method is kept for backward compatibility but returns empty list
      // Overdue functionality is now handled at the deck level
      return [];
    } catch (e) {
      print('Error getting all overdue cards: $e');
      return [];
    }
  }

  // Card-level tags are disabled - only deck-level tags are used
  // These methods return false/empty since we don't use card-level scheduling
  
  bool shouldShowReviewNowTag(Flashcard flashcard) => false;
  String getReviewNowTagText(Flashcard flashcard) => '';
  bool shouldShowOverdueTag(Flashcard flashcard) => false;
  String getOverdueTagText(Flashcard flashcard) => '';
  bool shouldShowReviewedTag(Flashcard flashcard) => false;
  String getReviewedTagText(Flashcard flashcard) => '';

  // Dispose resources
  void dispose() {
    stopOverdueMonitoring();
  }
}

