import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';

class RecordsOverviewScreen extends StatefulWidget {
  const RecordsOverviewScreen({Key? key}) : super(key: key);

  @override
  State<RecordsOverviewScreen> createState() => _RecordsOverviewScreenState();
}

class _RecordsOverviewScreenState extends State<RecordsOverviewScreen> {
  List<Map<String, dynamic>> _victimsWithCriminals = [];
  bool _isLoading = true;
  String _selectedTab = 'victims';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the correct API endpoint
      final response = await http.get(
        Uri.parse('https://tracking-criminal.onrender.com/api/v1/victim-criminal/victims-with-criminal-records'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> records = data['data'] as List;
          
          // Keep the original victim data structure with criminal records intact
          List<Map<String, dynamic>> victimData = [];
          
          for (var record in records) {
            final victim = record as Map<String, dynamic>;
            // Add the victim data as-is, keeping criminal_records intact
            victimData.add(victim);
          }
          
          debugPrint('Loaded ${victimData.length} victims with criminal records');
          for (var victim in victimData) {
            final criminalRecords = victim['criminal_records'] as List? ?? [];
            debugPrint('Victim ${victim['first_name']} has ${criminalRecords.length} criminal records');
          }
          
          setState(() {
            _victimsWithCriminals = victimData;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load data: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading data: ${e.toString()}');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ',
      };
    }
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppColors.errorColor,
      textColor: Colors.white,
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: AppColors.successColor,
      textColor: Colors.white,
    );
  }

  Future<void> _deleteRecord(int recordId) async {
    try {
      debugPrint('Attempting to delete record with ID: $recordId');
      
      // Try to delete the victim record first
      final response = await ApiService.deleteVictimCriminalRecord(recordId);
      debugPrint('Delete response: $response');
      
      if (response['success'] == true) {
        _showSuccessToast('✅ Victim and all associated criminal records deleted successfully');
        _loadData(); // Reload the data
      } else {
        debugPrint('Primary delete failed, trying alternative method...');
        // Try alternative delete method
        try {
          final success = await ApiService.deleteVictim(recordId);
          if (success) {
            _showSuccessToast('✅ Victim record deleted successfully');
            _loadData(); // Reload the data
          } else {
            _showErrorToast('❌ Unable to delete: Record ID not found or already deleted');
          }
        } catch (e2) {
          debugPrint('Alternative delete also failed: $e2');
          _showErrorToast('❌ Unable to delete: Record ID not found');
        }
      }
    } catch (e) {
      debugPrint('Error deleting record: $e');
      _showErrorToast('❌ Unable to delete: Record ID not found');
    }
  }

  void _showDeleteConfirmation(int recordId, String recordName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Victim & Criminal Records'),
          content: Text('Are you sure you want to delete the victim "$recordName" and ALL associated criminal records? This action cannot be undone and will permanently remove all data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecord(recordId);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorColor,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Records Overview'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCombinedRecordsTable(),
    );
  }

  Widget _buildCombinedRecordsTable() {
    if (_victimsWithCriminals.isEmpty) {
      return const Center(
        child: Text('No records found'),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.table_chart, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Records Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Records as Combined Boxes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _victimsWithCriminals.length,
            itemBuilder: (context, index) {
              final victimData = _victimsWithCriminals[index];
              return _buildVictimCriminalBox(victimData);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVictimCriminalBox(Map<String, dynamic> victimData) {
    final victimName = '${victimData['first_name'] ?? ''} ${victimData['last_name'] ?? ''}'.trim();
    final victimId = victimData['id_number'] ?? 'N/A';
    final victimCrimeType = victimData['crime_type'] ?? 'N/A';
    final victimDateCommitted = victimData['date_committed'] != null
        ? DateTime.parse(victimData['date_committed']).toString().split(' ')[0]
        : 'N/A';
    final victimRegisteredBy = victimData['registered_by']?.toString() ?? 'N/A';
    final criminalRecords = victimData['criminal_records'] as List<dynamic>? ?? [];
    
    // Debug logging
    debugPrint('Building victim box for: $victimName');
    debugPrint('Criminal records count: ${criminalRecords.length}');
    debugPrint('Criminal records: $criminalRecords');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Crime Type and Delete Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.gavel, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crime Type: $victimCrimeType',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Victim Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warningColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: AppColors.warningColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'VICTIM',
                        style: TextStyle(
                          color: AppColors.warningColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('ID Number', victimId, Icons.badge),
                  _buildDetailRow('Name', victimName, Icons.person_outline),
                  _buildDetailRow('Date Committed', victimDateCommitted, Icons.calendar_today),
                  _buildDetailRow('Registered By', victimRegisteredBy, Icons.admin_panel_settings),
                ],
              ),
            ),
            
            // Criminal Records Section
            if (criminalRecords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: AppColors.errorColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'CRIMINAL RECORDS',
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...criminalRecords.map((criminal) {
                      final criminalId = criminal['criminal_record_id']?.toString() ?? 'N/A';
                      final criminalName = '${criminal['first_name'] ?? ''} ${criminal['last_name'] ?? ''}'.trim();
                      final criminalIdNumber = criminal['id_number']?.toString() ?? 'N/A';
                      final criminalCrimeType = criminal['crime_type'] ?? 'N/A';
                      final criminalDateCommitted = criminal['date_committed'] != null
                          ? DateTime.parse(criminal['date_committed']).toString().split(' ')[0]
                          : 'N/A';
                      final criminalRegisteredBy = criminal['registered_by']?.toString() ?? 'N/A';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.errorColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Criminal Record',
                              style: TextStyle(
                                color: AppColors.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Criminal ID', criminalId, Icons.badge),
                            _buildDetailRow('ID Number', criminalIdNumber, Icons.credit_card),
                            _buildDetailRow('Name', criminalName, Icons.person_outline),
                            _buildDetailRow('Crime Type', criminalCrimeType, Icons.gavel),
                            _buildDetailRow('Date Committed', criminalDateCommitted, Icons.calendar_today),
                            _buildDetailRow('Registered By', criminalRegisteredBy, Icons.admin_panel_settings),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'No criminal records associated with this victim',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOldDataTable() {
    // This is the old DataTable implementation - keeping for reference
    List<Map<String, dynamic>> allRecords = _victimsWithCriminals;

    return Card(
      elevation: 4,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(
              label: Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'ID Number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'Crime Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'Date Committed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'Record ID',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            DataColumn(
              label: Text(
                'Registered By',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
          rows: allRecords.map((record) {
            final isVictim = record['type'] == 'Victim';
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return Colors.grey.withOpacity(0.1);
                  }
                  return null;
                },
              ),
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isVictim 
                          ? AppColors.warningColor.withOpacity(0.1)
                          : AppColors.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isVictim 
                            ? AppColors.warningColor.withOpacity(0.5)
                            : AppColors.errorColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVictim ? Icons.person : Icons.gavel,
                          size: 16,
                          color: isVictim ? AppColors.warningColor : AppColors.errorColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          record['type'],
                          style: TextStyle(
                            color: isVictim ? AppColors.warningColor : AppColors.errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record['id_number'] ?? 'N/A',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    record['name'] ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      record['crime_type'] ?? 'N/A',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record['date_committed'] != null
                          ? DateTime.parse(record['date_committed']).toString().split(' ')[0]
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    record['record_id']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    record['registered_by']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
