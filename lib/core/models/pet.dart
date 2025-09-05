import 'package:hive/hive.dart';

part 'pet.g.dart';

@HiveType(typeId: 5)
class Pet extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  PetType type;

  @HiveField(3)
  int level;

  @HiveField(4)
  int experience;

  @HiveField(5)
  int happiness;

  @HiveField(6)
  int energy;

  @HiveField(7)
  int hunger;

  @HiveField(8)
  DateTime lastFed;

  @HiveField(9)
  DateTime lastPlayed;

  @HiveField(10)
  DateTime lastStudied;

  @HiveField(11)
  int studyStreak;

  @HiveField(12)
  List<String> accessories;

  @HiveField(13)
  DateTime createdAt;

  @HiveField(14)
  bool isActive;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    this.level = 1,
    this.experience = 0,
    this.happiness = 100,
    this.energy = 100,
    this.hunger = 0,
    required this.lastFed,
    required this.lastPlayed,
    required this.lastStudied,
    this.studyStreak = 0,
    this.accessories = const [],
    required this.createdAt,
    this.isActive = true,
  });

  // Experience needed for next level
  int get experienceToNextLevel {
    return level * 100;
  }

  // Check if pet can level up
  bool get canLevelUp {
    return experience >= experienceToNextLevel;
  }

  // Pet mood based on stats
  PetMood get mood {
    if (happiness >= 80 && energy >= 80 && hunger <= 20) {
      return PetMood.veryHappy;
    } else if (happiness >= 60 && energy >= 60 && hunger <= 40) {
      return PetMood.happy;
    } else if (happiness >= 40 && energy >= 40 && hunger <= 60) {
      return PetMood.neutral;
    } else if (happiness >= 20 && energy >= 20 && hunger <= 80) {
      return PetMood.sad;
    } else {
      return PetMood.verySad;
    }
  }

  // Pet evolution stage
  PetStage get stage {
    if (level >= 20) return PetStage.legendary;
    if (level >= 15) return PetStage.epic;
    if (level >= 10) return PetStage.rare;
    if (level >= 5) return PetStage.uncommon;
    return PetStage.common;
  }

  // Copy with updates
  Pet copyWith({
    String? id,
    String? name,
    PetType? type,
    int? level,
    int? experience,
    int? happiness,
    int? energy,
    int? hunger,
    DateTime? lastFed,
    DateTime? lastPlayed,
    DateTime? lastStudied,
    int? studyStreak,
    List<String>? accessories,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      happiness: happiness ?? this.happiness,
      energy: energy ?? this.energy,
      hunger: hunger ?? this.hunger,
      lastFed: lastFed ?? this.lastFed,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      lastStudied: lastStudied ?? this.lastStudied,
      studyStreak: studyStreak ?? this.studyStreak,
      accessories: accessories ?? this.accessories,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

@HiveType(typeId: 6)
enum PetType {
  @HiveField(0)
  cat,
  @HiveField(1)
  dog,
  @HiveField(2)
  rabbit,
  @HiveField(3)
  bird,
  @HiveField(4)
  fish,
  @HiveField(5)
  hamster,
  @HiveField(6)
  turtle,
  @HiveField(7)
  dragon,
}

@HiveType(typeId: 7)
enum PetMood {
  @HiveField(0)
  veryHappy,
  @HiveField(1)
  happy,
  @HiveField(2)
  neutral,
  @HiveField(3)
  sad,
  @HiveField(4)
  verySad,
}

@HiveType(typeId: 8)
enum PetStage {
  @HiveField(0)
  common,
  @HiveField(1)
  uncommon,
  @HiveField(2)
  rare,
  @HiveField(3)
  epic,
  @HiveField(4)
  legendary,
}
