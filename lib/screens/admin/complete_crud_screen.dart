import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/criminal_record.dart';
import '../../models/victim.dart';
import '../../models/arrested_criminal.dart';
import '../../models/notification.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class CompleteCrudScreen extends StatefulWidget {
  const CompleteCrudScreen({super.key});

  @override
  State<CompleteCrudScreen> createState() => _CompleteCrudScreenState();
}

class _CompleteCrudScreenState extends State<CompleteCrudScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Data lists
  List<CriminalRecord> _criminalRecords = [];
  List<Victim> _victims = [];
  List<ArrestedCriminal> _arrestedCriminals = [];
  List<NotificationModel> _notifications = [];
  List<User> _users = [];

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadCriminalRecords(),
        _loadVictims(),
        _loadArrestedCriminals(),
        _loadNotifications(),
        _loadUsers(),
      ]);
    } catch (e) {
      _showErrorToast('Error loading data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCriminalRecords() async {
    try {
      final response = await ApiService.getCriminalRecords(page: _currentPage, limit: _itemsPerPage);
      if (response['success'] == true) {
        final records = (response['data'] as List).map((json) => CriminalRecord.fromJson(json)).toList();
        setState(() {
          _criminalRecords = records;
        });
      }
    } catch (e) {
      debugPrint('Error loading criminal records: $e');
    }
  }

  Future<void> _loadVictims() async {
    try {
      final response = await ApiService.getVictims();
      if (response['success'] == true) {
        final victims = (response['data'] as List).map((json) => Victim.fromJson(json)).toList();
        setState(() {
          _victims = victims;
        });
      }
    } catch (e) {
      debugPrint('Error loading victims: $e');
    }
  }

  Future<void> _loadArrestedCriminals() async {
    try {
      final response = await ApiService.getArrestedCriminals();
      if (response['success'] == true) {
        final arrested = (response['data']['records'] as List).map((json) => ArrestedCriminal.fromJson(json)).toList();
        setState(() {
          _arrestedCriminals = arrested;
        });
      }
    } catch (e) {
      debugPrint('Error loading arrested criminals: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await ApiService.getNotificationsAdmin();
      if (response['success'] == true) {
        final notifications = (response['data'] as List).map((json) => NotificationModel.fromJson(json)).toList();
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final response = await ApiService.getUsersAdmin();
      if (response['success'] == true) {
        final users = (response['data'] as List).map((json) => User.fromJson(json)).toList();
        setState(() {
          _users = users;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
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

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.successColor,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete CRUD Management'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Criminal Records', icon: Icon(Icons.person)),
            Tab(text: 'Victims', icon: Icon(Icons.people)),
            Tab(text: 'Arrested', icon: Icon(Icons.gavel)),
            Tab(text: 'Notifications', icon: Icon(Icons.notifications)),
            Tab(text: 'Users', icon: Icon(Icons.admin_panel_settings)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCriminalRecordsTab(),
                _buildVictimsTab(),
                _buildArrestedCriminalsTab(),
                _buildNotificationsTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  Widget _buildCriminalRecordsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Criminal Records (${_criminalRecords.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCriminalRecordDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _criminalRecords.length,
            itemBuilder: (context, index) {
              final record = _criminalRecords[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      '${record.firstName[0]}${record.lastName[0]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${record.firstName} ${record.lastName}'),
                  subtitle: Text('${record.crimeType} - ${record.idNumber}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditCriminalRecordDialog(record);
                      } else if (value == 'delete') {
                        _deleteCriminalRecord(record.criId!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVictimsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Victims (${_victims.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddVictimDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Victim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _victims.length,
            itemBuilder: (context, index) {
              final victim = _victims[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.secondaryColor,
                    child: Text(
                      '${victim.firstName[0]}${victim.lastName[0]}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${victim.firstName} ${victim.lastName}'),
                  subtitle: Text('${victim.crimeType} - ${victim.idNumber}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditVictimDialog(victim);
                      } else if (value == 'delete') {
                        _deleteVictim(victim.vicId!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArrestedCriminalsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arrested Criminals (${_arrestedCriminals.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddArrestedCriminalDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Arrested'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _arrestedCriminals.length,
            itemBuilder: (context, index) {
              final arrested = _arrestedCriminals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.warningColor,
                    child: Text(
                      arrested.fullname.isNotEmpty ? arrested.fullname[0] : 'A',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(arrested.fullname),
                  subtitle: Text('${arrested.crimeType} - ${arrested.arrestLocation}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditArrestedCriminalDialog(arrested);
                      } else if (value == 'delete') {
                        _deleteArrestedCriminal(arrested.arrestId!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications (${_notifications.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Note: Admins cannot send notifications as per requirement
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.infoColor,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(notification.fullname ?? 'Unknown'),
                  subtitle: Text(notification.message ?? 'No message'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _showNotificationDetails(notification);
                      } else if (value == 'delete') {
                        _deleteNotification(notification.notId!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Users (${_users.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: user.role == 'admin' ? AppColors.errorColor : AppColors.primaryColor,
                    child: Text(
                      user.fullname.isNotEmpty ? user.fullname[0] : 'U',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.fullname),
                  subtitle: Text('${user.role} - ${user.email}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditUserDialog(user);
                      } else if (value == 'delete') {
                        _deleteUser(user.userId!);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Dialog methods (simplified for brevity)
  void _showAddCriminalRecordDialog() {
    // Implementation for adding criminal record
    _showSuccessToast('Add Criminal Record dialog - Implementation needed');
  }

  void _showEditCriminalRecordDialog(CriminalRecord record) {
    // Implementation for editing criminal record
    _showSuccessToast('Edit Criminal Record dialog - Implementation needed');
  }

  void _showAddVictimDialog() {
    // Implementation for adding victim
    _showSuccessToast('Add Victim dialog - Implementation needed');
  }

  void _showEditVictimDialog(Victim victim) {
    // Implementation for editing victim
    _showSuccessToast('Edit Victim dialog - Implementation needed');
  }

  void _showAddArrestedCriminalDialog() {
    // Implementation for adding arrested criminal
    _showSuccessToast('Add Arrested Criminal dialog - Implementation needed');
  }

  void _showEditArrestedCriminalDialog(ArrestedCriminal arrested) {
    // Implementation for editing arrested criminal
    _showSuccessToast('Edit Arrested Criminal dialog - Implementation needed');
  }

  void _showAddUserDialog() {
    // Implementation for adding user
    _showSuccessToast('Add User dialog - Implementation needed');
  }

  void _showEditUserDialog(User user) {
    // Implementation for editing user
    _showSuccessToast('Edit User dialog - Implementation needed');
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${notification.fullname ?? 'N/A'}'),
            Text('Phone: ${notification.phone ?? 'N/A'}'),
            Text('Address: ${notification.address ?? 'N/A'}'),
            Text('Message: ${notification.message ?? 'N/A'}'),
            if (notification.latitude != null && notification.longitude != null)
              Text('Location: ${notification.latitude}, ${notification.longitude}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Delete methods
  Future<void> _deleteCriminalRecord(int id) async {
    try {
      final success = await ApiService.deleteCriminalRecord(id);
      if (success) {
        _showSuccessToast('Criminal record deleted successfully');
        _loadCriminalRecords();
      } else {
        _showErrorToast('Failed to delete criminal record');
      }
    } catch (e) {
      _showErrorToast('Error deleting criminal record: ${e.toString()}');
    }
  }

  Future<void> _deleteVictim(int id) async {
    try {
      final success = await ApiService.deleteVictim(id);
      if (success) {
        _showSuccessToast('Victim deleted successfully');
        _loadVictims();
      } else {
        _showErrorToast('Failed to delete victim');
      }
    } catch (e) {
      _showErrorToast('Error deleting victim: ${e.toString()}');
    }
  }

  Future<void> _deleteArrestedCriminal(int id) async {
    try {
      final success = await ApiService.deleteArrestedCriminal(id);
      if (success) {
        _showSuccessToast('Arrested criminal deleted successfully');
        _loadArrestedCriminals();
      } else {
        _showErrorToast('Failed to delete arrested criminal');
      }
    } catch (e) {
      _showErrorToast('Error deleting arrested criminal: ${e.toString()}');
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final response = await ApiService.deleteNotificationAdmin(id);
      if (response['success'] == true) {
        _showSuccessToast('Notification deleted successfully');
        _loadNotifications();
      } else {
        _showErrorToast('Failed to delete notification');
      }
    } catch (e) {
      _showErrorToast('Error deleting notification: ${e.toString()}');
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      final response = await ApiService.deleteUserAdmin(id);
      if (response['success'] == true) {
        _showSuccessToast('User deleted successfully');
        _loadUsers();
      } else {
        _showErrorToast('Failed to delete user');
      }
    } catch (e) {
      _showErrorToast('Error deleting user: ${e.toString()}');
    }
  }
}
