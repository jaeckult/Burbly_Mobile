import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ConstrainedBox(
          constraints: BoxConstraints(
  maxHeight: MediaQuery.of(context).size.height * 0.85, // 85% of screen
  maxWidth: 400,
),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDescription(context),
                      const SizedBox(height: 15),
                      _buildDetailedScheduleList(context),
                      const SizedBox(height: 15),
                      // _buildSummaryGrid(context),
                      // const SizedBox(height: 8),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Cards',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                                Text(
                  '"${widget.deck.name}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'Proposed changes:',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
    );
  }

  Widget _buildScheduleSummary(BuildContext context) {
    final summary = _calculateScheduleSummary();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildSummaryCard(
              context,
              'Soon',
              summary['soon'] ?? 0,
              Icons.schedule,
              Theme.of(context).colorScheme.primary,
              '≤7d',
            ),
            _buildSummaryCard(
              context,
              'Advanced',
              summary['advanced'] ?? 0,
              Icons.trending_up,
              Colors.green,
              '+Interval',
            ),
            _buildSummaryCard(
              context,
              'Reset',
              summary['reset'] ?? 0,
              Icons.refresh,
              Colors.red,
              'Learning',
            ),
            _buildSummaryCard(
              context,
              'Reduced',
              summary['reduced'] ?? 0,
              Icons.trending_down,
              Colors.amber,
              '-Interval',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2, // 2 columns
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 1.4, // Adjust to control card shape
    children: [
      _buildSummaryCard(
        context,
        "Completed",
        12,
        Icons.check_circle,
        Colors.green,
        "Tasks done",
      ),
      _buildSummaryCard(
        context,
        "Pending",
        5,
        Icons.pending,
        Colors.orange,
        "Waiting...",
      ),
      _buildSummaryCard(
        context,
        "Failed",
        2,
        Icons.error,
        Colors.red,
        "Issues found",
      ),
      _buildSummaryCard(
        context,
        "In Progress",
        7,
        Icons.work,
        Colors.blue,
        "Ongoing",
      ),
    ],
  );
}


  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      width: (MediaQuery.of(context).size.width - 28) / 2,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(height: 2),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: color.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
Widget _buildDetailedScheduleList(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Details',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 6),
      
      // Show early review information if any cards were reviewed early
      if (_hasEarlyReviews()) ...[
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getEarlyReviewMessage(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      
      SizedBox(
        height: 200, // or MediaQuery.of(context).size.height * 0.3
        child: ListView.builder(
          itemCount: widget.studyResults.length,
          itemBuilder: (context, index) {
            final result = widget.studyResults[index];
            final card = widget.flashcards.firstWhere(
              (c) => c.id == result.cardId,
              orElse: () => Flashcard(
                id: result.cardId,
                question: 'Unknown',
                answer: '',
                deckId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            return _buildScheduleItem(context, result, card, index);
          },
        ),
      ),
    ],
  );
}

  Widget _buildScheduleItem(
    BuildContext context,
    StudyResult result,
    Flashcard card,
    int index,
  ) {
    final changeType = _getChangeType(result);
    final changeColor = _getChangeColor(changeType);
    final changeIcon = _getChangeIcon(changeType);
    final changeText = _getChangeText(result, changeType);

    return Card(
      margin: EdgeInsets.only(bottom: index < widget.studyResults.length - 1 ? 4 : 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: Icon(changeIcon, color: changeColor, size: 16),
        title: Text(
          card.question.length > 25 ? '${card.question.substring(0, 25)}...' : card.question,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
        ),
        subtitle: Text(
          changeText,
          style: TextStyle(
            fontSize: 10,
            color: changeColor,
          ),
        ),
        trailing: _buildIntervalChange(context, result),
      ),
    );
  }

  Widget _buildIntervalChange(BuildContext context, StudyResult result) {
    final isIncrease = result.newInterval > result.oldInterval;
    final isDecrease = result.newInterval < result.oldInterval;
    final hasPreviouslyScheduled = result.previouslyScheduledReview != null;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Show previously scheduled time with strike-through if it exists
          if (hasPreviouslyScheduled) ...[
            Text(
              _formatDate(result.previouslyScheduledReview!),
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[600],
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
          ],
          // Show old interval
          Text(
            '${result.oldInterval}d',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Icon(
            isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: isIncrease ? Colors.green : Colors.red,
          ),
          // Show new interval
          Text(
            '${result.newInterval}d',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isIncrease ? Colors.green : Colors.red,
            ),
          ),
          // Show new review date
          Text(
            _formatDate(result.nextReview),
            style: TextStyle(
              fontSize: 8,
              color: isIncrease ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 1 && difference.inDays < 7) {
      return 'In ${difference.inDays}d';
    } else if (difference.inDays < 0) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}';
    }
  }

 

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onDecline,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: widget.onAccept,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getChangeType(StudyResult result) {
    if (result.rating == StudyRating.again) return 'reset';
    if (result.rating == StudyRating.hard) return 'reduced';
    if (result.rating == StudyRating.easy) return 'advanced';
    return 'normal';
  }

  Color _getChangeColor(String changeType) {
    switch (changeType) {
      case 'reset':
        return Colors.red;
      case 'reduced':
        return Colors.amber;
      case 'advanced':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getChangeIcon(String changeType) {
    switch (changeType) {
      case 'reset':
        return Icons.refresh;
      case 'reduced':
        return Icons.trending_down;
      case 'advanced':
        return Icons.trending_up;
      default:
        return Icons.schedule;
    }
  }

  String _getChangeText(StudyResult result, String changeType) {
    switch (changeType) {
      case 'reset':
        return 'Reset (1d)';
      case 'reduced':
        return 'To ${result.newInterval}d';
      case 'advanced':
        return 'To ${result.newInterval}d';
      default:
        return 'In ${result.newInterval}d';
    }
  }

  Map<String, int> _calculateScheduleSummary() {
    int soon = 0;
    int advanced = 0;
    int reset = 0;
    int reduced = 0;

    for (final result in widget.studyResults) {
      if (result.rating == StudyRating.again) {
        reset++;
      } else if (result.rating == StudyRating.hard) {
        reduced++;
      } else if (result.rating == StudyRating.easy) {
        advanced++;
      } else {
        if (result.newInterval <= 7) {
          soon++;
        } else {
          advanced++;
        }
      }
    }

    return {
      'soon': soon,
      'advanced': advanced,
      'reset': reset,
      'reduced': reduced,
    };
  }

  String _getEarlyReviewMessage() {
    final earlyReviews = widget.studyResults.where((result) => result.previouslyScheduledReview != null).length;
    final totalCards = widget.studyResults.length;
    
    if (earlyReviews == totalCards) {
      return 'All cards were reviewed early! Current intervals maintained, schedules start from now.';
    } else if (earlyReviews > 0) {
      return '$earlyReviews of $totalCards cards were reviewed early! Current intervals maintained, schedules start from now.';
    }
    return '';
  }

  bool _hasEarlyReviews() {
    return widget.studyResults.any((result) => result.previouslyScheduledReview != null);
  }
}