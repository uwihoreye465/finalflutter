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
import 'records_overview_screen.dart';
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
  Map<String, dynamic> _userStats = {};
  
  // Chart data
  List<Map<String, dynamic>> _crimeTypeStats = [];
  List<Map<String, dynamic>> _arrestStats = [];
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _provinceStats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _loadStatistics();
  }

  Future<void> _logout() async {
    try {
      await AuthService().logout();
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
        _loadNotificationStats(),
        _loadUserStatistics(),
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
        debugPrint('Notification stats loaded: $_notificationStats');
        debugPrint('Overall stats: ${_notificationStats['overall_stats']}');
        debugPrint('Overall statistics: ${_notificationStats['overall_statistics']}');
      } else {
        debugPrint('Failed to load notification stats: ${results[3]}');
      }
      
      // Always try to load notifications directly as additional data source
      try {
        final directResponse = await ApiService.getNotificationsAdmin();
        debugPrint('Direct notifications response: $directResponse');
        
        if (directResponse['success'] == true) {
          List<dynamic> notifications;
          if (directResponse['data'] is List) {
            notifications = directResponse['data'] as List;
          } else if (directResponse['data']['notifications'] != null) {
            notifications = directResponse['data']['notifications'] as List;
          } else {
            notifications = [];
          }
          
          debugPrint('Found ${notifications.length} notifications');
          final unreadCount = notifications.where((n) => n['is_read'] == false).length;
          final readCount = notifications.where((n) => n['is_read'] == true).length;
          debugPrint('Unread: $unreadCount, Read: $readCount');
          
          // Update notification stats with direct data
          _notificationStats = {
            'overall_statistics': {
              'total_notifications': notifications.length,
              'unread_notifications': unreadCount,
              'read_notifications': readCount,
            },
            'overall_stats': {
              'total_notifications': notifications.length,
              'unread_notifications': unreadCount,
              'read_notifications': readCount,
            }
          };
          debugPrint('Updated notification stats with direct data: $_notificationStats');
        }
      } catch (e) {
        debugPrint('Direct notification loading failed: $e');
      }

      // Process user statistics
      if (results[4]['success'] == true) {
        _userStats = results[4]['data'];
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

  Future<Map<String, dynamic>> _loadUserStatistics() async {
    try {
      final response = await ApiService.getUsersAdmin();
      if (response['success'] == true) {
        final users = response['data']['users'] as List;
        final totalUsers = users.length;
        final approvedUsers = users.where((user) => user['is_approved'] == true).length;
        final pendingUsers = users.where((user) => user['is_approved'] == false).length;
        final staffUsers = users.where((user) => user['role'] == 'staff').length;
        final adminUsers = users.where((user) => user['role'] == 'admin').length;
        
        return {
          'success': true,
          'data': {
            'total_users': totalUsers,
            'approved_users': approvedUsers,
            'pending_users': pendingUsers,
            'staff_users': staffUsers,
            'admin_users': adminUsers,
          }
        };
      } else {
        return {'success': false, 'data': {}};
      }
    } catch (e) {
      debugPrint('Error loading user statistics: $e');
      return {'success': false, 'data': {}};
    }
  }

  Future<Map<String, dynamic>> _loadNotificationStats() async {
    try {
      // First try the assignment statistics API
      final response = await ApiService.getNotificationAssignmentStatistics();
      debugPrint('Admin notification assignment stats response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        final overallStats = data['overall_stats'] as Map<String, dynamic>? ?? {};
        
        debugPrint('Overall stats: $overallStats');

        return {
          'success': true,
          'data': {
            'overall_statistics': {
              'total_messages': overallStats['total_notifications'] ?? 0,
              'unread_messages': overallStats['assigned_unread_notifications'] ?? 0,
              'read_messages': overallStats['assigned_read_notifications'] ?? 0,
              'assigned_messages': overallStats['assigned_notifications'] ?? 0,
              'unassigned_messages': overallStats['unassigned_notifications'] ?? 0,
            }
          }
        };
      } else {
        debugPrint('Assignment stats failed, trying regular notifications API...');
        // Fallback to regular notifications API
        final fallbackResponse = await ApiService.getNotificationsAdmin();
        if (fallbackResponse['success'] == true) {
          List<dynamic> notifications;
          if (fallbackResponse['data'] is List) {
            notifications = fallbackResponse['data'] as List;
          } else if (fallbackResponse['data']['notifications'] != null) {
            notifications = fallbackResponse['data']['notifications'] as List;
          } else {
            notifications = [];
          }
          
          final totalNotifications = notifications.length;
          final unreadNotifications = notifications.where((notification) => notification['is_read'] == false).length;
          final readNotifications = notifications.where((notification) => notification['is_read'] == true).length;

          return {
            'success': true,
            'data': {
              'overall_statistics': {
                'total_messages': totalNotifications,
                'unread_messages': unreadNotifications,
                'read_messages': readNotifications,
              }
            }
          };
        }
        return {'success': false, 'data': {}};
      }
    } catch (e) {
      debugPrint('Error loading notification statistics: $e');
      return {'success': false, 'data': {}};
    }
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
            Tab(text: 'Records', icon: Icon(Icons.table_chart)),
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
                const RecordsOverviewScreen(),
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
          const SizedBox(height: 24),
          
          // GPS Location Section
          _buildGPSLocationSection(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
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
          'Unread Notifications', 
          _getUnreadNotificationCount(), 
          Icons.notifications, 
          Colors.orange
        ),
      ],
    );
  }

  String _getUnreadNotificationCount() {
    // Try multiple possible field names and data structures
    final overallStats = _notificationStats['overall_statistics'] as Map<String, dynamic>? ?? {};
    final overallStatsAlt = _notificationStats['overall_stats'] as Map<String, dynamic>? ?? {};
    
    // Try different field names
    String? count;
    
    // Try overall_statistics first
    count = overallStats['unread_notifications']?.toString();
    if (count != null && count != '0') return count;
    
    count = overallStats['assigned_unread_notifications']?.toString();
    if (count != null && count != '0') return count;
    
    count = overallStats['unread_messages']?.toString();
    if (count != null && count != '0') return count;
    
    // Try overall_stats
    count = overallStatsAlt['unread_notifications']?.toString();
    if (count != null && count != '0') return count;
    
    count = overallStatsAlt['assigned_unread_notifications']?.toString();
    if (count != null && count != '0') return count;
    
    count = overallStatsAlt['unread_messages']?.toString();
    if (count != null && count != '0') return count;
    
    // If all else fails, return 0
    debugPrint('Could not find unread notification count in: $_notificationStats');
    return '0';
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    // Define background colors for different card types
    Color backgroundColor;
    Color textColor = Colors.white;
    
    if (title == 'Total Criminals') {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
    } else if (title == 'Arrested') {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
    } else if (title == 'Victims') {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
    } else if (title == 'Unread Notifications') {
      backgroundColor = Colors.purple.shade50;
      textColor = Colors.purple.shade800;
    } else {
      backgroundColor = Colors.grey.shade50;
      textColor = Colors.grey.shade800;
    }
    
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.7),
            ],
          ),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 24),
        
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

  Widget _buildGPSLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'GPS Location Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Google Maps Integration',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time location tracking will be displayed here',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement GPS location functionality
                        _showLocationDialog();
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text('Get Current Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
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

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Location'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 48, color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text('GPS location tracking feature will be implemented here.'),
            SizedBox(height: 8),
            Text('This will show real-time location data from notifications and reports.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
