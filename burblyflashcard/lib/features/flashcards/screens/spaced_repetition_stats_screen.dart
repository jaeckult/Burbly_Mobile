import 'package:flutter/material.dart';
import '../../../core/core.dart';

class SpacedRepetitionStatsScreen extends StatefulWidget {
  final Deck deck;

  const SpacedRepetitionStatsScreen({
    super.key,
    required this.deck,
  });

  @override
  State<SpacedRepetitionStatsScreen> createState() => _SpacedRepetitionStatsScreenState();
}

class _SpacedRepetitionStatsScreenState extends State<SpacedRepetitionStatsScreen> {
  final DataService _dataService = DataService();
  List<Flashcard> _flashcards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    final flashcards = await _dataService.getFlashcardsForDeck(widget.deck.id);
    setState(() {
      _flashcards = flashcards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SR Stats: ${widget.deck.name}'),
        backgroundColor: Color(int.parse('0xFF${widget.deck.coverColor ?? '2196F3'}')),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFlashcards,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    _buildOverviewSection(),
                    const SizedBox(height: 24),
                    
                    // Interval Distribution
                    _buildIntervalDistributionSection(),
                    const SizedBox(height: 24),
                    
                    // Due Cards Overview
                    _buildDueCardsSection(),
                    const SizedBox(height: 24),
                    
                    // Learning Progress
                    _buildLearningProgressSection(),
                    const SizedBox(height: 24),
                    
                    // Performance Metrics
                    _buildPerformanceMetricsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewSection() {
    final totalCards = _flashcards.length;
    final learningCards = _flashcards.where((card) => card.interval == 1).length;
    final reviewCards = _flashcards.where((card) => card.interval > 1).length;
    final dueCards = _flashcards.where((card) => 
        card.nextReview == null || card.nextReview!.isBefore(DateTime.now())).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Cards',
                totalCards.toString(),
                Icons.style,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Learning',
                learningCards.toString(),
                Icons.school,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Review',
                reviewCards.toString(),
                Icons.refresh,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Due Today',
                dueCards.toString(),
                Icons.schedule,
                dueCards > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalDistributionSection() {
    final intervalMap = <int, int>{};
    for (final card in _flashcards) {
      intervalMap[card.interval] = (intervalMap[card.interval] ?? 0) + 1;
    }

    final sortedIntervals = intervalMap.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interval Distribution',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Custom Bar Chart
                SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: sortedIntervals.map((interval) {
                      final count = intervalMap[interval]!;
                      final maxCount = intervalMap.values.reduce((a, b) => a > b ? a : b);
                      final height = count / maxCount * 150;
                      final label = interval == 1 ? 'Learning' : '${interval}d';
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            count.toString(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 40,
                            height: height,
                            decoration: BoxDecoration(
                              color: _getIntervalColor(interval),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Interval Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: sortedIntervals.map((interval) {
                    final count = intervalMap[interval]!;
                    final percentage = (count / _flashcards.length * 100).round();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getIntervalColor(interval),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${interval == 1 ? "Learning" : "${interval}d"}: $count ($percentage%)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDueCardsSection() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final overdueCards = _flashcards.where((card) => 
        card.nextReview != null && card.nextReview!.isBefore(today)).toList();
    final dueTodayCards = _flashcards.where((card) => 
        card.nextReview != null && 
        card.nextReview!.isAtSameMomentAs(today)).toList();
    final dueTomorrowCards = _flashcards.where((card) => 
        card.nextReview != null && 
        card.nextReview!.isAtSameMomentAs(today.add(const Duration(days: 1)))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Cards Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDueCard(
                'Overdue',
                overdueCards.length,
                Colors.red,
                Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDueCard(
                'Due Today',
                dueTodayCards.length,
                Colors.orange,
                Icons.today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDueCard(
                'Due Tomorrow',
                dueTomorrowCards.length,
                Colors.blue,
                Icons.schedule,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDueCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningProgressSection() {
    final totalReviews = _flashcards.fold<int>(0, (sum, card) => sum + card.reviewCount);
    final averageReviews = _flashcards.isNotEmpty ? totalReviews / _flashcards.length : 0;
    final cardsWithReviews = _flashcards.where((card) => card.reviewCount > 0).length;
    final reviewPercentage = _flashcards.isNotEmpty ? (cardsWithReviews / _flashcards.length * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learning Progress',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressItem(
                        'Total Reviews',
                        totalReviews.toString(),
                        Icons.refresh,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressItem(
                        'Avg Reviews/Card',
                        averageReviews.toStringAsFixed(1),
                        Icons.analytics,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressItem(
                        'Cards Reviewed',
                        '$cardsWithReviews/${_flashcards.length}',
                        Icons.check_circle,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildProgressItem(
                        'Review Rate',
                        '$reviewPercentage%',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceMetricsSection() {
    final averageEaseFactor = _flashcards.isNotEmpty 
        ? _flashcards.fold<double>(0, (sum, card) => sum + card.easeFactor) / _flashcards.length 
        : 0;
    
    final recentCards = _flashcards.where((card) => 
        card.lastReviewed != null && 
        card.lastReviewed!.isAfter(DateTime.now().subtract(const Duration(days: 7)))).toList();
    
    final averageInterval = _flashcards.isNotEmpty 
        ? _flashcards.fold<int>(0, (sum, card) => sum + card.interval) / _flashcards.length 
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Avg Ease Factor',
                        averageEaseFactor.toStringAsFixed(2),
                        Icons.speed,
                        Colors.green,
                        tooltip: 'Higher values mean cards are easier to remember',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricItem(
                        'Avg Interval',
                        '${averageInterval.round()} days',
                        Icons.calendar_today,
                        Colors.blue,
                        tooltip: 'Average days between reviews',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Recent Activity',
                        '${recentCards.length} cards',
                        Icons.access_time,
                        Colors.orange,
                        tooltip: 'Cards reviewed in the last 7 days',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricItem(
                        'Study Streak',
                        'Active',
                        Icons.local_fire_department,
                        Colors.red,
                        tooltip: 'Keep studying daily for best results',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color, {String? tooltip}) {
    return Tooltip(
      message: tooltip ?? '',
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIntervalColor(int interval) {
    switch (interval) {
      case 1:
        return Colors.orange;
      case 6:
        return Colors.blue;
      case 15:
        return Colors.green;
      case 30:
        return Colors.purple;
      case 60:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}


