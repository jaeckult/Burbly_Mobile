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
                    // _buildIntervalDistributionSection(),
                    // const SizedBox(height: 24),
                    
                   
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
    final overdueCards = _studyStats['overdueCards'] ?? 0;
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
            _buildStatCard('Overdue', overdueCards.toString(), Icons.school, Colors.red),
            _buildStatCard('Review', reviewCards.toString(),Icons.refresh, Colors.green),
            _buildStatCard('Due Today', dueCards.toString(),Icons.schedule,Colors.orange),
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
                // Horizontal Bar Chart (Much clearer than vertical bars)
                ...sortedIntervals.map((interval) {
                  final count = intervalMap[interval]!;
                  final percentage = (count / _flashcards.length * 100).round();
                  final maxCount = intervalMap.values.isEmpty ? 1 : intervalMap.values.reduce((a, b) => a > b ? a : b);
                  final barWidth = count / maxCount;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getIntervalLabel(interval),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              '$count cards ($percentage%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: barWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getIntervalColor(interval),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: count > 0 ? Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ) : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                
                const SizedBox(height: 16),
                
                // Summary and Insights
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'What This Means',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '• Learning (1 day): Cards you\'re currently learning or need to review frequently\n'
                        '• Short intervals (3-14 days): Cards you know moderately well\n'
                        '• Long intervals (30+ days): Cards you know very well - great progress!\n'
                        '• More cards in longer intervals = better retention and learning',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
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


