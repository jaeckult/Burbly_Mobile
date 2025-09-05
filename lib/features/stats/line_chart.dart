import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import '../../../core/core.dart';

class LineChart extends StatefulWidget {
  const LineChart({super.key});
  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> {
  final DataService _dataService = DataService();
  List<fl_chart.FlSpot> _spots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get study sessions for the last 15 days
      final sessions = await _dataService.getStudySessionsForDays(15);
      
      // Group sessions by day and calculate average scores
      final Map<int, List<double>> dailyScores = {};
      final now = DateTime.now();
      
      // Initialize all 15 days
      for (int i = 0; i < 15; i++) {
        final day = now.subtract(Duration(days: i));
        final dayKey = day.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
        dailyScores[dayKey] = [];
      }
      
      // Add scores to their respective days
      for (final session in sessions) {
        final dayKey = session.date.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
        if (dailyScores.containsKey(dayKey)) {
          dailyScores[dayKey]!.add(session.averageScore);
        }
      }
      
      // Calculate average scores and create spots
      final spots = <fl_chart.FlSpot>[];
      for (int i = 14; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dayKey = day.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
        final scores = dailyScores[dayKey] ?? [];
        final averageScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
        spots.add(fl_chart.FlSpot(i.toDouble(), averageScore));
      }
      
      setState(() {
        _spots = spots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Use sample data if there's an error
      _spots = [
        fl_chart.FlSpot(0, 0),
        fl_chart.FlSpot(1, 3),
        fl_chart.FlSpot(2, 1),
        fl_chart.FlSpot(3, 2),
        fl_chart.FlSpot(4, 3),
        fl_chart.FlSpot(5, 2),
        fl_chart.FlSpot(6, 4),
        fl_chart.FlSpot(7, 2),
        fl_chart.FlSpot(8, 3),
        fl_chart.FlSpot(9, 1),
        fl_chart.FlSpot(10, 2),
        fl_chart.FlSpot(11, 2),
        fl_chart.FlSpot(12, 4),
        fl_chart.FlSpot(13, 1),
        fl_chart.FlSpot(14, 2),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: 300,
      child: Column(
        children: [
          Text(
            "15 days average score",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10),
                                            child: fl_chart.LineChart(
                 fl_chart.LineChartData(
                   gridData: fl_chart.FlGridData(show: true),
                   titlesData: fl_chart.FlTitlesData(
                     leftTitles: fl_chart.AxisTitles(
                       sideTitles: fl_chart.SideTitles(
                         showTitles: true,
                         reservedSize: 40,
                         interval: 20,
                       ),
                     ),
                     bottomTitles: fl_chart.AxisTitles(
                       sideTitles: fl_chart.SideTitles(
                         showTitles: true,
                         reservedSize: 30,
                         interval: 1,
                       ),
                     ),
                     rightTitles: fl_chart.AxisTitles(sideTitles: fl_chart.SideTitles(showTitles: false)),
                     topTitles: fl_chart.AxisTitles(sideTitles: fl_chart.SideTitles(showTitles: false)),
                   ),
                   borderData: fl_chart.FlBorderData(show: true),
                   lineBarsData: [
                     fl_chart.LineChartBarData(
                       spots: _spots,
                       isCurved: true,
                       color: Theme.of(context).colorScheme.primary,
                       barWidth: 3,
                       dotData: fl_chart.FlDotData(show: true),
                       belowBarData: fl_chart.BarAreaData(
                         show: true,
                         color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                       ),
                     ),
                   ],
                   minY: 0,
                   maxY: 100,
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }
}
