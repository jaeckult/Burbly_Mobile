import 'package:hive/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 1)
class Flashcard extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String deckId;

  @HiveField(2)
  String question;

  @HiveField(3)
  String answer;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  int interval;

  @HiveField(7)
  DateTime? nextReview;

  @HiveField(8)
  double easeFactor;

  @HiveField(9)
  DateTime? lastReviewed;

  @HiveField(10)
  int reviewCount;

  @HiveField(11)
  bool isSynced;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
    this.interval = 1,
    this.nextReview,
    this.easeFactor = 2.5,
    this.lastReviewed,
    this.reviewCount = 0,
    this.isSynced = false,
  });

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? interval,
    DateTime? nextReview,
    double? easeFactor,
    DateTime? lastReviewed,
    int? reviewCount,
    bool? isSynced,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      interval: interval ?? this.interval,
      nextReview: nextReview ?? this.nextReview,
      easeFactor: easeFactor ?? this.easeFactor,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'interval': interval,
      'nextReview': nextReview?.toIso8601String(),
      'easeFactor': easeFactor,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'isSynced': isSynced,
    };
  }

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      deckId: map['deckId'],
      question: map['question'],
      answer: map['answer'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      interval: map['interval'] ?? 1,
      nextReview: map['nextReview'] != null ? DateTime.parse(map['nextReview']) : null,
      easeFactor: map['easeFactor']?.toDouble() ?? 2.5,
      lastReviewed: map['lastReviewed'] != null ? DateTime.parse(map['lastReviewed']) : null,
      reviewCount: map['reviewCount'] ?? 0,
      isSynced: map['isSynced'] ?? false,
    );
  }
}
