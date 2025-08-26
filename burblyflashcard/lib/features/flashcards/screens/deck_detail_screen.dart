import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'add_flashcard_screen.dart';
import 'study_mode_selection_screen.dart';
import 'spaced_repetition_stats_screen.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class DeckDetailScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailScreen({
    super.key,
    required this.deck,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  final DataService _dataService = DataService();
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  late Deck _currentDeck;

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck;
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final flashcards = await _dataService.getFlashcardsForDeck(_currentDeck.id);
    setState(() {
      _flashcards = flashcards;
      _isLoading = false;
    });
  }

  Future<void> _refreshDeck() async {
    try {
      final allDecks = await _dataService.getDecks();
      final updatedDeck = allDecks.firstWhere(
        (deck) => deck.id == _currentDeck.id,
        orElse: () => _currentDeck,
      );
      setState(() {
        _currentDeck = updatedDeck;
      });
    } catch (e) {
      print('Error refreshing deck: $e');
    }
  }

  void _addFlashcard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFlashcardScreen(deckId: widget.deck.id),
      ),
    ).then((_) => _loadFlashcards());
  }

  void _startStudy() {
    if (_flashcards.isEmpty) {
      SnackbarUtils.showWarningSnackbar(
        context,
        'Add some flashcards to start studying!',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyModeSelectionScreen(
          deck: _currentDeck,
          flashcards: _flashcards,
        ),
      ),
    ).then((_) {
      _loadFlashcards();
      _refreshDeck();
    });
  }

  void _showSpacedRepetitionStats() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpacedRepetitionStatsScreen(
          deck: _currentDeck,
        ),
      ),
    );
  }

  void _showDeckSettings() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Deck Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Study Features',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Timer: Automatically shows answer after set time (Enhanced Study mode only)\n'
                  '• Spaced Repetition: Uses SM2 algorithm to schedule cards for optimal review intervals\n'
                  '• Cards you know well appear less frequently, difficult cards appear more often',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Timer Settings
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Study Timer'),
            subtitle: Text(
              _currentDeck.timerDuration != null
                  ? '${_currentDeck.timerDuration} seconds per card'
                  : 'Disabled - No time limit',
            ),
            trailing: Switch(
              value: _currentDeck.timerDuration != null,
              onChanged: (value) async {
                if (!value) {
                  // 🔴 Switch turned OFF → disable timer immediately
                  try {
                    final updatedDeck = _currentDeck.copyWith(timerDuration: null);
                    await _dataService.updateDeck(updatedDeck);
                    setState(() {
                      _currentDeck = updatedDeck;
                    });
                    Navigator.pop(context);

                    if (mounted) {
                      SnackbarUtils.showSuccessSnackbar(
                        context,
                        'Timer disabled.',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      SnackbarUtils.showErrorSnackbar(
                        context,
                        'Error disabling timer: ${e.toString()}',
                      );
                    }
                  }
                } else {
                  // 🟢 Switch turned ON → open timer settings dialog
                  Navigator.pop(context);
                  _showTimerSettings();
                }
              },
            ),
          ),

          // Spaced Repetition Settings
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Spaced Repetition'),
            subtitle: Text(
              _currentDeck.spacedRepetitionEnabled
                  ? 'Enabled - Cards will be scheduled for optimal review'
                  : 'Disabled - Cards will be shown in order',
            ),
            trailing: Switch(
              value: _currentDeck.spacedRepetitionEnabled,
              onChanged: (value) async {
                try {
                  final updatedDeck = _currentDeck.copyWith(
                    spacedRepetitionEnabled: value,
                  );
                  await _dataService.updateDeck(updatedDeck);
                  setState(() {
                    _currentDeck = updatedDeck;
                  });
                  Navigator.pop(context);

                  if (mounted) {
                    SnackbarUtils.showSuccessSnackbar(
                      context,
                      value
                          ? 'Spaced repetition enabled! Cards will be scheduled for optimal review.'
                          : 'Spaced repetition disabled. Cards will be shown in order.',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    SnackbarUtils.showErrorSnackbar(
                      context,
                      'Error updating spaced repetition setting: ${e.toString()}',
                    );
                  }
                }
              },
            ),
          ),

          // Deck Pack Settings
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Deck Pack'),
            subtitle: Text(
              _currentDeck.packId != null ? 'Assigned to pack' : 'No pack assigned',
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeckPackSettings();
            },
          ),
        ],
      ),
    ),
  );
}

void _showTimerSettings() {
  int? selectedDuration = _currentDeck.timerDuration;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Study Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set a timer for each flashcard during study sessions. The timer will automatically show the answer when time runs out.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: selectedDuration,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Timer Duration',
              helperText: 'Choose how long to spend on each card',
            ),
            items: const [
              DropdownMenuItem(
                value: null,
                child: Text('No Timer (Disabled)'),
              ),
              DropdownMenuItem(
                value: 10,
                child: Text('10 seconds (Quick)'),
              ),
              DropdownMenuItem(
                value: 15,
                child: Text('15 seconds'),
              ),
              DropdownMenuItem(
                value: 30,
                child: Text('30 seconds (Recommended)'),
              ),
              DropdownMenuItem(
                value: 45,
                child: Text('45 seconds'),
              ),
              DropdownMenuItem(
                value: 60,
                child: Text('60 seconds (Slow)'),
              ),
              DropdownMenuItem(
                value: 90,
                child: Text('90 seconds'),
              ),
              DropdownMenuItem(
                value: 120,
                child: Text('2 minutes'),
              ),
            ],
            onChanged: (value) {
              selectedDuration = value;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Timer only works in Enhanced Study mode. Regular study mode ignores timer settings.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
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
              final updatedDeck = _currentDeck.copyWith(
                timerDuration: selectedDuration,
              );
              await _dataService.updateDeck(updatedDeck);
              setState(() {
                _currentDeck = updatedDeck;
              });
              Navigator.pop(context);

              if (mounted) {
                SnackbarUtils.showSuccessSnackbar(
                  context,
                  selectedDuration != null
                      ? 'Timer set to ${selectedDuration} seconds per card!'
                      : 'Timer disabled.',
                );
              }
            } catch (e) {
              if (mounted) {
                SnackbarUtils.showErrorSnackbar(
                  context,
                  'Error updating timer setting: ${e.toString()}',
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

  void _showDeckPackSettings() async {
    List<DeckPack> availablePacks = [];
    try {
      availablePacks = await _dataService.getDeckPacks();
    } catch (e) {
      // Handle error silently
    }

    String? selectedPackId = _currentDeck.packId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deck Pack Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assign this deck to a pack:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPackId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Deck Pack',
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('No Pack'),
                ),
                ...availablePacks.map((pack) => DropdownMenuItem(
                  value: pack.id,
                  child: Text(pack.name),
                )),
              ],
              onChanged: (value) {
                selectedPackId = value;
              },
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
                 if (selectedPackId != null) {
                   await _dataService.addDeckToPack(_currentDeck.id, selectedPackId!);
                 } else if (_currentDeck.packId != null) {
                   await _dataService.removeDeckFromPack(_currentDeck.id, _currentDeck.packId!);
                 }
                 
                 final updatedDeck = _currentDeck.copyWith(
                   packId: selectedPackId,
                 );
                 await _dataService.updateDeck(updatedDeck);
                 
                 setState(() {
                   _currentDeck = updatedDeck;
                 });
                 Navigator.pop(context);
                
                                 if (mounted) {
                   SnackbarUtils.showSuccessSnackbar(
                     context,
                     selectedPackId != null 
                         ? 'Deck assigned to pack successfully!' 
                         : 'Deck removed from pack successfully!',
                   );
                 }
              } catch (e) {
                                 if (mounted) {
                   SnackbarUtils.showErrorSnackbar(
                     context,
                     'Error updating deck pack: ${e.toString()}',
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

  Future<void> _editDeck() async {
    String name = _currentDeck.name;
    String description = _currentDeck.description;
    String color = (_currentDeck.coverColor ?? '2196F3').toUpperCase();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deck'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => description = v,
              ),
              const SizedBox(height: 12),
              ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updated = _currentDeck.copyWith(
                  name: name.trim(),
                  description: description.trim(),
                  coverColor: color.trim().isEmpty ? _currentDeck.coverColor : color.trim(),
                  updatedAt: DateTime.now(),
                );
                await _dataService.updateDeck(updated);
                setState(() {
                  _currentDeck = updated;
                });
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                if (mounted) {
                  SnackbarUtils.showSuccessSnackbar(context, 'Deck updated');
                }
              } catch (e) {
                if (mounted) {
                  SnackbarUtils.showErrorSnackbar(context, 'Update failed: ${e.toString()}');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showFlashcardOptions(Flashcard flashcard) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Flashcard'),
              onTap: () {
                Navigator.pop(context);
                _editFlashcard(flashcard);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Flashcard', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteFlashcard(flashcard);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editFlashcard(Flashcard flashcard) async {
    final questionController = TextEditingController(text: flashcard.question);
    final answerController = TextEditingController(text: flashcard.answer);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Flashcard'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Answer',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updated = flashcard.copyWith(
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                await _dataService.updateFlashcard(updated);
                await _loadFlashcards();
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                if (mounted) {
                  SnackbarUtils.showSuccessSnackbar(context, 'Flashcard updated');
                }
              } catch (e) {
                if (mounted) {
                  SnackbarUtils.showErrorSnackbar(context, 'Update failed: ${e.toString()}');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Flashcard'),
        content: const Text('Are you sure you want to delete this flashcard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteFlashcard(flashcard.id);
      await _loadFlashcards();
      
             if (mounted) {
         SnackbarUtils.showWarningSnackbar(
           context,
           'Flashcard deleted',
         );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentDeck.name),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDeck,
            tooltip: 'Edit Deck',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDeckSettings,
            tooltip: 'Deck Settings',
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _startStudy,
            tooltip: 'Start Studying',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
             floatingActionButton: FloatingActionButton(
         onPressed: _addFlashcard,
         backgroundColor: Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')),
         foregroundColor: Colors.white,
         child: const Icon(Icons.add),
       ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Deck Info Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                           colors: [
               Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')),
               Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')).withOpacity(0.7),
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
                 _currentDeck.name,
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 24,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               if (_currentDeck.description.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 Text(
                   _currentDeck.description,
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
                    Icons.style,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_flashcards.length} flashcards',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_flashcards.isNotEmpty) ...[
                    Icon(
                      Icons.timer,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_flashcards.length * 0.5).ceil()} min',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Settings Indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Study Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Timer Setting
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                                                   color: _currentDeck.timerDuration != null 
                             ? Colors.orange 
                             : Colors.grey[400],
                       ),
                       const SizedBox(width: 4),
                       Expanded(
                         child: Text(
                           _currentDeck.timerDuration != null 
                               ? '${_currentDeck.timerDuration}s'
                               : 'No timer',
                           style: TextStyle(
                             fontSize: 12,
                             color: _currentDeck.timerDuration != null 
                                 ? Colors.orange[700]
                                 : Colors.grey[500],
                           ),
                         ),
                       ),
                      ],
                    ),
                  ),
                  // Spaced Repetition Setting
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                                                   color: _currentDeck.spacedRepetitionEnabled 
                             ? Colors.green 
                             : Colors.grey[400],
                       ),
                       const SizedBox(width: 4),
                       Expanded(
                         child: Text(
                           _currentDeck.spacedRepetitionEnabled 
                               ? 'SR Enabled'
                               : 'SR Disabled',
                           style: TextStyle(
                             fontSize: 12,
                             color: _currentDeck.spacedRepetitionEnabled 
                                 ? Colors.green[700]
                                 : Colors.grey[500],
                           ),
                         ),
                       ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Buttons
        if (_flashcards.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startStudy,
                    icon: const Icon(Icons.school),
                    label: const Text('Study'),
                                         style: ElevatedButton.styleFrom(
                       backgroundColor: Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSpacedRepetitionStats,
                    icon: const Icon(Icons.analytics),
                    label: const Text('SR Stats'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Flashcards List
        Expanded(
          child: _flashcards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = _flashcards[index];
                    return _buildFlashcardCard(flashcard);
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
            Icons.style_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No flashcards yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first flashcard to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addFlashcard,
            icon: const Icon(Icons.add),
            label: const Text('Add Flashcard'),
                         style: ElevatedButton.styleFrom(
               backgroundColor: Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')),
               foregroundColor: Colors.white,
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showFlashcardOptions(flashcard),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Q: ${flashcard.question}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showFlashcardOptions(flashcard),
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A: ${flashcard.answer}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ease: ${flashcard.easeFactor.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (flashcard.lastReviewed != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(flashcard.lastReviewed!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
