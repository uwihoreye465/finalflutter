import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import 'manage_users_screen.dart';
import 'enhanced_notification_screen.dart';
import 'manage_criminal_records_screen.dart';
import 'manage_victims_screen.dart';
import 'manage_arrested_criminals_screen.dart';
// Remove unused imports for now

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _criminalStats = {};
  Map<String, dynamic> _victimStats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final criminalStatsResponse = await ApiService.getCriminalStatistics();
      final victimStatsResponse = await ApiService.getVictimStatistics();
      
      setState(() {
        _criminalStats = criminalStatsResponse['data'] ?? {};
        _victimStats = victimStatsResponse['data'] ?? {};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    _buildStatisticsSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Charts Section
                    _buildChartsSection(),
                    
                    const SizedBox(height: 30),
                    
                    // Management Options
                    _buildManagementSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview Statistics',
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
              child: _buildStatCard(
                'Total Criminals',
                _criminalStats['total']?.toString() ?? '0',
                Icons.warning,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Total Victims',
                _victimStats['total']?.toString() ?? '0',
                Icons.person,
                Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month',
                (_criminalStats['thisMonth']?.toString() ?? '0') + ' Crimes',
                Icons.calendar_today,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active Cases',
                (_victimStats['thisMonth']?.toString() ?? '0') + ' Reports',
                Icons.assignment,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crime Statistics by Province',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildPieChart(),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final provinceStats = _criminalStats['byProvince'] as Map<String, dynamic>? ?? {};
    
    if (provinceStats.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final sections = provinceStats.entries.map((entry) {
      final colors = [
        AppColors.primaryColor,
        AppColors.secondaryColor,
        Colors.orange,
        Colors.green,
        Colors.red,
      ];
      
      final index = provinceStats.keys.toList().indexOf(entry.key);
      final color = colors[index % colors.length];
      
      return PieChartSectionData(
        color: color,
        value: (entry.value as num).toDouble(),
        title: '${entry.value}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: provinceStats.entries.map((entry) {
            final colors = [
              AppColors.primaryColor,
              AppColors.secondaryColor,
              Colors.orange,
              Colors.green,
              Colors.red,
            ];
            
            final index = provinceStats.keys.toList().indexOf(entry.key);
            final color = colors[index % colors.length];
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Management Options',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            // Level 3 Data Flow - Crime Reporting
            _buildManagementCard(
              'Report Crime',
              Icons.report,
              Colors.red,
              () {
                // Feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            _buildManagementCard(
              'Person Verification',
              Icons.verified_user,
              Colors.blue,
              () {
                // Feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            _buildManagementCard(
              'RIB Arrest',
              Icons.gavel,
              Colors.purple,
              () {
                // Feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            _buildManagementCard(
              'Arrest News',
              Icons.newspaper,
              Colors.indigo,
              () {
                // Feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
            // Management Screens
            _buildManagementCard(
              'Criminal Records',
              Icons.warning,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageCriminalRecordsScreen()),
              ),
            ),
            _buildManagementCard(
              'Arrested Criminals',
              Icons.gavel,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageArrestedCriminalsScreen()),
              ),
            ),
            _buildManagementCard(
              'Victim Reports',
              Icons.person,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageVictimsScreen()),
              ),
            ),
            _buildManagementCard(
              'Manage Users',
              Icons.people,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageUsersScreen()),
              ),
            ),
            _buildManagementCard(
              'Notifications',
              Icons.notifications,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EnhancedNotificationScreen()),
              ),
            ),
            _buildManagementCard(
              'Crime Types',
              Icons.category,
              Colors.teal,
              () {
                // Feature coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}