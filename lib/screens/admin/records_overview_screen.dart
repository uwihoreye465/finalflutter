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
          final List<Map<String, dynamic>> combinedData = [];
          
          for (var record in records) {
            final victim = record as Map<String, dynamic>;
            
            // Add victim record
            final victimFirstName = victim['first_name']?.toString() ?? 'Unknown';
            final victimLastName = victim['last_name']?.toString() ?? 'Unknown';
            combinedData.add({
              'type': 'Victim',
              'id_number': victim['id_number']?.toString() ?? 'N/A',
              'name': '$victimFirstName $victimLastName',
              'crime_type': victim['crime_type']?.toString() ?? 'Unknown',
              'date_committed': victim['date_committed']?.toString() ?? 'N/A',
              'record_id': victim['vic_id']?.toString() ?? 'N/A',
            });
            
            // Add associated criminal records
            final criminalRecords = victim['criminal_records'] as List? ?? [];
            for (var criminal in criminalRecords) {
              combinedData.add({
                'type': 'Criminal',
                'id_number': victim['id_number']?.toString() ?? 'N/A', // Same ID as victim
                'name': '$victimFirstName $victimLastName', // Same name as victim
                'crime_type': criminal['crime_type']?.toString() ?? 'Unknown',
                'date_committed': criminal['date_committed']?.toString() ?? 'N/A',
                'record_id': criminal['criminal_record_id']?.toString() ?? 'N/A',
              });
            }
          }
          
          setState(() {
            _victimsWithCriminals = combinedData;
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

    // Create a combined list of all records (victims and their criminal records)
    List<Map<String, dynamic>> allRecords = [];
    
    for (var victim in _victimsWithCriminals) {
      // Add victim record
      allRecords.add({
        'type': 'Victim',
        'id_number': victim['id_number'],
        'first_name': victim['first_name'],
        'last_name': victim['last_name'],
        'crime_type': victim['crime_type'],
        'date_committed': victim['date_committed'],
        'record_id': victim['vic_id'],
      });
      
      // Add associated criminal records
      final criminalRecords = victim['criminal_records'] as List<dynamic>? ?? [];
      for (var criminal in criminalRecords) {
        allRecords.add({
          'type': 'Criminal',
          'id_number': victim['id_number'],
          'first_name': victim['first_name'],
          'last_name': victim['last_name'],
          'crime_type': criminal['crime_type'],
          'date_committed': criminal['date_committed'],
          'record_id': criminal['criminal_record_id'],
        });
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('ID Number')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Crime Type')),
          DataColumn(label: Text('Date Committed')),
          DataColumn(label: Text('Record ID')),
        ],
        rows: allRecords.map((record) {
          final isVictim = record['type'] == 'Victim';
          return DataRow(
            cells: [
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVictim 
                        ? AppColors.warningColor.withOpacity(0.1)
                        : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVictim 
                          ? AppColors.warningColor.withOpacity(0.3)
                          : AppColors.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    record['type'],
                    style: TextStyle(
                      color: isVictim ? AppColors.warningColor : AppColors.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(record['id_number'] ?? 'N/A')),
              DataCell(Text('${record['first_name']} ${record['last_name']}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVictim 
                        ? AppColors.warningColor.withOpacity(0.1)
                        : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isVictim 
                          ? AppColors.warningColor.withOpacity(0.3)
                          : AppColors.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    record['crime_type'] ?? 'N/A',
                    style: TextStyle(
                      color: isVictim ? AppColors.warningColor : AppColors.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(Text(
                record['date_committed'] != null
                    ? DateTime.parse(record['date_committed']).toString().split(' ')[0]
                    : 'N/A',
              )),
              DataCell(Text(record['record_id']?.toString() ?? 'N/A')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
