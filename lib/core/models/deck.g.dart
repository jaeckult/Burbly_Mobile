// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeckAdapter extends TypeAdapter<Deck> {
  @override
  final int typeId = 0;

  @override
  Deck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Deck(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      coverColor: fields[5] as String?,
      cardCount: fields[6] as int,
      packId: fields[7] as String?,
      spacedRepetitionEnabled: fields[8] as bool,
      timerDuration: fields[9] as int?,
      isSynced: fields[10] as bool,
      showStudyStats: fields[11] as bool?,
      scheduledReviewTime: fields[12] as DateTime?,
      scheduledReviewEnabled: fields[13] as bool?,
      deckIsReviewNow: fields[14] as bool?,
      deckReviewNowStartTime: fields[15] as DateTime?,
      deckIsOverdue: fields[16] as bool?,
      deckOverdueStartTime: fields[17] as DateTime?,
      deckIsReviewed: fields[18] as bool?,
      deckReviewedStartTime: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Deck obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.coverColor)
      ..writeByte(6)
      ..write(obj.cardCount)
      ..writeByte(7)
      ..write(obj.packId)
      ..writeByte(8)
      ..write(obj.spacedRepetitionEnabled)
      ..writeByte(9)
      ..write(obj.timerDuration)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.showStudyStats)
      ..writeByte(12)
      ..write(obj.scheduledReviewTime)
      ..writeByte(13)
      ..write(obj.scheduledReviewEnabled)
      ..writeByte(14)
      ..write(obj.deckIsReviewNow)
      ..writeByte(15)
      ..write(obj.deckReviewNowStartTime)
      ..writeByte(16)
      ..write(obj.deckIsOverdue)
      ..writeByte(17)
      ..write(obj.deckOverdueStartTime)
      ..writeByte(18)
      ..write(obj.deckIsReviewed)
      ..writeByte(19)
      ..write(obj.deckReviewedStartTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
