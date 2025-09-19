import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/notification.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';

class ManageNotificationsScreen extends StatefulWidget {
  const ManageNotificationsScreen({super.key});

  @override
  State<ManageNotificationsScreen> createState() => _ManageNotificationsScreenState();
}

class _ManageNotificationsScreenState extends State<ManageNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nearRibController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _locationNameController = TextEditingController();

  NotificationModel? _editingNotification;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _nearRibController.dispose();
    _fullnameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getNotificationsAdmin();
      if (response['success'] == true) {
        final notificationsData = response['data'] as List;
        setState(() {
          _notifications = notificationsData.map((data) => NotificationModel.fromJson(data)).toList();
        });
      }
    } catch (e) {
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

  Future<void> _addNotification() async {
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
        'latitude': _latitudeController.text.trim().isNotEmpty 
            ? double.tryParse(_latitudeController.text.trim()) 
            : null,
        'longitude': _longitudeController.text.trim().isNotEmpty 
            ? double.tryParse(_longitudeController.text.trim()) 
            : null,
        'location_name': _locationNameController.text.trim(),
      };

      final response = await ApiService.createNotification(notificationData);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Notification created successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _loadNotifications();
      } else {
        throw Exception(response['message'] ?? 'Failed to create notification');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error creating notification: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _updateNotification() async {
    if (!_formKey.currentState!.validate() || _editingNotification == null) return;

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
        'latitude': _latitudeController.text.trim().isNotEmpty 
            ? double.tryParse(_latitudeController.text.trim()) 
            : null,
        'longitude': _longitudeController.text.trim().isNotEmpty 
            ? double.tryParse(_longitudeController.text.trim()) 
            : null,
        'location_name': _locationNameController.text.trim(),
      };

      final response = await ApiService.updateNotification(_editingNotification!.notId!, notificationData);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Notification updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _loadNotifications();
      } else {
        throw Exception(response['message'] ?? 'Failed to update notification');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating notification: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification from ${notification.fullname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteNotificationAdmin(notification.notId!);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'Notification deleted successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _loadNotifications();
      } else {
        throw Exception(response['message'] ?? 'Failed to delete notification');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error deleting notification: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  void _editNotification(NotificationModel notification) {
    setState(() {
      _editingNotification = notification;
      _nearRibController.text = notification.nearRib;
      _fullnameController.text = notification.fullname;
      _addressController.text = notification.address;
      _phoneController.text = notification.phone;
      _messageController.text = notification.message;
      _latitudeController.text = notification.latitude?.toString() ?? '';
      _longitudeController.text = notification.longitude?.toString() ?? '';
      _locationNameController.text = notification.locationName ?? '';
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nearRibController.clear();
    _fullnameController.clear();
    _addressController.clear();
    _phoneController.clear();
    _messageController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _locationNameController.clear();
    _editingNotification = null;
  }

  Future<void> _openLocationInMaps(double? latitude, double? longitude) async {
    if (latitude == null || longitude == null) {
      Fluttertoast.showToast(
        msg: 'No GPS coordinates available',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.warningColor,
        textColor: Colors.white,
      );
      return;
    }

    final url = 'https://www.google.com/maps?q=$latitude,$longitude';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Fluttertoast.showToast(
        msg: 'Could not open maps',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Form Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          _editingNotification == null ? 'Add New Notification' : 'Edit Notification',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _nearRibController,
                                hintText: 'Near RIB',
                                labelText: 'Near RIB',
                                validator: Validators.validateRequired,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _fullnameController,
                                hintText: 'Full Name',
                                labelText: 'Full Name',
                                validator: Validators.validateRequired,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          controller: _addressController,
                          hintText: 'Address',
                          labelText: 'Address',
                          validator: Validators.validateRequired,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _phoneController,
                                hintText: 'Phone',
                                labelText: 'Phone',
                                validator: Validators.validateRequired,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _locationNameController,
                                hintText: 'Location Name',
                                labelText: 'Location Name',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        CustomTextField(
                          controller: _messageController,
                          hintText: 'Message',
                          labelText: 'Message',
                          maxLines: 3,
                          validator: Validators.validateRequired,
                        ),
                        const SizedBox(height: 16),
                        
                        // GPS Coordinates
                        const Text(
                          'GPS Coordinates (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _latitudeController,
                                hintText: 'Latitude',
                                labelText: 'Latitude',
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _longitudeController,
                                hintText: 'Longitude',
                                labelText: 'Longitude',
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: _editingNotification == null ? 'Add Notification' : 'Update Notification',
                                onPressed: _editingNotification == null ? _addNotification : _updateNotification,
                                isLoading: _isSubmitting,
                              ),
                            ),
                            if (_editingNotification != null) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  onPressed: _clearForm,
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Notifications List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            child: const Icon(Icons.notifications, color: Colors.white),
                          ),
                          title: Text(notification.fullname),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Near RIB: ${notification.nearRib}'),
                              Text('Phone: ${notification.phone}'),
                              Text('Address: ${notification.address}'),
                              if (notification.locationName != null)
                                Text('Location: ${notification.locationName}'),
                              if (notification.latitude != null && notification.longitude != null)
                                Text('GPS: ${notification.latitude}, ${notification.longitude}'),
                              Text('Message: ${notification.message}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (notification.latitude != null && notification.longitude != null)
                                IconButton(
                                  onPressed: () => _openLocationInMaps(
                                    notification.latitude, 
                                    notification.longitude
                                  ),
                                  icon: const Icon(Icons.location_on),
                                  color: AppColors.primaryColor,
                                  tooltip: 'Open in Maps',
                                ),
                              IconButton(
                                onPressed: () => _editNotification(notification),
                                icon: const Icon(Icons.edit),
                                color: AppColors.primaryColor,
                              ),
                              IconButton(
                                onPressed: () => _deleteNotification(notification),
                                icon: const Icon(Icons.delete),
                                color: AppColors.errorColor,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}