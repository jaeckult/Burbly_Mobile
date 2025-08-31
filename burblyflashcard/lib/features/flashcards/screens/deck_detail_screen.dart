import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/core.dart';
import 'add_flashcard_screen.dart';
import 'study_mode_selection_screen.dart';
import 'spaced_repetition_stats_screen.dart';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _currentDeck = widget.deck;
    _loadFlashcards();
    _startPeriodicRefresh();
    
    // Start overdue monitoring for this deck
    if (_currentDeck.spacedRepetitionEnabled) {
      OverdueService().startOverdueMonitoring();
    }
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

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds to keep tag states updated
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshDeck();
        _loadFlashcards();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatusItem(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Card-level review status tags removed - only deck-level tags are used

  void _addFlashcard() {
    context.pushScale(
      AddFlashcardScreen(deckId: widget.deck.id),
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

    context.pushSharedAxis(
      StudyModeSelectionScreen(
        deck: _currentDeck,
        flashcards: _flashcards,
      ),
    ).then((_) {
      _loadFlashcards();
      _refreshDeck();
    });
  }

  void _showSpacedRepetitionStats() {
    context.pushFade(
      SpacedRepetitionStatsScreen(
        deck: _currentDeck,
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
            title: const Text('Study Timer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _currentDeck.timerDuration != null
                  ? '${_currentDeck.timerDuration} seconds per card'
                  : '30 seconds per card (default)',
            ),
            trailing: IconButton(
              onPressed: () => _showTimerSettings(),
              icon: const Icon(Icons.edit, size: 20),
              tooltip: 'Edit Timer',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.1),
                foregroundColor: Colors.blue,
              ),
            ),
          ),

          // Spaced Repetition Settings
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Spaced Repetition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _currentDeck.spacedRepetitionEnabled
                  ? 'Enabled - Cards will be scheduled for optimal review'
                  : 'Disabled - Cards will be shown in order',
            ),
           trailing: Transform.scale(
  scale: 0.8, // reduce switch size
  child: Switch.adaptive(
    value: _currentDeck.spacedRepetitionEnabled,
    activeColor: Theme.of(context).colorScheme.primary,
    activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
    inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
    inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
    onChanged: (value) async {
      try {
        final updatedDeck = _currentDeck.copyWith(
          spacedRepetitionEnabled: value,
        );
        await _dataService.updateDeck(updatedDeck);
        setState(() => _currentDeck = updatedDeck);
        Navigator.pop(context);

        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            value
                ? 'Spaced repetition enabled!'
                : 'Spaced repetition disabled!',
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
),

          // Study Stats Visibility Settings
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Show Study Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _currentDeck.showStudyStats ?? true
                  ? 'Stats bar will be visible during study'
                  : 'Stats bar will be hidden during study',
            ),
            trailing: Transform.scale(
  scale: 0.8, // reduce size a bit
  child: Switch.adaptive(
    value: _currentDeck.showStudyStats ?? true,
    activeColor: Theme.of(context).colorScheme.primary, // consistent with theme
    activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
    inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
    inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
    onChanged: (value) async {
      try {
        final updatedDeck = _currentDeck.copyWith(showStudyStats: value);
        await _dataService.updateDeck(updatedDeck);
        setState(() => _currentDeck = updatedDeck);
        Navigator.pop(context);

        if (mounted) {
          SnackbarUtils.showSuccessSnackbar(
            context,
            value
                ? 'Study stats will be shown!'
                : 'Study stats will be hidden!',
          );
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showErrorSnackbar(
            context,
            'Error updating study stats setting: ${e.toString()}',
          );
        }
      }
    },
  ),
),
),

          // Scheduled Review Settings removed (use header alarm button instead)

          // Deck Pack Settings
          
        ],
      ),
    ),
  );
}

void _showTimerSettings() {
  int? selectedDuration = _currentDeck.timerDuration ?? 30; // Default to 30 if null

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Timer Settings',
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Set a timer for each flashcard during study sessions. The timer will automatically show the answer when time runs out.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // Quick Selection Buttons
            const Text(
              'Quick Select:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickTimerButton(1, '1s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(3, '3s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(10, '10s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(15, '15s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(30, '30s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(45, '45s', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(60, '1m', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(90, '1.5m', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
                _buildQuickTimerButton(120, '2m', selectedDuration, (value) {
                  selectedDuration = value;
                  setDialogState(() {}); // Force UI update
                }),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Info Box
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
          ElevatedButton(
            onPressed: () async {
              try {
                // Handle the case where selectedDuration is 0 (should be saved as null)
                final finalDuration = selectedDuration == 0 ? null : selectedDuration;
                final updatedDeck = _currentDeck.copyWith(
                  timerDuration: finalDuration,
                );
                await _dataService.updateDeck(updatedDeck);
                setState(() {
                  _currentDeck = updatedDeck;
                });
                Navigator.pop(context);
                Navigator.pop(context);

                if (mounted) {
                  SnackbarUtils.showSuccessSnackbar(
                    context,
                    finalDuration != null
                        ? 'Timer set to ${finalDuration} seconds per card!'
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
    ),
  );
}
Widget _buildQuickTimerButton(
  int duration,
  String label,
  int? selectedDuration,
  Function(int?) onTap,
) {
  final isSelected = selectedDuration == duration;

  return InkWell(
    onTap: () => onTap(isSelected ? null : duration),
    borderRadius: BorderRadius.circular(20),
    splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    focusColor: Theme.of(context).colorScheme.primary,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.green // Green when selected
            : Colors.blue.withOpacity(0.1), // Blue when not selected
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.green // Green border when selected
              : Colors.blue.withOpacity(0.5), // Blue border when not selected
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.blue[700], // Blue text when not selected
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
      ),
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
        title: Text(
          _currentDeck.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
      floatingActionButton: _flashcards.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addFlashcard,
              backgroundColor: Color(int.parse('0xFF${_currentDeck.coverColor ?? '2196F3'}')),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,

    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        
        return Column(
          children: [
        // Deck Info Card
        Container(
          margin: EdgeInsets.all(isWide ? 24 : 16),
          padding: EdgeInsets.all(isWide ? 24 : 16),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentDeck.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Builder(
                          builder: (context) {
                            final enabled = _currentDeck.scheduledReviewEnabled ?? false;
                            final time = _currentDeck.scheduledReviewTime;
                            if (!enabled || time == null) {
                              return const Text(
                                'No schedule',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            final now = DateTime.now();
                            if (time.isAfter(now)) {
                              return Text(
                                'Next: ${_formatScheduledTime(time)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            // Past scheduled time → show Overdue without the 'Next:' prefix
                            return const Text(
                              'Schedule here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: _showScheduledReviewSettings,
                        icon: const Icon(
                          Icons.alarm_add,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Schedule Review',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
               if (_currentDeck.description.isNotEmpty) ...[
                 const SizedBox(height: 8),
                 Text(
                   _currentDeck.description,
                   style: TextStyle(
                     color: Colors.white.withOpacity(0.9),
                     fontSize: 16,
                   ),
                   maxLines: 3,
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  if (_currentDeck.deckIsReviewNow == true) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,   color: Color.fromARGB(255, 239, 212, 173), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _formatDeckReviewNowText(_currentDeck.deckReviewNowStartTime),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 239, 212, 173),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (_currentDeck.deckIsOverdue == true) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.35)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Overdue',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (_currentDeck.deckReviewedStartTime != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Color.fromARGB(255, 255, 255, 255), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _formatDeckReviewedText(_currentDeck.deckReviewedStartTime),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if ((_currentDeck.scheduledReviewEnabled ?? false) && _currentDeck.scheduledReviewTime != null) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Next: ${_formatScheduledTime(_currentDeck.scheduledReviewTime!)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  // No status yet: show Schedule Review chip to open the popup
                  return InkWell(
                    onTap: _showScheduledReviewSettings,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_alarm, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Schedule Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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

        // // Review Status Card
        // if (_currentDeck.spacedRepetitionEnabled) ...[
        //   Container(
        //     margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 8),
        //     padding: EdgeInsets.all(isWide ? 16 : 12),
        //     decoration: BoxDecoration(
        //       color: Theme.of(context).cardColor,
        //       borderRadius: BorderRadius.circular(12),
        //       border: Border.all(
        //         color: Colors.grey.withOpacity(0.2),
        //       ),
        //     ),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Row(
        //           children: [
        //             Icon(
        //               Icons.assignment_turned_in,
        //               size: 16,
        //               color: Colors.blue[600],
        //             ),
        //             const SizedBox(width: 8),
        //             Text(
        //               'Review Status',
        //               style: TextStyle(
        //                 fontSize: 14,
        //                 fontWeight: FontWeight.w600,
        //                 color: Colors.blue[700],
        //               ),
        //             ),
        //           ],
        //         ),
        //         const SizedBox(height: 12),
        //         FutureBuilder<Map<String, dynamic>>(
        //           future: OverdueService().getOverdueStats(_currentDeck.id),
        //           builder: (context, snapshot) {
        //             if (snapshot.connectionState == ConnectionState.waiting) {
        //               return const Center(child: CircularProgressIndicator());
        //             }
                    
        //             if (snapshot.hasError) {
        //               return Text(
        //                 'Error loading review status',
        //                 style: TextStyle(color: Colors.red[600], fontSize: 12),
        //               );
        //             }
                    
        //             final stats = snapshot.data ?? {};
        //             final totalOverdue = stats['totalOverdue'] ?? 0;
        //             final totalCards = _flashcards.length;
        //             final reviewNowCards = _flashcards.where((card) => 
        //               OverdueService().shouldShowReviewNowTag(card)).length;
        //             final reviewedCards = _flashcards.where((card) => 
        //               OverdueService().shouldShowReviewedTag(card)).length;
                    
        //             return Column(
        //               children: [
        //                 Row(
        //                   children: [
        //                     Expanded(
        //                       child: _buildStatusItem(
        //                         'Review Now',
        //                         (_currentDeck.deckIsReviewNow ?? false) ? 1 : 0,
        //                         Colors.orange,
        //                         Icons.schedule,
        //                       ),
        //                     ),
        //                     Expanded(
        //                       child: _buildStatusItem(
        //                         'Overdue',
        //                         (_currentDeck.deckIsOverdue ?? false) ? 1 : 0,
        //                         Colors.red,
        //                         Icons.warning,
        //                       ),
        //                     ),
        //                     Expanded(
        //                       child: _buildStatusItem(
        //                         'Reviewed',
        //                         (_currentDeck.deckIsReviewed ?? false) ? 1 : 0,
        //                         Colors.green,
        //                         Icons.check_circle,
        //                       ),
        //                     ),
        //                   ],
        //                 ),
        //                 const SizedBox(height: 8),
        //                 // Deck-level tags (badges)
        //                 Wrap(
        //                   spacing: 8,
        //                   runSpacing: 8,
        //                   children: [
        //                     if ((_currentDeck.deckIsReviewNow ?? false))
        //                       Container(
        //                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //                         decoration: BoxDecoration(
        //                           color: Colors.orange.withOpacity(0.15),
        //                           borderRadius: BorderRadius.circular(16),
        //                           border: Border.all(color: Colors.orange.withOpacity(0.35)),
        //                         ),
        //                         child: Row(
        //                           mainAxisSize: MainAxisSize.min,
        //                           children: [
        //                             const Icon(Icons.schedule, size: 14, color: Colors.orange),
        //                             const SizedBox(width: 6),
        //                             Text(
        //                               _formatDeckReviewNowText(_currentDeck.deckReviewNowStartTime),
        //                               style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                     if ((_currentDeck.deckIsOverdue ?? false))
        //                       Container(
        //                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //                         decoration: BoxDecoration(
        //                           color: Colors.red.withOpacity(0.15),
        //                           borderRadius: BorderRadius.circular(16),
        //                           border: Border.all(color: Colors.red.withOpacity(0.35)),
        //                         ),
        //                         child: const Row(
        //                           mainAxisSize: MainAxisSize.min,
        //                           children: [
        //                             Icon(Icons.warning, size: 14, color: Colors.red),
        //                             SizedBox(width: 6),
        //                             Text(
        //                               'Overdue',
        //                               style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                     if ((_currentDeck.deckIsReviewed ?? false))
        //                       Container(
        //                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        //                         decoration: BoxDecoration(
        //                           color: Colors.green.withOpacity(0.15),
        //                           borderRadius: BorderRadius.circular(16),
        //                           border: Border.all(color: Colors.green.withOpacity(0.35)),
        //                         ),
        //                         child: Row(
        //                           mainAxisSize: MainAxisSize.min,
        //                           children: [
        //                             const Icon(Icons.check_circle, size: 14, color: Colors.green),
        //                             const SizedBox(width: 6),
        //                             Text(
        //                               _formatDeckReviewedText(_currentDeck.deckReviewedStartTime),
        //                               style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
        //                             ),
        //                           ],
        //                         ),
        //                       ),
        //                   ],
        //                 ),
        //                 if (totalOverdue > 0) ...[
        //                   const SizedBox(height: 8),
        //                   Container(
        //                     padding: const EdgeInsets.all(8),
        //                     decoration: BoxDecoration(
        //                       color: Colors.red.withOpacity(0.1),
        //                       borderRadius: BorderRadius.circular(8),
        //                       border: Border.all(color: Colors.red.withOpacity(0.3)),
        //                     ),
        //                     child: Row(
        //                       children: [
        //                         Icon(Icons.info, color: Colors.red[600], size: 16),
        //                         const SizedBox(width: 8),
        //                         Expanded(
        //                           child: Text(
        //                             'You have $totalOverdue overdue cards that need attention!',
        //                             style: TextStyle(
        //                               color: Colors.red[700],
        //                               fontSize: 12,
        //                               fontWeight: FontWeight.w500,
        //                             ),
        //                           ),
        //                         ),
        //                       ],
        //                     ),
        //                   ),
        //                 ],
        //               ],
        //             );
        //           },
        //         ),
        //       ],
        //     ),
        //   ),
        // ],

        // Settings Indicator
        Container(
          margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 8),
          padding: EdgeInsets.all(isWide ? 16 : 12),
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
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _currentDeck.timerDuration != null 
                               ? '${_currentDeck.timerDuration}s'
                               : '30s (default)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
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
  
  // Overdue Stats Button
  // if (_currentDeck.spacedRepetitionEnabled) ...[
  //   Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: ElevatedButton.icon(
  //       onPressed: _showOverdueStats,
  //       icon: const Icon(Icons.warning, color: Colors.orange),
  //       label: const Text('Overdue Stats'),
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: Colors.orange,
  //         foregroundColor: Colors.white,
  //         padding: const EdgeInsets.symmetric(vertical: 12),
  //       ),
  //     ),
  //   ),
  // ],
],

        // Flashcards List
        Expanded(
          child: _flashcards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
                  itemCount: _flashcards.length,
                  itemBuilder: (context, index) {
                    final flashcard = _flashcards[index];
                    return _buildFlashcardCard(flashcard);
                  },
                ),
        ),
      ],
    );
      },
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
                    child:                     Text(
                      'Q: ${flashcard.question}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
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
              
                            // Debug: Manual Overdue Check Button (only in debug mode)
              
              const SizedBox(height: 8),
              Text(
                'A: ${flashcard.answer}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Card-level tags are disabled - only deck-level tags are shown
              // Review Status Tags removed since we only use deck-level scheduling
              
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

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h from now';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m from now';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m from now';
    } else {
      return 'Now';
    }
  }

  String _formatDeckReviewNowText(DateTime? start) {
    if (start == null) return 'Review Now';
    final now = DateTime.now();
    final elapsed = now.difference(start);
    final remaining = 10 - elapsed.inMinutes;
    if (remaining <= 0) return 'Review Now';
    if (remaining == 10) return 'Review Now';
    return 'Review Now';
  }

  String _formatDeckReviewedText(DateTime? start) {
    if (start == null) return 'Reviewed';
    final now = DateTime.now();
    final elapsed = now.difference(start);
    if (elapsed.inMinutes < 60) {
      final mins = elapsed.inMinutes;
      if (mins <= 0) return 'Reviewed just now';
      if (mins == 1) return 'Reviewed 1m ago';
      return 'Reviewed ${mins}m ago';
    }
    if (elapsed.inHours < 24) {
      final hrs = elapsed.inHours;
      if (hrs == 1) return 'Reviewed 1h ago';
      return 'Reviewed ${hrs}h ago';
    }
    final days = elapsed.inDays;
    if (days == 1) return 'Reviewed 1d ago';
    return 'Reviewed ${days}d ago';
  }

  void _showScheduledReviewSettings() {
    DateTime selectedDateTime = _currentDeck.scheduledReviewTime ?? DateTime.now().add(const Duration(hours: 1));
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alarm_add, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Schedule Review'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pick a date and time for your next review. We’ll remind you and show a "Review Now" window 10 minutes before.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Quick picks
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Quick picks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickScheduleChip(
  'In 10m',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 10 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 9,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(minutes: 10)));
  },
),
_buildQuickScheduleChip(
  'In 15m',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 15 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 14,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(minutes: 15)));
  },
),
_buildQuickScheduleChip(
  'In 30m',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 30 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 29,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(minutes: 30)));
  },
),
_buildQuickScheduleChip(
  'In 1h',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 60 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 59,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(hours: 1)));
  },
),
_buildQuickScheduleChip(
  'In 6h',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 360 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 359,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(hours: 6)));
  },
),
_buildQuickScheduleChip(
  'In 24h',
  selectedDateTime.difference(DateTime.now()).inMinutes <= 1440 &&
      selectedDateTime.difference(DateTime.now()).inMinutes >= 1439,
  () {
    setDialogState(
        () => selectedDateTime = DateTime.now().add(const Duration(hours: 24)));
  },
),

                 
                ],
              ),
              const SizedBox(height: 12),
              
              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  '${selectedDateTime.day}/${selectedDateTime.month}/${selectedDateTime.year}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDateTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() {
                      selectedDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedDateTime.hour,
                        selectedDateTime.minute,
                      );
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              // Time Picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(
                  '${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                  );
                  if (time != null) {
                    setDialogState(() {
                      selectedDateTime = DateTime(
                        selectedDateTime.year,
                        selectedDateTime.month,
                        selectedDateTime.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
  child: Text(
    selectedDateTime.isBefore(DateTime.now())
        ? 'Not scheduled yet'
        : 'Next: ${_formatScheduledTime(selectedDateTime)}',
    style: const TextStyle(fontSize: 12, color: Colors.blue),
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
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedDeck = _currentDeck.copyWith(
                    scheduledReviewTime: selectedDateTime,
                    scheduledReviewEnabled: true,
                  );
                  await _dataService.updateDeck(updatedDeck);
                  setState(() => _currentDeck = updatedDeck);
                  
                  // Handle notification scheduling based on enabled state
                  await NotificationService().updateDeckReviewNotification(updatedDeck);
                  // Start overdue monitoring for this deck
                  OverdueService().startOverdueMonitoring();
                  
                  Navigator.pop(context);

                  if (mounted) {
                    final message = 'Scheduled for ${_formatScheduledTime(selectedDateTime)}';
                    SnackbarUtils.showSuccessSnackbar(context, message);
                  }
                } catch (e) {
                  if (mounted) {
                    SnackbarUtils.showErrorSnackbar(
                      context,
                      'Error setting scheduled review time: ${e.toString()}',
                    );
                  }
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickScheduleChip(String label, bool isActive, VoidCallback onTap) {
    final Color baseColor = const Color.fromARGB(255, 55, 66, 115);
    final Color notBaseColor = const Color.fromARGB(255, 0, 47, 255);
 final Color bg = isActive ? notBaseColor.withOpacity(0.25) : baseColor.withOpacity(0.12);
final Color border = isActive ? notBaseColor.withOpacity(0.9) : baseColor.withOpacity(0.5);
final Color text = isActive ? notBaseColor : baseColor.withOpacity(0.9);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      highlightColor: notBaseColor.withOpacity(0.12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
        ),
      ),
    );
  }

  void _showOverdueStats() async {
    try {
      final stats = await OverdueService().getOverdueStats(_currentDeck.id);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Overdue Statistics'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Overdue Cards: ${stats['totalOverdue']}'),
                const SizedBox(height: 8),
                if (stats['totalOverdue'] > 0) ...[
                  Text('Total Overdue Time: ${stats['totalOverdueMinutes']} minutes'),
                  const SizedBox(height: 4),
                  Text('Average Overdue Time: ${stats['averageOverdueMinutes'].toStringAsFixed(1)} minutes'),
                  const SizedBox(height: 16),
                  const Text(
                    'Review Now and Reviewed tags last 10 minutes. Overdue stays until you study the deck.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  const Text('No overdue cards! 🎉'),
                  const SizedBox(height: 8),
                  const Text(
                    'All cards are up to date with their review schedule.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
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
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error loading overdue statistics: ${e.toString()}',
        );
      }
    }
  }
}
