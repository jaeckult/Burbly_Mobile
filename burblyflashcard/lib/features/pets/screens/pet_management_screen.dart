import 'package:flutter/material.dart';
import '../../../core/models/pet.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/pet_notification_service.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PetManagementScreen extends StatefulWidget {
  const PetManagementScreen({super.key});

  @override
  State<PetManagementScreen> createState() => _PetManagementScreenState();
}

class _PetManagementScreenState extends State<PetManagementScreen> {
  final PetService _petService = PetService();
  final PetNotificationService _petNotificationService = PetNotificationService();
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    await _petService.initialize();
    final pets = _petService.getAllPets();
    setState(() {
      _pets = pets;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Management'),
        // actions: [
        //   IconButton(
        //     onPressed: () => _showAdoptPetDialog(),
        //     icon: const Icon(Icons.add),
        //     tooltip: 'Adopt New Pet',
        //   ),
        // ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pets.isEmpty
              ? _buildNoPetsWidget()
              : _buildPetsList(),
    );
  }

  Widget _buildNoPetsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Pet Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adopt your study companion! (Only one pet per user)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAdoptPetDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Adopt Your Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pets.length,
      itemBuilder: (context, index) {
        final pet = _pets[index];
        return _buildPetCard(pet);
      },
    );
  }

  Widget _buildPetCard(Pet pet) {
    final stats = _petService.getPetStats(pet);
    final needsAttention = _petService.needsAttention(pet);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: pet.isActive
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Pet Avatar
              Container(
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
                        if (pet.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  if (!pet.isActive)
                    IconButton(
                      onPressed: () => _setActivePet(pet),
                      icon: const Icon(Icons.star_outline),
                      tooltip: 'Set as Active Pet',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  IconButton(
                    onPressed: () => _showPetOptions(pet),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More Options',
                  ),
                ],
              ),
            ],
          ),
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
            minHeight: 4,
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



  void _setActivePet(Pet pet) async {
    await _petService.setActivePet(pet.id);
    await _loadPets();
    if (mounted) {
      SnackbarUtils.showSuccessSnackbar(
        context,
        '${pet.name} is now your active pet!',
      );
    }
  }

  void _showPetOptions(Pet pet) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!pet.isActive)
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Set as Active Pet'),
                onTap: () {
                  Navigator.pop(context);
                  _setActivePet(pet);
                },
              ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('View Statistics'),
              onTap: () {
                Navigator.pop(context);
                _showPetStats(pet);
              },
            ),
            if (_pets.length > 1)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Release Pet', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showReleasePetDialog(pet);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPetStats(Pet pet) {
    final stats = _petService.getPetStats(pet);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${pet.name}\'s Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Name', pet.name),
            _buildStatRow('Type', pet.type.name.toUpperCase()),
            _buildStatRow('Level', '${pet.level}'),
            _buildStatRow('Experience', '${pet.experience}/${pet.experienceToNextLevel}'),
            _buildStatRow('Study Streak', '${pet.studyStreak} days'),
            _buildStatRow('Happiness', '${stats['happiness']}%'),
            _buildStatRow('Energy', '${stats['energy']}%'),
            _buildStatRow('Hunger', '${stats['hunger']}%'),
            _buildStatRow('Created', _formatDate(pet.createdAt)),
            _buildStatRow('Last Fed', _formatDate(pet.lastFed)),
            _buildStatRow('Last Played', _formatDate(pet.lastPlayed)),
            _buildStatRow('Last Studied', _formatDate(pet.lastStudied)),
            _buildStatRow('Accessories', '${pet.accessories.length}'),
            _buildStatRow('Status', pet.isActive ? 'Active' : 'Inactive'),
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

  void _showReleasePetDialog(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Release Pet'),
        content: Text(
          'Are you sure you want to release ${pet.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _releasePet(pet);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  Future<void> _releasePet(Pet pet) async {
    await _petService.deletePet(pet.id);
    await _loadPets();
    if (mounted) {
      SnackbarUtils.showErrorSnackbar(
        context,
        '${pet.name} has been released.',
      );
    }
  }

  void _showAdoptPetDialog() {
    // Check if user already has a pet
    if (_pets.isNotEmpty) {
      _petNotificationService.showPetLimitNotification();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => const AdoptPetDialog(),
    ).then((_) => _loadPets());
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
      return FontAwesomeIcons.cat;
    case PetType.dog:
      return FontAwesomeIcons.dog;
    case PetType.rabbit:
      return FontAwesomeIcons.cat; // in FontAwesome
    case PetType.bird:
      return FontAwesomeIcons.dove;
    case PetType.fish:
      return FontAwesomeIcons.fish;
    case PetType.hamster:
      return FontAwesomeIcons.wheelchair; // no hamster icon, pick alt or custom
    case PetType.turtle:
      return FontAwesomeIcons.kiwiBird; // closest (quirky alternative)
    case PetType.dragon:
      return FontAwesomeIcons.dragon;
    default:
      return Icons.help_outline;
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

class AdoptPetDialog extends StatefulWidget {
  const AdoptPetDialog({super.key});

  @override
  State<AdoptPetDialog> createState() => _AdoptPetDialogState();
}

class _AdoptPetDialogState extends State<AdoptPetDialog> {
  final TextEditingController _nameController = TextEditingController();
  PetType _selectedType = PetType.cat;
  final PetService _petService = PetService();
  final PetNotificationService _petNotificationService = PetNotificationService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return AlertDialog(
    title: const Text('Adopt Your Study Pet'),
    content: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8, // prevent wide dialogs
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              'Note: Only one pet per user is allowed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontStyle: FontStyle.italic,
                  ),
            ),
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
      ),
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
      SnackbarUtils.showWarningSnackbar(
        context,
        'Please enter a name for your pet',
      );
      return;
    }

    final pet = await _petService.createPet(
      name: name,
      type: _selectedType,
    );

    if (mounted) {
      Navigator.pop(context);
      
      if (pet != null) {
        _petNotificationService.showPetAdoptionNotification(name);
      } else {
        _petNotificationService.showPetLimitNotification();
      }
    }
  }
}
