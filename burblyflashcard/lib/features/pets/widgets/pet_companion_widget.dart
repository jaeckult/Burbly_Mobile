import 'package:flutter/material.dart';
import '../../../core/models/pet.dart';
import '../../../core/services/pet_service.dart';
import '../screens/pet_care_screen.dart';

class PetCompanionWidget extends StatefulWidget {
  const PetCompanionWidget({super.key});

  @override
  State<PetCompanionWidget> createState() => _PetCompanionWidgetState();
}

class _PetCompanionWidgetState extends State<PetCompanionWidget>
    with TickerProviderStateMixin {
  final PetService _petService = PetService();
  Pet? _currentPet;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _loadPet();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    await _petService.initialize();
    final pet = _petService.getCurrentPet();
    setState(() {
      _currentPet = pet;
      _isLoading = false;
    });
    
    if (pet != null) {
      _animationController.forward();
    }
  }

  void _onPetTap() {
    if (_currentPet != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PetCareScreen(pet: _currentPet!),
        ),
      ).then((_) => _loadPet());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_currentPet == null) {
      return _buildNoPetWidget();
    }

    return _buildPetWidget();
  }

  Widget _buildNoPetWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.pets,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Adopt a Pet!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Get a study companion to motivate you',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showAdoptPetDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Adopt Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetWidget() {
    final pet = _currentPet!;
    final stats = _petService.getPetStats(pet);
    final needsAttention = _petService.needsAttention(pet);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: needsAttention
            ? Border.all(
                color: Colors.orange,
                width: 2,
              )
            : null,
      ),
      child: InkWell(
        onTap: _onPetTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet Avatar
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_bounceAnimation.value * 0.2),
                    child: _buildPetAvatar(pet),
                  );
                },
              ),
              const SizedBox(width: 16),
              
              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pet.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPetTypeIcon(pet.type),
                        const Spacer(),
                        if (needsAttention)
                          Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${pet.level} • ${pet.type.name.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    
                    // Stats bars
                    _buildStatBar('Happiness', stats['happiness'], Colors.yellow),
                    const SizedBox(height: 4),
                    _buildStatBar('Energy', stats['energy'], Colors.blue),
                    const SizedBox(height: 4),
                                         _buildStatBar('Hunger', (100 - stats['hunger']).toInt(), Colors.green),
                    
                    const SizedBox(height: 8),
                    Text(
                      _petService.getMotivationalMessage(pet),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    onPressed: () => _feedPet(),
                    icon: const Icon(Icons.restaurant),
                    tooltip: 'Feed Pet',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _playWithPet(),
                    icon: const Icon(Icons.sports_esports),
                    tooltip: 'Play with Pet',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetAvatar(Pet pet) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getPetColor(pet.type),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getPetColor(pet.type).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _getPetIcon(pet.type),
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildPetTypeIcon(PetType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPetColor(type).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPetColor(type),
        ),
      ),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
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

  void _feedPet() async {
    if (_currentPet != null) {
      await _petService.feedPet(_currentPet!);
      await _loadPet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentPet!.name} enjoyed the food! 🍽️'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _playWithPet() async {
    if (_currentPet != null) {
      await _petService.playWithPet(_currentPet!);
      await _loadPet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_currentPet!.name} had fun playing! 🎾'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  void _showAdoptPetDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdoptPetDialog(),
    ).then((_) => _loadPet());
  }
}

class AdoptPetDialog extends StatefulWidget {
  const AdoptPetDialog({super.key});

  @override
  State<AdoptPetDialog> createState() => _AdoptPetDialogState();
}

class _AdoptPetDialogState extends State<AdoptPetDialog> {
  final TextEditingController _nameController = TextEditingController();
  PetType _selectedType = PetType.cat;
  final PetService _petService = PetService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adopt a Pet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Pet Name',
              hintText: 'Enter your pet\'s name',
            ),
          ),
          const SizedBox(height: 16),
          const Text('Choose your pet type:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: PetType.values.map((type) {
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: _selectedType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedType = type);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _adoptPet,
          child: const Text('Adopt'),
        ),
      ],
    );
  }

  void _adoptPet() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your pet')),
      );
      return;
    }

    await _petService.createPet(
      name: name,
      type: _selectedType,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome $name! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
