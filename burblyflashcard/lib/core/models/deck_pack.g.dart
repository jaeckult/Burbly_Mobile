// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_pack.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeckPackAdapter extends TypeAdapter<DeckPack> {
  @override
  final int typeId = 2;

  @override
  DeckPack read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeckPack(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      coverColor: fields[5] as String,
      deckCount: fields[6] as int,
      deckIds: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, DeckPack obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.deckCount)
      ..writeByte(7)
      ..write(obj.deckIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeckPackAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
