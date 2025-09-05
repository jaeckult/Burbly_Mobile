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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: 300,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ScaleTransition(
          scale: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDescription(context),
                      const SizedBox(height: 20),
                      _buildDeckPerformanceSummary(context),
                      const SizedBox(height: 20),
                      _buildCardBreakdown(context),
                      const SizedBox(height: 20),
                      _buildNextReviewInfo(context),
                    ],
                  ),
                ),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

 
  Widget _buildDescription(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Deck-Level Scheduling',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The algorithm schedules your next deck review based on your overall performance, ensuring efficient learning.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
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
        border: Border.all(
          color: performanceColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: performanceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(performanceIcon, color: performanceColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performanceText,
                      style: TextStyle(
                        color: performanceColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: performanceColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(performanceColor),
            minHeight: 8,
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
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
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
                  height: 1.4,
                ),
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width * 0.9 - 60) / 2,
              child: _buildRatingCard(context, 'Again', againCount, totalCards, Colors.red, Icons.refresh, 0),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width * 0.9 - 60) / 2,
              child: _buildRatingCard(context, 'Hard', hardCount, totalCards, Colors.orange, Icons.trending_down, 1),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width * 0.9 - 60) / 2,
              child: _buildRatingCard(context, 'Good', goodCount, totalCards, Colors.blue, Icons.trending_up, 2),
            ),
            SizedBox(
              width: (MediaQuery.of(context).size.width * 0.9 - 60) / 2,
              child: _buildRatingCard(context, 'Easy', easyCount, totalCards, Colors.green, Icons.trending_up, 3),
            ),
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$count (${(percentage * 100).round()}%)',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
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
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onAccept();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}