import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import '../../../core/core.dart';

class PieChart extends StatefulWidget {
  @override
  _PieChartState createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  final DataService _dataService = DataService();
  List<fl_chart.PieChartSectionData> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Get overall stats to determine difficulty distribution
      final overallStats = await _dataService.getOverallStats();
      
      // For now, we'll create sample data based on total cards
      // In a real implementation, you'd track difficulty levels per card
      final totalCards = overallStats['totalCards'] ?? 0;
      
      if (totalCards > 0) {
        // Simulate difficulty distribution
        final easy = (totalCards * 0.4).round();
        final moderate = (totalCards * 0.35).round();
        final hard = (totalCards * 0.2).round();
        final insane = (totalCards * 0.05).round();
        
        _sections = [
          fl_chart.PieChartSectionData(
            color: Colors.green,
            value: easy.toDouble(),
            title: '$easy',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.yellow,
            value: moderate.toDouble(),
            title: '$moderate',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.orange,
            value: hard.toDouble(),
            title: '$hard',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.red,
            value: insane.toDouble(),
            title: '$insane',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ];
      } else {
        // Use sample data if no cards exist
        _sections = [
          fl_chart.PieChartSectionData(
            color: Colors.green,
            value: 40,
            title: '40',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.yellow,
            value: 35,
            title: '35',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.orange,
            value: 20,
            title: '20',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.red,
            value: 5,
            title: '5',
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ];
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Use sample data if there's an error
      _sections = [
        fl_chart.PieChartSectionData(
          color: Colors.green,
          value: 40,
          title: '40',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        fl_chart.PieChartSectionData(
          color: Colors.yellow,
          value: 35,
          title: '35',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        fl_chart.PieChartSectionData(
          color: Colors.orange,
          value: 20,
          title: '20',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        fl_chart.PieChartSectionData(
          color: Colors.red,
          value: 5,
          title: '5',
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
            "Card Difficulty Distribution",
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
              child: fl_chart.PieChart(
                fl_chart.PieChartData(
                  sections: _sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Easy', Colors.green),
              _buildLegendItem('Moderate', Colors.yellow),
              _buildLegendItem('Hard', Colors.orange),
              _buildLegendItem('Insane', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
