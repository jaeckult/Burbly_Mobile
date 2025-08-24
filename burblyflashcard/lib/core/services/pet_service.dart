import 'package:hive/hive.dart';
import '../models/pet.dart';

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  late Box<Pet> _petsBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _petsBox = await Hive.openBox<Pet>('pets');
    _isInitialized = true;
  }

  // Get current active pet
  Pet? getCurrentPet() {
    if (!_isInitialized) return null;
    
    // Check if there are any pets at all
    if (_petsBox.values.isEmpty) {
      return null;
    }
    
    return _petsBox.values.firstWhere(
      (pet) => pet.isActive,
      orElse: () => _petsBox.values.first,
    );
  }

  // Create a new pet (only one pet per user allowed)
  Future<Pet?> createPet({
    required String name,
    required PetType type,
  }) async {
    if (!_isInitialized) await initialize();

    // Check if user already has a pet
    if (_petsBox.values.isNotEmpty) {
      print('User already has a pet. Only one pet per user is allowed.');
      return null;
    }

    final now = DateTime.now();
    final pet = Pet(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: type,
      lastFed: now,
      lastPlayed: now,
      lastStudied: now,
      createdAt: now,
    );

    await _petsBox.put(pet.id, pet);
    return pet;
  }

  // Update pet stats
  Future<void> updatePet(Pet pet) async {
    if (!_isInitialized) await initialize();
    await _petsBox.put(pet.id, pet);
  }

  // Feed the pet
  Future<void> feedPet(Pet pet) async {
    final updatedPet = pet.copyWith(
      hunger: (pet.hunger - 30).clamp(0, 100),
      happiness: (pet.happiness + 10).clamp(0, 100),
      lastFed: DateTime.now(),
    );
    await updatePet(updatedPet);
  }

  // Play with the pet
  Future<void> playWithPet(Pet pet) async {
    final updatedPet = pet.copyWith(
      energy: (pet.energy - 20).clamp(0, 100),
      happiness: (pet.happiness + 20).clamp(0, 100),
      lastPlayed: DateTime.now(),
    );
    await updatePet(updatedPet);
  }

  // Study with pet (called when user studies)
  Future<void> studyWithPet(Pet pet, int cardsStudied) async {
    final experienceGained = cardsStudied * 5;
    final happinessGained = cardsStudied * 2;
    
    var updatedPet = pet.copyWith(
      experience: pet.experience + experienceGained,
      happiness: (pet.happiness + happinessGained).clamp(0, 100),
      lastStudied: DateTime.now(),
    );

    // Check for level up
    while (updatedPet.canLevelUp) {
      updatedPet = updatedPet.copyWith(
        level: updatedPet.level + 1,
        experience: updatedPet.experience - updatedPet.experienceToNextLevel,
      );
    }

    await updatePet(updatedPet);
  }

  // Feed pet based on flashcard answers (called when user answers correctly)
  Future<void> feedPetOnCorrectAnswer(Pet pet, int points) async {
    // Calculate feeding based on points (more points = more feeding)
    final feedingAmount = (points * 0.5).clamp(5, 25).round(); // 5-25 hunger reduction
    final happinessGain = (points * 0.3).clamp(2, 15).round(); // 2-15 happiness gain
    
    final updatedPet = pet.copyWith(
      hunger: (pet.hunger - feedingAmount).clamp(0, 100),
      happiness: (pet.happiness + happinessGain).clamp(0, 100),
      lastFed: DateTime.now(),
    );
    
    await updatePet(updatedPet);
  }

  // Give pet attention when user visits the app
  Future<void> givePetAttention(Pet pet) async {
    final now = DateTime.now();
    final hoursSinceLastAttention = now.difference(pet.lastPlayed).inHours;
    
    // Only give attention if it's been at least 1 hour since last attention
    if (hoursSinceLastAttention >= 1) {
      final attentionGain = 15; // Fixed happiness gain for attention
      
      final updatedPet = pet.copyWith(
        happiness: (pet.happiness + attentionGain).clamp(0, 100),
        lastPlayed: now,
      );
      
      await updatePet(updatedPet);
    }
  }

  // Get pet symbol/emoji based on type
  String getPetSymbol(PetType type) {
    switch (type) {
      case PetType.cat:
        return '🐱';
      case PetType.dog:
        return '🐕';
      case PetType.rabbit:
        return '🐰';
      case PetType.bird:
        return '🐦';
      case PetType.fish:
        return '🐠';
      case PetType.hamster:
        return '🐹';
      case PetType.turtle:
        return '🐢';
      case PetType.dragon:
        return '🐉';
    }
  }

  // Get personalized notification message
  String getPersonalizedNotificationMessage(Pet pet) {
    final hoursSinceLastVisit = DateTime.now().difference(pet.lastPlayed).inHours;
    final petSymbol = getPetSymbol(pet.type);
    
    if (hoursSinceLastVisit >= 24) {
      return "$petSymbol Hey ${pet.name} here! Where have you been? I missed you! 😢";
    } else if (hoursSinceLastVisit >= 12) {
      return "$petSymbol Hi ${pet.name} here! I was wondering where you went! 😊";
    } else if (hoursSinceLastVisit >= 6) {
      return "$petSymbol Hey ${pet.name} here! Are you coming back soon? 🐾";
    } else if (hoursSinceLastVisit >= 2) {
      return "$petSymbol ${pet.name} here! I'm getting a bit lonely... 😔";
    } else {
      return "$petSymbol ${pet.name} here! I'm ready to study with you! 📚";
    }
  }

  // Get pet status message for notifications
  String getPetStatusMessage(Pet pet) {
    final stats = getPetStats(pet);
    final petSymbol = getPetSymbol(pet.type);
    
    if (stats['hunger'] > 70) {
      return "$petSymbol ${pet.name} is very hungry! Feed me by answering flashcards correctly! 🍽️";
    } else if (stats['happiness'] < 30) {
      return "$petSymbol ${pet.name} is feeling sad! Come visit me and give me attention! 😢";
    } else if (stats['energy'] < 30) {
      return "$petSymbol ${pet.name} is tired! Let me rest a bit... 😴";
    } else if (stats['hoursSinceStudied'] > 48) {
      return "$petSymbol ${pet.name} misses studying with you! Let's learn together! 📚";
    } else {
      return "$petSymbol ${pet.name} is doing great! Keep up the good work! 🌟";
    }
  }

  // Update study streak
  Future<void> updateStudyStreak(Pet pet, int streak) async {
    final updatedPet = pet.copyWith(studyStreak: streak);
    await updatePet(updatedPet);
  }

  // Add accessory to pet
  Future<void> addAccessory(Pet pet, String accessory) async {
    final accessories = List<String>.from(pet.accessories);
    if (!accessories.contains(accessory)) {
      accessories.add(accessory);
      final updatedPet = pet.copyWith(accessories: accessories);
      await updatePet(updatedPet);
    }
  }

  // Get all pets
  List<Pet> getAllPets() {
    if (!_isInitialized) return [];
    return _petsBox.values.toList();
  }

  // Delete pet
  Future<void> deletePet(String petId) async {
    if (!_isInitialized) await initialize();
    await _petsBox.delete(petId);
  }

  // Set active pet
  Future<void> setActivePet(String petId) async {
    if (!_isInitialized) await initialize();
    
    // Deactivate all pets
    for (final pet in _petsBox.values) {
      if (pet.isActive) {
        final updatedPet = pet.copyWith(isActive: false);
        await _petsBox.put(pet.id, updatedPet);
      }
    }
    
    // Activate selected pet
    final pet = _petsBox.get(petId);
    if (pet != null) {
      final updatedPet = pet.copyWith(isActive: true);
      await _petsBox.put(petId, updatedPet);
    }
  }

  // Get pet statistics
  Map<String, dynamic> getPetStats(Pet pet) {
    final now = DateTime.now();
    final hoursSinceFed = now.difference(pet.lastFed).inHours;
    final hoursSincePlayed = now.difference(pet.lastPlayed).inHours;
    final hoursSinceStudied = now.difference(pet.lastStudied).inHours;

    return {
      'level': pet.level,
      'experience': pet.experience,
      'experienceToNext': pet.experienceToNextLevel,
      'happiness': pet.happiness,
      'energy': pet.energy,
      'hunger': pet.hunger,
      'studyStreak': pet.studyStreak,
      'hoursSinceFed': hoursSinceFed,
      'hoursSincePlayed': hoursSincePlayed,
      'hoursSinceStudied': hoursSinceStudied,
      'mood': pet.mood,
      'stage': pet.stage,
    };
  }

  // Get motivational message based on pet mood
  String getMotivationalMessage(Pet pet) {
    switch (pet.mood) {
      case PetMood.veryHappy:
        return "🌟 Your pet is super happy! Keep up the great studying!";
      case PetMood.happy:
        return "😊 Your pet is happy and ready to study with you!";
      case PetMood.neutral:
        return "😐 Your pet is doing okay. A little study session would cheer them up!";
      case PetMood.sad:
        return "😔 Your pet is feeling down. They miss studying with you!";
      case PetMood.verySad:
        return "😢 Your pet is very sad! Please study with them soon!";
    }
  }

  // Get pet care suggestions
  List<String> getCareSuggestions(Pet pet) {
    final suggestions = <String>[];
    final stats = getPetStats(pet);

    if (stats['hunger'] > 60) {
      suggestions.add("🍽️ Your pet is hungry! Feed them some treats.");
    }
    if (stats['energy'] < 40) {
      suggestions.add("😴 Your pet is tired. Let them rest or play gently.");
    }
    if (stats['happiness'] < 40) {
      suggestions.add("🎾 Your pet wants to play! Spend some time with them.");
    }
    if (stats['hoursSinceStudied'] > 24) {
      suggestions.add("📚 Your pet misses studying with you!");
    }

    return suggestions;
  }

  // Check if pet needs attention
  bool needsAttention(Pet pet) {
    final stats = getPetStats(pet);
    return stats['hunger'] > 70 || 
           stats['energy'] < 30 || 
           stats['happiness'] < 30 ||
           stats['hoursSinceStudied'] > 48;
  }

  // Get pet evolution message
  String? getEvolutionMessage(Pet pet) {
    final oldStage = pet.stage;
    // This would be called after leveling up
    return null; // Will be implemented in the UI
  }
}
