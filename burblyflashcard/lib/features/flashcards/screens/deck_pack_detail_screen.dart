import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'deck_detail_screen.dart';
import 'create_deck_screen.dart';

class DeckPackDetailScreen extends StatefulWidget {
  final DeckPack deckPack;

  const DeckPackDetailScreen({
    super.key,
    required this.deckPack,
  });

  @override
  State<DeckPackDetailScreen> createState() => _DeckPackDetailScreenState();
}

class _DeckPackDetailScreenState extends State<DeckPackDetailScreen> {
  final DataService _dataService = DataService();
  List<Deck> _decks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      final allDecks = await _dataService.getDecks();
      final decksInPack = allDecks.where((deck) => deck.packId == widget.deckPack.id).toList();
      setState(() {
        _decks = decksInPack;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error loading decks: ${e.toString()}',
        );
      }
    }
  }

  void _createNewDeck() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDeckScreen(
          onDeckCreated: (deck) async {
            // Add the deck to this pack
            try {
              await _dataService.addDeckToPack(deck.id, widget.deckPack.id);
              await _loadDecks();
            } catch (e) {
              if (mounted) {
                        SnackbarUtils.showErrorSnackbar(
          context,
          'Error adding deck to pack: ${e.toString()}',
        );
              }
            }
          },
        ),
      ),
    );
  }

  void _removeDeckFromPack(Deck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Deck from Pack'),
        content: Text('Are you sure you want to remove "${deck.name}" from this pack?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataService.removeDeckFromPack(deck.id, widget.deckPack.id);
        await _loadDecks();
        
        if (mounted) {
                  SnackbarUtils.showWarningSnackbar(
          context,
          'Deck "${deck.name}" removed from pack',
        );
        }
      } catch (e) {
        if (mounted) {
                  SnackbarUtils.showErrorSnackbar(
          context,
          'Error removing deck: ${e.toString()}',
        );
        }
      }
    }
  }

  void _showAddDeckOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Deck'),
              onTap: () {
                Navigator.pop(context);
                _createNewDeck();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Add Existing Deck'),
              onTap: () {
                Navigator.pop(context);
                _addExistingDeck();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addExistingDeck() async {
    try {
      final allDecks = await _dataService.getDecks();
      final availableDecks = allDecks.where((deck) => deck.packId == null).toList();
      
      if (availableDecks.isEmpty) {
        if (mounted) {
          SnackbarUtils.showWarningSnackbar(
            context,
            'No available decks to add. All decks are already in packs.',
          );
        }
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Add Existing Deck'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableDecks.length,
                itemBuilder: (context, index) {
                  final deck = availableDecks[index];
                  return ListTile(
                    title: Text(deck.name),
                    subtitle: Text('${deck.cardCount} cards'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await _dataService.addDeckToPack(deck.id, widget.deckPack.id);
                        await _loadDecks();
                        if (mounted) {
                          SnackbarUtils.showSuccessSnackbar(
                            context,
                            'Deck "${deck.name}" added to pack',
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarUtils.showErrorSnackbar(
                            context,
                            'Error adding deck: ${e.toString()}',
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
              if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Error loading available decks: ${e.toString()}',
          );
        }
    }
  }

  void _showEditPackOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Deck Pack',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Change Color'),
              onTap: () {
                Navigator.pop(context);
                _showColorPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name & Description'),
              onTap: () {
                Navigator.pop(context);
                _showEditPackDetails();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    final List<String> colorOptions = [
      'FF9800', // Orange
      'E91E63', // Pink
      '9C27B0', // Purple
      '673AB7', // Deep Purple
      '3F51B5', // Indigo
      '2196F3', // Blue
      '00BCD4', // Cyan
      '009688', // Teal
      '4CAF50', // Green
      '8BC34A', // Light Green
      'CDDC39', // Lime
      'FFEB3B', // Yellow
      'FFC107', // Amber
      'FF5722', // Deep Orange
      '795548', // Brown
      '9E9E9E', // Grey
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Pack Color'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: colorOptions.length,
            itemBuilder: (context, index) {
              final color = colorOptions[index];
              final isSelected = color == widget.deckPack.coverColor;
              
              return GestureDetector(
                onTap: () async {
                  try {
                    final updatedPack = widget.deckPack.copyWith(
                      coverColor: color,
                      updatedAt: DateTime.now(),
                    );
                    await _dataService.updateDeckPack(updatedPack);
                    
                    // Update all decks in this pack to use the new color
                    for (final deck in _decks) {
                      final updatedDeck = deck.copyWith(
                        coverColor: color,
                        updatedAt: DateTime.now(),
                      );
                      await _dataService.updateDeck(updatedDeck);
                    }
                    
                    Navigator.pop(context);
                    setState(() {});
                    
                                         if (mounted) {
                       SnackbarUtils.showSuccessSnackbar(
                         context,
                         'Pack color updated! All decks now use this color.',
                       );
                     }
                  } catch (e) {
                                         if (mounted) {
                       SnackbarUtils.showErrorSnackbar(
                         context,
                         'Error updating color: ${e.toString()}',
                       );
                     }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF$color')),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditPackDetails() {
    final nameController = TextEditingController(text: widget.deckPack.name);
    final descriptionController = TextEditingController(text: widget.deckPack.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Pack Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Pack Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedPack = widget.deckPack.copyWith(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await _dataService.updateDeckPack(updatedPack);
                
                Navigator.pop(context);
                setState(() {});
                
                                 if (mounted) {
                   SnackbarUtils.showSuccessSnackbar(
                     context,
                     'Pack details updated successfully!',
                   );
                 }
              } catch (e) {
                                 if (mounted) {
                   SnackbarUtils.showErrorSnackbar(
                     context,
                     'Error updating pack: ${e.toString()}',
                   );
                 }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckPack.name),
        backgroundColor: Color(int.parse('0xFF${widget.deckPack.coverColor ?? 'FF9800'}')),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditPackOptions,
            tooltip: 'Edit Pack',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeckOptions,
        backgroundColor: Color(int.parse('0xFF${widget.deckPack.coverColor ?? 'FF9800'}')),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Decks'),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Pack Info Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(int.parse('0xFF${widget.deckPack.coverColor ?? 'FF9800'}')),
                Color(int.parse('0xFF${widget.deckPack.coverColor ?? 'FF9800'}')).withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.deckPack.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.deckPack.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.deckPack.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_decks.length} decks',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(widget.deckPack.updatedAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Decks List
        Expanded(
          child: _decks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _decks.length,
                  itemBuilder: (context, index) {
                    final deck = _decks[index];
                    return _buildDeckCard(deck);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No decks in this pack yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first deck to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckCard(Deck deck) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDeck(deck),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Deck Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}')),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Deck Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deck.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.style,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${deck.cardCount} cards',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Remove Button
              IconButton(
                onPressed: () => _removeDeckFromPack(deck),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                tooltip: 'Remove from pack',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailScreen(deck: deck),
      ),
    ).then((_) => _loadDecks());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
