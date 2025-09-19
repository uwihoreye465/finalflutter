import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/arrested_criminal.dart';
import '../../models/criminal_record.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ManageArrestedCriminalsScreen extends StatefulWidget {
  const ManageArrestedCriminalsScreen({super.key});

  @override
  State<ManageArrestedCriminalsScreen> createState() => _ManageArrestedCriminalsScreenState();
}

class _ManageArrestedCriminalsScreenState extends State<ManageArrestedCriminalsScreen> {
  List<ArrestedCriminal> _arrestedCriminals = [];
  List<CriminalRecord> _criminalRecords = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

  // Add arrested criminal form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _crimeTypeController = TextEditingController();
  final _arrestLocationController = TextEditingController();
  final _idNumberController = TextEditingController();
  
  String? _selectedIdType;
  DateTime? _selectedDateArrested;
  bool _isSubmitting = false;
  int? _selectedCriminalRecordId;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadArrestedCriminals();
    _loadCriminalRecords();
  }

  Future<void> _loadArrestedCriminals({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _arrestedCriminals = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getArrestedCriminals(
        page: _currentPage,
        limit: _itemsPerPage,
      );

      final List<ArrestedCriminal> newCriminals = (response['data']['records'] as List)
          .map((json) => ArrestedCriminal.fromJson(json))
          .toList();

      setState(() {
        if (refresh) {
          _arrestedCriminals = newCriminals;
        } else {
          _arrestedCriminals.addAll(newCriminals);
        }
        _hasMoreData = newCriminals.length == _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading arrested criminals: ${e.toString()}');
    }
  }

  Future<void> _loadCriminalRecords() async {
    try {
      final response = await ApiService.getCriminalRecords(limit: 100); // Get all records
      final List<CriminalRecord> records = (response['data'] as List)
          .map((json) => CriminalRecord.fromJson(json))
          .toList();

      setState(() {
        _criminalRecords = records;
      });
    } catch (e) {
      debugPrint('Error loading criminal records: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateArrested = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorToast('Error picking image: $e');
    }
  }

  Future<void> _addArrestedCriminal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await ApiService.uploadImage(_selectedImage!);
        } catch (e) {
          // If image upload fails, continue without image
          debugPrint('Image upload failed: $e');
          _showErrorToast('Image upload failed, continuing without image');
        }
      }

      final arrestedCriminal = ArrestedCriminal(
        fullname: _fullnameController.text.trim(),
        imageUrl: imageUrl,
        crimeType: _crimeTypeController.text.trim(),
        dateArrested: _selectedDateArrested ?? DateTime.now(),
        arrestLocation: _arrestLocationController.text.trim().isEmpty 
            ? null 
            : _arrestLocationController.text.trim(),
        idType: _selectedIdType,
        idNumber: _idNumberController.text.trim().isEmpty 
            ? null 
            : _idNumberController.text.trim(),
        criminalRecordId: _selectedCriminalRecordId,
      );

      await ApiService.addArrestedCriminal(arrestedCriminal);
      
      Fluttertoast.showToast(
        msg: "Arrested criminal record added successfully! This will appear in the news.",
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      
      _clearForm();
      _loadArrestedCriminals(refresh: true);
      
    } catch (e) {
      _showErrorToast('Error adding arrested criminal: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _fullnameController.clear();
    _crimeTypeController.clear();
    _arrestLocationController.clear();
    _idNumberController.clear();
    
    setState(() {
      _selectedIdType = null;
      _selectedDateArrested = null;
      _selectedCriminalRecordId = null;
      _selectedImage = null;
    });
  }

  void _showAddArrestedCriminalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Arrested Criminal'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Link to existing criminal record
                        if (_criminalRecords.isNotEmpty) ...[
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: "Link to Criminal Record (Optional)",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedCriminalRecordId,
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('No link'),
                              ),
                              ..._criminalRecords.map((record) {
                                return DropdownMenuItem<int>(
                                  value: record.criId,
                                  child: Text('${record.firstName} ${record.lastName} - ${record.crimeType}'),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                _selectedCriminalRecordId = value;
                                if (value != null) {
                                  final record = _criminalRecords.firstWhere((r) => r.criId == value);
                                  _fullnameController.text = '${record.firstName} ${record.lastName}';
                                  _crimeTypeController.text = record.crimeType;
                                  _idNumberController.text = record.idNumber;
                                  _selectedIdType = record.idType;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                        ],
                        
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
                        
                        // Crime Type
                        CustomTextField(
                          controller: _crimeTypeController,
                          hintText: 'Enter Crime Type',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter crime type';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Date Arrested
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedDateArrested != null
                                        ? DateFormat('yyyy-MM-dd').format(_selectedDateArrested!)
                                        : 'Select Arrest Date',
                                    style: TextStyle(
                                      color: _selectedDateArrested != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Arrest Location
                        CustomTextField(
                          controller: _arrestLocationController,
                          hintText: 'Enter Arrest Location',
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // ID Type
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "ID Type (Optional)",
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedIdType,
                          items: AppConstants.idTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              _selectedIdType = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // ID Number
                        CustomTextField(
                          controller: _idNumberController,
                          hintText: 'Enter ID Number (Optional)',
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Image Selection
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_selectedImage != null) ...[
                                // Note: Image.file is not supported on Flutter Web
                                // For web compatibility, you would need to use Image.network
                                // or implement a proper file upload solution
                                Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(_selectedImage != null ? 'Change Photo' : 'Add Photo'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Photo will be displayed in news alerts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      await _addArrestedCriminal();
                      setDialogState(() {
                        _isSubmitting = false;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Add to News', style: TextStyle(color: Colors.white)),
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
        title: const Text('Manage Arrested Criminals', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddArrestedCriminalDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Arrested criminals added here will appear in the News section for public viewing.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search arrested criminals...',
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
                    _loadArrestedCriminals(refresh: true);
                  }
                });
              },
            ),
          ),
          
          // Arrested Criminals List
          Expanded(
            child: _isLoading && _arrestedCriminals.isEmpty
                ? const Center(child: LoadingWidget())
                : _arrestedCriminals.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No arrested criminals found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add criminals who have been arrested to show in news',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadArrestedCriminals(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _arrestedCriminals.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _arrestedCriminals.length) {
                              // Load more indicator
                              if (_hasMoreData) {
                                _loadArrestedCriminals();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: LoadingWidget(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final criminal = _arrestedCriminals[index];
                            return _buildArrestedCriminalCard(criminal);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddArrestedCriminalDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildArrestedCriminalCard(ArrestedCriminal criminal) {
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
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo or placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: criminal.imageUrl != null && criminal.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        criminal.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.grey[600], size: 30);
                        },
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey[600], size: 30),
            ),
            
            const SizedBox(width: 16),
            
            // Criminal details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    criminal.fullname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    criminal.crimeType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arrested: ${DateFormat('MMM dd, yyyy').format(criminal.dateArrested)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (criminal.arrestLocation != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Location: ${criminal.arrestLocation}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ARRESTED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullnameController.dispose();
    _crimeTypeController.dispose();
    _arrestLocationController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }
}
