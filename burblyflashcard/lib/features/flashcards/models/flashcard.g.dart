// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 0;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      deckId: fields[1] as String,
      question: fields[2] as String,
      answer: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      difficulty: fields[6] as int,
      lastReviewed: fields[7] as DateTime?,
      reviewCount: fields[8] as int,
      isSynced: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deckId)
      ..writeByte(2)
      ..write(obj.question)
      ..writeByte(3)
      ..write(obj.answer)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.difficulty)
      ..writeByte(7)
      ..write(obj.lastReviewed)
      ..writeByte(8)
      ..write(obj.reviewCount)
      ..writeByte(9)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
