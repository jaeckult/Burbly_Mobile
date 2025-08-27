import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../../core/services/study_service.dart';

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
  final StudyService _studyService = StudyService();
  List<Flashcard> _flashcards = [];
  Map<String, dynamic> _studyStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final flashcards = await _dataService.getFlashcardsForDeck(widget.deck.id);
      final studyStats = await _studyService.getStudyStats(widget.deck.id);
      
      setState(() {
        _flashcards = flashcards;
        _studyStats = studyStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
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
              onRefresh: _loadData,
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
    final totalCards = _studyStats['totalCards'] ?? _flashcards.length;
    final learningCards = _studyStats['learningCards'] ?? 0;
    final reviewCards = _studyStats['reviewCards'] ?? 0;
    final dueCards = _studyStats['dueCards'] ?? 0;

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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard('Total Cards', totalCards.toString(), Icons.style, Colors.blue),
            _buildStatCard('Learning', learningCards.toString(), Icons.school, Colors.orange),
            _buildStatCard('Review', reviewCards.toString(), Icons.refresh, Colors.green),
            _buildStatCard('Due Today', dueCards.toString(), Icons.schedule,
                dueCards > 0 ? Colors.red : Colors.grey),
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
                      final maxCount = intervalMap.values.isEmpty ? 1 : intervalMap.values.reduce((a, b) => a > b ? a : b);
                      final height = count / maxCount * 150;
                      final label = _getIntervalLabel(interval);
                      
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
                          '${_getIntervalLabel(interval)}: $count ($percentage%)',
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

  String _getIntervalLabel(int interval) {
    switch (interval) {
      case 1:
        return 'Learning';
      case 3:
        return '3 days';
      case 7:
        return '1 week';
      case 14:
        return '2 weeks';
      case 30:
        return '1 month';
      case 60:
        return '2 months';
      case 90:
        return '3 months';
      case 180:
        return '6 months';
      case 365:
        return '1 year';
      default:
        return '${interval}d';
    }
  }

  Widget _buildDueCardsSection() {
    final overdueCards = _studyStats['overdueCards'] ?? 0;
    final dueTodayCards = _studyStats['dueCards'] ?? 0;
    final dueTomorrowCards = _getDueTomorrowCount();

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
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDueCard(
                    'Overdue',
                    overdueCards,
                    Colors.red,
                    Icons.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDueCard(
                    'Due Today',
                    dueTodayCards,
                    Colors.orange,
                    Icons.today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDueCard(
              'Due Tomorrow',
              dueTomorrowCards,
              Colors.blue,
              Icons.schedule,
            ),
          ],
        ),
      ],
    );
  }

  int _getDueTomorrowCount() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    return _flashcards.where((card) {
      if (card.nextReview == null) return false;
      final reviewDate = DateTime(
        card.nextReview!.year,
        card.nextReview!.month,
        card.nextReview!.day,
      );
      return reviewDate.isAtSameMomentAs(tomorrow);
    }).length;
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
    final averageEaseFactor = _studyStats['avgEaseFactor'] ?? 2.5;
    final averageInterval = _studyStats['avgInterval'] ?? 1;
    final recentCards = _getRecentCardsCount();
    final studyStreak = _getStudyStreak();

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
                        '${recentCards} cards',
                        Icons.access_time,
                        Colors.orange,
                        tooltip: 'Cards reviewed in the last 7 days',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricItem(
                        'Study Streak',
                        studyStreak,
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

  int _getRecentCardsCount() {
    final now = DateTime.now();
    return _flashcards.where((card) => 
        card.lastReviewed != null && 
        card.lastReviewed!.isAfter(now.subtract(const Duration(days: 7)))).length;
  }

  String _getStudyStreak() {
    // This would ideally come from a study streak service
    // For now, return a placeholder
    return 'Active';
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
      case 3:
        return Colors.blue;
      case 7:
        return Colors.green;
      case 14:
        return Colors.purple;
      case 30:
        return Colors.indigo;
      case 60:
        return Colors.teal;
      case 90:
        return Colors.cyan;
      case 180:
        return Colors.deepPurple;
      case 365:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}


