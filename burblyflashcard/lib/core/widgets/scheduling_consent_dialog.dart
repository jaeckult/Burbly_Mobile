import 'package:flutter/material.dart';
import '../models/study_result.dart';
import '../models/flashcard.dart';

class SchedulingConsentDialog extends StatefulWidget {
  final List<StudyResult> studyResults;
  final List<Flashcard> flashcards;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final String deckName;

  const SchedulingConsentDialog({
    super.key,
    required this.studyResults,
    required this.flashcards,
    required this.onAccept,
    required this.onDecline,
    required this.deckName,
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
                  '"${widget.deckName}"',
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

    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
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
          Text(
            '${result.newInterval}d',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isIncrease ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
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
}