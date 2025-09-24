import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import 'enhanced_criminal_management_screen.dart';
import 'enhanced_arrested_criminals_screen.dart';
import 'enhanced_victim_management_screen.dart';
import 'rib_assigned_notifications_screen.dart';
import 'rib_statistics_screen.dart';
import 'records_overview_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RibStationDashboard extends StatefulWidget {
  const RibStationDashboard({super.key});

  @override
  State<RibStationDashboard> createState() => _RibStationDashboardState();
}

class _RibStationDashboardState extends State<RibStationDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _userName;
  String? _userSector;
  int? _userId;
  Map<String, dynamic> _notificationStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadStatistics();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = authService.user;
      debugPrint('Auth service user: $user');
      
      if (user != null) {
        setState(() {
          _userName = user.fullname;
          _userSector = user.sector;
          _userId = user.userId;
        });
        debugPrint('User loaded: $_userName from $_userSector (ID: $_userId)');
      } else {
        debugPrint('No user found in auth service');
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading statistics...');
      final response = await ApiService.getNotificationAssignmentStatistics();
      debugPrint('Statistics API response: $response');
      
      if (response['success'] == true) {
        setState(() {
          _notificationStats = response['data'];
        });
        debugPrint('Statistics loaded successfully');
        debugPrint('Overall stats: ${response['data']['overall_stats']}');
        debugPrint('User stats: ${response['data']['user_stats']}');
        debugPrint('Sector stats: ${response['data']['sector_stats']}');
        
        // If user ID is null, try to get it from the statistics response
        if (_userId == null) {
          final userStats = response['data']['user_stats'] as List<dynamic>?;
          if (userStats != null && userStats.isNotEmpty) {
            _userId = userStats.first['user_id'];
            _userName = userStats.first['fullname'];
            _userSector = userStats.first['sector'];
            debugPrint('Got user info from statistics: $_userName from $_userSector (ID: $_userId)');
          }
        }
      } else {
        debugPrint('Statistics API returned error: ${response['message']}');
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

  Future<void> _logout() async {
    try {
      final authService = AuthService();
      await authService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      Fluttertoast.showToast(
        msg: 'Error during logout: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'RIB Station Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _loadUserInfo();
              _loadStatistics();
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
            Tab(text: 'Criminals', icon: Icon(Icons.person)),
            Tab(text: 'Arrested', icon: Icon(Icons.gavel)),
            Tab(text: 'Victims', icon: Icon(Icons.people)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Records', icon: Icon(Icons.table_chart)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          const EnhancedCriminalManagementScreen(),
          const EnhancedArrestedCriminalsScreen(),
          const EnhancedVictimManagementScreen(),
          const RibAssignedNotificationsScreen(),
          const RecordsOverviewScreen(),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingWidget(),
            SizedBox(height: 16),
            Text(
              'Loading dashboard data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            
            // Overall Statistics
            _buildOverallStats(),
            const SizedBox(height: 24),
            
            // User Statistics
            _buildUserStats(),
            const SizedBox(height: 24),
            
            // Sector Statistics
            _buildSectorStats(),
            const SizedBox(height: 24),
            
            // Charts
            _buildCharts(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${_userName ?? 'User'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RIB Station: ${_userSector ?? 'Loading...'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final overallStats = _notificationStats['overall_stats'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Notifications Statistics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildStatCard(
              title: 'Total Assigned',
              value: overallStats['assigned_notifications']?.toString() ?? '0',
              icon: Icons.assignment,
              color: AppColors.primaryColor,
              gradient: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
            ),
            _buildStatCard(
              title: 'Read Assigned',
              value: overallStats['assigned_read_notifications']?.toString() ?? '0',
              icon: Icons.mark_email_read,
              color: AppColors.successColor,
              gradient: [AppColors.successColor, AppColors.successColor.withOpacity(0.8)],
            ),
            _buildStatCard(
              title: 'Unread Assigned',
              value: overallStats['assigned_unread_notifications']?.toString() ?? '0',
              icon: Icons.mark_email_unread,
              color: AppColors.warningColor,
              gradient: [AppColors.warningColor, AppColors.warningColor.withOpacity(0.8)],
            ),
            _buildStatCard(
              title: 'Read Rate',
              value: '${overallStats['assigned_read_percentage']?.toString() ?? '0'}%',
              icon: Icons.trending_up,
              color: AppColors.infoColor,
              gradient: [AppColors.infoColor, AppColors.infoColor.withOpacity(0.8)],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    final userStats = _notificationStats['user_stats'] as List<dynamic>? ?? [];
    Map<String, dynamic> currentUserStats = {};
    
    // Find the current user's stats
    if (_userId != null && userStats.isNotEmpty) {
      for (var userStat in userStats) {
        if (userStat['user_id'] == _userId) {
          currentUserStats = userStat;
          break;
        }
      }
    }
    
    // If no specific user found, use the first one as fallback
    if (currentUserStats.isEmpty && userStats.isNotEmpty) {
      currentUserStats = userStats.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Assigned Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _userSector ?? 'Station',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildUserStatItem(
                      'Total Assigned',
                      currentUserStats['total_assigned_notifications']?.toString() ?? '0',
                      Icons.assignment,
                      AppColors.primaryColor,
                    ),
                  ),
                  Expanded(
                    child: _buildUserStatItem(
                      'Read Messages',
                      currentUserStats['read_notifications']?.toString() ?? '0',
                      Icons.mark_email_read,
                      AppColors.successColor,
                    ),
                  ),
                  Expanded(
                    child: _buildUserStatItem(
                      'Unread Messages',
                      currentUserStats['unread_notifications']?.toString() ?? '0',
                      Icons.mark_email_unread,
                      AppColors.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectorStats() {
    final sectorStats = _notificationStats['sector_stats'] as List<dynamic>? ?? [];
    
    // Filter sectors to show only those with assigned notifications
    final sectorsWithAssignments = sectorStats.where((sector) {
      final assignedCount = int.tryParse(sector['assigned_notifications']?.toString() ?? '0') ?? 0;
      return assignedCount > 0;
    }).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sectors with Assigned Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: sectorsWithAssignments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No assigned notifications in any sector',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sectorsWithAssignments.length,
                  itemBuilder: (context, index) {
                    final sector = sectorsWithAssignments[index];
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sector['sector'] ?? 'Unknown Sector',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${sector['assigned_notifications']} assigned notifications',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${sector['assigned_read']} read',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.successColor,
                                ),
                              ),
                              Text(
                                '${sector['assigned_unread']} unread',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warningColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCharts() {
    final overallStats = _notificationStats['overall_stats'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Notifications Analytics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: double.tryParse(overallStats['assigned_read_notifications']?.toString() ?? '0') ?? 0,
                        title: 'Read',
                        color: AppColors.successColor,
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: double.tryParse(overallStats['assigned_unread_notifications']?.toString() ?? '0') ?? 0,
                        title: 'Unread',
                        color: AppColors.warningColor,
                        radius: 60,
                      ),
                    ],
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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



}