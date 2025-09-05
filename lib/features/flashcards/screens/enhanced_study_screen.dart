import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../../core/core.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/deck_scheduling_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class EnhancedStudyScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> flashcards;
  final bool useFSRS;

  const EnhancedStudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
    this.useFSRS = false,
  });

  @override
  State<EnhancedStudyScreen> createState() => _EnhancedStudyScreenState();
}

class _EnhancedStudyScreenState extends State<EnhancedStudyScreen> with TickerProviderStateMixin {
  late final StudyService _studyService;
  late final FSRSStudyService _fsrsStudyService;
  final DataService _dataService = DataService();
  late final DeckSchedulingService _deckSchedulingService;
  
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  bool _showRatingButtons = false;
  bool _isFlipping = false;
  bool _showExtendedDescription = false;
  bool _isStudyComplete = false;
  int _correctAnswers = 0;
  int _incorrectAnswers = 0;
  DateTime _studyStartTime = DateTime.now();
  bool _timerEnabled = false;
  int _timeRemaining = 0;
  Timer? _timer;
  
  // Study session tracking
  late SimpleStudySession _studySession;
  final Map<String, StudyRating> _cardResults = {};
  final List<StudyResult> _pendingStudyResults = [];
  
  // Animation controllers for realistic flip effect
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  // Animation controller for text fade-in
  late AnimationController _textFadeController;
  late Animation<double> _textFadeAnimation;
  // Animation controller for tap scale effect
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeStudyServices();
    _initializeStudySession();
    _initializeAnimations();
    _timerEnabled = _effectiveTimerDuration > 0;
    if (_timerEnabled) {
      _timeRemaining = _effectiveTimerDuration;
      _startTimer();
    }
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

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));

    _textFadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textFadeController,
      curve: Curves.easeIn,
    ));

    _tapScaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _tapScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapScaleController,
      curve: Curves.easeInOut,
    ));

    // Start text fade animation
    _textFadeController.forward();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _textFadeController.dispose();
    _tapScaleController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  int get _effectiveTimerDuration => (widget.deck.timerDuration ?? 30);

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_showAnswer && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
          if (_timeRemaining <= 0) {
            _showAnswer = true;
            _showRatingButtons = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _resetStudySession() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _showRatingButtons = false;
      _isStudyComplete = false;
      _correctAnswers = 0;
      _incorrectAnswers = 0;
      _studyStartTime = DateTime.now();
      _cardResults.clear();
      _pendingStudyResults.clear(); // Clear pending study results
      _showExtendedDescription = false;
      _textFadeController.reset();
      _textFadeController.forward();
      _timerEnabled = _effectiveTimerDuration > 0;
      if (_timerEnabled) {
        _timeRemaining = _effectiveTimerDuration;
        _startTimer();
      } else {
        _timeRemaining = 0;
      }
    });
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
        _showRatingButtons = false;
        _showExtendedDescription = false;
        _textFadeController.reset();
        _textFadeController.forward();
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
        _showRatingButtons = false;
        _showExtendedDescription = false;
        _textFadeController.reset();
        _textFadeController.forward();
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
      _showRatingButtons = _showAnswer;
      _showExtendedDescription = false;
      _textFadeController.reset();
      _textFadeController.forward();
    });
    
    // If showing answer and timer is enabled, stop the timer completely
    if (_showAnswer && _timerEnabled) {
      _pauseTimer();
    }
    // If hiding answer and timer is enabled, restart the timer with full duration
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
          final points = quality - 2;
          await petService.feedPetOnCorrectAnswer(currentPet, points);
        }
      } catch (e) {
        print('Error feeding pet: $e');
      }
    } else {
      _incorrectAnswers++;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Calculate study result for spaced repetition decks
      if (widget.deck.spacedRepetitionEnabled) {
        final rating = _qualityToStudyRating(quality);
        final studyResult = widget.useFSRS 
            ? _fsrsStudyService.calculateStudyResult(currentCard, rating)
            : _studyService.calculateStudyResult(currentCard, rating);
        
        _pendingStudyResults.add(studyResult);
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
      // Update overdue/review tags: mark as studied (clears overdue/review-now and sets Reviewed for 10m)
      try {
        await OverdueService().markCardAsStudied(currentCard, quality);
      } catch (e) {
        print('OverdueService markCardAsStudied failed: $e');
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
    
    // Show scheduling consent dialog for spaced repetition decks
    if (widget.deck.spacedRepetitionEnabled && _pendingStudyResults.isNotEmpty) {
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

  Future<bool> _showSchedulingConsentDialog() async {
    print('Enhanced Study: Showing scheduling consent dialog...');
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => SchedulingConsentDialog(
        studyResults: _pendingStudyResults,
        flashcards: widget.flashcards,
        deck: widget.deck,
        onAccept: () {
          print('Enhanced Study: Dialog onAccept called');
          Navigator.pop(context, true);
        },
        onDecline: () {
          print('Enhanced Study: Dialog onDecline called');
          Navigator.pop(context, false);
        },
      ),
    );
    print('Enhanced Study: Dialog result: $result');
    return result ?? false;
  }

  String _calculateAccuracy() {
    if (_correctAnswers + _incorrectAnswers == 0) return '0';
    final accuracy = (_correctAnswers / (_correctAnswers + _incorrectAnswers)) * 100;
    return accuracy.toStringAsFixed(1);
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }

  void _handleDoubleTap() {
    if (_isFlipping) return;
    
    setState(() {
      _isFlipping = true;
    });
    
    _textFadeController.reverse();
    Future.delayed(const Duration(milliseconds: 100), () {
      _flipController.forward().then((_) {
        setState(() {
          _showAnswer = !_showAnswer;
          _showRatingButtons = _showAnswer;
          _isFlipping = false;
          _showExtendedDescription = false;
          _textFadeController.reset();
          _textFadeController.forward();
        });
        _flipController.reset();
        // Handle timer when flipping
        if (_showAnswer && _timerEnabled) {
          _pauseTimer();
        } else if (!_showAnswer && _timerEnabled) {
          _timeRemaining = _effectiveTimerDuration;
          _resumeTimer();
        }
      });
    });
  }

  void _handleSwipeUp() {
    if (_showAnswer) {
      setState(() {
        _showExtendedDescription = true;
      });
    }
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
              Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
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
                    value: _showAnswer ? 0.0 : value.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _showAnswer ? Colors.grey[400]! :
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
                        _showAnswer ? Icons.pause : Icons.timer,
                        size: 16,
                        color: _showAnswer ? Colors.grey[600]! :
                               _timeRemaining > 10 ? Colors.green : 
                               _timeRemaining > 5 ? Colors.orange : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showAnswer ? 'PAUSED' : '$_timeRemaining seconds',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _showAnswer ? Colors.grey[600]! : 
                                 _timeRemaining > 10 ? Colors.green : 
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
    child: GestureDetector(
      onDoubleTap: _handleDoubleTap,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          _handleSwipeUp();
        }
      },
      onTapDown: (_) => _tapScaleController.forward(),
      onTapUp: (_) => _tapScaleController.reverse(),
      onTapCancel: () => _tapScaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipAnimation, _tapScaleAnimation]),
        builder: (context, child) {
                               final angle = _flipAnimation.value * pi;
                     final isFront = !_showAnswer;
                     
                     return Transform(
                       transform: Matrix4.identity()
                         ..setEntry(3, 2, 0.001)
                         ..rotateY(angle)
                         ..scale(_tapScaleAnimation.value),
                       alignment: Alignment.center,
                       child: isFront
                           ? _buildCardSide(currentCard.question, isQuestion: true)
                           : Transform(
                               transform: Matrix4.identity()..rotateY(pi),
                               alignment: Alignment.center,
                               child: Transform(
                                 transform: Matrix4.identity()..rotateY(pi),
                                 alignment: Alignment.center,
                                 child: _buildCardSide(
                                   currentCard.answer,
                                   isQuestion: false,
                                 ),
                               ),
                             ),
          );
        },
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
                    
                  ),
                ],

                                 // Rating Buttons (always visible, enabled only when showing answer)
                 Column(
                   children: [
                     const SizedBox(height: 16),
                     Text(
                       _showAnswer ? 'How well did you know this?' : 'Double tap to show answer',
                       style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                         color: _showAnswer ? const Color.fromARGB(221, 255, 255, 255) : Colors.grey[600],
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
                             _showAnswer ? () => _rateCard(1) : null,
                             'I got it wrong',
                           ),
                         ),
                         const SizedBox(width: 8),
                         Expanded(
                           child: _buildAnkiRatingButton(
                             'Hard',
                             Icons.remove,
                             Colors.orange,
                             _showAnswer ? () => _rateCard(2) : null,
                             'I struggled but remembered',
                           ),
                         ),
                         const SizedBox(width: 8),
                         Expanded(
                           child: _buildAnkiRatingButton(
                             'Good',
                             Icons.check,
                             Colors.green,
                             _showAnswer ? () => _rateCard(3) : null,
                             'I remembered it',
                           ),
                         ),
                         const SizedBox(width: 8),
                         Expanded(
                           child: _buildAnkiRatingButton(
                             'Easy',
                             Icons.star,
                             Colors.blue,
                             _showAnswer ? () => _rateCard(4) : null,
                             'I knew it effortlessly',
                           ),
                         ),
                       ],
                     ),
                   ],
                 ),
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
     VoidCallback? onPressed,
     String tooltip,
   ) {
     return Tooltip(
       message: tooltip,
       child: ElevatedButton(
         onPressed: (_isLoading || onPressed == null) ? null : onPressed,
         style: ElevatedButton.styleFrom(
           backgroundColor: onPressed == null ? Colors.grey[400] : color,
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

     Widget _buildCardSide(String content, {required bool isQuestion}) {
     return Card(
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
               FadeTransition(
                 opacity: _textFadeAnimation,
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.2),
                     borderRadius: BorderRadius.circular(20),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 8,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                                        child: Text(
                       !_showAnswer ? 'QUESTION' : 'ANSWER',
                       style: const TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.bold,
                         fontSize: 14,
                         letterSpacing: 1.2,
                       ),
                     ),
                 ),
               ),
               const SizedBox(height: 24),

               // Question/Answer Text
               Expanded(
                 child: SingleChildScrollView(
                   child: FadeTransition(
                     opacity: _textFadeAnimation,
                     child: Text(
                       content,
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: isQuestion ? 26 : 22,
                         fontWeight: isQuestion ? FontWeight.w700 : FontWeight.w600,
                         height: 1.5,
                         shadows: [
                           Shadow(
                             color: Colors.black.withOpacity(0.2),
                             blurRadius: 4,
                             offset: const Offset(2, 2),
                           ),
                         ],
                       ),
                       textAlign: TextAlign.center,
                     ),
                   ),
                 ),
               ),

               // Extended Description
               if (!isQuestion && _showExtendedDescription) ...[
                 const SizedBox(height: 16),
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.white.withOpacity(0.2),
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.1),
                         blurRadius: 8,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   child: Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         "Description: ",
                         style: TextStyle(
                           color: Colors.white.withOpacity(0.95),
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                           letterSpacing: 0.8,
                         ),
                       ),
                       Expanded(
                         child: Text(
                           widget.flashcards[_currentIndex].extendedDescription ?? '',
                           style: TextStyle(
                             color: Colors.white.withOpacity(0.9),
                             fontSize: 16,
                           ),
                           overflow: TextOverflow.ellipsis,
                           maxLines: 3,
                         ),
                       ),
                     ],
                   ),
                 ),
               ],

               // Spaced Repetition Info (if enabled and showing answer)
               if (widget.deck.spacedRepetitionEnabled && !isQuestion) ...[
                 const SizedBox(height: 16),
                 FadeTransition(
                   opacity: _textFadeAnimation,
                   child: Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                    
                   ),
                 ),
               ],
             ],
           ),
         ),
       ),
     );
   }

   StudyRating _qualityToStudyRating(int quality) {
     switch (quality) {
       case 1:
         return StudyRating.again;
       case 2:
         return StudyRating.hard;
       case 3:
         return StudyRating.good;
       case 4:
         return StudyRating.easy;
       default:
         return StudyRating.good;
     }
   }
 }