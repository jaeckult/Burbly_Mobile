// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PetAdapter extends TypeAdapter<Pet> {
  @override
  final int typeId = 5;

  @override
  Pet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pet(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as PetType,
      level: fields[3] as int,
      experience: fields[4] as int,
      happiness: fields[5] as int,
      energy: fields[6] as int,
      hunger: fields[7] as int,
      lastFed: fields[8] as DateTime,
      lastPlayed: fields[9] as DateTime,
      lastStudied: fields[10] as DateTime,
      studyStreak: fields[11] as int,
      accessories: (fields[12] as List).cast<String>(),
      createdAt: fields[13] as DateTime,
      isActive: fields[14] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Pet obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.level)
      ..writeByte(4)
      ..write(obj.experience)
      ..writeByte(5)
      ..write(obj.happiness)
      ..writeByte(6)
      ..write(obj.energy)
      ..writeByte(7)
      ..write(obj.hunger)
      ..writeByte(8)
      ..write(obj.lastFed)
      ..writeByte(9)
      ..write(obj.lastPlayed)
      ..writeByte(10)
      ..write(obj.lastStudied)
      ..writeByte(11)
      ..write(obj.studyStreak)
      ..writeByte(12)
      ..write(obj.accessories)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetTypeAdapter extends TypeAdapter<PetType> {
  @override
  final int typeId = 6;

  @override
  PetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PetType.cat;
      case 1:
        return PetType.dog;
      case 2:
        return PetType.rabbit;
      case 3:
        return PetType.bird;
      case 4:
        return PetType.fish;
      case 5:
        return PetType.hamster;
      case 6:
        return PetType.turtle;
      case 7:
        return PetType.dragon;
      default:
        return PetType.cat;
    }
  }

  @override
  void write(BinaryWriter writer, PetType obj) {
    switch (obj) {
      case PetType.cat:
        writer.writeByte(0);
        break;
      case PetType.dog:
        writer.writeByte(1);
        break;
      case PetType.rabbit:
        writer.writeByte(2);
        break;
      case PetType.bird:
        writer.writeByte(3);
        break;
      case PetType.fish:
        writer.writeByte(4);
        break;
      case PetType.hamster:
        writer.writeByte(5);
        break;
      case PetType.turtle:
        writer.writeByte(6);
        break;
      case PetType.dragon:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetMoodAdapter extends TypeAdapter<PetMood> {
  @override
  final int typeId = 7;

  @override
  PetMood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PetMood.veryHappy;
      case 1:
        return PetMood.happy;
      case 2:
        return PetMood.neutral;
      case 3:
        return PetMood.sad;
      case 4:
        return PetMood.verySad;
      default:
        return PetMood.veryHappy;
    }
  }

  @override
  void write(BinaryWriter writer, PetMood obj) {
    switch (obj) {
      case PetMood.veryHappy:
        writer.writeByte(0);
        break;
      case PetMood.happy:
        writer.writeByte(1);
        break;
      case PetMood.neutral:
        writer.writeByte(2);
        break;
      case PetMood.sad:
        writer.writeByte(3);
        break;
      case PetMood.verySad:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetMoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PetStageAdapter extends TypeAdapter<PetStage> {
  @override
  final int typeId = 8;

  @override
  PetStage read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PetStage.common;
      case 1:
        return PetStage.uncommon;
      case 2:
        return PetStage.rare;
      case 3:
        return PetStage.epic;
      case 4:
        return PetStage.legendary;
      default:
        return PetStage.common;
    }
  }

  @override
  void write(BinaryWriter writer, PetStage obj) {
    switch (obj) {
      case PetStage.common:
        writer.writeByte(0);
        break;
      case PetStage.uncommon:
        writer.writeByte(1);
        break;
      case PetStage.rare:
        writer.writeByte(2);
        break;
      case PetStage.epic:
        writer.writeByte(3);
        break;
      case PetStage.legendary:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PetStageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
