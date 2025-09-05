import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import '../../../core/core.dart';

class PieChart extends StatefulWidget {
  const PieChart({super.key});
  @override
  _PieChartState createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> {
  final DataService _dataService = DataService();
  List<fl_chart.PieChartSectionData> _sections = [];
  bool _isLoading = true;
  int _totalCards = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Build real distribution from flashcards using easeFactor (proxy for difficulty)
      // Thresholds (tweak as needed): Easy >= 2.3, Moderate 2.0-2.29, Hard 1.6-1.99, Insane < 1.6
      final flashcards = await _dataService.getAllFlashcards();
      final totalCards = flashcards.length;
      _totalCards = totalCards;

      int easy = 0;
      int moderate = 0;
      int hard = 0;
      int insane = 0;

      for (final card in flashcards) {
        final ease = card.easeFactor;
        if (ease >= 2.3) {
          easy++;
        } else if (ease >= 2.0) {
          moderate++;
        } else if (ease >= 1.6) {
          hard++;
        } else {
          insane++;
        }
      }

      // Build sections (use counts so labels are meaningful)
      if (totalCards > 0) {
        _sections = [
          fl_chart.PieChartSectionData(
            color: Colors.green,
            value: easy.toDouble(),
            title: '$easy',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.yellow,
            value: moderate.toDouble(),
            title: '$moderate',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.orange,
            value: hard.toDouble(),
            title: '$hard',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          fl_chart.PieChartSectionData(
            color: Colors.red,
            value: insane.toDouble(),
            title: '$insane',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ];
      } else {
        _sections = [];
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
            _totalCards > 0 ? "Card Difficulty Distribution" : 'No cards yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          if (_totalCards > 0)
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
            )
          else
            const Expanded(
              child: Center(
                child: Text('Start studying to see difficulty distribution'),
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
