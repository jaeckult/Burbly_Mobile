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

      // Pre-window: Set Review Now 10 minutes BEFORE scheduled time
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
            // Enter Review Now window (ends exactly at scheduled time)
            if (updated.deckIsReviewNow != true) {
              updated = updated.copyWith(
                deckIsReviewNow: true,
                deckReviewNowStartTime: now,
                deckIsOverdue: false,
                // reset prior reviewed when a new schedule window starts
                deckIsReviewed: false,
                deckReviewedStartTime: null,
              );
            }
          } else {
            // Outside pre-window
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
          // Scheduled time has passed: show Overdue (unless recently reviewed by user)
          if (updated.deckIsOverdue != true && updated.deckIsReviewed != true) {
            updated = updated.copyWith(
              deckIsReviewNow: false,
              deckReviewNowStartTime: null,
              deckIsOverdue: true,
              deckOverdueStartTime: now,
            );
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

      // Note: No generic 10-minute Review Now expiry; it ends at the scheduled time.

      // Expire Reviewed after 10 minutes (keep timestamp to show "Reviewed X ago")
      if (updated.deckIsReviewed == true && updated.deckReviewedStartTime != null) {
        final diff = now.difference(updated.deckReviewedStartTime!);
        if (diff.inMinutes >= 10) {
          updated = updated.copyWith(
            deckIsReviewed: false,
            // keep deckReviewedStartTime for relative time display
          );
        }
      }

      if (updated != deck) {
        await _dataService.updateDeck(updated);
      }
    } catch (e) {
      print('Error updating deck tag state for deck ${deck.name}: $e');
    }
  }

  Future<void> _updateDeckOverdueStatus(Deck deck) async {
    try {
      final flashcards = await _dataService.getFlashcardsForDeck(deck.id);
      final now = DateTime.now();
      
      for (final flashcard in flashcards) {
        // Card-level logic remains for nextReview and transitions, but deck-level UI/tags are now primary
        if (flashcard.nextReview != null && flashcard.nextReview!.isBefore(now)) {
          // Card is due for review
          if (flashcard.isReviewNow != true && flashcard.isOverdue != true && flashcard.isReviewed != true) {
            // Show "Review Now" tag for 10 minutes
            final updatedFlashcard = flashcard.copyWith(
              isReviewNow: true,
              reviewNowStartTime: now,
            );
            await _dataService.updateFlashcard(updatedFlashcard);
            
            // Send review now notification
            await _notificationService.showReviewNowNotification(
              deck.name,
              flashcard.question,
            );
            
            print('Card ${flashcard.id} marked as Review Now at ${now.toString()}');
          } else if (flashcard.isReviewNow == true && flashcard.reviewNowStartTime != null) {
            // Check if "Review Now" tag should expire (after 10 minutes)
            final reviewNowDuration = now.difference(flashcard.reviewNowStartTime!);
            if (reviewNowDuration.inMinutes >= 10) {
              // Expire "Review Now" tag and show "Overdue" tag
              final updatedFlashcard = flashcard.copyWith(
                isReviewNow: false,
                reviewNowStartTime: null,
                isOverdue: true,
                overdueStartTime: now,
              );
              await _dataService.updateFlashcard(updatedFlashcard);
              
              // Send overdue notification
              await _notificationService.showOverdueCardNotification(
                deck.name,
                flashcard.question,
              );
              
              print('Card ${flashcard.id} expired Review Now and marked as Overdue at ${now.toString()}');
            }
          }
        }
        
        // Check if "Reviewed" tag should expire (after 10 minutes)
        if (flashcard.isReviewed == true && flashcard.reviewedStartTime != null) {
          final reviewedDuration = now.difference(flashcard.reviewedStartTime!);
          if (reviewedDuration.inMinutes >= 10) {
            final updatedFlashcard = flashcard.copyWith(
              isReviewed: false,
              reviewedStartTime: null,
            );
            await _dataService.updateFlashcard(updatedFlashcard);
            
            print('Card ${flashcard.id} Reviewed tag expired at ${now.toString()}');
          }
        }
      }
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
      
      // Update flashcard with new review data
      final updatedFlashcard = flashcard.copyWith(
        lastReviewed: now,
        nextReview: nextReview,
        reviewCount: flashcard.reviewCount + 1,
        isOverdue: false, // No longer overdue
        overdueStartTime: null, // Clear overdue tracking
        isReviewNow: false, // No longer review now
        reviewNowStartTime: null, // Clear review now tracking
        isReviewed: true, // Show reviewed tag
        reviewedStartTime: now, // Start reviewed tag timer
        updatedAt: now,
      );
      
      await _dataService.updateFlashcard(updatedFlashcard);

      // Also update deck-level tags to Reviewed (for 10 minutes) and clear others
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
      }
      
      // Check if we need to send a notification for the next review
      if (nextReview.isAfter(now)) {
        await _scheduleNextReviewNotification(updatedFlashcard);
      }
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

  // Schedule notification for next review
  Future<void> _scheduleNextReviewNotification(Flashcard flashcard) async {
    try {
      final deck = await _dataService.getDeck(flashcard.deckId);
      if (deck != null) {
        await _notificationService.scheduleCardReviewNotification(
          flashcard,
          deck,
          flashcard.nextReview!,
        );
      }
    } catch (e) {
      print('Error scheduling next review notification: $e');
    }
  }

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
      final decks = await _dataService.getDecks();
      List<Flashcard> allOverdueCards = [];
      
      for (final deck in decks) {
        if (deck.spacedRepetitionEnabled) {
          final flashcards = await _dataService.getFlashcardsForDeck(deck.id);
          final overdueCards = flashcards.where((card) => card.isOverdue == true).toList();
          allOverdueCards.addAll(overdueCards);
        }
      }
      
      // Sort by overdue start time (most overdue first)
      allOverdueCards.sort((a, b) {
        if (a.overdueStartTime == null && b.overdueStartTime == null) return 0;
        if (a.overdueStartTime == null) return 1;
        if (b.overdueStartTime == null) return -1;
        return a.overdueStartTime!.compareTo(b.overdueStartTime!);
      });
      
      return allOverdueCards;
    } catch (e) {
      print('Error getting all overdue cards: $e');
      return [];
    }
  }

  // Check if a card should show review now tag (within 10 minutes of becoming due)
  bool shouldShowReviewNowTag(Flashcard flashcard) {
    if (flashcard.isReviewNow != true || flashcard.reviewNowStartTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final reviewNowDuration = now.difference(flashcard.reviewNowStartTime!);
    
    // Only show review now tag for 10 minutes after becoming due
    return reviewNowDuration.inMinutes < 10;
  }

  // Get review now tag text with countdown
  String getReviewNowTagText(Flashcard flashcard) {
    if (flashcard.isReviewNow != true || flashcard.reviewNowStartTime == null) {
      return '';
    }
    
    final now = DateTime.now();
    final reviewNowDuration = now.difference(flashcard.reviewNowStartTime!);
    final remainingMinutes = 10 - reviewNowDuration.inMinutes;
    
    if (remainingMinutes <= 0) {
      return 'Review Now';
    } else if (remainingMinutes == 1) {
      return 'Review Now (1m)';
    } else {
      return 'Review Now (${remainingMinutes}m)';
    }
  }

  // Check if a card should show overdue tag (stays until reviewed)
  bool shouldShowOverdueTag(Flashcard flashcard) {
    return flashcard.isOverdue == true;
  }

  // Get overdue tag text
  String getOverdueTagText(Flashcard flashcard) {
    if (flashcard.isOverdue != true) {
      return '';
    }
    
    return 'Overdue';
  }

  // Check if a card should show reviewed tag (within 10 minutes of being reviewed)
  bool shouldShowReviewedTag(Flashcard flashcard) {
    if (flashcard.isReviewed != true || flashcard.reviewedStartTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final reviewedDuration = now.difference(flashcard.reviewedStartTime!);
    
    // Only show reviewed tag for 10 minutes after being reviewed
    return reviewedDuration.inMinutes < 10;
  }

  // Get reviewed tag text with countdown
  String getReviewedTagText(Flashcard flashcard) {
    if (flashcard.isReviewed != true || flashcard.reviewedStartTime == null) {
      return '';
    }
    
    final now = DateTime.now();
    final reviewedDuration = now.difference(flashcard.reviewedStartTime!);
    final remainingMinutes = 10 - reviewedDuration.inMinutes;
    
    if (remainingMinutes <= 0) {
      return 'Reviewed';
    } else if (remainingMinutes == 1) {
      return 'Reviewed (1m)';
    } else {
      return 'Reviewed (${remainingMinutes}m)';
    }
  }

  // Dispose resources
  void dispose() {
    stopOverdueMonitoring();
  }
}

