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
    );
  }
}
