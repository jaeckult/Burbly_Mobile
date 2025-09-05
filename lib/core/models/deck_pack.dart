import 'package:hive/hive.dart';

part 'deck_pack.g.dart';

@HiveType(typeId: 2)
class DeckPack extends HiveObject {
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
  String coverColor;

  @HiveField(6)
  int deckCount;

  @HiveField(7)
  List<String> deckIds;

  DeckPack({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.coverColor,
    this.deckCount = 0,
    this.deckIds = const [],
  });

  DeckPack copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverColor,
    int? deckCount,
    List<String>? deckIds,
  }) {
    return DeckPack(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverColor: coverColor ?? this.coverColor,
      deckCount: deckCount ?? this.deckCount,
      deckIds: deckIds ?? this.deckIds,
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
      'deckCount': deckCount,
      'deckIds': deckIds,
    };
  }

  factory DeckPack.fromMap(Map<String, dynamic> map) {
    return DeckPack(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      coverColor: map['coverColor'],
      deckCount: map['deckCount'] ?? 0,
      deckIds: List<String>.from(map['deckIds'] ?? []),
    );
  }
}
