import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 3)
class Note extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  List<String> tags;

  @HiveField(6)
  String? linkedCardId;

  @HiveField(7)
  String? linkedDeckId;

  @HiveField(8)
  String? linkedPackId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.linkedCardId,
    this.linkedDeckId,
    this.linkedPackId,
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? linkedCardId,
    String? linkedDeckId,
    String? linkedPackId,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      linkedCardId: linkedCardId ?? this.linkedCardId,
      linkedDeckId: linkedDeckId ?? this.linkedDeckId,
      linkedPackId: linkedPackId ?? this.linkedPackId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'linkedCardId': linkedCardId,
      'linkedDeckId': linkedDeckId,
      'linkedPackId': linkedPackId,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      tags: List<String>.from(map['tags'] ?? []),
      linkedCardId: map['linkedCardId'],
      linkedDeckId: map['linkedDeckId'],
      linkedPackId: map['linkedPackId'],
    );
  }
}
