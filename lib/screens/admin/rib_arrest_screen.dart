import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/arrested_criminal.dart';
import '../../models/criminal_record.dart';
import '../../services/api_service.dart';
import '../../services/autofill_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import 'add_arrested_criminal_screen.dart';

class RibArrestScreen extends StatefulWidget {
  const RibArrestScreen({super.key});

  @override
  State<RibArrestScreen> createState() => _RibArrestScreenState();
}

class _RibArrestScreenState extends State<RibArrestScreen> {
  final _idNumberController = TextEditingController();
  final _arrestLocationController = TextEditingController();
  final _arrestNotesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSearching = false;
  CriminalRecord? _foundCriminal;
  String? _selectedCrimeType;
  DateTime _arrestDate = DateTime.now();

  @override
  void dispose() {
    _idNumberController.dispose();
    _arrestLocationController.dispose();
    _arrestNotesController.dispose();
    super.dispose();
  }

  Future<void> _searchCriminal() async {
    if (_idNumberController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _foundCriminal = null;
    });

    try {
      final criminal = await ApiService.searchCriminalRecord(_idNumberController.text.trim());
      
      if (criminal != null) {
        setState(() {
          _foundCriminal = criminal;
          _selectedCrimeType = criminal.crimeType;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Criminal record found'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No criminal record found with this ID'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching criminal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectArrestDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _arrestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _arrestDate = date;
      });
    }
  }

  Future<void> _processArrest() async {
    if (_foundCriminal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please search for a criminal record first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create arrested criminal record
      final arrestedCriminal = ArrestedCriminal(
        fullname: '${_foundCriminal!.firstName} ${_foundCriminal!.lastName}',
        crimeType: _selectedCrimeType ?? _foundCriminal!.crimeType,
        dateArrested: _arrestDate,
        arrestLocation: _arrestLocationController.text.trim().isEmpty 
            ? null 
            : _arrestLocationController.text.trim(),
        idType: _foundCriminal!.idType,
        idNumber: _foundCriminal!.idNumber,
        criminalRecordId: _foundCriminal!.criId,
      );

      // Add to arrested criminals
      await ApiService.addArrestedCriminal(arrestedCriminal);

      // Send news notification
      await ApiService.sendNotification({
        'near_rib': 'General Public',
        'fullname': '${_foundCriminal!.firstName} ${_foundCriminal!.lastName}',
        'address': _arrestLocationController.text.trim().isEmpty 
            ? 'Unknown Location' 
            : _arrestLocationController.text.trim(),
        'phone': _foundCriminal!.phone ?? 'Unknown',
        'message': 'BREAKING NEWS: ${_foundCriminal!.firstName} ${_foundCriminal!.lastName} has been arrested for ${_selectedCrimeType ?? _foundCriminal!.crimeType} on ${_arrestDate.day}/${_arrestDate.month}/${_arrestDate.year}. The suspect is now in custody.',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Arrest processed successfully and news sent'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reset form
        _resetForm();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing arrest: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _idNumberController.clear();
    _arrestLocationController.clear();
    _arrestNotesController.clear();
    setState(() {
      _foundCriminal = null;
      _selectedCrimeType = null;
      _arrestDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIB Arrest Processing'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddArrestedCriminalScreen(),
                ),
              );
            },
            tooltip: 'View Arrested Criminals',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Card(
                    color: Colors.purple[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.gavel,
                            size: 48,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'RIB Arrest Processing',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search criminal record and process arrest',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Criminal Search Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Criminal Search',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _idNumberController,
                                  labelText: 'ID Number',
                                  hintText: 'Enter criminal\'s ID number',
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSearching ? null : _searchCriminal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple[700],
                                  foregroundColor: Colors.white,
                                ),
                                child: _isSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Search'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Criminal Details
                  if (_foundCriminal != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red[700]),
                                const SizedBox(width: 8),
                                const Text(
                                  'Criminal Record Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            _buildDetailRow('Name', '${_foundCriminal!.firstName} ${_foundCriminal!.lastName}'),
                            _buildDetailRow('ID Number', _foundCriminal!.idNumber),
                            _buildDetailRow('Gender', _foundCriminal!.gender),
                            _buildDetailRow('Crime Type', _foundCriminal!.crimeType),
                            _buildDetailRow('Date Committed', 
                                _foundCriminal!.dateCommitted != null 
                                    ? '${_foundCriminal!.dateCommitted!.day}/${_foundCriminal!.dateCommitted!.month}/${_foundCriminal!.dateCommitted!.year}'
                                    : 'Unknown'),
                            if (_foundCriminal!.province != null)
                              _buildDetailRow('Province', _foundCriminal!.province!),
                            if (_foundCriminal!.phone != null)
                              _buildDetailRow('Phone', _foundCriminal!.phone!),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Arrest Details
                  if (_foundCriminal != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Arrest Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            DropdownSearch<String>(
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              items: AutofillService.getCommonCrimeTypes(),
                              dropdownDecoratorProps: const DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "Crime Type",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              onChanged: (value) => setState(() => _selectedCrimeType = value),
                              selectedItem: _selectedCrimeType,
                            ),
                            const SizedBox(height: 16),
                            
                            // Arrest Date
                            GestureDetector(
                              onTap: _selectArrestDate,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Arrest Date: ${_arrestDate.day}/${_arrestDate.month}/${_arrestDate.year}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _arrestLocationController,
                              labelText: 'Arrest Location',
                              hintText: 'Where was the arrest made?',
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _arrestNotesController,
                              labelText: 'Arrest Notes',
                              hintText: 'Additional details about the arrest',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Clear',
                          onPressed: _resetForm,
                          backgroundColor: Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Process Arrest',
                          onPressed: _foundCriminal == null ? null : _processArrest,
                          backgroundColor: Colors.red[700] ?? Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Process Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Search for criminal record using ID number\n'
                            '• Verify criminal details\n'
                            '• Process arrest and add to arrested criminals\n'
                            '• Send news notification to public\n'
                            '• Record will appear in news feed with image and details',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
