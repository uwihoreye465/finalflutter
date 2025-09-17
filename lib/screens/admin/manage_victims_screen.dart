import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../models/victim.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';

class ManageVictimsScreen extends StatefulWidget {
  const ManageVictimsScreen({super.key});

  @override
  State<ManageVictimsScreen> createState() => _ManageVictimsScreenState();
}

class _ManageVictimsScreenState extends State<ManageVictimsScreen> {
  List<Victim> _victims = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIdTypeFilter;

  @override
  void initState() {
    super.initState();
    _loadVictims();
  }

  Future<void> _loadVictims({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _victims = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getVictims(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        idType: _selectedIdTypeFilter,
      );

      final List<Victim> newVictims = (response['data'] as List)
          .map((json) => Victim.fromJson(json))
          .toList();

      setState(() {
        if (refresh) {
          _victims = newVictims;
        } else {
          _victims.addAll(newVictims);
        }
        _hasMoreData = newVictims.length == _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading victims: ${e.toString()}');
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

  void _showVictimDetails(Victim victim) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${victim.firstName} ${victim.lastName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailSection('Personal Information', [
                  _buildDetailItem('ID Type', _formatIdType(victim.idType)),
                  _buildDetailItem('ID Number', victim.idNumber),
                  _buildDetailItem('Gender', victim.gender),
                  if (victim.dateOfBirth != null)
                    _buildDetailItem('Date of Birth', DateFormat('yyyy-MM-dd').format(victim.dateOfBirth!)),
                  if (victim.phone != null)
                    _buildDetailItem('Phone', victim.phone!),
                  if (victim.victimEmail != null)
                    _buildDetailItem('Email', victim.victimEmail!),
                  if (victim.maritalStatus != null)
                    _buildDetailItem('Marital Status', victim.maritalStatus!),
                ]),
                
                const SizedBox(height: 16),
                
                if (_hasAddressInfo(victim))
                  _buildDetailSection('Address Information', [
                    if (victim.country != null)
                      _buildDetailItem('Country', victim.country!),
                    if (victim.province != null)
                      _buildDetailItem('Province', victim.province!),
                    if (victim.district != null)
                      _buildDetailItem('District', victim.district!),
                    if (victim.sector != null)
                      _buildDetailItem('Sector', victim.sector!),
                    if (victim.cell != null)
                      _buildDetailItem('Cell', victim.cell!),
                    if (victim.village != null)
                      _buildDetailItem('Village', victim.village!),
                    if (victim.addressNow != null)
                      _buildDetailItem('Address', victim.addressNow!),
                    if (victim.addressNow != null)
                      _buildDetailItem('Current Address', victim.addressNow!),
                  ]),
                
                const SizedBox(height: 16),
                
                _buildDetailSection('Crime Information', [
                  _buildDetailItem('Crime Type', victim.crimeType),
                  if (victim.sinnerIdentification != null)
                    _buildDetailItem('Suspect Info', victim.sinnerIdentification!),
                  if (victim.evidence != null)
                    _buildDetailItem('Evidence', victim.evidence!),
                  if (victim.dateCommitted != null)
                    _buildDetailItem('Date Committed', DateFormat('yyyy-MM-dd').format(victim.dateCommitted!)),
                  if (victim.createdAt != null)
                    _buildDetailItem('Report Date', DateFormat('yyyy-MM-dd HH:mm').format(victim.createdAt!)),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Victim Reports', style: TextStyle(color: Colors.white)),
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
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by ID or name...',
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
                        _loadVictims(refresh: true);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // ID Type Filter
                DropdownSearch<String>(
                  items: ['All', ...AppConstants.idTypes],
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Filter by ID Type",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  selectedItem: _selectedIdTypeFilter ?? 'All',
                  onChanged: (value) {
                    setState(() {
                      _selectedIdTypeFilter = value == 'All' ? null : value;
                    });
                    _loadVictims(refresh: true);
                  },
                ),
              ],
            ),
          ),
          
          // Victims List
          Expanded(
            child: _isLoading && _victims.isEmpty
                ? const Center(child: LoadingWidget())
                : _victims.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No victim reports found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadVictims(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _victims.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _victims.length) {
                              // Load more indicator
                              if (_hasMoreData) {
                                _loadVictims();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: LoadingWidget(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final victim = _victims[index];
                            return _buildVictimCard(victim);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictimCard(Victim victim) {
    return GestureDetector(
      onTap: () => _showVictimDetails(victim),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Victim Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${victim.firstName} ${victim.lastName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatIdType(victim.idType),
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
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'VICTIM',
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
              
              // Victim Details
              _buildDetailRow('ID Number', victim.idNumber),
              _buildDetailRow('Gender', victim.gender),
              if (victim.phone != null)
                _buildDetailRow('Phone', victim.phone!),
              
              const SizedBox(height: 8),
              
              // Crime Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crime Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow('Crime Type', victim.crimeType),
                    if (victim.dateCommitted != null)
                      _buildDetailRow('Date Committed', DateFormat('yyyy-MM-dd').format(victim.dateCommitted!)),
                    if (victim.createdAt != null)
                      _buildDetailRow('Reported', DateFormat('MMM dd, yyyy').format(victim.createdAt!)),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tap to view details
              Center(
                child: Text(
                  'Tap to view full details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
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
            width: 100,
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

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  bool _hasAddressInfo(Victim victim) {
    return victim.country != null ||
           victim.province != null ||
           victim.district != null ||
           victim.sector != null ||
           victim.cell != null ||
           victim.village != null ||
           victim.addressNow != null ||
           victim.addressNow != null;
  }

  String _formatIdType(String idType) {
    switch (idType) {
      case 'indangamuntu_yumunyarwanda':
        return 'Indangamuntu y\'Umunyarwanda';
      case 'indangamuntu_yumunyamahanga':
        return 'Indangamuntu y\'Umunyamahanga';
      case 'indangampunzi':
        return 'Indangampunzi';
      case 'passport':
        return 'Passport';
      default:
        return idType;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
