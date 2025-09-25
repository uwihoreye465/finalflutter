import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../models/criminal_record.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../user/enhanced_report_screen.dart';

class EnhancedCriminalManagementScreen extends StatefulWidget {
  const EnhancedCriminalManagementScreen({super.key});

  @override
  State<EnhancedCriminalManagementScreen> createState() => _EnhancedCriminalManagementScreenState();
}

class _EnhancedCriminalManagementScreenState extends State<EnhancedCriminalManagementScreen> {
    List<CriminalRecord> _criminalRecords = [];
    List<CriminalRecord> _filteredRecords = [];
    bool _isLoading = true;
    int _currentPage = 1;
    bool _hasMoreData = true;
    final int _itemsPerPage = 20;
    final TextEditingController _searchController = TextEditingController();
    String? _selectedIdTypeFilter;
    String? _selectedGenderFilter;
    String? _selectedMaritalStatusFilter;

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
    final _phoneController = TextEditingController();
    final _crimeTypeController = TextEditingController();
    final _descriptionController = TextEditingController();
    
    String? _selectedIdType;
    String? _selectedGender;
    String? _selectedMaritalStatus;
    String? _selectedCrimeType;
    DateTime? _selectedDateOfBirth;
    DateTime? _selectedDateCommitted;
    bool _isSubmitting = false;
    bool _isEditMode = false;
    CriminalRecord? _editingRecord;

    // Crime types list
    final List<String> _crimeTypes = [
      'Theft',
      'Assault',
      'Battery',
      'Robbery',
      'Burglary',
      'Fraud',
      'Drug Possession',
      'Drug Trafficking',
      'Domestic Violence',
      'Sexual Assault',
      'Murder',
      'Manslaughter',
      'Kidnapping',
      'Arson',
      'Vandalism',
      'Trespassing',
      'Embezzlement',
      'Money Laundering',
      'Cyber Crime',
      'Terrorism',
      'Other'
    ];

    @override
    void initState() {
      super.initState();
      _loadCriminalRecords();
      _searchController.addListener(_onSearchChanged);
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
      _phoneController.dispose();
      _crimeTypeController.dispose();
      _descriptionController.dispose();
      super.dispose();
    }

    void _onSearchChanged() {
      _applyFilters();
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
        );

        final List<CriminalRecord> newRecords = ((response['data']['criminalRecords'] as List?) ?? (response['data'] as List))
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
        
        _applyFilters();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error loading criminal records: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }

    void _applyFilters() {
      setState(() {
        _filteredRecords = _criminalRecords.where((record) {
          // Search filter
          if (_searchController.text.isNotEmpty) {
            final searchTerm = _searchController.text.toLowerCase();
            if (!record.firstName.toLowerCase().contains(searchTerm) &&
                !record.lastName.toLowerCase().contains(searchTerm) &&
                !record.idNumber.toLowerCase().contains(searchTerm) &&
                !record.crimeType.toLowerCase().contains(searchTerm)) {
              return false;
            }
          }

          // ID Type filter
          if (_selectedIdTypeFilter != null && _selectedIdTypeFilter != 'All') {
            if (record.idType != _selectedIdTypeFilter) {
              return false;
            }
          }

          // Gender filter
          if (_selectedGenderFilter != null && _selectedGenderFilter != 'All') {
            if (record.gender != _selectedGenderFilter) {
              return false;
            }
          }

          // Marital Status filter
          if (_selectedMaritalStatusFilter != null && _selectedMaritalStatusFilter != 'All') {
            if (record.maritalStatus != _selectedMaritalStatusFilter) {
              return false;
            }
          }

          return true;
        }).toList();
      });
    }

    Future<void> _searchAndAutofill(String idNumber) async {
      if (idNumber.length < 8) return;

      try {
        final response = await ApiService.searchPersonData(idNumber);
        
        if (response != null && response['success'] == true) {
          final data = response['data'];
          final personType = data['personType'];
          final person = data['person'];
          
          if (personType == 'citizen') {
            _firstNameController.text = person['first_name'] ?? '';
            _lastNameController.text = person['last_name'] ?? '';
            _selectedGender = person['gender'];
            _selectedDateOfBirth = person['date_of_birth'] != null 
                ? DateTime.parse(person['date_of_birth']) 
                : null;
            _selectedMaritalStatus = person['marital_status'];
            _provinceController.text = person['province'] ?? '';
            _districtController.text = person['district'] ?? '';
            _sectorController.text = person['sector'] ?? '';
            _cellController.text = person['cell'] ?? '';
            _villageController.text = person['village'] ?? '';
            _phoneController.text = person['phone'] ?? '';
            _selectedIdType = person['id_type'];
            
          } else if (personType == 'passport') {
            _firstNameController.text = person['first_name'] ?? '';
            _lastNameController.text = person['last_name'] ?? '';
            _selectedGender = person['gender'];
            _selectedDateOfBirth = person['date_of_birth'] != null 
                ? DateTime.parse(person['date_of_birth']) 
                : null;
            _selectedMaritalStatus = person['marital_status'];
            _countryController.text = person['nationality'] ?? '';
            _addressNowController.text = person['address_in_rwanda'] ?? '';
            _phoneController.text = person['phone'] ?? '';
            _selectedIdType = 'passport';
          }
          
          Fluttertoast.showToast(
            msg: 'Data auto-filled from NIDA records',
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'No data found for this ID number',
            backgroundColor: AppColors.warningColor,
            textColor: Colors.white,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error searching data: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }

    Future<void> _submitCriminalRecord() async {
      if (!_formKey.currentState!.validate()) {
        Fluttertoast.showToast(
          msg: "Please fill in all required fields",
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
        return;
      }

      if (_selectedIdType == null || _selectedGender == null || _selectedMaritalStatus == null || _selectedDateCommitted == null) {
        Fluttertoast.showToast(
          msg: "Please fill in all required fields",
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final criminalRecord = CriminalRecord(
          criId: _isEditMode ? _editingRecord!.criId : null,
          citizenId: _selectedIdType != 'passport' ? 1 : null, // This should be determined from autofill
          passportHolderId: _selectedIdType == 'passport' ? 1 : null, // This should be determined from autofill
          idType: _selectedIdType!,
          idNumber: _idNumberController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          gender: _selectedGender!,
          dateOfBirth: _selectedDateOfBirth,
          maritalStatus: _selectedMaritalStatus!,
          country: _selectedIdType == 'passport' ? (_countryController.text.trim().isEmpty ? null : _countryController.text.trim()) : null,
          province: _selectedIdType == 'passport' ? null : (_provinceController.text.trim().isEmpty ? null : _provinceController.text.trim()),
          district: _selectedIdType == 'passport' ? null : (_districtController.text.trim().isEmpty ? null : _districtController.text.trim()),
          sector: _selectedIdType == 'passport' ? null : (_sectorController.text.trim().isEmpty ? null : _sectorController.text.trim()),
          cell: _selectedIdType == 'passport' ? null : (_cellController.text.trim().isEmpty ? null : _cellController.text.trim()),
          village: _selectedIdType == 'passport' ? null : (_villageController.text.trim().isEmpty ? null : _villageController.text.trim()),
          addressNow: _addressNowController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          crimeType: _selectedCrimeType ?? '',
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          dateCommitted: _selectedDateCommitted!,
        );

        if (_isEditMode) {
          await ApiService.updateCriminalRecord(_editingRecord!.criId!, criminalRecord);
          Fluttertoast.showToast(
            msg: "Criminal record updated successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
        } else {
          await ApiService.addCriminalRecord(criminalRecord);
          Fluttertoast.showToast(
            msg: "Criminal record added successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
        }
        
        _clearForm();
        _loadCriminalRecords(refresh: true);
        
        // Close the dialog after successful operation
        Navigator.of(context).pop();
        
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error ${_isEditMode ? 'updating' : 'adding'} criminal record: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    Future<void> _deleteCriminalRecord(CriminalRecord record) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Criminal Record'),
          content: Text('Are you sure you want to delete the criminal record for ${record.firstName} ${record.lastName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await ApiService.deleteCriminalRecord(record.criId!);
          Fluttertoast.showToast(
            msg: "Criminal record deleted successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
          _loadCriminalRecords(refresh: true);
        } catch (e) {
          Fluttertoast.showToast(
            msg: 'Error deleting criminal record: ${e.toString()}',
            backgroundColor: AppColors.errorColor,
            textColor: Colors.white,
          );
        }
      }
    }

    void _editCriminalRecord(CriminalRecord record) {
      setState(() {
        _isEditMode = true;
        _editingRecord = record;
        _idNumberController.text = record.idNumber;
        _firstNameController.text = record.firstName;
        _lastNameController.text = record.lastName;
        _selectedGender = record.gender;
        _selectedDateOfBirth = record.dateOfBirth;
        _selectedMaritalStatus = record.maritalStatus;
        _selectedIdType = record.idType;
        _countryController.text = record.country ?? '';
        _provinceController.text = record.province ?? '';
        _districtController.text = record.district ?? '';
        _sectorController.text = record.sector ?? '';
        _cellController.text = record.cell ?? '';
        _villageController.text = record.village ?? '';
        _addressNowController.text = record.addressNow ?? '';
        _phoneController.text = record.phone ?? '';
        _selectedCrimeType = record.crimeType;
        _descriptionController.text = record.description ?? '';
        _selectedDateCommitted = record.dateCommitted;
      });
      
      _showAddCriminalDialog();
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
      _phoneController.clear();
      _descriptionController.clear();
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedCrimeType = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = null;
      _isEditMode = false;
      _editingRecord = null;
    }

    void _showAddCriminalDialog() {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(_isEditMode ? 'Edit Criminal Record' : 'Add Criminal Record'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ID Type
                      DropdownSearch<String>(
                        popupProps: const PopupProps.menu(showSearchBox: true),
                        items: AppConstants.idTypes,
                        selectedItem: _selectedIdType,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedIdType = value;
                          });
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                          labelText: "ID Type *",
                          border: OutlineInputBorder(),
                          ),
                        ),
                        validator: (value) => value == null ? "Please select ID type" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // ID Number
                      CustomTextField(
                        controller: _idNumberController,
                        hintText: 'Enter ID Number',
                        label: 'ID Number *',
                        onChanged: (value) {
                          if (value.length >= 8) {
                            _searchAndAutofill(value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ID number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // First Name
                      CustomTextField(
                        controller: _firstNameController,
                        hintText: 'Enter First Name',
                        label: 'First Name *',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Last Name
                      CustomTextField(
                        controller: _lastNameController,
                        hintText: 'Enter Last Name',
                        label: 'Last Name *',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Gender
                      DropdownSearch<String>(
                        popupProps: const PopupProps.menu(showSearchBox: true),
                        items: AppConstants.genderOptions,
                        selectedItem: _selectedGender,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedGender = value;
                          });
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                          labelText: "Gender *",
                          border: OutlineInputBorder(),
                          ),
                        ),
                        validator: (value) => value == null ? "Please select gender" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Date of Birth
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedDateOfBirth = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDateOfBirth != null
                                    ? DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!)
                                    : 'Select Date of Birth',
                                style: TextStyle(
                                  color: _selectedDateOfBirth != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Marital Status
                      DropdownSearch<String>(
                        popupProps: const PopupProps.menu(showSearchBox: true),
                        items: AppConstants.maritalStatusOptions,
                        selectedItem: _selectedMaritalStatus,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedMaritalStatus = value;
                          });
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                          labelText: "Marital Status *",
                          border: OutlineInputBorder(),
                          ),
                        ),
                        validator: (value) => value == null ? "Please select marital status" : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Conditional fields based on ID type
                      if (_selectedIdType == 'passport') ...[
                        // Country
                        CustomTextField(
                          controller: _countryController,
                          hintText: 'Enter Country',
                          label: 'Country',
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Province
                        CustomTextField(
                          controller: _provinceController,
                          hintText: 'Enter Province',
                          label: 'Province',
                        ),
                        const SizedBox(height: 16),
                        
                        // District
                        CustomTextField(
                          controller: _districtController,
                          hintText: 'Enter District',
                          label: 'District',
                        ),
                        const SizedBox(height: 16),
                        
                        // Sector
                        CustomTextField(
                          controller: _sectorController,
                          hintText: 'Enter Sector',
                          label: 'Sector',
                        ),
                        const SizedBox(height: 16),
                        
                        // Cell
                        CustomTextField(
                          controller: _cellController,
                          hintText: 'Enter Cell',
                          label: 'Cell',
                        ),
                        const SizedBox(height: 16),
                        
                        // Village
                        CustomTextField(
                          controller: _villageController,
                          hintText: 'Enter Village',
                          label: 'Village',
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Current Address
                      CustomTextField(
                        controller: _addressNowController,
                        hintText: 'Enter Current Address',
                        label: 'Current Address *',
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter current address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter Phone Number',
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      
                      // Crime Type
                      DropdownButtonFormField<String>(
                        value: _selectedCrimeType,
                        decoration: const InputDecoration(
                          labelText: 'Crime Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: _crimeTypes.map((String crimeType) {
                          return DropdownMenuItem<String>(
                            value: crimeType,
                            child: Text(crimeType),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCrimeType = newValue;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select crime type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Enter Description',
                        label: 'Description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Date Committed
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDateCommitted ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              _selectedDateCommitted = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDateCommitted != null
                                    ? DateFormat('yyyy-MM-dd').format(_selectedDateCommitted!)
                                    : 'Select Date Committed *',
                                style: TextStyle(
                                  color: _selectedDateCommitted != null ? Colors.black : Colors.grey[600],
                                ),
                              ),
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
                  Navigator.pop(context);
                  _clearForm();
                },
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: _isSubmitting ? 'Saving...' : (_isEditMode ? 'Update' : 'Add'),
                onPressed: _isSubmitting ? null : _submitCriminalRecord,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Criminal Records Management'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () => _loadCriminalRecords(refresh: true),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by ID, name, or crime type...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  Row(
                    children: [
                      // ID Type Filter
                      Expanded(
                        child: DropdownSearch<String>(
                          popupProps: const PopupProps.menu(showSearchBox: true),
                          items: ['All', ...AppConstants.idTypes],
                          selectedItem: _selectedIdTypeFilter ?? 'All',
                          onChanged: (value) {
                            setState(() {
                              _selectedIdTypeFilter = value == 'All' ? null : value;
                              _applyFilters();
                            });
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Filter by ID Type",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Gender Filter
                      Expanded(
                        child: DropdownSearch<String>(
                          popupProps: const PopupProps.menu(showSearchBox: true),
                          items: ['All', ...AppConstants.genderOptions],
                          selectedItem: _selectedGenderFilter ?? 'All',
                          onChanged: (value) {
                            setState(() {
                              _selectedGenderFilter = value == 'All' ? null : value;
                              _applyFilters();
                            });
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Filter by Gender",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Marital Status Filter
                      Expanded(
                        child: DropdownSearch<String>(
                          popupProps: const PopupProps.menu(showSearchBox: true),
                          items: ['All', ...AppConstants.maritalStatusOptions],
                          selectedItem: _selectedMaritalStatusFilter ?? 'All',
                          onChanged: (value) {
                            setState(() {
                              _selectedMaritalStatusFilter = value == 'All' ? null : value;
                              _applyFilters();
                            });
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Filter by Marital Status",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Records List
            Expanded(
              child: _isLoading
                  ? const LoadingWidget()
                  : _filteredRecords.isEmpty
                      ? const Center(
                          child: Text(
                            'No criminal records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadCriminalRecords(refresh: true),
                          child: ListView.builder(
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) {
                              final record = _filteredRecords[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryColor,
                                    child: Text(
                                      record.firstName[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '${record.firstName} ${record.lastName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${record.idNumber} (${record.idType})'),
                                      Text('Crime: ${record.crimeType}'),
                                      Text('Gender: ${record.gender}'),
                                      if (record.maritalStatus != null)
                                        Text('Marital Status: ${record.maritalStatus}'),
                                      Text('Date: ${record.dateCommitted != null ? DateFormat('yyyy-MM-dd').format(record.dateCommitted!) : 'N/A'}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: const Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: const Row(
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
                                        _editCriminalRecord(record);
                                      } else if (value == 'delete') {
                                        _deleteCriminalRecord(record);
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EnhancedReportScreen()),
            );
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
}
