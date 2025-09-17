import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/arrested_criminal.dart';
import '../../models/notification.dart';
import '../../services/api_service.dart';
import '../../widgets/loading_widget.dart';

class ArrestNewsScreen extends StatefulWidget {
  const ArrestNewsScreen({super.key});

  @override
  State<ArrestNewsScreen> createState() => _ArrestNewsScreenState();
}

class _ArrestNewsScreenState extends State<ArrestNewsScreen> {
  List<ArrestedCriminal> _recentArrests = [];
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _selectedCrimeType = 'All';

  final List<String> _crimeTypes = [
    'All',
    'Theft',
    'Robbery',
    'Assault',
    'Fraud',
    'Drug Offenses',
    'Violence',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load recent arrests
      final arrestsResponse = await ApiService.getArrestedCriminals(page: 1, limit: 20);
      final arrests = (arrestsResponse['data'] as List)
          .map((json) => ArrestedCriminal.fromJson(json))
          .toList();

      // Load notifications
      final notificationsResponse = await ApiService.getNotifications(page: 1, limit: 20);
      final notifications = (notificationsResponse['data'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _recentArrests = arrests;
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _sendArrestNotification(ArrestedCriminal arrested) async {
    try {
      final notificationData = {
        'near_rib': 'General Public',
        'fullname': arrested.fullname,
        'address': arrested.arrestLocation ?? 'Unknown Location',
        'phone': 'N/A',
        'message': 'URGENT: ${arrested.fullname} has been arrested for ${arrested.crimeType} on ${arrested.dateArrested.day}/${arrested.dateArrested.month}/${arrested.dateArrested.year}. Stay vigilant and report any suspicious activities.',
      };

      await ApiService.sendNotification(notificationData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrest notification sent successfully')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
        );
      }
    }
  }

  List<ArrestedCriminal> get _filteredArrests {
    if (_selectedCrimeType == 'All') {
      return _recentArrests;
    }
    return _recentArrests.where((arrest) => arrest.crimeType == _selectedCrimeType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrest News & Alerts'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Crime Type Filter
                Container(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCrimeType,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Crime Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _crimeTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCrimeType = value!;
                      });
                    },
                  ),
                ),

                // Statistics Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Arrests',
                          '${_recentArrests.length}',
                          Colors.red,
                          Icons.gavel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'This Week',
                          '${_recentArrests.where((a) => a.dateArrested.isAfter(DateTime.now().subtract(const Duration(days: 7)))).length}',
                          Colors.orange,
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Notifications',
                          '${_notifications.length}',
                          Colors.blue,
                          Icons.notifications,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recent Arrests
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          tabs: [
                            Tab(text: 'Recent Arrests', icon: Icon(Icons.gavel)),
                            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // Recent Arrests Tab
                              _filteredArrests.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No arrests found',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _filteredArrests.length,
                                      itemBuilder: (context, index) {
                                        final arrest = _filteredArrests[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.red[100],
                                              child: arrest.imageUrl != null
                                                  ? ClipOval(
                                                      child: arrest.imageUrl!.startsWith('data:image')
                                                          ? Image.memory(
                                                              base64Decode(arrest.imageUrl!.split(',')[1]),
                                                              width: 40,
                                                              height: 40,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Icon(
                                                                  Icons.person,
                                                                  color: Colors.red[700],
                                                                );
                                                              },
                                                            )
                                                          : Image.network(
                                                              arrest.imageUrl!,
                                                              width: 40,
                                                              height: 40,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) {
                                                                return Icon(
                                                                  Icons.person,
                                                                  color: Colors.red[700],
                                                                );
                                                              },
                                                            ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: Colors.red[700],
                                                    ),
                                            ),
                                            title: Text(
                                              arrest.fullname,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Crime: ${arrest.crimeType}'),
                                                Text(
                                                  'Arrested: ${arrest.dateArrested.day}/${arrest.dateArrested.month}/${arrest.dateArrested.year}',
                                                ),
                                                if (arrest.arrestLocation != null)
                                                  Text('Location: ${arrest.arrestLocation}'),
                                              ],
                                            ),
                                            trailing: PopupMenuButton(
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'notify',
                                                  child: Text('Send Alert'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'view',
                                                  child: Text('View Details'),
                                                ),
                                              ],
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'notify':
                                                    _sendArrestNotification(arrest);
                                                    break;
                                                  case 'view':
                                                    // Navigate to detail screen
                                                    break;
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                              // Notifications Tab
                              _notifications.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No notifications found',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _notifications.length,
                                      itemBuilder: (context, index) {
                                        final notification = _notifications[index];
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: notification.isRead
                                                  ? Colors.grey[300]
                                                  : Colors.blue[100],
                                              child: Icon(
                                                Icons.notifications,
                                                color: notification.isRead
                                                    ? Colors.grey[600]
                                                    : Colors.blue[700],
                                              ),
                                            ),
                                            title: Text(
                                              notification.fullname,
                                              style: TextStyle(
                                                fontWeight: notification.isRead
                                                    ? FontWeight.normal
                                                    : FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(notification.message),
                                                Text(
                                                  'Near: ${notification.nearRib}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                                Text(
                                                  'Date: ${notification.createdAt?.day}/${notification.createdAt?.month}/${notification.createdAt?.year}',
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            trailing: notification.isRead
                                                ? null
                                                : Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
