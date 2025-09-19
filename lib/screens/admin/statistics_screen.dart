import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  
  // Statistics data
  int _totalCriminals = 0;
  int _totalArrested = 0;
  int _totalVictims = 0;
  int _totalNotifications = 0;
  int _totalUsers = 0;
  
  List<Map<String, dynamic>> _crimeTypeStats = [];
  List<Map<String, dynamic>> _arrestStats = [];
  List<Map<String, dynamic>> _monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all statistics in parallel
      final results = await Future.wait([
        ApiService.getCriminalRecords(page: 1, limit: 100),
        ApiService.getArrestedCriminals(),
        ApiService.getVictims(),
        ApiService.getNotificationsAdmin(),
        ApiService.getUsersAdmin(),
      ]);

      // Process criminal records
      if (results[0]['success'] == true) {
        final criminals = results[0]['data'] as List;
        _totalCriminals = criminals.length;
        _crimeTypeStats = _processCrimeTypeStats(criminals);
      }

      // Process arrested criminals
      if (results[1]['success'] == true) {
        final arrested = results[1]['data']['records'] as List;
        _totalArrested = arrested.length;
        _arrestStats = _processArrestStats(arrested);
      }

      // Process victims
      if (results[2]['success'] == true) {
        final victims = results[2]['data'] as List;
        _totalVictims = victims.length;
      }

      // Process notifications
      if (results[3]['success'] == true) {
        final notifications = results[3]['data'] as List;
        _totalNotifications = notifications.length;
      }

      // Process users
      if (results[4]['success'] == true) {
        final users = results[4]['data'] as List;
        _totalUsers = users.length;
      }

      _monthlyStats = _processMonthlyStats();

    } catch (e) {
      debugPrint('Error loading statistics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _processCrimeTypeStats(List criminals) {
    Map<String, int> crimeCounts = {};
    
    for (var criminal in criminals) {
      final crimeType = criminal['crime_type'] ?? 'Unknown';
      crimeCounts[crimeType] = (crimeCounts[crimeType] ?? 0) + 1;
    }
    
    return crimeCounts.entries
        .map((entry) => {'crime_type': entry.key, 'count': entry.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  List<Map<String, dynamic>> _processArrestStats(List arrested) {
    Map<String, int> arrestCounts = {};
    
    for (var arrest in arrested) {
      final crimeType = arrest['crime_type'] ?? 'Unknown';
      arrestCounts[crimeType] = (arrestCounts[crimeType] ?? 0) + 1;
    }
    
    return arrestCounts.entries
        .map((entry) => {'crime_type': entry.key, 'count': entry.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  }

  List<Map<String, dynamic>> _processMonthlyStats() {
    // Mock monthly data - in real app, this would come from API
    return [
      {'month': 'Jan', 'criminals': 5, 'arrested': 3, 'victims': 8},
      {'month': 'Feb', 'criminals': 8, 'arrested': 6, 'victims': 12},
      {'month': 'Mar', 'criminals': 12, 'arrested': 9, 'victims': 15},
      {'month': 'Apr', 'criminals': 15, 'arrested': 12, 'victims': 18},
      {'month': 'May', 'criminals': 18, 'arrested': 15, 'victims': 22},
      {'month': 'Jun', 'criminals': 22, 'arrested': 18, 'victims': 25},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(),
                  const SizedBox(height: 24),
                  _buildCrimeTypePieChart(),
                  const SizedBox(height: 24),
                  _buildArrestStatsPieChart(),
                  const SizedBox(height: 24),
                  _buildMonthlyBarChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard('Total Criminals', _totalCriminals.toString(), Icons.person, AppColors.primaryColor),
        _buildStatCard('Arrested', _totalArrested.toString(), Icons.gavel, AppColors.warningColor),
        _buildStatCard('Victims', _totalVictims.toString(), Icons.people, AppColors.secondaryColor),
        _buildStatCard('Notifications', _totalNotifications.toString(), Icons.notifications, AppColors.infoColor),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrimeTypePieChart() {
    if (_crimeTypeStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No crime type data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crime Types Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _crimeTypeStats.take(5).map((stat) {
                          final index = _crimeTypeStats.indexOf(stat);
                          return PieChartSectionData(
                            color: _getColorForIndex(index),
                            value: (stat['count'] as int).toDouble(),
                            title: '${stat['count']}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _crimeTypeStats.take(5).map((stat) {
                        final index = _crimeTypeStats.indexOf(stat);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: _getColorForIndex(index),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stat['crime_type'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrestStatsPieChart() {
    if (_arrestStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: Text('No arrest data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arrest Statistics by Crime Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _arrestStats.take(5).map((stat) {
                          final index = _arrestStats.indexOf(stat);
                          return PieChartSectionData(
                            color: _getColorForIndex(index + 5),
                            value: (stat['count'] as int).toDouble(),
                            title: '${stat['count']}',
                            radius: 80,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _arrestStats.take(5).map((stat) {
                        final index = _arrestStats.indexOf(stat);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: _getColorForIndex(index + 5),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stat['crime_type'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 30,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _monthlyStats.length) {
                            return Text(_monthlyStats[index]['month']);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _monthlyStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (data['criminals'] as int).toDouble(),
                          color: AppColors.primaryColor,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: (data['arrested'] as int).toDouble(),
                          color: AppColors.warningColor,
                          width: 8,
                        ),
                        BarChartRodData(
                          toY: (data['victims'] as int).toDouble(),
                          color: AppColors.secondaryColor,
                          width: 8,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Criminals', AppColors.primaryColor),
                _buildLegendItem('Arrested', AppColors.warningColor),
                _buildLegendItem('Victims', AppColors.secondaryColor),
              ],
            ),
          ],
        ),
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
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primaryColor,
      AppColors.secondaryColor,
      AppColors.warningColor,
      AppColors.errorColor,
      AppColors.successColor,
      AppColors.infoColor,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
