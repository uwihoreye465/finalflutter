import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/criminal_record.dart';
import '../../models/victim.dart';
import '../../models/arrested_criminal.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import 'enhanced_criminal_management_screen.dart';
import 'enhanced_victim_management_screen.dart';
import 'enhanced_arrested_criminals_screen.dart';
import 'enhanced_notifications_screen.dart';
import 'manage_users_screen.dart';
import 'enhanced_statistics_screen.dart';
import '../user/enhanced_report_screen.dart';
import '../auth/login_screen.dart';

class EnhancedAdminDashboard extends StatefulWidget {
  const EnhancedAdminDashboard({super.key});

  @override
  State<EnhancedAdminDashboard> createState() => _EnhancedAdminDashboardState();
}

class _EnhancedAdminDashboardState extends State<EnhancedAdminDashboard> with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadStatistics();
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        Fluttertoast.showToast(
          msg: 'Logged out successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error logging out: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
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
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Criminals', icon: Icon(Icons.person)),
            Tab(text: 'Arrested', icon: Icon(Icons.gavel)),
            Tab(text: 'Victims', icon: Icon(Icons.people)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Users', icon: Icon(Icons.admin_panel_settings)),
            Tab(text: 'Report', icon: Icon(Icons.add_alert)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboard(),
                const EnhancedCriminalManagementScreen(),
                const EnhancedArrestedCriminalsScreen(),
                const EnhancedVictimManagementScreen(),
                const EnhancedNotificationsScreen(),
                const ManageUsersScreen(),
                const EnhancedReportScreen(),
                const EnhancedStatisticsScreen(),
              ],
            ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          _buildStatsCards(),
          const SizedBox(height: 24),
          
          // Charts Section
          _buildChartsSection(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
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

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics Charts',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Crime Types Chart
        _buildCrimeTypesChart(),
        const SizedBox(height: 24),
        
        // Province Distribution Chart
        _buildProvinceChart(),
        const SizedBox(height: 24),
        
        // Monthly Trends Chart
        _buildMonthlyTrendsChart(),
        const SizedBox(height: 24),
        
        // Arrest Statistics Chart
        _buildArrestStatsChart(),
      ],
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
              'Arrest Statistics',
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
