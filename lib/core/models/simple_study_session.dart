import 'study_result.dart';

class SimpleStudySession {
  final String id;
  final String deckId;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalCards;
  final int completedCards;
  final Map<String, StudyRating> cardResults;
  final bool isCompleted;

  SimpleStudySession({
    required this.id,
    required this.deckId,
    required this.startTime,
    this.endTime,
    required this.totalCards,
    this.completedCards = 0,
    this.cardResults = const {},
    this.isCompleted = false,
  });

  SimpleStudySession copyWith({
    String? id,
    String? deckId,
    DateTime? startTime,
    DateTime? endTime,
    int? totalCards,
    int? completedCards,
    Map<String, StudyRating>? cardResults,
    bool? isCompleted,
  }) {
    return SimpleStudySession(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalCards: totalCards ?? this.totalCards,
      completedCards: completedCards ?? this.completedCards,
      cardResults: cardResults ?? this.cardResults,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Get completion percentage
  double get completionPercentage {
    if (totalCards == 0) return 0.0;
    return (completedCards / totalCards) * 100;
  }

  /// Get accuracy percentage
  double get accuracyPercentage {
    if (cardResults.isEmpty) return 0.0;
    
    int correctAnswers = 0;
    for (final rating in cardResults.values) {
      if (rating == StudyRating.good || rating == StudyRating.easy) {
        correctAnswers++;
      }
    }
    
    return (correctAnswers / cardResults.length) * 100;
  }

  /// Add a card result
  SimpleStudySession addCardResult(String cardId, StudyRating rating) {
    final newResults = Map<String, StudyRating>.from(cardResults);
    newResults[cardId] = rating;
    
    return copyWith(
      cardResults: newResults,
      completedCards: completedCards + 1,
    );
  }

  /// Complete the session
  SimpleStudySession complete() {
    return copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );
  }
}
