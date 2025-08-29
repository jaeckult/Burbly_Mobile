import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/utils/snackbar_utils.dart';

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

class _AnkiStudyScreenState extends State<AnkiStudyScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
  bool _isAnswerRevealed = false;
  bool _isStudyComplete = false;
  
  // Study session tracking
  int _cardsReviewed = 0;
  int _cardsCorrect = 0;
  int _cardsIncorrect = 0;
  DateTime _sessionStartTime = DateTime.now();
  final List<StudyResult> _pendingStudyResults = [];

  bool _isFlipping = false;
  bool _showExtendedDescription = false;
  
  // Animation controllers for realistic flip effect
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  // Animation controller for text fade-in
  late AnimationController _textFadeController;
  late Animation<double> _textFadeAnimation;
  // Animation controller for tap scale effect
  late AnimationController _tapScaleController;
  late Animation<double> _tapScaleAnimation;

  // Deck information for mixed study
  List<Deck> _allDecks = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDeckInformation();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      duration: const Duration(milliseconds: 600),
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
    super.dispose();
  }

  Future<void> _loadDeckInformation() async {
    try {
      final decks = await _dataService.getDecks();
      if (mounted) {
        setState(() {
          _allDecks = decks;
        });
      }
    } catch (e) {
      print('Error loading deck information: $e');
    }
  }

  void _resetStudySession() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _isAnswerRevealed = false;
      _isStudyComplete = false;
      _cardsReviewed = 0;
      _cardsCorrect = 0;
      _cardsIncorrect = 0;
      _sessionStartTime = DateTime.now();
      _pendingStudyResults.clear(); // Clear pending study results
      _textFadeController.reset();
      _textFadeController.forward();
    });
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
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Complete!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Returning to deck...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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

          // Study Stats Bar (only show if enabled in deck settings)
          if (widget.deck.showStudyStats ?? true) ...[
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
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle)
                      ..scale(_tapScaleAnimation.value);
                    
                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
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
                                Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')).withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Question/Answer Label with Deck Info for Mixed Study
                                FadeTransition(
                                  opacity: _textFadeAnimation,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
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
                                          _showAnswer ? 'ANSWER' : 'QUESTION',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      if (_isMixedStudy) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getDeckColor(currentCard.deckId).withValues(alpha: 0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getDeckName(currentCard.deckId),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Question/Answer Text
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: FadeTransition(
                                      opacity: _textFadeAnimation,
                                      child: Text(
                                        _showAnswer ? currentCard.answer : currentCard.question,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
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
                                if (_showAnswer && _showExtendedDescription) ...[
                                  const SizedBox(height: 16),
                                  FadeTransition(
                                    opacity: _textFadeAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        currentCard.extendedDescription?.isNotEmpty == true 
                                          ? currentCard.extendedDescription!
                                          : 'No extended description available',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],

                                // Spaced Repetition Info
                                if (_showAnswer) ...[
                                  const SizedBox(height: 16),
                                  FadeTransition(
                                    opacity: _textFadeAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              _buildInfoItem('Reviews', '${currentCard.reviewCount}'),
                                              _buildInfoItem('Ease', '${currentCard.easeFactor.toStringAsFixed(2)}'),
                                            ],
                                          ),
                                          if (_isMixedStudy) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getDeckColor(currentCard.deckId).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: _getDeckColor(currentCard.deckId),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _getDeckName(currentCard.deckId),
                                                    style: TextStyle(
                                                      color: _getDeckColor(currentCard.deckId),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
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
                                ],

                                // Study Instructions
                                if (!_showAnswer) ...[
                                  const SizedBox(height: 16),
                                  FadeTransition(
                                    opacity: _textFadeAnimation,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
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
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'This active recall strengthens your memory',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.7),
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
        _cardsIncorrect++;
      }

      // Calculate study result for spaced repetition
      if (widget.deck.spacedRepetitionEnabled) {
        final rating = _qualityToStudyRating(quality);
        final studyService = StudyService();
        final studyResult = studyService.calculateStudyResult(currentCard, rating);
        _pendingStudyResults.add(studyResult);
      } else {
        // Apply SM2 spaced repetition algorithm for non-SR decks
        await _dataService.updateFlashcardWithReview(currentCard, quality);
      }
      // Update overdue/review tags: mark as studied (clears overdue/review-now and sets Reviewed for 10m)
      try {
        await OverdueService().markCardAsStudied(currentCard, quality);
      } catch (e) {
        print('OverdueService markCardAsStudied failed: $e');
      }

      // Wait a moment then move to next card
      await Future.delayed(const Duration(milliseconds: 800));

      // Move to next card or finish session
      if (_currentIndex < widget.flashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _showAnswer = false;
          _isAnswerRevealed = false;
          _showExtendedDescription = false;
          _textFadeController.reset();
          _textFadeController.forward();
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
    setState(() {
      _isStudyComplete = true;
    });

    try {
      // Show scheduling consent dialog for spaced repetition decks
      if (widget.deck.spacedRepetitionEnabled && _pendingStudyResults.isNotEmpty) {
        final shouldApplySchedules = await _showSchedulingConsentDialog();
        
        if (shouldApplySchedules) {
          // Apply the study results
          final studyService = StudyService();
          await studyService.applyStudyResults(_pendingStudyResults, widget.flashcards);
        }
      }
      
      // Update study streak
      await BackgroundService().updateStudyStreak();
      
      // Update pet with study progress
      try {
        final petService = PetService();
        await petService.initialize();
        final currentPet = petService.getCurrentPet();
        if (currentPet != null) {
          await petService.studyWithPet(currentPet, _cardsReviewed);
        }
      } catch (e) {
        print('Error updating pet: $e');
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

  Future<bool> _showSchedulingConsentDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SchedulingConsentDialog(
        studyResults: _pendingStudyResults,
        flashcards: widget.flashcards,
        deckName: widget.deck.name,
        onAccept: () => Navigator.pop(context, true),
        onDecline: () => Navigator.pop(context, false),
      ),
    ) ?? false;
  }

  Future<void> _showCompletionDialog(Duration sessionDuration, int accuracy) async {
    return showDialog(
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
                Text('Correct: $_cardsCorrect'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text('Incorrect: $_cardsIncorrect'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text('Accuracy: $accuracy%'),
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

  Color _getDeckColor(String deckId) {
    try {
      final deck = _allDecks.firstWhere((d) => d.id == deckId);
      return Color(int.parse('0xFF${deck.coverColor ?? '2196F3'}'));
    } catch (e) {
      return Colors.blue; // Default color
    }
  }

  String _getDeckName(String deckId) {
    try {
      final deck = _allDecks.firstWhere((d) => d.id == deckId);
      return deck.name;
    } catch (e) {
      return 'Unknown Deck';
    }
  }

  bool get _isMixedStudy => widget.deck.id == 'mixed_study_session';

  void _handleDoubleTap() {
    if (_isFlipping) return;
    
    setState(() {
      _isFlipping = true;
    });
    
    _flipController.forward().then((_) {
      setState(() {
        _showAnswer = !_showAnswer;
        _isAnswerRevealed = _showAnswer;
        _isFlipping = false;
        _showExtendedDescription = false;
        _textFadeController.reset();
        _textFadeController.forward();
      });
      _flipController.reset();
    });
  }

  void _handleSwipeUp() {
    if (_showAnswer) {
      setState(() {
        _showExtendedDescription = true;
      });
      if (widget.flashcards[_currentIndex].extendedDescription?.isEmpty ?? true) {
        SnackbarUtils.showInfoSnackbar(
          context,
          'No extended description available for this card',
        );
      }
    }
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
      case 5:
        return StudyRating.easy; // Map 5 to easy as well
      default:
        return StudyRating.good;
    }
  }
}