import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _users = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getUsers(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      final List<User> newUsers = (response['data'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      setState(() {
        if (refresh) {
          _users = newUsers;
        } else {
          _users.addAll(newUsers);
        }
        _hasMoreData = newUsers.length == _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading users: ${e.toString()}');
    }
  }

  Future<void> _approveUser(User user, bool approve) async {
    try {
      await ApiService.approveUser(user.userId!, approve);
      
      setState(() {
        final index = _users.indexWhere((u) => u.userId == user.userId);
        if (index != -1) {
          _users[index] = User(
            userId: user.userId,
            sector: user.sector,
            fullname: user.fullname,
            position: user.position,
            email: user.email,
            role: user.role,
            isVerified: approve,
            createdAt: user.createdAt,
          );
        }
      });

      Fluttertoast.showToast(
        msg: approve ? 'User approved successfully' : 'User rejected',
        backgroundColor: approve ? AppColors.successColor : AppColors.errorColor,
        textColor: Colors.white,
      );
    } catch (e) {
      _showErrorToast('Error updating user: ${e.toString()}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                hintText: 'Search users...',
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
          
          // Users List
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: LoadingWidget())
                : RefreshIndicator(
                    onRefresh: () => _loadUsers(refresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length + (_hasMoreData ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          // Load more indicator
                          if (_hasMoreData) {
                            _loadUsers();
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: LoadingWidget(),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final user = _users[index];
                        return _buildUserCard(user);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
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
            // User Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: user.isVerified 
                        ? AppColors.successColor.withOpacity(0.1)
                        : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: user.isVerified ? AppColors.successColor : AppColors.errorColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.position,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isVerified 
                        ? AppColors.successColor
                        : AppColors.errorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isVerified ? 'Approved' : 'Pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // User Details
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Sector', user.sector),
            _buildDetailRow('Role', user.role.toUpperCase()),
            
            if (!user.isVerified) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveUser(user, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveUser(user, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
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
            width: 60,
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
    super.dispose();
  }
}