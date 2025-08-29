import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/core.dart';
import '../../../core/services/background_service.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/utils/snackbar_utils.dart';

class StudyScreen extends StatefulWidget {
  final Deck deck;
  final List<Flashcard> flashcards;

  const StudyScreen({
    super.key,
    required this.deck,
    required this.flashcards,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = false;
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
                                AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  transitionBuilder: (child, animation) {
    final rotation = Tween(begin: pi, end: 0.0).animate(animation);

    return AnimatedBuilder(
      animation: rotation,
      child: child,
      builder: (context, child) {
        final isUnder = (child?.key != ValueKey(_showAnswer));
        final value = isUnder ? min(rotation.value, pi / 2) : rotation.value;

        return Transform(
          transform: Matrix4.rotationY(value),
          alignment: Alignment.center,
          child: child,
        );
      },
    );
  },
  child: AnimatedSwitcher(
  duration: const Duration(milliseconds: 400),
  transitionBuilder: (child, animation) => FadeTransition(
    opacity: animation,
    child: child,
  ),
  child: Container(
    key: ValueKey(_showAnswer),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: _showAnswer 
          ? Colors.green.withOpacity(0.3) 
          : Colors.white.withOpacity(0.2),
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
)

                              
),
                              
const SizedBox(height: 24),

                                // Question/Answer Text
                                Expanded(
  child: SingleChildScrollView(
    child: Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            final rotation = Tween(begin: pi, end: 0.0).animate(animation);
            return AnimatedBuilder(
              animation: rotation,
              child: child,
              builder: (context, child) {
                final isUnder = (child?.key != ValueKey(_showAnswer));
                final value = isUnder ? min(rotation.value, pi / 2) : rotation.value;
                return Transform(
                  transform: Matrix4.rotationY(value),
                  alignment: Alignment.center,
                  child: child,
                );
              },
            );
          },
          child: Text(
            _showAnswer ? currentCard.answer : currentCard.question,
            key: ValueKey(_showAnswer),
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
        if (_showAnswer && _showExtendedDescription) ...[
          
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _textFadeAnimation,
            child: Container(
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
        currentCard.extendedDescription ?? '',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 16,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 3, // adjust as needed
      ),
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
const SizedBox(height: 32),

                                // Tap to reveal hint
                                if (!_showAnswer)
                                  FadeTransition(
                                    opacity: _textFadeAnimation,
                                    child: Text(
                                      'Double tap to reveal answer',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _rateCard(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hard',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _rateCard(3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Good',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _rateCard(5),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Easy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ],
        ],
      ),
    );
  }

  Future<void> _rateCard(int difficulty) async {
    setState(() => _isLoading = true);

    try {
      final currentCard = widget.flashcards[_currentIndex];
      final updatedCard = currentCard.copyWith(
        easeFactor: currentCard.easeFactor + (0.1 * (5 - difficulty)),
        lastReviewed: DateTime.now(),
        reviewCount: currentCard.reviewCount + 1,
      );

      await _dataService.updateFlashcard(updatedCard);
      // Update overdue/review tags: mark as studied (clears overdue/review-now and sets Reviewed for 10m)
      try {
        // Map original difficulty (1,3,5) to quality scale roughly
        final quality = difficulty <= 1 ? 1 : (difficulty == 3 ? 3 : 4);
        await OverdueService().markCardAsStudied(updatedCard, quality);
      } catch (e) {
        print('OverdueService markCardAsStudied failed: $e');
      }

      // Move to next card or finish
      if (_currentIndex < widget.flashcards.length - 1) {
        setState(() {
          _currentIndex++;
          _showAnswer = false;
          _showExtendedDescription = false;
          _textFadeController.reset();
          _textFadeController.forward();
        });
      } else {
        // Study session completed
        // Update study streak
        await BackgroundService().updateStudyStreak();
        
        // Update pet with study progress
        final petService = PetService();
        await petService.initialize();
        final currentPet = petService.getCurrentPet();
        if (currentPet != null) {
          await petService.studyWithPet(currentPet, _currentIndex + 1);
        }
        
        if (mounted) {
          Navigator.pop(context);
          SnackbarUtils.showSuccessSnackbar(
            context,
            'Study session completed! You reviewed ${widget.flashcards.length} cards.',
          );
        }
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

  void _handleDoubleTap() {
    if (_isFlipping) return;
    
    setState(() {
      _isFlipping = true;
    });
    
    _flipController.forward().then((_) {
      setState(() {
        _showAnswer = !_showAnswer;
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
      
    }
  }
}