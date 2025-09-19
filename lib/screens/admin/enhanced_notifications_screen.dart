import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/notification.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class EnhancedNotificationsScreen extends StatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  State<EnhancedNotificationsScreen> createState() => _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState extends State<EnhancedNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRibFilter;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _notifications = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getNotifications(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      if (response['success'] == true) {
        final List<NotificationModel> newNotifications = (response['data']['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _notifications = newNotifications;
          } else {
            _notifications.addAll(newNotifications);
          }
          _hasMoreData = newNotifications.length == _itemsPerPage;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showErrorToast('Error loading notifications: ${e.toString()}');
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId);
      
      setState(() {
        _notifications.removeWhere((notification) => notification.notId == notificationId);
      });
      
      Fluttertoast.showToast(
        msg: 'Notification deleted successfully',
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
    } catch (e) {
      _showErrorToast('Error deleting notification: ${e.toString()}');
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.errorColor,
      textColor: Colors.white,
    );
  }

  void _launchMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showErrorToast('Could not launch maps');
    }
  }

  List<NotificationModel> get _filteredNotifications {
    List<NotificationModel> filtered = _notifications;
    
    if (_showUnreadOnly) {
      filtered = filtered.where((notification) => !notification.isRead).toList();
    }
    
    if (_selectedRibFilter != null && _selectedRibFilter != 'All') {
      filtered = filtered.where((notification) => notification.nearRib == _selectedRibFilter).toList();
    }
    
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((notification) => 
        notification.fullname.toLowerCase().contains(searchTerm) ||
        notification.message.toLowerCase().contains(searchTerm) ||
        notification.address.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications Management', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notifications...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter Row
                Row(
                  children: [
                    // RIB Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRibFilter,
                        decoration: const InputDecoration(
                          labelText: "Filter by RIB",
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'All',
                          ..._notifications.map((n) => n.nearRib).toSet().toList(),
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRibFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Unread Only Toggle
                    FilterChip(
                      label: Text(_showUnreadOnly ? 'Unread Only' : 'All'),
                      selected: _showUnreadOnly,
                      onSelected: (bool value) {
                        setState(() {
                          _showUnreadOnly = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notifications List
          Expanded(
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: LoadingWidget())
                : _filteredNotifications.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No notifications found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadNotifications(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNotifications.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredNotifications.length) {
                              // Load more indicator
                              if (_hasMoreData) {
                                _loadNotifications();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: LoadingWidget(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(
          color: notification.isRead ? Colors.grey.withOpacity(0.3) : AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notification.isRead 
                        ? Colors.grey.withOpacity(0.1)
                        : AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: notification.isRead ? Colors.grey : AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.fullname,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RIB: ${notification.nearRib}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              notification.message,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            // Address
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Phone
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  notification.phone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            // GPS Location (if available)
            if (notification.latitude != null && notification.longitude != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.gps_fixed, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'GPS: ${notification.latitude}, ${notification.longitude}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchMaps(
                      notification.latitude!,
                      notification.longitude!,
                    ),
                    child: const Text('View on Map'),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Timestamp and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.createdAt != null 
                      ? DateFormat('yyyy-MM-dd HH:mm').format(notification.createdAt!)
                      : 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => notification.notId != null 
                          ? _deleteNotification(notification.notId!)
                          : null,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
