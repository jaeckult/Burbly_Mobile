import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../models/study_result.dart';
import '../models/flashcard.dart';
import '../models/deck.dart';
import '../services/deck_scheduling_service.dart';

class SchedulingConsentDialog extends StatefulWidget {
  final List<StudyResult> studyResults;
  final List<Flashcard> flashcards;
  final Deck deck;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const SchedulingConsentDialog({
    super.key,
    required this.studyResults,
    required this.flashcards,
    required this.deck,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<SchedulingConsentDialog> createState() => _SchedulingConsentDialogState();
}

class _SchedulingConsentDialogState extends State<SchedulingConsentDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late DeckSchedulingService _deckSchedulingService;
  Map<String, dynamic>? _performanceSummary;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _calculatePerformanceSummary();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  void _initializeServices() {
    _deckSchedulingService = DeckSchedulingService();
  }

  void _calculatePerformanceSummary() {
    _performanceSummary = _deckSchedulingService.getDeckPerformanceSummary(widget.studyResults);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 400,
              ),
              child: _fadeAnimation.isCompleted
                  ? ScaleTransition(
                      scale: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(context),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDescription(context),
                                  const SizedBox(height: 20),
                                  _buildDeckPerformanceSummary(context),
                                  const SizedBox(height: 20),
                                  _buildNextReviewInfo(context),
                                  const SizedBox(height: 20),
                                  _buildCardBreakdown(context),
                                ],
                              ),
                            ),
                          ),
                          _buildActions(context),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(), // Fallback if animation not ready
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule Deck Review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Flexible(
                  child: Text(
                    '"${widget.deck.name}"',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onDecline,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.lightbulb_outline,
                  key: ValueKey(_fadeAnimation.value),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Deck-Level Scheduling',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The algorithm schedules your next deck review based on your overall performance, ensuring efficient learning.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            semanticsLabel: 'The algorithm schedules your next deck review based on your performance for efficient learning.',
          ),
        ],
      ),
    );
  }

  Widget _buildDeckPerformanceSummary(BuildContext context) {
    if (_performanceSummary == null) return const SizedBox.shrink();

    final performance = _performanceSummary!['performance'] as String;
    final nextReview = _performanceSummary!['nextReview'] as String;

    Color performanceColor;
    IconData performanceIcon;
    String performanceText;
    double progressValue;

    switch (performance) {
      case 'again':
        performanceColor = Colors.red;
        performanceIcon = Icons.refresh;
        performanceText = 'Needs Review';
        progressValue = 0.25;
        break;
      case 'hard':
        performanceColor = Colors.orange;
        performanceIcon = Icons.trending_down;
        performanceText = 'Some Difficulty';
        progressValue = 0.5;
        break;
      case 'good':
        performanceColor = Colors.blue;
        performanceIcon = Icons.trending_up;
        performanceText = 'Good';
        progressValue = 0.75;
        break;
      case 'easy':
        performanceColor = Colors.green;
        performanceIcon = Icons.trending_up;
        performanceText = 'Excellent';
        progressValue = 1.0;
        break;
      default:
        performanceColor = Colors.grey;
        performanceIcon = Icons.help_outline;
        performanceText = 'Unknown';
        progressValue = 0.0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: performanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(performanceIcon, color: performanceColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performanceText,
                      style: TextStyle(
                        color: performanceColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Next Review: $nextReview',
                      style: TextStyle(
                        color: performanceColor.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: performanceColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(performanceColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildNextReviewInfo(BuildContext context) {
    if (_performanceSummary == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedScale(
                scale: _fadeAnimation.value,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Review Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your next review is optimized for retention based on your performance.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            semanticsLabel: 'Your next review is optimized for retention based on your performance.',
          ),
        ],
      ),
    );
  }

  Widget _buildCardBreakdown(BuildContext context) {
    if (_performanceSummary == null) return const SizedBox.shrink();

    final againCount = _performanceSummary!['againCount'] as int;
    final hardCount = _performanceSummary!['hardCount'] as int;
    final goodCount = _performanceSummary!['goodCount'] as int;
    final easyCount = _performanceSummary!['easyCount'] as int;
    final totalCards = _performanceSummary!['totalCards'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildRatingCard(context, 'Again', againCount, totalCards, Colors.red, Icons.refresh, 0),
            _buildRatingCard(context, 'Hard', hardCount, totalCards, Colors.orange, Icons.trending_down, 1),
            _buildRatingCard(context, 'Good', goodCount, totalCards, Colors.blue, Icons.trending_up, 2),
            _buildRatingCard(context, 'Easy', easyCount, totalCards, Colors.green, Icons.trending_up, 3),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingCard(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
    int index,
  ) {
    final percentage = total > 0 ? (count / total).toDouble() : 0.0;

    return AnimatedOpacity(
      opacity: _fadeAnimation.value,
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 4,
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count (${(percentage * 100).round()}%)',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onDecline();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.onSurfaceVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Skip Scheduling',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onAccept();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: const Text('Schedule Review'),
            ),
          ),
        ],
      ),
    );
  }
}