import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class EnhancedStatisticsScreen extends StatefulWidget {
  const EnhancedStatisticsScreen({super.key});

  @override
  State<EnhancedStatisticsScreen> createState() => _EnhancedStatisticsScreenState();
}

class _EnhancedStatisticsScreenState extends State<EnhancedStatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  // Statistics data
  Map<String, dynamic> _criminalStats = {};
  Map<String, dynamic> _arrestedStats = {};
  Map<String, dynamic> _victimStats = {};
  Map<String, dynamic> _notificationStats = {};
  
  // Chart data
  List<Map<String, dynamic>> _crimeTypeStats = [];
  List<Map<String, dynamic>> _arrestStats = [];
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _provinceStats = [];
  List<Map<String, dynamic>> _districtStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all statistics in parallel
      final results = await Future.wait([
        ApiService.getCriminalRecordsStatistics(),
        ApiService.getArrestedStatistics(),
        ApiService.getVictimsStatistics(),
        ApiService.getNotificationStatistics(),
      ]);

      // Process criminal records statistics
      if (results[0]['success'] == true) {
        _criminalStats = results[0]['data'];
        _crimeTypeStats = _processCrimeTypeStatsFromStats(_criminalStats);
        _provinceStats = _processProvinceStatsFromStats(_criminalStats);
        _districtStats = _processDistrictStatsFromStats(_criminalStats);
        _monthlyStats = _processMonthlyStatsFromStats(_criminalStats);
      }

      // Process arrested criminals statistics
      if (results[1]['success'] == true) {
        _arrestedStats = results[1]['data'];
        _arrestStats = _processArrestStatsFromStats(_arrestedStats);
      }

      // Process victims statistics
      if (results[2]['success'] == true) {
        _victimStats = results[2]['data'];
      }

      // Process notifications statistics
      if (results[3]['success'] == true) {
        _notificationStats = results[3]['data'];
      }

    } catch (e) {
      debugPrint('Error loading statistics: $e');
      Fluttertoast.showToast(
        msg: 'Error loading statistics: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _processCrimeTypeStatsFromStats(Map<String, dynamic> stats) {
    List<Map<String, dynamic>> crimeStats = [];
    
    if (stats['crimeTypes'] != null) {
      final crimeTypes = stats['crimeTypes'] as List;
      for (var crime in crimeTypes) {
        crimeStats.add({
          'type': crime['crime_type'],
          'count': int.parse(crime['count']),
          'percentage': double.parse(crime['percentage']),
        });
      }
    }
    
    crimeStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return crimeStats;
  }

  List<Map<String, dynamic>> _processProvinceStatsFromStats(Map<String, dynamic> stats) {
    List<Map<String, dynamic>> provinceStats = [];
    
    if (stats['provinces'] != null) {
      final provinces = stats['provinces'] as List;
      for (var province in provinces) {
        provinceStats.add({
          'province': province['province'],
          'count': int.parse(province['count']),
          'percentage': double.parse(province['percentage']),
        });
      }
    }
    
    provinceStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return provinceStats;
  }

  List<Map<String, dynamic>> _processDistrictStatsFromStats(Map<String, dynamic> stats) {
    List<Map<String, dynamic>> districtStats = [];
    
    if (stats['districts'] != null) {
      final districts = stats['districts'] as List;
      for (var district in districts) {
        districtStats.add({
          'province': district['province'],
          'district': district['district'],
          'count': int.parse(district['count']),
          'percentage': double.parse(district['percentage']),
        });
      }
    }
    
    districtStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return districtStats;
  }

  List<Map<String, dynamic>> _processMonthlyStatsFromStats(Map<String, dynamic> stats) {
    List<Map<String, dynamic>> monthlyStats = [];
    
    if (stats['monthlyTrend'] != null) {
      final monthly = stats['monthlyTrend'] as List;
      for (var month in monthly) {
        monthlyStats.add({
          'month': month['month'],
          'count': int.parse(month['count']),
        });
      }
    }
    
    return monthlyStats;
  }

  List<Map<String, dynamic>> _processArrestStatsFromStats(Map<String, dynamic> stats) {
    List<Map<String, dynamic>> arrestStats = [];
    
    if (stats['crimeTypeDistribution'] != null) {
      final crimeTypes = stats['crimeTypeDistribution'] as Map<String, dynamic>;
      crimeTypes.forEach((type, count) {
        arrestStats.add({
          'type': type,
          'count': int.parse(count.toString()),
        });
      });
    }
    
    arrestStats.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return arrestStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Criminals', icon: Icon(Icons.person)),
            Tab(text: 'Arrested', icon: Icon(Icons.gavel)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCriminalsTab(),
                _buildArrestedTab(),
                _buildNotificationsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          _buildSummaryCards(),
          const SizedBox(height: 24),
          
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Criminals', 
          _criminalStats['overview']?['total_criminals'] ?? '0', 
          Icons.person, 
          AppColors.errorColor
        ),
        _buildStatCard(
          'Arrested', 
          _arrestedStats['totalArrests']?.toString() ?? '0', 
          Icons.gavel, 
          AppColors.warningColor
        ),
        _buildStatCard(
          'Victims', 
          _victimStats['overview']?['total_victims'] ?? '0', 
          Icons.people, 
          AppColors.infoColor
        ),
        _buildStatCard(
          'Notifications', 
          _notificationStats['overall_statistics']?['total_messages'] ?? '0', 
          Icons.notifications, 
          AppColors.primaryColor
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_criminalStats['overview'] != null) ...[
              _buildStatRow('Male Criminals', _criminalStats['overview']['male_criminals']),
              _buildStatRow('Female Criminals', _criminalStats['overview']['female_criminals']),
              _buildStatRow('Citizen Criminals', _criminalStats['overview']['citizen_criminals']),
              _buildStatRow('Passport Criminals', _criminalStats['overview']['passport_criminals']),
              _buildStatRow('Today\'s Criminals', _criminalStats['overview']['today_criminals']),
              _buildStatRow('This Week', _criminalStats['overview']['week_criminals']),
              _buildStatRow('This Month', _criminalStats['overview']['month_criminals']),
              _buildStatRow('This Year', _criminalStats['overview']['year_criminals']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentActivity = _criminalStats['recentActivity'] as List? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Criminal Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recentActivity.isEmpty)
              const Text('No recent activity')
            else
              ...recentActivity.take(5).map((activity) => _buildActivityItem(activity)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity['first_name']} ${activity['last_name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${activity['crime_type']} - ${activity['province'] ?? 'Unknown Province'}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            activity['created_at']?.split('T')[0] ?? '',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCriminalsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crime Types Chart
          _buildCrimeTypesChart(),
          const SizedBox(height: 24),
          
          // Province Distribution Chart
          _buildProvinceChart(),
          const SizedBox(height: 24),
          
          // District Distribution Chart
          _buildDistrictChart(),
          const SizedBox(height: 24),
          
          // Monthly Trends Chart
          _buildMonthlyTrendsChart(),
        ],
      ),
    );
  }

  Widget _buildArrestedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Arrest Statistics Chart
          _buildArrestStatsChart(),
          const SizedBox(height: 24),
          
          // Arrests by Location
          _buildArrestsByLocationChart(),
          const SizedBox(height: 24),
          
          // Top Officers
          _buildTopOfficers(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Statistics
          _buildNotificationStats(),
          const SizedBox(height: 24),
          
          // RIB Statistics
          _buildRibStatistics(),
        ],
      ),
    );
  }

  Widget _buildCrimeTypesChart() {
    if (_crimeTypeStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No crime data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crime Types Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _crimeTypeStats.take(5).map((stat) {
                    final color = _getColorForIndex(_crimeTypeStats.indexOf(stat));
                    return PieChartSectionData(
                      color: color,
                      value: stat['count'].toDouble(),
                      title: '${stat['type']}\n${stat['count']}',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 10,
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
          ],
        ),
      ),
    );
  }

  Widget _buildProvinceChart() {
    if (_provinceStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No province data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crime Distribution by Province',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _provinceStats.isNotEmpty 
                      ? _provinceStats.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _provinceStats.length) {
                            return Text(
                              _provinceStats[value.toInt()]['province'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _provinceStats.take(5).toList().asMap().entries.map((entry) {
                    final color = _getColorForIndex(entry.key);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: color,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictChart() {
    if (_districtStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No district data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crime Distribution by District',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _districtStats.isNotEmpty 
                      ? _districtStats.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _districtStats.length) {
                            return Text(
                              _districtStats[value.toInt()]['district'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _districtStats.take(5).toList().asMap().entries.map((entry) {
                    final color = _getColorForIndex(entry.key);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: color,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTrendsChart() {
    if (_monthlyStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No monthly data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Trends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _monthlyStats.length) {
                            return Text(_monthlyStats[value.toInt()]['month']);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyStats.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['count'].toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.errorColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrestStatsChart() {
    if (_arrestStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No arrest data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arrest Statistics by Crime Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _arrestStats.isNotEmpty 
                      ? _arrestStats.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b).toDouble() + 2
                      : 10,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _arrestStats.length) {
                            return Text(
                              _arrestStats[value.toInt()]['type'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _arrestStats.take(5).toList().asMap().entries.map((entry) {
                    final color = _getColorForIndex(entry.key);
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['count'].toDouble(),
                          color: color,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrestsByLocationChart() {
    final arrestsByLocation = _arrestedStats['arrestsByLocation'] as Map<String, dynamic>? ?? {};
    
    if (arrestsByLocation.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No location data available'),
          ),
        ),
      );
    }

    final locationData = arrestsByLocation.entries
        .map((entry) => {'location': entry.key, 'count': int.parse(entry.value.toString())})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arrests by Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...locationData.take(5).map((data) => _buildLocationItem(data)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data['location']),
          Text(
            data['count'].toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOfficers() {
    final topOfficers = _arrestedStats['topOfficers'] as List? ?? [];
    
    if (topOfficers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No officer data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Officers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topOfficers.map((officer) => _buildOfficerItem(officer)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficerItem(Map<String, dynamic> officer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                officer['officer_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                officer['position'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          Text(
            '${officer['arrests_made']} arrests',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStats() {
    final overallStats = _notificationStats['overall_statistics'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Messages', overallStats['total_messages']?.toString() ?? '0'),
            _buildStatRow('Unread Messages', overallStats['total_unread']?.toString() ?? '0'),
            _buildStatRow('Read Messages', overallStats['total_read']?.toString() ?? '0'),
            _buildStatRow('Messages with GPS', overallStats['total_with_gps']?.toString() ?? '0'),
            _buildStatRow('Total RIBs', overallStats['total_ribs']?.toString() ?? '0'),
          ],
        ),
      ),
    );
  }

  Widget _buildRibStatistics() {
    final ribStats = _notificationStats['rib_statistics'] as List? ?? [];
    
    if (ribStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No RIB statistics available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RIB Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ribStats.take(10).map((rib) => _buildRibItem(rib)),
          ],
        ),
      ),
    );
  }

  Widget _buildRibItem(Map<String, dynamic> rib) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rib['near_rib'] ?? 'Unknown RIB',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${rib['total_messages']} messages (${rib['unread_messages']} unread)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${rib['messages_with_gps']} GPS',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.primaryColor,
      AppColors.errorColor,
      AppColors.warningColor,
      AppColors.infoColor,
      AppColors.successColor,
    ];
    return colors[index % colors.length];
  }
}
