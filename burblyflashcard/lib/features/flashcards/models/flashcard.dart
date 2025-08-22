import 'package:hive/hive.dart';

part 'flashcard.g.dart';

@HiveType(typeId: 0)
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
  int difficulty; // 1-5 scale

  @HiveField(7)
  DateTime? lastReviewed;

  @HiveField(8)
  int reviewCount;

  @HiveField(9)
  bool isSynced; // Track if synced to Firestore

  Flashcard({
    required this.id,
    required this.deckId,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
    this.difficulty = 3,
    this.lastReviewed,
    this.reviewCount = 0,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deckId': deckId,
      'question': question,
      'answer': answer,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'difficulty': difficulty,
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
      difficulty: map['difficulty'] ?? 3,
      lastReviewed: map['lastReviewed'] != null 
          ? DateTime.parse(map['lastReviewed']) 
          : null,
      reviewCount: map['reviewCount'] ?? 0,
      isSynced: map['isSynced'] ?? true,
    );
  }

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? question,
    String? answer,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? difficulty,
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
      difficulty: difficulty ?? this.difficulty,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
