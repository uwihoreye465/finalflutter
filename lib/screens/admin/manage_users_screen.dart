import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../utils/validators.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sectorController = TextEditingController();
  final _positionController = TextEditingController();

  String? _selectedRole;
  User? _editingUser;
  
  // Filter variables
  String _selectedRoleFilter = 'all';
  String _selectedApprovalFilter = 'all';
  List<User> _filteredUsers = [];
  

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _sectorController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUsersAdmin();
      if (response['success'] == true) {
        final usersData = response['data']['users'] as List;
        setState(() {
          _users = usersData.map((userData) => User.fromJson(userData)).toList();
          _applyFilters();
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error loading users: $e',
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

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userData = {
        'fullname': _fullnameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'sector': _sectorController.text.trim(),
        'position': _positionController.text.trim(),
        'role': _selectedRole!,
      };

      final response = await ApiService.createUser(userData);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'User created successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _loadUsers();
        Navigator.of(context).pop(); // Close the dialog
      } else {
        throw Exception(response['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error creating user: $e',
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

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate() || _editingUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userData = {
        'fullname': _fullnameController.text.trim(),
        'email': _emailController.text.trim(),
        'sector': _sectorController.text.trim(),
        'position': _positionController.text.trim(),
        'role': _selectedRole!,
      };

      // Only include password if it's not empty
      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text.trim();
      }

      final response = await ApiService.updateUser(_editingUser!.userId!, userData);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'User updated successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _clearForm();
        _loadUsers();
        Navigator.of(context).pop(); // Close the dialog
      } else {
        throw Exception(response['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating user: $e',
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

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullname}?'),
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
      final response = await ApiService.deleteUserAdmin(user.userId!);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'User deleted successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _loadUsers();
      } else {
        throw Exception(response['message'] ?? 'Failed to delete user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error deleting user: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  void _editUser(User user) {
    setState(() {
      _editingUser = user;
      _fullnameController.text = user.fullname;
      _emailController.text = user.email;
      _sectorController.text = user.sector;
      _positionController.text = user.position;
      _selectedRole = user.role;
      _passwordController.clear();
    });
    _showAddUserDialog();
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _fullnameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _sectorController.clear();
    _positionController.clear();
    _selectedRole = null;
    _editingUser = null;
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingUser == null ? 'Add New User' : 'Edit User'),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _fullnameController,
                  hintText: 'Full Name',
                  labelText: 'Full Name',
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  labelText: 'Email',
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _sectorController,
                  hintText: 'Sector',
                  labelText: 'Sector',
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _positionController,
                  hintText: 'Position',
                  labelText: 'Position',
                  validator: Validators.validateRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  hintText: _editingUser == null ? 'Password' : 'New Password (optional)',
                  labelText: _editingUser == null ? 'Password' : 'New Password (optional)',
                  obscureText: true,
                  validator: _editingUser == null 
                      ? Validators.validateStrongPassword
                      : (value) {
                          if (value != null && value.isNotEmpty) {
                            return Validators.validateStrongPassword(value);
                          }
                          return null;
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a role';
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
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: _editingUser == null ? 'Add User' : 'Update User',
            onPressed: _isSubmitting ? null : (_editingUser == null ? _addUser : _updateUser),
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(User user) async {
    try {
      final response = await ApiService.approveUser(user.userId!, true);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'User approved successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        _loadUsers();
      } else {
        throw Exception(response['message'] ?? 'Failed to approve user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error approving user: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _blockUser(User user) async {
    try {
      final response = await ApiService.approveUser(user.userId!, false);
      if (response['success'] == true) {
        Fluttertoast.showToast(
          msg: 'User blocked successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
        _loadUsers();
      } else {
        throw Exception(response['message'] ?? 'Failed to block user');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error blocking user: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }


  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        bool roleMatch = _selectedRoleFilter == 'all' || user.role == _selectedRoleFilter;
        bool approvalMatch = _selectedApprovalFilter == 'all' || 
            (_selectedApprovalFilter == 'approved' && user.isApproved) ||
            (_selectedApprovalFilter == 'pending' && !user.isApproved);
        return roleMatch && approvalMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _clearForm();
          _showAddUserDialog();
        },
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : Column(
              children: [
                // Statistics Section
                
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRoleFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Role',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Roles')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'staff', child: Text('Staff')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleFilter = value!;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedApprovalFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Users')),
                            DropdownMenuItem(value: 'approved', child: Text('Approved')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedApprovalFilter = value!;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Users List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor,
                            child: Text(
                              user.fullname[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user.fullname),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${user.email}'),
                              Text('Role: ${user.role.toUpperCase()}'),
                              Text('Sector: ${user.sector}'),
                              Text('Position: ${user.position}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!user.isApproved)
                                IconButton(
                                  onPressed: () => _approveUser(user),
                                  icon: const Icon(Icons.check_circle),
                                  color: AppColors.successColor,
                                  tooltip: 'Approve User',
                                ),
                              if (user.isApproved)
                                IconButton(
                                  onPressed: () => _blockUser(user),
                                  icon: const Icon(Icons.block),
                                  color: AppColors.warningColor,
                                  tooltip: 'Block User',
                                ),
                              IconButton(
                                onPressed: () => _editUser(user),
                                icon: const Icon(Icons.edit),
                                color: AppColors.primaryColor,
                                tooltip: 'Edit User',
                              ),
                              IconButton(
                                onPressed: () => _deleteUser(user),
                                icon: const Icon(Icons.delete),
                                color: AppColors.errorColor,
                                tooltip: 'Delete User',
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