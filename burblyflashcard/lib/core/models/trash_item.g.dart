// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TrashItemAdapter extends TypeAdapter<TrashItem> {
  @override
  final int typeId = 9;

  @override
  TrashItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrashItem(
      id: fields[0] as String,
      itemType: fields[1] as String,
      originalId: fields[2] as String,
      deletedAt: fields[3] as DateTime,
      payload: (fields[4] as Map).cast<String, dynamic>(),
      parentId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TrashItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemType)
      ..writeByte(2)
      ..write(obj.originalId)
      ..writeByte(3)
      ..write(obj.deletedAt)
      ..writeByte(4)
      ..write(obj.payload)
      ..writeByte(5)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
