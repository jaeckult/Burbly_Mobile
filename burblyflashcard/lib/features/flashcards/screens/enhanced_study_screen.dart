import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/core.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/pet_notification_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class EnhancedStudyScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> flashcards;

  const EnhancedStudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
  });

  @override
  State<EnhancedStudyScreen> createState() => _EnhancedStudyScreenState();
}

class _EnhancedStudyScreenState extends State<EnhancedStudyScreen> {
  final DataService _dataService = DataService();
  final PetNotificationService _petNotificationService = PetNotificationService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  Timer? _timer;
  int _timeRemaining = 0;
  bool _timerEnabled = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  DateTime _studyStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    if (widget.deck.timerDuration != null && widget.deck.timerDuration! > 0) {
      _timerEnabled = true;
      _timeRemaining = widget.deck.timerDuration!;
      _startTimer();
    }
  }

  void _startTimer() {
    if (!_timerEnabled) return;
    
    // Cancel any existing timer
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        if (!_showAnswer) {
          setState(() {
            _showAnswer = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        if (_timerEnabled) {
          _timeRemaining = widget.deck.timerDuration!;
          _startTimer();
        }
      });
    } else {
      _showStudyComplete();
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
        if (_timerEnabled) {
          _timeRemaining = widget.deck.timerDuration!;
          _startTimer();
        }
      });
    }
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
    
    // If showing answer and timer is enabled, pause the timer
    if (_showAnswer && _timerEnabled) {
      _timer?.cancel();
    }
    // If hiding answer and timer is enabled, restart the timer
    else if (!_showAnswer && _timerEnabled) {
      _timeRemaining = widget.deck.timerDuration!;
      _startTimer();
    }
  }

  void _rateCard(int quality) async {
    final currentCard = widget.flashcards[_currentIndex];
    
    // Track answer quality
    if (quality >= 3) {
      _correctAnswers++;
      
              // Feed pet when user answers correctly
        try {
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
        } catch (e) {
          print('Error feeding pet: $e');
        }
    } else {
      _incorrectAnswers++;
    }
    
    setState(() => _isLoading = true);
    
    try {
      if (widget.deck.spacedRepetitionEnabled) {
        await _dataService.updateFlashcardWithReview(currentCard, quality);
      }
      
      _nextCard();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showErrorSnackbar(
          context,
          'Error updating card: ${e.toString()}',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showStudyComplete() async {
    // Save study session
    try {
      final studyTime = DateTime.now().difference(_studyStartTime).inSeconds;
      final session = StudySession.create(
        deckId: widget.deck.id,
        totalCards: widget.flashcards.length,
        correctAnswers: _correctAnswers,
        incorrectAnswers: _incorrectAnswers,
        studyTimeSeconds: studyTime,
        usedTimer: _timerEnabled,
      );
      
      await _dataService.saveStudySession(session);
    } catch (e) {
      print('Error saving study session: $e');
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Study Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have completed studying "${widget.deck.name}"'),
            const SizedBox(height: 16),
            Text('Correct: $_correctAnswers'),
            Text('Incorrect: $_incorrectAnswers'),
            Text('Time: ${DateTime.now().difference(_studyStartTime).inSeconds}s'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
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

          // Timer (if enabled)
          if (_timerEnabled) ...[
            Container(
              width: double.infinity,
              height: 6,
              child: LinearProgressIndicator(
                value: _timeRemaining / (widget.deck.timerDuration ?? 1),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _timeRemaining > 10 ? Colors.green : 
                  _timeRemaining > 5 ? Colors.orange : Colors.red,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: _timeRemaining > 10 ? Colors.green : 
                               _timeRemaining > 5 ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_timeRemaining seconds',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _timeRemaining > 10 ? Colors.green : 
                                 _timeRemaining > 5 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (_timeRemaining <= 5)
                    Text(
                      'Answer will show automatically!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],

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
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // Spaced Repetition Info (if enabled)
                        if (widget.deck.spacedRepetitionEnabled && _showAnswer) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Review Count: ${currentCard.reviewCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                if (currentCard.lastReviewed != null)
                                  Text(
                                    'Last: ${_formatDate(currentCard.lastReviewed!)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
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

          // Navigation and Rating Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Navigation Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0 ? _previousCard : null,
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        disabledBackgroundColor: Colors.grey[100],
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleAnswer,
                      icon: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                      ),
                    ),
                    IconButton(
                      onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
                      icon: const Icon(Icons.arrow_forward),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        disabledBackgroundColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),

                // Quality Rating Buttons (only when answer is shown)
                if (_showAnswer && widget.deck.spacedRepetitionEnabled) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'How well did you know this?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRatingButton(1, 'Again', Colors.red),
                      _buildRatingButton(2, 'Hard', Colors.orange),
                      _buildRatingButton(3, 'Good', Colors.yellow),
                      _buildRatingButton(4, 'Easy', Colors.lightGreen),
                      _buildRatingButton(5, 'Perfect', Colors.green),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(int quality, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _rateCard(quality),
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
              Text(
                quality.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12),
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
