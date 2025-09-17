import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/notification.dart';
import '../../models/arrested_criminal.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class EnhancedNotificationScreen extends StatefulWidget {
  const EnhancedNotificationScreen({super.key});

  @override
  State<EnhancedNotificationScreen> createState() => _EnhancedNotificationScreenState();
}

class _EnhancedNotificationScreenState extends State<EnhancedNotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

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

      final List<NotificationModel> newNotifications = (response['data'] as List)
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading notifications: ${e.toString()}');
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorToast('Could not launch phone dialer');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await ApiService.deleteNotification(notification.notId!);
      setState(() {
        _notifications.removeWhere((n) => n.notId == notification.notId);
      });
      Fluttertoast.showToast(
        msg: "Notification deleted successfully",
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
    } catch (e) {
      _showErrorToast('Error deleting notification: ${e.toString()}');
    }
  }

  void _showArrestDialog(NotificationModel notification) {
    final formKey = GlobalKey<FormState>();
    final arrestLocationController = TextEditingController();
    final officerNotesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register Arrest'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Arresting: ${notification.fullname}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: arrestLocationController,
                        decoration: const InputDecoration(
                          labelText: 'Arrest Location',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter arrest location';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Arrest Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: officerNotesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Officer Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        // Create arrested criminal record
                        final arrestedCriminal = ArrestedCriminal(
                          fullname: notification.fullname,
                          crimeType: 'Based on tip received',
                          dateArrested: selectedDate,
                          arrestLocation: arrestLocationController.text.trim(),
                        );

                        await ApiService.addArrestedCriminal(arrestedCriminal);
                        
                        // Delete the notification
                        await _deleteNotification(notification);
                        
                        Navigator.of(context).pop();
                        
                        Fluttertoast.showToast(
                          msg: "Arrest registered successfully! Criminal added to news.",
                          backgroundColor: AppColors.successColor,
                          textColor: Colors.white,
                          toastLength: Toast.LENGTH_LONG,
                        );
                      } catch (e) {
                        _showErrorToast('Error registering arrest: $e');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register Arrest'),
                ),
              ],
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Criminal Sighting Alerts', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These are reports from citizens who spotted wanted criminals. Take action to investigate and arrest.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
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
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadNotifications(refresh: true);
                  }
                });
              },
            ),
          ),
          
          // Notifications List
          Expanded(
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: LoadingWidget())
                : _notifications.isEmpty
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
                            SizedBox(height: 8),
                            Text(
                              'Criminal sighting alerts will appear here',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadNotifications(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _notifications.length) {
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

                            final notification = _notifications[index];
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
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SIGHTING ALERT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (notification.createdAt != null)
                  Text(
                    DateFormat('MMM dd, HH:mm').format(notification.createdAt!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Criminal Name
                Text(
                  'Suspect: ${notification.fullname}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Location
                _buildDetailRow('Location', notification.address),
                
                // RIB Station
                _buildDetailRow('Nearest RIB', notification.nearRib),
                
                // Reporter Phone
                _buildDetailRow('Reporter Phone', notification.phone),
                
                const SizedBox(height: 12),
                
                // Message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makePhoneCall(notification.phone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text('Call Reporter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showArrestDialog(notification),
                    icon: const Icon(Icons.gavel, size: 18),
                    label: const Text('Register Arrest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deleteNotification(notification),
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  tooltip: 'Delete notification',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
