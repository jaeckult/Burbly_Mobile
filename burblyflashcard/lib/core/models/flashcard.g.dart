// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

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
      interval: fields[6] as int,
      nextReview: fields[7] as DateTime?,
      easeFactor: fields[8] as double,
      lastReviewed: fields[9] as DateTime?,
      reviewCount: fields[10] as int,
      isSynced: fields[11] as bool,
      overdueStartTime: fields[12] as DateTime?,
      isOverdue: fields[13] as bool?,
      reviewNowStartTime: fields[14] as DateTime?,
      reviewedStartTime: fields[15] as DateTime?,
      isReviewNow: fields[16] as bool?,
      isReviewed: fields[17] as bool?,
      extendedDescription: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(19)
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
      ..write(obj.interval)
      ..writeByte(7)
      ..write(obj.nextReview)
      ..writeByte(8)
      ..write(obj.easeFactor)
      ..writeByte(9)
      ..write(obj.lastReviewed)
      ..writeByte(10)
      ..write(obj.reviewCount)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
      ..write(obj.overdueStartTime)
      ..writeByte(13)
      ..write(obj.isOverdue)
      ..writeByte(14)
      ..write(obj.reviewNowStartTime)
      ..writeByte(15)
      ..write(obj.reviewedStartTime)
      ..writeByte(16)
      ..write(obj.isReviewNow)
      ..writeByte(17)
      ..write(obj.isReviewed)
      ..writeByte(18)
      ..write(obj.extendedDescription);
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
