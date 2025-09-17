import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../services/autofill_service.dart';
import '../../models/criminal_record.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class ManageCriminalRecordsScreen extends StatefulWidget {
  const ManageCriminalRecordsScreen({super.key});

  @override
  State<ManageCriminalRecordsScreen> createState() => _ManageCriminalRecordsScreenState();
}

class _ManageCriminalRecordsScreenState extends State<ManageCriminalRecordsScreen> {
  List<CriminalRecord> _criminalRecords = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIdTypeFilter;

  // Add criminal record form controllers
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressNowController = TextEditingController();
  final _crimeTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedIdType;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateCommitted;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCriminalRecords();
  }

  Future<void> _loadCriminalRecords({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _criminalRecords = [];
        _hasMoreData = true;
        _isLoading = true;
      });
    }

    try {
      final response = await ApiService.getCriminalRecords(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        idType: _selectedIdTypeFilter,
      );

      final List<CriminalRecord> newRecords = (response['data'] as List)
          .map((json) => CriminalRecord.fromJson(json))
          .toList();

      setState(() {
        if (refresh) {
          _criminalRecords = newRecords;
        } else {
          _criminalRecords.addAll(newRecords);
        }
        _hasMoreData = newRecords.length == _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorToast('Error loading criminal records: ${e.toString()}');
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isDateOfBirth}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _selectedDateOfBirth = picked;
        } else {
          _selectedDateCommitted = picked;
        }
      });
    }
  }

  Future<void> _searchAndAutofill(String idNumber) async {
    try {
      final citizen = await AutofillService.searchRwandanCitizen(idNumber);
      if (citizen != null) {
        setState(() {
          _firstNameController.text = citizen.firstName;
          _lastNameController.text = citizen.lastName;
          _selectedGender = citizen.gender;
          _selectedDateOfBirth = citizen.dateOfBirth;
          _selectedMaritalStatus = citizen.maritalStatus;
          _provinceController.text = citizen.province ?? '';
          _districtController.text = citizen.district ?? '';
          _sectorController.text = citizen.sector ?? '';
          _cellController.text = citizen.cell ?? '';
          _villageController.text = citizen.village ?? '';
          _addressNowController.text = citizen.phone ?? '';
        });
        
        Fluttertoast.showToast(
          msg: 'Citizen data found and auto-filled',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'No citizen data found for this ID',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error searching citizen data: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> _addCriminalRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final criminalRecord = CriminalRecord(
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender!,
        dateOfBirth: _selectedDateOfBirth,
        maritalStatus: _selectedMaritalStatus,
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        sector: _sectorController.text.trim().isEmpty ? null : _sectorController.text.trim(),
        cell: _cellController.text.trim().isEmpty ? null : _cellController.text.trim(),
        village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
        addressNow: _addressNowController.text.trim().isEmpty ? null : _addressNowController.text.trim(),
        crimeType: _crimeTypeController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        dateCommitted: _selectedDateCommitted,
      );

      await ApiService.addCriminalRecord(criminalRecord);
      
      Fluttertoast.showToast(
        msg: "Criminal record added successfully!",
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      
      _clearForm();
      _loadCriminalRecords(refresh: true);
      
    } catch (e) {
      _showErrorToast('Error adding criminal record: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _idNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _countryController.clear();
    _provinceController.clear();
    _districtController.clear();
    _sectorController.clear();
    _cellController.clear();
    _villageController.clear();
    _addressNowController.clear();
    _crimeTypeController.clear();
    _descriptionController.clear();
    
    setState(() {
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = null;
    });
  }

  void _showAddCriminalRecordDialog() {
    // showDialog(
    //   context: context,
    //   isScrollControlled: true,

    //   builder: (BuildContext context) {
    showDialog(
  context: context,
  builder: (BuildContext context) {
    // ... rest of the code
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Criminal Record'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.7,
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ID Type Selection
                        DropdownSearch<String>(
                          popupProps: const PopupProps.menu(showSearchBox: true),
                          items: AppConstants.idTypes,
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Select ID Type",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() => _selectedIdType = value);
                          },
                          selectedItem: _selectedIdType,
                          validator: (value) => value == null ? 'Please select ID type' : null,
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // ID Number with autofill
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _idNumberController,
                                hintText: 'Enter ID Number',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter ID number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (value.length >= 8) {
                                    _searchAndAutofill(value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (_idNumberController.text.isNotEmpty) {
                                  _searchAndAutofill(_idNumberController.text);
                                }
                              },
                              child: const Text('Search'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // First Name
                        CustomTextField(
                          controller: _firstNameController,
                          hintText: 'Enter First Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter first name';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Last Name
                        CustomTextField(
                          controller: _lastNameController,
                          hintText: 'Enter Last Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter last name';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Gender
                        DropdownSearch<String>(
                          items: AppConstants.genderOptions,
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Select Gender",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() => _selectedGender = value);
                          },
                          selectedItem: _selectedGender,
                          validator: (value) => value == null ? 'Please select gender' : null,
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Date of Birth
                        GestureDetector(
                          onTap: () => _selectDate(context, isDateOfBirth: true),
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
                                    _selectedDateOfBirth != null
                                        ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
                                        : 'Select Date of Birth',
                                    style: TextStyle(
                                      color: _selectedDateOfBirth != null ? Colors.black : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Icon(Icons.calendar_today, color: Colors.grey[600]),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Marital Status
                        DropdownSearch<String>(
                          items: AppConstants.maritalStatusOptions,
                          dropdownDecoratorProps: const DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Marital Status",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() => _selectedMaritalStatus = value);
                          },
                          selectedItem: _selectedMaritalStatus,
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Address Fields based on ID Type
                        if (_selectedIdType == 'passport') ...[
                          CustomTextField(
                            controller: _countryController,
                            hintText: 'Enter Country',
                          ),
                          const SizedBox(height: 15),
                        ] else ...[
                          DropdownSearch<String>(
                            items: AppConstants.provinces,
                            dropdownDecoratorProps: const DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: "Province",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            onChanged: (value) {
                              _provinceController.text = value ?? '';
                            },
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            controller: _districtController,
                            hintText: 'Enter District',
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            controller: _sectorController,
                            hintText: 'Enter Sector',
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            controller: _cellController,
                            hintText: 'Enter Cell',
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            controller: _villageController,
                            hintText: 'Enter Village',
                          ),
                          const SizedBox(height: 15),
                        ],
                        
                        // Current Address
                        CustomTextField(
                          controller: _addressNowController,
                          hintText: 'Enter Current Address',
                          maxLines: 2,
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
                        
                        // Description
                        CustomTextField(
                          controller: _descriptionController,
                          hintText: 'Enter Crime Description',
                          maxLines: 3,
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Date Committed
 GestureDetector(
  onTap: () => _selectDate(context, isDateOfBirth: false),
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
            _selectedDateCommitted != null
                ? DateFormat('yyyy-MM-dd').format(_selectedDateCommitted!)
                : 'Select Crime Date',
            style: TextStyle(
              color: _selectedDateCommitted != null ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
        Icon(Icons.calendar_today, color: Colors.grey[600]),
      ],
    ),
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
                      await _addCriminalRecord();
                      setDialogState(() {
                        _isSubmitting = false;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successColor,
                    ),
                    child: const Text('Add Record', style: TextStyle(color: Colors.white)),
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
        title: const Text('Criminal Records', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCriminalRecordDialog,
          ),
        ],
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
                        _loadCriminalRecords(refresh: true);
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
                    _loadCriminalRecords(refresh: true);
                  },
                ),
              ],
            ),
          ),
          
          // Criminal Records List
          Expanded(
            child: _isLoading && _criminalRecords.isEmpty
                ? const Center(child: LoadingWidget())
                : _criminalRecords.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No criminal records found',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadCriminalRecords(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _criminalRecords.length + (_hasMoreData ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _criminalRecords.length) {
                              // Load more indicator
                              if (_hasMoreData) {
                                _loadCriminalRecords();
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: LoadingWidget(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }

                            final record = _criminalRecords[index];
                            return _buildCriminalRecordCard(record);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCriminalRecordDialog,
        backgroundColor: AppColors.errorColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCriminalRecordCard(CriminalRecord record) {
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
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Record Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${record.firstName} ${record.lastName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatIdType(record.idType),
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
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CRIMINAL',
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
            
            // Record Details
            _buildDetailRow('ID Number', record.idNumber),
            _buildDetailRow('Gender', record.gender),
            if (record.dateOfBirth != null)
              _buildDetailRow('Date of Birth', DateFormat('yyyy-MM-dd').format(record.dateOfBirth!)),
            
            // Address Information
            if (_hasAddressInfo(record)) ...[
              const SizedBox(height: 8),
              const Text(
                'Address Information:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              if (record.country != null)
                _buildDetailRow('Country', record.country!),
              if (record.province != null)
                _buildDetailRow('Province', record.province!),
              if (record.district != null)
                _buildDetailRow('District', record.district!),
              if (record.addressNow != null)
                _buildDetailRow('Current Address', record.addressNow!),
            ],
            
            const SizedBox(height: 8),
            
            // Crime Information
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crime Information:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDetailRow('Crime Type', record.crimeType),
                  if (record.description != null)
                    _buildDetailRow('Description', record.description!),
                  if (record.dateCommitted != null)
                    _buildDetailRow('Date Committed', DateFormat('yyyy-MM-dd').format(record.dateCommitted!)),
                  if (record.createdAt != null)
                    _buildDetailRow('Record Created', DateFormat('yyyy-MM-dd HH:mm').format(record.createdAt!)),
                ],
              ),
            ),
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

  bool _hasAddressInfo(CriminalRecord record) {
    return record.country != null ||
           record.province != null ||
           record.district != null ||
           record.sector != null ||
           record.cell != null ||
           record.village != null ||
           record.addressNow != null;
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
    _idNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _villageController.dispose();
    _addressNowController.dispose();
    _crimeTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}