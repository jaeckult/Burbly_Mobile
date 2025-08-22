import 'package:hive/hive.dart';

part 'deck.g.dart';

@HiveType(typeId: 1)
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
  int cardCount;

  @HiveField(6)
  bool isSynced; // Track if synced to Firestore

  @HiveField(7)
  String? coverColor; // Hex color for deck cover

  Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.cardCount = 0,
    this.isSynced = false,
    this.coverColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cardCount': cardCount,
      'isSynced': isSynced,
      'coverColor': coverColor,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      cardCount: map['cardCount'] ?? 0,
      isSynced: map['isSynced'] ?? true,
      coverColor: map['coverColor'],
    );
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? cardCount,
    bool? isSynced,
    String? coverColor,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cardCount: cardCount ?? this.cardCount,
      isSynced: isSynced ?? this.isSynced,
      coverColor: coverColor ?? this.coverColor,
    );
  }
}
