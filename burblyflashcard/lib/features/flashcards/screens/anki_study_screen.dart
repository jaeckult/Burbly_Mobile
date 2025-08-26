import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/pet_notification_service.dart';

class AnkiStudyScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> flashcards;

  const AnkiStudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
  });

  @override
  State<AnkiStudyScreen> createState() => _AnkiStudyScreenState();
}

class _AnkiStudyScreenState extends State<AnkiStudyScreen> {
  final DataService _dataService = DataService();
  final PetNotificationService _petNotificationService = PetNotificationService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  bool _isAnswerRevealed = false;
  
  // Study session tracking
  int _cardsReviewed = 0;
  int _cardsCorrect = 0;
  int _cardsIncorrect = 0;
  DateTime _sessionStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
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
    final isLastCard = _currentIndex == widget.flashcards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Study: ${widget.deck.name}'),
        backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
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
            valueColor: AlwaysStoppedAnimation<Color>(
              Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
            ),
          ),

          // Study Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Reviewed', _cardsReviewed, Colors.blue),
                _buildStatItem('Correct', _cardsCorrect, Colors.green),
                _buildStatItem('Incorrect', _cardsIncorrect, Colors.red),
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
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
                        Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')).withOpacity(0.7),
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
                        Expanded(
                          child: Center(
                            child: Text(
                              _showAnswer ? currentCard.answer : currentCard.question,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Spaced Repetition Info
                        if (_showAnswer) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildInfoItem('Reviews', '${currentCard.reviewCount}'),
                                    _buildInfoItem('Interval', '${currentCard.interval} days'),
                                    _buildInfoItem('Ease', '${currentCard.easeFactor.toStringAsFixed(2)}'),
                                  ],
                                ),
                                if (currentCard.nextReview != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Next: ${_formatDate(currentCard.nextReview!)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Study Instructions
                        if (!_showAnswer) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try to recall the answer before revealing it',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This active recall strengthens your memory',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
          if (_showAnswer) ...[
            // SM2 Rating Buttons (Anki-style)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'How well did you know this?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRatingButton(
                          'Again',
                          Icons.close,
                          Colors.red,
                          () => _rateCard(1),
                          'I got it wrong',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Hard',
                          Icons.remove,
                          Colors.orange,
                          () => _rateCard(2),
                          'I struggled but remembered',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Good',
                          Icons.check,
                          Colors.green,
                          () => _rateCard(3),
                          'I remembered it',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildRatingButton(
                          'Easy',
                          Icons.star,
                          Colors.blue,
                          () => _rateCard(4),
                          'I knew it effortlessly',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Show Answer Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showAnswer = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
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

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
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

  Future<void> _rateCard(int quality) async {
    setState(() => _isLoading = true);

    try {
      final currentCard = widget.flashcards[_currentIndex];
      
      // Update study session stats
      _cardsReviewed++;
      if (quality >= 3) {
        _cardsCorrect++;
        
        // Feed pet when user answers correctly
        final petService = PetService();
        await petService.initialize();
        final currentPet = petService.getCurrentPet();
        if (currentPet != null) {
          // Calculate points based on quality (3-5 = 1-3 points)
          final points = quality - 2;
          final oldHunger = currentPet.hunger;
          final oldHappiness = currentPet.happiness;
          
          await petService.feedPetOnCorrectAnswer(currentPet, points);
          
          // Show notification for pet feeding
          final updatedPet = petService.getCurrentPet();
          if (updatedPet != null) {
            final hungerReduced = oldHunger - updatedPet.hunger;
            final happinessGained = updatedPet.happiness - oldHappiness;
            
            _petNotificationService.showPetFeedingNotification(
              updatedPet.name,
              hungerReduced,
              happinessGained,
            );
          }
        }
      } else {
        _cardsIncorrect++;
      }

      // Apply SM2 spaced repetition algorithm
      await _dataService.updateFlashcardWithReview(currentCard, quality);

      // Move to next card or finish session
      if (_currentIndex < widget.flashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _showAnswer = false;
        });
      } else {
        // Study session completed
        await _completeStudySession();
      }
    } catch (e) {
      if (mounted) {
                 SnackbarUtils.showErrorSnackbar(
           context,
           'Error updating card: ${e.toString()}',
         );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeStudySession() async {
    try {
      // Update study streak
      await BackgroundService().updateStudyStreak();
      
      // Update pet with study progress
      final petService = PetService();
      await petService.initialize();
      final currentPet = petService.getCurrentPet();
      if (currentPet != null) {
        await petService.studyWithPet(currentPet, _cardsReviewed);
      }

      // Calculate session statistics
      final sessionDuration = DateTime.now().difference(_sessionStartTime);
      final accuracy = _cardsReviewed > 0 ? (_cardsCorrect / _cardsReviewed * 100).round() : 0;

      // Persist study session for stats/backup
      try {
        final session = StudySession.create(
          deckId: widget.deck.id,
          totalCards: _cardsReviewed,
          correctAnswers: _cardsCorrect,
          incorrectAnswers: _cardsIncorrect,
          studyTimeSeconds: sessionDuration.inSeconds,
          usedTimer: false,
        );
        await _dataService.saveStudySession(session);
      } catch (e) {
        print('Error saving Anki study session: $e');
      }

      if (mounted) {
        // Show completion dialog with statistics
        await _showCompletionDialog(sessionDuration, accuracy);
      }
    } catch (e) {
      print('Error completing study session: $e');
    }
  }

  Future<void> _showCompletionDialog(Duration sessionDuration, int accuracy) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Study Session Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You reviewed ${_cardsReviewed} cards'),
            const SizedBox(height: 8),
            Text('Accuracy: $accuracy%'),
            const SizedBox(height: 8),
            Text('Time: ${_formatDuration(sessionDuration)}'),
            const SizedBox(height: 16),
            const Text(
              'Great job! Your cards have been scheduled for optimal review intervals.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    ).then((_) => Navigator.of(context).pop());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
