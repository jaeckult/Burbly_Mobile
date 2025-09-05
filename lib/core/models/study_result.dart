class StudyResult {
  final String cardId;
  final int oldInterval;
  final int newInterval;
  final double oldEaseFactor;
  final double newEaseFactor;
  final StudyRating rating;
  final DateTime nextReview;
  final bool isNewCard;
  final DateTime? previouslyScheduledReview; // New field to track previously scheduled time

  StudyResult({
    required this.cardId,
    required this.oldInterval,
    required this.newInterval,
    required this.oldEaseFactor,
    required this.newEaseFactor,
    required this.rating,
    required this.nextReview,
    required this.isNewCard,
    this.previouslyScheduledReview, // Optional field for previously scheduled time
  });
}

/// Study rating enum
enum StudyRating {
  again,  // Failed to recall
  hard,   // Difficult to recall
  good,   // Correctly recalled
  easy,   // Very easy to recall
}
