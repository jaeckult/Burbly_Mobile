import 'package:hive/hive.dart';

part 'trash_item.g.dart';

@HiveType(typeId: 9)
class TrashItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String itemType; // deck, flashcard, note, deck_pack

  @HiveField(2)
  String originalId;

  @HiveField(3)
  DateTime deletedAt;

  @HiveField(4)
  Map<String, dynamic> payload; // Original item's serialized map

  @HiveField(5)
  String? parentId; // e.g., deckId for flashcard

  TrashItem({
    required this.id,
    required this.itemType,
    required this.originalId,
    required this.deletedAt,
    required this.payload,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemType': itemType,
      'originalId': originalId,
      'deletedAt': deletedAt.toIso8601String(),
      'payload': payload,
      'parentId': parentId,
    };
  }

  factory TrashItem.fromMap(Map<String, dynamic> map) {
    return TrashItem(
      id: map['id'],
      itemType: map['itemType'],
      originalId: map['originalId'],
      deletedAt: DateTime.parse(map['deletedAt']),
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      parentId: map['parentId'],
    );
  }
}




