import 'package:flutter/material.dart';
import '../../../core/models/pet.dart';
import '../../../core/services/pet_service.dart';

class PetCareScreen extends StatefulWidget {
  final Pet pet;

  const PetCareScreen({super.key, required this.pet});

  @override
  State<PetCareScreen> createState() => _PetCareScreenState();
}

class _PetCareScreenState extends State<PetCareScreen>
    with TickerProviderStateMixin {
  final PetService _petService = PetService();
  late Pet _pet;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePet(Pet updatedPet) {
    setState(() {
      _pet = updatedPet;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _petService.getPetStats(_pet);
    final suggestions = _petService.getCareSuggestions(_pet);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_pet.name}\'s Care'),
        actions: [
          IconButton(
            onPressed: () => _showPetStats(context),
            icon: const Icon(Icons.analytics),
            tooltip: 'Pet Stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Pet Display
            _buildPetDisplay(),
            const SizedBox(height: 24),

            // Stats Cards
            _buildStatsCards(stats),
            const SizedBox(height: 24),

            // Care Actions
            _buildCareActions(),
            const SizedBox(height: 24),

            // Care Suggestions
            if (suggestions.isNotEmpty) _buildCareSuggestions(suggestions),
          ],
        ),
      ),
    );
  }

  Widget _buildPetDisplay() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pet Avatar
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildLargePetAvatar(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Pet Info
          Text(
            _pet.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Level ${_pet.level} ${_pet.type.name.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),

          // Experience Bar
          _buildExperienceBar(),
          const SizedBox(height: 16),

          // Mood Display
          _buildMoodDisplay(),
        ],
      ),
    );
  }

  Widget _buildLargePetAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: _getPetColor(_pet.type),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getPetColor(_pet.type).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        _getPetIcon(_pet.type),
        color: Colors.white,
        size: 64,
      ),
    );
  }

  Widget _buildExperienceBar() {
    final progress = _pet.experience / _pet.experienceToNextLevel;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Experience',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${_pet.experience}/${_pet.experienceToNextLevel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getPetColor(_pet.type),
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildMoodDisplay() {
    final moodEmoji = _getMoodEmoji(_pet.mood);
    final moodText = _getMoodText(_pet.mood);
    final moodColor = _getMoodColor(_pet.mood);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: moodColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moodColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            moodEmoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            moodText,
            style: TextStyle(
              color: moodColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard('Happiness', (stats['happiness'] as num).toInt(), Colors.yellow, Icons.favorite),
        _buildStatCard('Energy', (stats['energy'] as num).toInt(), Colors.blue, Icons.flash_on),
        _buildStatCard('Hunger', (100 - (stats['hunger'] as num)).toInt(), Colors.green, Icons.restaurant),
        _buildStatCard('Study Streak', (stats['studyStreak'] as num).toInt(), Colors.purple, Icons.local_fire_department),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Feed',
                Icons.restaurant,
                Colors.green,
                () => _feedPet(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Play',
                Icons.sports_esports,
                Colors.blue,
                () => _playWithPet(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Study',
                Icons.school,
                Colors.purple,
                () => _studyWithPet(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCareSuggestions(List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Care Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...suggestions.map((suggestion) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showPetStats(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_pet.name}\'s Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Level', '${_pet.level}'),
            _buildStatRow('Experience', '${_pet.experience}/${_pet.experienceToNextLevel}'),
            _buildStatRow('Study Streak', '${_pet.studyStreak} days'),
            _buildStatRow('Created', _formatDate(_pet.createdAt)),
            _buildStatRow('Last Fed', _formatDate(_pet.lastFed)),
            _buildStatRow('Last Played', _formatDate(_pet.lastPlayed)),
            _buildStatRow('Last Studied', _formatDate(_pet.lastStudied)),
            _buildStatRow('Accessories', '${_pet.accessories.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _feedPet() async {
    await _petService.feedPet(_pet);
    final updatedPet = _petService.getCurrentPet();
    if (updatedPet != null) {
      _updatePet(updatedPet);
      _animationController.forward().then((_) => _animationController.reverse());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pet.name} enjoyed the food! 🍽️'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _playWithPet() async {
    await _petService.playWithPet(_pet);
    final updatedPet = _petService.getCurrentPet();
    if (updatedPet != null) {
      _updatePet(updatedPet);
      _animationController.forward().then((_) => _animationController.reverse());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pet.name} had fun playing! 🎾'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _studyWithPet() async {
    // This would typically be called from the study screen
    // For now, we'll simulate studying 5 cards
    await _petService.studyWithPet(_pet, 5);
    final updatedPet = _petService.getCurrentPet();
    if (updatedPet != null) {
      _updatePet(updatedPet);
      _animationController.forward().then((_) => _animationController.reverse());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_pet.name} gained experience from studying! 📚'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    }
  }

  Color _getPetColor(PetType type) {
    switch (type) {
      case PetType.cat:
        return Colors.orange;
      case PetType.dog:
        return Colors.brown;
      case PetType.rabbit:
        return Colors.grey;
      case PetType.bird:
        return Colors.blue;
      case PetType.fish:
        return Colors.cyan;
      case PetType.hamster:
        return Colors.amber;
      case PetType.turtle:
        return Colors.green;
      case PetType.dragon:
        return Colors.purple;
    }
  }

  IconData _getPetIcon(PetType type) {
    switch (type) {
      case PetType.cat:
        return Icons.pets;
      case PetType.dog:
        return Icons.pets;
      case PetType.rabbit:
        return Icons.pets;
      case PetType.bird:
        return Icons.flutter_dash;
      case PetType.fish:
        return Icons.water;
      case PetType.hamster:
        return Icons.pets;
      case PetType.turtle:
        return Icons.pets;
      case PetType.dragon:
        return Icons.local_fire_department;
    }
  }

  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.veryHappy:
        return '🌟';
      case PetMood.happy:
        return '😊';
      case PetMood.neutral:
        return '😐';
      case PetMood.sad:
        return '😔';
      case PetMood.verySad:
        return '😢';
    }
  }

  String _getMoodText(PetMood mood) {
    switch (mood) {
      case PetMood.veryHappy:
        return 'Very Happy';
      case PetMood.happy:
        return 'Happy';
      case PetMood.neutral:
        return 'Neutral';
      case PetMood.sad:
        return 'Sad';
      case PetMood.verySad:
        return 'Very Sad';
    }
  }

  Color _getMoodColor(PetMood mood) {
    switch (mood) {
      case PetMood.veryHappy:
        return Colors.yellow;
      case PetMood.happy:
        return Colors.green;
      case PetMood.neutral:
        return Colors.blue;
      case PetMood.sad:
        return Colors.orange;
      case PetMood.verySad:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
