import 'package:flutter/material.dart';
import '../../../core/core.dart';
import 'package:burblyflashcard/features/stats/line_chart.dart';
import 'package:burblyflashcard/features/stats/pie_chart.dart';

class StatsPage extends StatefulWidget {
  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final DataService _dataService = DataService();
  Map<String, dynamic>? _overallStats;
  bool _isLoading = true;
  Key _lineChartKey = UniqueKey();
  Key _pieChartKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _dataService.getOverallStats();
      setState(() {
        _overallStats = stats;
        _isLoading = false;
        _lineChartKey = UniqueKey();
        _pieChartKey = UniqueKey();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: ${e.toString()}')),
      );
    }
  }

  Future<void> _syncFromCloud() async {
    setState(() => _isLoading = true);
    try {
      await _dataService.initialize();
      await _dataService.loadDataFromFirestore();
    } catch (_) {}
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Center(
          child: Text(
            "Statistics",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync from cloud',
            icon: Icon(Icons.cloud_download, color: Theme.of(context).colorScheme.primary),
            onPressed: _isLoading ? null : _syncFromCloud,
          ),
        ],
      ),
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: RefreshIndicator(
            onRefresh: _loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                foregroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                _isLoading 
                                  ? 'Loading...' 
                                  : '${_overallStats?['totalDecks'] ?? 0} Decks',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.withOpacity(0.2),
                                foregroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                _isLoading 
                                  ? 'Loading...' 
                                  : '${_overallStats?['totalCards'] ?? 0} Cards',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LineChart(key: _lineChartKey),
                  ),
                ),
                SizedBox(height: 15),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PieChart(key: _pieChartKey),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
      )
    );
    
  }
}

