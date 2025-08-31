import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/deck_scheduling_service.dart';

class ModernStudyScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  final bool useFSRS;

  const ModernStudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
    this.useFSRS = false,
  });

  @override
  State<ModernStudyScreen> createState() => _ModernStudyScreenState();
}

class _ModernStudyScreenState extends State<ModernStudyScreen> {
  late final StudyService _studyService;
  late final FSRSStudyService _fsrsStudyService;
  final DataService _dataService = DataService();
  late final DeckSchedulingService _deckSchedulingService;
  
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  bool _showRatingButtons = false;
  
  // Study session tracking
  late SimpleStudySession _studySession;
  final Map<String, StudyRating> _cardResults = {};
  final List<StudyResult> _pendingStudyResults = [];

  @override
  void initState() {
    super.initState();
    _initializeStudyServices();
    _initializeStudySession();
  }

  void _initializeStudyServices() {
    _studyService = StudyService();
    _fsrsStudyService = FSRSStudyService();
    _deckSchedulingService = DeckSchedulingService();
  }

  void _initializeStudySession() {
    _studySession = SimpleStudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deckId: widget.deck.id,
      startTime: DateTime.now(),
      totalCards: widget.flashcards.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Study: ${widget.deck.name}'),
          backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No flashcards to study!'),
        ),
      );
    }

    final currentCard = widget.flashcards[_currentIndex];
    final deckColor = Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}'));

    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${widget.deck.name}'),
        backgroundColor: deckColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${widget.flashcards.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.flashcards.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(deckColor),
          ),

          // Card Info Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: deckColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: deckColor),
                const SizedBox(width: 8),
                Text(
                  _getCardInfo(currentCard),
                  style: TextStyle(
                    fontSize: 12,
                    color: deckColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (currentCard.lastReviewed != null)
                  Text(
                    'Last: ${_formatDate(currentCard.lastReviewed!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: deckColor.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Flashcard Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        deckColor,
                        deckColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Question/Answer Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _showAnswer ? 'ANSWER' : 'QUESTION',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Question/Answer Text
                        Text(
                          _showAnswer ? currentCard.answer : currentCard.question,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Study progress info
                        if (_showAnswer) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Interval: ${currentCard.interval} days',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ease: ${currentCard.easeFactor.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Tap to reveal answer',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          if (_showAnswer && _showRatingButtons) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Rating buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildRatingButton(
                          'Again',
                          Icons.close,
                          Colors.red,
                          StudyRating.again,
                          'Failed to recall',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Hard',
                          Icons.remove,
                          Colors.orange,
                          StudyRating.hard,
                          'Difficult to recall',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Good',
                          Icons.check,
                          Colors.green,
                          StudyRating.good,
                          'Correctly recalled',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Easy',
                          Icons.thumb_up,
                          Colors.blue,
                          StudyRating.easy,
                          'Very easy to recall',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (!_showAnswer) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAnswerAndRating(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deckColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Show Answer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingButton(
    String label,
    IconData icon,
    Color color,
    StudyRating rating,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _rateCard(rating),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnswerAndRating() {
    setState(() {
      _showAnswer = true;
      _showRatingButtons = true;
    });
  }

  Future<void> _rateCard(StudyRating rating) async {
    setState(() => _isLoading = true);

    try {
      final currentCard = widget.flashcards[_currentIndex];
      
      // Calculate the study result without applying changes
      final studyResult = widget.useFSRS 
          ? _fsrsStudyService.calculateStudyResult(currentCard, rating)
          : _studyService.calculateStudyResult(currentCard, rating);
      
      // Store the pending result
      _pendingStudyResults.add(studyResult);
      
      // Update overdue/review tags: mark as studied (clears overdue/review-now and sets Reviewed for 10m)
      try {
        final quality = {
          StudyRating.again: 1,
          StudyRating.hard: 2,
          StudyRating.good: 3,
          StudyRating.easy: 4,
        }[rating] ?? 3;
        await OverdueService().markCardAsStudied(currentCard, quality);
      } catch (e) {
        print('OverdueService markCardAsStudied failed: $e');
      }
      
      // Track the result
      _cardResults[currentCard.id] = rating;
      
      // Show result feedback
      _showRatingFeedback(studyResult);
      
      // Move to next card or finish
      if (_currentIndex < widget.flashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _showAnswer = false;
          _showRatingButtons = false;
        });
      } else {
        // Study session completed
        await _completeStudySession();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error processing card: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRatingFeedback(StudyResult result) {
    String message = '';
    Color color = Colors.grey;
    
    switch (result.rating) {
      case StudyRating.again:
        message = 'Card reset to learning (1 day)';
        color = Colors.red;
        break;
      case StudyRating.hard:
        message = 'Interval reduced to ${result.newInterval} days';
        color = Colors.orange;
        break;
      case StudyRating.good:
        message = 'Next review in ${result.newInterval} days';
        color = Colors.green;
        break;
      case StudyRating.easy:
        message = 'Advanced to ${result.newInterval} days';
        color = Colors.blue;
        break;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _completeStudySession() async {
    try {
      // Show scheduling consent dialog
      if (mounted && _pendingStudyResults.isNotEmpty) {
        final shouldApplySchedules = await _showSchedulingConsentDialog();
        
        if (shouldApplySchedules) {
          // Apply the study results to individual cards
          if (widget.useFSRS) {
            await _fsrsStudyService.applyStudyResults(_pendingStudyResults, widget.flashcards);
          } else {
            await _studyService.applyStudyResults(_pendingStudyResults, widget.flashcards);
          }
          
          // Apply deck-level scheduling
          await _deckSchedulingService.scheduleDeckReview(widget.deck, _pendingStudyResults);
        }
      }
      
      // Update study streak
      await BackgroundService().updateStudyStreak();
      
      // Update pet with study progress
      final petService = PetService();
      await petService.initialize();
      final currentPet = petService.getCurrentPet();
      if (currentPet != null) {
        await petService.studyWithPet(currentPet, widget.flashcards.length);
      }
      
      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showSuccessSnackbar(
          context,
          'Study session completed! You reviewed ${widget.flashcards.length} cards.',
        );
      }
    } catch (e) {
      print('Error completing study session: $e');
    }
  }

  Future<bool> _showSchedulingConsentDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => SchedulingConsentDialog(
        studyResults: _pendingStudyResults,
        flashcards: widget.flashcards,
        deck: widget.deck,
        onAccept: () => Navigator.pop(context, true),
        onDecline: () => Navigator.pop(context, false),
      ),
    );
    return result ?? false;
  }

  void _resetStudySession() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _showRatingButtons = false;
      _cardResults.clear();
      _pendingStudyResults.clear(); // Clear pending study results
    });
  }

  String _getCardInfo(Flashcard card) {
    if (card.lastReviewed == null) {
      return 'New card';
    }
    
    if (card.nextReview != null) {
      final now = DateTime.now();
      final daysUntilReview = card.nextReview!.difference(now).inDays;
      
      if (daysUntilReview < 0) {
        return 'Overdue by ${daysUntilReview.abs()} days';
      } else if (daysUntilReview == 0) {
        return 'Due today';
      } else {
        return 'Due in $daysUntilReview days';
      }
    }
    
    return 'Interval: ${card.interval} days';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
