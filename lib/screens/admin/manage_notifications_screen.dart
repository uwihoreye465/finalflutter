import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../models/notification.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() => _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

  // Send notification form controllers
  final _formKey = GlobalKey<FormState>();
  final _nearRibController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

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

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notificationData = {
        'near_rib': _nearRibController.text.trim(),
        'fullname': _fullnameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': _messageController.text.trim(),
      };

      await ApiService.sendNotification(notificationData);
      
      Fluttertoast.showToast(
        msg: "Notification sent successfully!",
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      
      // Clear form
      _clearForm();
      
      // Refresh notifications list
      _loadNotifications(refresh: true);
      
    } catch (e) {
      _showErrorToast('Error sending notification: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _nearRibController.clear();
    _fullnameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _messageController.clear();
  }

  void _showSendNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Send Notification'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Near RIB Station
                      DropdownSearch<String>(
                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              hintText: "Search RIB station...",
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        items: const [
                          'RIB Gasabo',
                          'RIB Kicukiro',
                          'RIB Nyarugenge',
                          'RIB Bugesera',
                          'RIB Gatsibo',
                          'RIB Kayonza',
                          'RIB Kirehe',
                          'RIB Ngoma',
                          'RIB Nyagatare',
                          'RIB Rwamagana',
                          'RIB Kamonyi',
                          'RIB Muhanga',
                          'RIB Nyanza',
                          'RIB Ruhango',
                          'RIB Huye',
                          'RIB Nyamagabe',
                          'RIB Nyaruguru',
                          'RIB Gisagara',
                          'RIB Burera',
                          'RIB Gakenke',
                          'RIB Gicumbi',
                          'RIB Musanze',
                          'RIB Rulindo',
                          'RIB Karongi',
                          'RIB Ngororero',
                          'RIB Nyabihu',
                          'RIB Rubavu',
                          'RIB Rusizi',
                          'RIB Nyamasheke',
                        ],
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: "Select Near RIB Station",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        onChanged: (value) {
                          _nearRibController.text = value ?? '';
                        },
                        validator: (value) => value == null ? 'Please select RIB station' : null,
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Full Name
                      CustomTextField(
                        controller: _fullnameController,
                        hintText: 'Enter Full Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter full name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Address
                      CustomTextField(
                        controller: _addressController,
                        hintText: 'Enter Address',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Phone
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Message
                      CustomTextField(
                        controller: _messageController,
                        hintText: 'Write Message',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter message';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                if (_isSubmitting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: () async {
                      setDialogState(() {
                        _isSubmitting = true;
                      });
                      await _sendNotification();
                      setDialogState(() {
                        _isSubmitting = false;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                    ),
                    child: const Text('Send', style: TextStyle(color: Colors.white)),
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
        title: const Text('Manage Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showSendNotificationDialog,
          ),
        ],
      ),
      body: Column(
        children: [
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
                // Implement search functionality
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
                            Icon(Icons.notifications_none, size: 80, color: Colors.grey),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendNotificationDialog,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.fullname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        notification.nearRib,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (notification.createdAt != null)
                  Text(
                    '${notification.createdAt!.day}/${notification.createdAt!.month}/${notification.createdAt!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Notification Details
            _buildDetailRow('Phone', notification.phone),
            _buildDetailRow('Address', notification.address),
            
            const SizedBox(height: 8),
            
            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nearRibController.dispose();
    _fullnameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}