import 'package:hive/hive.dart';

part 'deck.g.dart';

@HiveType(typeId: 0)
class Deck extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String? coverColor;

  @HiveField(6)
  int cardCount;

  @HiveField(7)
  String? packId;

  @HiveField(8)
  bool spacedRepetitionEnabled;

  @HiveField(9)
  int? timerDuration;

  @HiveField(10)
  bool isSynced;

  @HiveField(11)
  bool? showStudyStats;

  @HiveField(12)
  DateTime? scheduledReviewTime;

  @HiveField(13)
  bool? scheduledReviewEnabled;

  // Deck-level tags for review flow
  @HiveField(14)
  bool? deckIsReviewNow;

  @HiveField(15)
  DateTime? deckReviewNowStartTime;

  @HiveField(16)
  bool? deckIsOverdue;

  @HiveField(17)
  DateTime? deckOverdueStartTime;

  @HiveField(18)
  bool? deckIsReviewed;

  @HiveField(19)
  DateTime? deckReviewedStartTime;

  Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.coverColor,
    this.cardCount = 0,
    this.packId,
    this.spacedRepetitionEnabled = true,
    this.timerDuration,
    this.isSynced = false,
    this.showStudyStats = true,
    this.scheduledReviewTime,
    this.scheduledReviewEnabled = false,
    this.deckIsReviewNow = false,
    this.deckReviewNowStartTime,
    this.deckIsOverdue = false,
    this.deckOverdueStartTime,
    this.deckIsReviewed = false,
    this.deckReviewedStartTime,
  });

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverColor,
    int? cardCount,
    String? packId,
    bool? spacedRepetitionEnabled,
    int? timerDuration,
    bool? isSynced,
    bool? showStudyStats,
    DateTime? scheduledReviewTime,
    bool? scheduledReviewEnabled,
    bool? deckIsReviewNow,
    DateTime? deckReviewNowStartTime,
    bool? deckIsOverdue,
    DateTime? deckOverdueStartTime,
    bool? deckIsReviewed,
    DateTime? deckReviewedStartTime,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverColor: coverColor ?? this.coverColor,
      cardCount: cardCount ?? this.cardCount,
      packId: packId ?? this.packId,
      spacedRepetitionEnabled: spacedRepetitionEnabled ?? this.spacedRepetitionEnabled,
      timerDuration: timerDuration ?? this.timerDuration,
      isSynced: isSynced ?? this.isSynced,
      showStudyStats: showStudyStats ?? this.showStudyStats,
      scheduledReviewTime: scheduledReviewTime ?? this.scheduledReviewTime,
      scheduledReviewEnabled: scheduledReviewEnabled ?? this.scheduledReviewEnabled,
      deckIsReviewNow: deckIsReviewNow ?? this.deckIsReviewNow,
      deckReviewNowStartTime: deckReviewNowStartTime ?? this.deckReviewNowStartTime,
      deckIsOverdue: deckIsOverdue ?? this.deckIsOverdue,
      deckOverdueStartTime: deckOverdueStartTime ?? this.deckOverdueStartTime,
      deckIsReviewed: deckIsReviewed ?? this.deckIsReviewed,
      deckReviewedStartTime: deckReviewedStartTime ?? this.deckReviewedStartTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverColor': coverColor,
      'cardCount': cardCount,
      'packId': packId,
      'spacedRepetitionEnabled': spacedRepetitionEnabled,
      'timerDuration': timerDuration,
      'isSynced': isSynced,
      'showStudyStats': showStudyStats,
      'scheduledReviewTime': scheduledReviewTime?.toIso8601String(),
      'scheduledReviewEnabled': scheduledReviewEnabled,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      coverColor: map['coverColor'],
      cardCount: map['cardCount'] ?? 0,
      packId: map['packId'],
      spacedRepetitionEnabled: map['spacedRepetitionEnabled'] ?? false,
      timerDuration: map['timerDuration'],
      isSynced: map['isSynced'] ?? false,
      showStudyStats: map['showStudyStats'] ?? true,
      scheduledReviewTime: map['scheduledReviewTime'] != null 
          ? DateTime.parse(map['scheduledReviewTime']) 
          : null,
      scheduledReviewEnabled: map['scheduledReviewEnabled'] ?? false,
    );
  }
}
