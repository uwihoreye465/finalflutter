import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/criminal_record.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/common_header.dart';
import '../../widgets/common_footer.dart';
import '../auth/login_screen.dart';
import '../user/enhanced_report_screen.dart';
import '../admin/admin_dashboard.dart';
import '../admin/rib_station_dashboard.dart';
import '../search/search_result_screen.dart';
import '../news/news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _detectedIdType = 'indangamuntu_yumunyarwanda';

  bool _looksLikePassport(String input) {
    // Passport: not strictly 16 digits; letters allowed
    return RegExp(r'^[A-Za-z]').hasMatch(input) || input.length != 16;
  }

  void _detectIdType(String input) {
    if (_looksLikePassport(input)) {
      _detectedIdType = 'passport';
    } else if (input.length == 16) {
      _detectedIdType = 'indangamuntu_yumunyarwanda';
    }
  }

  Future<void> _searchCriminal() async {
    final idNumber = _searchController.text.trim();
    if (idNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter an ID number',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.warningColor,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _detectIdType(idNumber);
      final criminalRecord = await ApiService.searchCriminalRecord(idNumber);
      
      if (criminalRecord != null) {
        _showCriminalFoundDialog(criminalRecord);
      } else {
        _showCleanRecordDialog();
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error searching criminal record: $e',
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

  void _showCriminalFoundDialog(CriminalRecord criminalRecord) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'WAHUNZE UBUTABERA',
          style: TextStyle(
            color: AppColors.errorColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Name: ${criminalRecord.firstName} ${criminalRecord.lastName}'),
              Text('ID Type: ${criminalRecord.idType}'),
              Text('ID Number: ${criminalRecord.idNumber}'),
              Text('Crime Type: ${criminalRecord.crimeType}'),
              Text('Date Committed: ${criminalRecord.dateCommitted?.toString().split(' ')[0] ?? 'N/A'}'),
              if (criminalRecord.description != null)
                Text('Description: ${criminalRecord.description}'),
              const SizedBox(height: 16),
              const Text(
                'This person has a criminal record. Would you like to send an alert to RIB?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showNotificationForm(criminalRecord);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _showCleanRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Uri umwere ntago wahunze ubutabera',
          style: TextStyle(
            color: AppColors.successColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const SingleChildScrollView(
          child: Column(
            children: [
              Icon(
                Icons.verified,
                color: AppColors.successColor,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'This person has no criminal record in our database.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationForm(CriminalRecord criminalRecord) {
    final _formKey = GlobalKey<FormState>();
    String? _selectedRibStation;
    final _fullnameController = TextEditingController();
    final _addressController = TextEditingController();
    final _phoneController = TextEditingController();
    final _messageController = TextEditingController();
    
    // List of all RIB stations
    final List<String> ribStations = [
      'Bugesera STATIONS',
      'Gatsibo STATIONS',
      'Kayonza STATIONS',
      'Kirehe STATIONS',
      'Ngoma STATIONS',
      'Nyagatare STATIONS',
      'Rwamagana STATIONS',
      'Gasabo STATIONS',
      'Kicukiro STATIONS',
      'Nyarugenge STATIONS',
      'Burera STATIONS',
      'Gakenke STATIONS',
      'Gicumbi STATIONS',
      'Musanze STATIONS',
      'Rulindo STATIONS',
      'Gisagara STATIONS',
      'Huye STATIONS',
      'Kamonyi STATIONS',
      'Muhanga STATIONS',
      'Nyamagabe STATIONS',
      'Nyanza STATIONS',
      'Nyaruguru STATIONS',
      'Ruhango STATIONS',
      'Karongi STATIONS',
      'Ngororero STATIONS',
      'Nyabihu STATIONS',
      'Nyamasheke STATIONS',
      'Rubavu STATIONS',
      'Rusizi STATIONS',
      'Rutsiro STATIONS',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Alert to RIB'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedRibStation,
                  decoration: const InputDecoration(
                    labelText: 'Select RIB Station',
                    border: OutlineInputBorder(),
                  ),
                  items: ribStations.map((String station) {
                    return DropdownMenuItem<String>(
                      value: station,
                      child: Text(station),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    _selectedRibStation = newValue;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a RIB station';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullnameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final notificationData = {
                    'near_rib': _selectedRibStation ?? '',
                    'fullname': _fullnameController.text.trim(),
                    'address': _addressController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'message': _messageController.text.trim(),
                  };

                  await ApiService.sendNotification(notificationData);
                  
                  Fluttertoast.showToast(
                    msg: 'Alert sent to RIB successfully',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: AppColors.successColor,
                    textColor: Colors.white,
                  );
                  
                  Navigator.pop(context);
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: 'Error sending alert: $e',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: AppColors.errorColor,
                    textColor: Colors.white,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = false;
    bool isAdmin = false;
    bool isNearRib = false;
    AuthService? authService;

    try {
      authService = Provider.of<AuthService>(context, listen: false);
      isLoggedIn = authService.isAuthenticated;
      isAdmin = authService.user?.role == 'admin';
      isNearRib = authService.user?.role == 'near_rib';
    } catch (e) {
      debugPrint('Auth service not available: $e');
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLoggedIn)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'logout') {
                            AuthService().logout();
                          } else if (value == 'admin' && isAdmin) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminDashboard()),
                            );
                          } else if (value == 'rib_station' && isNearRib) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RibStationDashboard()),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          List<PopupMenuEntry<String>> items = [];
                          
                          if (isAdmin) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'admin',
                                child: Text('Admin Dashboard'),
                              ),
                            );
                          }

                          if (isNearRib) {
                            items.add(
                              const PopupMenuItem<String>(
                                value: 'rib_station',
                                child: Text('RIB Station Dashboard'),
                              ),
                            );
                          }
                          
                          items.add(
                            const PopupMenuItem<String>(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          );
                          
                          return items;
                        },
                      ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      const Text(
                        'Online Criminal\nTracking',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // RIB Logo placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Center(
                          child: Text(
                            'RIB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Search Input (only for non-logged users)
                      if (!isLoggedIn) ...[
                        CustomTextField(
                          controller: _searchController,
                          hintText: 'Enter id',
                          fillColor: Colors.white,
                          onSubmitted: (_) => _searchCriminal(),
                          onChanged: (value) {
                            // Auto-search when non-passport reaches 16 digits
                            if (value.trim().length == 16 && !_looksLikePassport(value.trim())) {
                              _searchCriminal();
                            }
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Search Button
                        if (_isLoading)
                          const LoadingWidget()
                        else
                          ElevatedButton(
                            onPressed: _searchCriminal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search),
                                SizedBox(width: 8),
                                Text('Search'),
                              ],
                            ),
                          ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Report Button (only shown when logged in)
                      if (isLoggedIn)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EnhancedReportScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.errorColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.report_problem),
                              SizedBox(width: 8),
                              Text('Report Crime'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom Navigation
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBottomNavItem(
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _buildBottomNavItem(
                      icon: Icons.person,
                      label: 'Login',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    _buildBottomNavItem(
                      icon: Icons.newspaper,
                      label: 'News',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NewsScreen()),
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
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryColor : Colors.grey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryColor : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
