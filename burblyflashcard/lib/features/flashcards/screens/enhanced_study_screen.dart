import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/core.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/pet_notification_service.dart';
import '../../../core/services/background_service.dart';
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
  // final PetNotificationService _petNotificationService = PetNotificationService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  Timer? _timer;
  int _timeRemaining = 0;
  bool _timerEnabled = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  final DateTime _studyStartTime = DateTime.now();
  bool _isStudyComplete = false;

  int get _effectiveTimerDuration => (widget.deck.timerDuration ?? 30);

  void _resetStudySession() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _isStudyComplete = false;
      _correctAnswers = 0;
      _incorrectAnswers = 0;
      _timerEnabled = _effectiveTimerDuration > 0;
      _timer?.cancel();
      if (_timerEnabled) {
        _timeRemaining = _effectiveTimerDuration;
        _startTimer();
      } else {
        _timeRemaining = 0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  void _initializeTimer() {
    if (_effectiveTimerDuration > 0) {
      _timerEnabled = true;
      _timeRemaining = _effectiveTimerDuration;
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
        if (!_showAnswer && !_isStudyComplete) {
          setState(() {
            _showAnswer = true;
          });
          // Auto-rate as "Again" when timer expires
          Timer(const Duration(seconds: 2), () {
            if (mounted && !_isStudyComplete) {
              _rateCard(1); // Rate as "Again"
            }
          });
        }
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    if (_timerEnabled && !_isStudyComplete) {
      _startTimer();
    }
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
          _timeRemaining = _effectiveTimerDuration;
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
          _timeRemaining = _effectiveTimerDuration;
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
      _pauseTimer();
    }
    // If hiding answer and timer is enabled, restart the timer
    else if (!_showAnswer && _timerEnabled) {
      _timeRemaining = _effectiveTimerDuration;
      _resumeTimer();
    }
  }

  void _rateCard(int quality) async {
    if (_isStudyComplete) return;
    
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
            
            // _petNotificationService.showPetFeedingNotification(
            //   updatedPet.name,
            //   hungerReduced,
            //   happinessGained,
            // );
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
      // Always record an update when rating to drive stats and progress
      if (widget.deck.spacedRepetitionEnabled) {
        await _dataService.updateFlashcardWithReview(currentCard, quality);
      } else {
        // Non-SR decks: minimally update review metadata for stats
        await _dataService.updateFlashcard(
          currentCard.copyWith(
            lastReviewed: DateTime.now(),
            reviewCount: currentCard.reviewCount + 1,
            easeFactor: (quality >= 3)
                ? (currentCard.easeFactor + 0.05).clamp(1.3, 2.5)
                : (currentCard.easeFactor - 0.1).clamp(1.3, 2.5),
            updatedAt: DateTime.now(),
          ),
        );
      }
      
      // Pause timer during transition
      _pauseTimer();
      
     
      
      // Wait a moment then move to next card
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted && !_isStudyComplete) {
        _nextCard();
      }
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
    setState(() {
      _isStudyComplete = true;
    });
    
    // Stop timer
    _pauseTimer();
    
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
    
    // Update study streak
    try {
      await BackgroundService().updateStudyStreak();
    } catch (e) {
      print('Error updating study streak: $e');
    }
    
    // Update pet with study progress
    try {
      final petService = PetService();
      await petService.initialize();
      final currentPet = petService.getCurrentPet();
      if (currentPet != null) {
        await petService.studyWithPet(currentPet, widget.flashcards.length);
      }
    } catch (e) {
      print('Error updating pet: $e');
    }
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Study Complete! 🎉'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You have completed studying "${widget.deck.name}"'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text('Correct: $_correctAnswers'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('Incorrect: $_incorrectAnswers'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Time: ${_formatDuration(DateTime.now().difference(_studyStartTime).inSeconds)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.psychology, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  Text('Accuracy: ${_calculateAccuracy()}%'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Back to Deck'),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to deck screen
                Navigator.pop(context); // Return to deck screen
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Study Again'),
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _resetStudySession(); // Reset the study session
              },
            ),
          ],
        ),
      );
    }
  }

  String _calculateAccuracy() {
    if (_correctAnswers + _incorrectAnswers == 0) return '0';
    final accuracy = (_correctAnswers / (_correctAnswers + _incorrectAnswers)) * 100;
    return accuracy.toStringAsFixed(1);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
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

    if (_isStudyComplete) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Study: ${widget.deck.name}'),
          backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text('Study Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Returning to deck...'),
            ],
          ),
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
              Color(int.parse('0xFF${'2196F3'}')),
            ),
          ),

          // Timer (if enabled)
          if (_timerEnabled) ...[
            Container(
              width: double.infinity,
              height: 6,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: (_timeRemaining + 1) / _effectiveTimerDuration,
                  end: _timeRemaining / _effectiveTimerDuration,
                ),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timeRemaining > 10
                          ? Colors.green
                          : _timeRemaining > 5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  );
                },
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
                        Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')).withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.2),
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
                              color: Colors.white.withValues(alpha: 0.1),
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

          // Check Button and Rating Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Center Check Button (when answer is not shown)
                if (!_showAnswer) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showAnswer = true),
                      icon: const Icon(Icons.check),
                      label: const Text('Show Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Anki-style Rating Buttons (show whenever answer is shown)
                if (_showAnswer) ...[
                  const SizedBox(height: 16),
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
                        child: _buildAnkiRatingButton(
                          'Again',
                          Icons.close,
                          Colors.red,
                          () => _rateCard(1),
                          'I got it wrong',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnkiRatingButton(
                          'Hard',
                          Icons.remove,
                          Colors.orange,
                          () => _rateCard(2),
                          'I struggled but remembered',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnkiRatingButton(
                          'Good',
                          Icons.check,
                          Colors.green,
                          () => _rateCard(3),
                          'I remembered it',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnkiRatingButton(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnkiRatingButton(
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
