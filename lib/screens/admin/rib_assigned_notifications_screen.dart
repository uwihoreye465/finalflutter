import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RibAssignedNotificationsScreen extends StatefulWidget {
  const RibAssignedNotificationsScreen({super.key});

  @override
  State<RibAssignedNotificationsScreen> createState() => _RibAssignedNotificationsScreenState();
}

class _RibAssignedNotificationsScreenState extends State<RibAssignedNotificationsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];
  String _selectedFilter = 'all';
  int? _userId;
  Set<int> _selectedNotifications = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserInfo();
    await _loadNotifications();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final user = authService.user;
      debugPrint('Auth service user for notifications: $user');
      debugPrint('Auth service isAuthenticated: ${authService.isAuthenticated}');
      debugPrint('Auth service isLoading: ${authService.isLoading}');
      
      if (user != null) {
        setState(() {
          _userId = user.userId;
        });
        debugPrint('User ID loaded for notifications: $_userId');
        debugPrint('User fullname: ${user.fullname}');
        debugPrint('User sector: ${user.sector}');
        debugPrint('User role: ${user.role}');
      } else {
        debugPrint('No user found in auth service for notifications');
        // Try to wait a bit and check again
        await Future.delayed(const Duration(milliseconds: 100));
        final user2 = authService.user;
        debugPrint('Second attempt - Auth service user: $user2');
        if (user2 != null) {
          setState(() {
            _userId = user2.userId;
          });
          debugPrint('User ID loaded on second attempt: $_userId');
        }
      }
    } catch (e) {
      debugPrint('Error loading user info for notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    // If user ID is still null, try to get it from statistics API
    if (_userId == null) {
      debugPrint('User ID is null, trying to get from statistics API');
      try {
        final statsResponse = await ApiService.getNotificationAssignmentStatistics();
        if (statsResponse['success'] == true) {
          final userStats = statsResponse['data']['user_stats'] as List<dynamic>?;
          if (userStats != null && userStats.isNotEmpty) {
            _userId = userStats.first['user_id'];
            debugPrint('Got user ID from statistics: $_userId');
          }
        }
      } catch (e) {
        debugPrint('Error getting user ID from statistics: $e');
      }
    }

    if (_userId == null) {
      debugPrint('Cannot load notifications: User ID is still null');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading notifications for user ID: $_userId');
      final response = await ApiService.getUserNotifications(_userId!);
      debugPrint('Notifications API response: $response');
      
      if (response['success'] == true) {
        final notifications = response['data']['notifications'] as List;
        setState(() {
          _notifications = notifications.cast<Map<String, dynamic>>();
          _applyFilter();
        });
        debugPrint('Loaded ${notifications.length} notifications');
      } else {
        debugPrint('Notifications API returned error: ${response['message']}');
        throw Exception(response['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      Fluttertoast.showToast(
        msg: 'Error loading notifications: $e',
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

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'read':
          _filteredNotifications = _notifications.where((n) => n['is_read'] == true).toList();
          break;
        case 'unread':
          _filteredNotifications = _notifications.where((n) => n['is_read'] == false).toList();
          break;
        default:
          _filteredNotifications = List.from(_notifications);
      }
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      final response = await ApiService.markNotificationAsRead(notificationId);
      
      if (response['success'] == true) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            if (_notifications[i]['not_id'] == notificationId) {
              _notifications[i]['is_read'] = true;
              break;
            }
          }
          _applyFilter();
        });
        
        Fluttertoast.showToast(
          msg: 'Notification marked as read',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to mark as read');
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _markAsUnread(int notificationId) async {
    try {
      final response = await ApiService.markNotificationAsUnread(notificationId);
      
      if (response['success'] == true) {
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            if (_notifications[i]['not_id'] == notificationId) {
              _notifications[i]['is_read'] = false;
              break;
            }
          }
          _applyFilter();
        });
        
        Fluttertoast.showToast(
          msg: 'Notification marked as unread',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to mark as unread');
      }
    } catch (e) {
      debugPrint('Error marking as unread: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      final response = await ApiService.deleteAssignedNotification(notificationId);
      
      if (response['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n['not_id'] == notificationId);
          _applyFilter();
        });
        
        Fluttertoast.showToast(
          msg: 'Notification deleted',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _deleteSelectedNotifications() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      final response = await ApiService.deleteMultipleAssignedNotifications(
        _selectedNotifications.toList(),
      );
      
      if (response['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => _selectedNotifications.contains(n['not_id']));
          _selectedNotifications.clear();
          _isSelectionMode = false;
          _applyFilter();
        });
        
        Fluttertoast.showToast(
          msg: 'Selected notifications deleted',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to delete notifications');
      }
    } catch (e) {
      debugPrint('Error deleting notifications: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  void _toggleSelection(int notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
      
      if (_selectedNotifications.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNotifications = _filteredNotifications.map((n) => n['not_id'] as int).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNotifications.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header with Filter
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(value: 'unread', label: Text('Unread')),
                          ButtonSegment(value: 'read', label: Text('Read')),
                        ],
                        selected: {_selectedFilter},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _selectedFilter = selection.first;
                            _applyFilter();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                if (_isSelectionMode) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${_selectedNotifications.length} selected',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _selectAll,
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text('Clear'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _deleteSelectedNotifications,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Notifications List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton(
        onPressed: () {
          setState(() {
            _isSelectionMode = true;
          });
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.checklist, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: AppColors.primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no ${_selectedFilter} notifications at the moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final isSelected = _selectedNotifications.contains(notification['not_id']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode 
              ? () => _toggleSelection(notification['not_id'])
              : null,
          onLongPress: () {
            setState(() {
              _isSelectionMode = true;
              _toggleSelection(notification['not_id']);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRead 
                            ? AppColors.successColor.withOpacity(0.1)
                            : AppColors.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                        color: isRead ? AppColors.successColor : AppColors.warningColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['fullname'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification['near_rib'] ?? 'Unknown Station',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isSelectionMode)
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primaryColor : Colors.grey[400],
                      )
                    else
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'read':
                              _markAsRead(notification['not_id']);
                              break;
                            case 'unread':
                              _markAsUnread(notification['not_id']);
                              break;
                            case 'delete':
                              _deleteNotification(notification['not_id']);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: isRead ? 'unread' : 'read',
                            child: Row(
                              children: [
                                Icon(
                                  isRead ? Icons.mark_email_unread : Icons.mark_email_read,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(isRead ? 'Mark as Unread' : 'Mark as Read'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification['message'] ?? 'No message',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notification['address'] ?? 'No address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(notification['created_at']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}