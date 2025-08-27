import 'package:flutter/material.dart';
import '../../../core/core.dart';


class CreateDeckScreen extends StatefulWidget {
  final Function(Deck) onDeckCreated;
  final String? initialPackId;

  const CreateDeckScreen({
    super.key,
    required this.onDeckCreated,
    this.initialPackId,
  });

  @override
  State<CreateDeckScreen> createState() => _CreateDeckScreenState();
}

class _CreateDeckScreenState extends State<CreateDeckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dataService = DataService();
  String? _selectedPackId;
  List<DeckPack> _availablePacks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPackId = widget.initialPackId;
    _loadDeckPacks();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDeckPacks() async {
    try {
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }
      final packs = await _dataService.getDeckPacks();
      setState(() {
        _availablePacks = packs;
      });
    } catch (e) {
      // Silently handle error, packs are optional
    }
  }

  Future<void> _createDeck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Ensure DataService is initialized
      if (!_dataService.isInitialized) {
        await _dataService.initialize();
      }
      
      // Get the deck pack color if one is selected
      String? deckColor;
      if (_selectedPackId != null) {
        try {
          final selectedPack = _availablePacks.firstWhere((pack) => pack.id == _selectedPackId);
          deckColor = selectedPack.coverColor;
        } catch (e) {
          print('Warning: Selected pack not found, using default color');
          // Continue without a specific color
        }
      }
      
      final deck = await _dataService.createDeck(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        coverColor: deckColor,
      );

      // If a pack is selected, add the deck to it
      if (_selectedPackId != null) {
        await _dataService.addDeckToPack(deck.id, _selectedPackId!);
      }

      widget.onDeckCreated(deck);

      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showSuccessSnackbar(
          context,
          'Deck "${deck.name}" created successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error creating deck: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Deck'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Deck Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Deck Name',
                hintText: 'Enter deck name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a deck name';
                }
                if (value.trim().length < 3) {
                  return 'Deck name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter deck description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Deck Pack Selection
            if (_availablePacks.isNotEmpty && widget.initialPackId == null) ...[
              Text(
                'Assign to Deck Pack (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPackId,
                decoration: const InputDecoration(
                  labelText: 'Deck Pack',
                  hintText: 'Select a pack (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No Pack'),
                  ),
                  ..._availablePacks.map((pack) => DropdownMenuItem(
                    value: pack.id,
                    child: Text(pack.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPackId = value;
                  });
                },
              ),
              const SizedBox(height: 32),
            ] else if (widget.initialPackId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _availablePacks.firstWhere(
                          (p) => p.id == widget.initialPackId,
                          orElse: () => DeckPack(
                            id: widget.initialPackId!,
                            name: 'Selected Pack',
                            description: '',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            coverColor: '2196F3',
                          ),
                        ).name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createDeck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Create Deck',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
