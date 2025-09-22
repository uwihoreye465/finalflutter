import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../models/victim.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EnhancedVictimManagementScreen extends StatefulWidget {
  const EnhancedVictimManagementScreen({super.key});

  @override
  State<EnhancedVictimManagementScreen> createState() => _EnhancedVictimManagementScreenState();
}

class _EnhancedVictimManagementScreenState extends State<EnhancedVictimManagementScreen> {
    List<Victim> _victims = [];
    List<Victim> _filteredVictims = [];
    bool _isLoading = true;
    int _currentPage = 1;
    bool _hasMoreData = true;
    final int _itemsPerPage = 20;
    final TextEditingController _searchController = TextEditingController();
    String? _selectedIdTypeFilter;
    String? _selectedGenderFilter;
    String? _selectedMaritalStatusFilter;

    // Add victim form controllers
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
    final _emailController = TextEditingController();
    final _sinnerIdController = TextEditingController();
    final _crimeTypeController = TextEditingController();
    final _evidenceDescriptionController = TextEditingController();
    
    String? _selectedIdType;
    String? _selectedGender;
    String? _selectedMaritalStatus;
    DateTime? _selectedDateOfBirth;
    DateTime? _selectedDateCommitted;
    bool _isSubmitting = false;
    bool _isEditMode = false;
    Victim? _editingVictim;
    
    // File upload variables
    List<File> _selectedFiles = [];
    final ImagePicker _picker = ImagePicker();

    @override
    void initState() {
      super.initState();
      _loadVictims();
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
      _emailController.dispose();
      _sinnerIdController.dispose();
      _crimeTypeController.dispose();
      _evidenceDescriptionController.dispose();
      super.dispose();
    }

    void _onSearchChanged() {
      _applyFilters();
    }

    Future<void> _pickFiles() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.any,
        );

        if (result != null) {
          setState(() {
            _selectedFiles = result.paths.map((path) => File(path!)).toList();
          });
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error picking files: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }

    Future<void> _pickImage() async {
      try {
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedFiles.add(File(image.path));
          });
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error picking image: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }

    void _removeFile(int index) {
      setState(() {
        _selectedFiles.removeAt(index);
      });
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
        );

        final List<Victim> newVictims = ((response['data']['victims'] as List?) ?? (response['data'] as List))
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
        
        _applyFilters();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(
          msg: 'Error loading victims: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    }

    void _applyFilters() {
      setState(() {
        _filteredVictims = _victims.where((victim) {
          // Search filter
          if (_searchController.text.isNotEmpty) {
            final searchTerm = _searchController.text.toLowerCase();
            if (!victim.firstName.toLowerCase().contains(searchTerm) &&
                !victim.lastName.toLowerCase().contains(searchTerm) &&
                !victim.idNumber.toLowerCase().contains(searchTerm) &&
                !victim.crimeType.toLowerCase().contains(searchTerm)) {
              return false;
            }
          }

          // ID Type filter
          if (_selectedIdTypeFilter != null && _selectedIdTypeFilter != 'All') {
            if (victim.idType != _selectedIdTypeFilter) {
              return false;
            }
          }

          // Gender filter
          if (_selectedGenderFilter != null && _selectedGenderFilter != 'All') {
            if (victim.gender != _selectedGenderFilter) {
              return false;
            }
          }

          // Marital Status filter
          if (_selectedMaritalStatusFilter != null && _selectedMaritalStatusFilter != 'All') {
            if (victim.maritalStatus != _selectedMaritalStatusFilter) {
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
            _emailController.text = person['email'] ?? '';
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
            _emailController.text = person['email'] ?? '';
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

    Future<void> _submitVictim() async {
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
        final victim = Victim(
          vicId: _isEditMode ? _editingVictim!.vicId : null,
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
          victimEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          sinnerIdentification: _sinnerIdController.text.trim().isEmpty ? null : _sinnerIdController.text.trim(),
          crimeType: _crimeTypeController.text.trim(),
          evidence: _evidenceDescriptionController.text.trim().isEmpty ? null : {
            'description': _evidenceDescriptionController.text.trim(),
            'files': [],
            'uploadedAt': DateTime.now().toIso8601String(),
          },
          dateCommitted: _selectedDateCommitted!,
        );

        if (_isEditMode) {
          // Update victim with file information
          final updatedVictim = Victim(
            vicId: victim.vicId,
            idType: victim.idType,
            idNumber: victim.idNumber,
            firstName: victim.firstName,
            lastName: victim.lastName,
            gender: victim.gender,
            dateOfBirth: victim.dateOfBirth,
            maritalStatus: victim.maritalStatus,
            country: victim.country,
            province: victim.province,
            district: victim.district,
            sector: victim.sector,
            cell: victim.cell,
            village: victim.village,
            addressNow: victim.addressNow,
            phone: victim.phone,
            victimEmail: victim.victimEmail,
            sinnerIdentification: victim.sinnerIdentification,
            crimeType: victim.crimeType,
            evidence: {
              'description': _evidenceDescriptionController.text.trim(),
              'files': _selectedFiles.map((file) => {
                'name': file.path.split('/').last,
                'type': file.path.split('.').last,
                'path': file.path,
                'uploadedAt': DateTime.now().toIso8601String(),
              }).toList(),
              'uploadedAt': DateTime.now().toIso8601String(),
            },
            dateCommitted: victim.dateCommitted,
          );
          
          await ApiService.updateVictim(_editingVictim!.vicId!, updatedVictim);
          
          Fluttertoast.showToast(
            msg: "Victim record updated successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
        } else {
          // Create victim with file information
          final newVictim = Victim(
            idType: victim.idType,
            idNumber: victim.idNumber,
            firstName: victim.firstName,
            lastName: victim.lastName,
            gender: victim.gender,
            dateOfBirth: victim.dateOfBirth,
            maritalStatus: victim.maritalStatus,
            country: victim.country,
            province: victim.province,
            district: victim.district,
            sector: victim.sector,
            cell: victim.cell,
            village: victim.village,
            addressNow: victim.addressNow,
            phone: victim.phone,
            victimEmail: victim.victimEmail,
            sinnerIdentification: victim.sinnerIdentification,
            crimeType: victim.crimeType,
            evidence: {
              'description': _evidenceDescriptionController.text.trim(),
              'files': _selectedFiles.map((file) => {
                'name': file.path.split('/').last,
                'type': file.path.split('.').last,
                'path': file.path,
                'uploadedAt': DateTime.now().toIso8601String(),
              }).toList(),
              'uploadedAt': DateTime.now().toIso8601String(),
            },
            dateCommitted: victim.dateCommitted,
          );
          
          await ApiService.addVictim(newVictim);
          
          Fluttertoast.showToast(
            msg: "Victim record added successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
        }
        
        _clearForm();
        _loadVictims(refresh: true);
        
        // Close the dialog
        Navigator.of(context).pop();
        
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error ${_isEditMode ? 'updating' : 'adding'} victim record: ${e.toString()}',
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }

    Future<void> _deleteVictim(Victim victim) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Victim Record'),
          content: Text('Are you sure you want to delete the victim record for ${victim.firstName} ${victim.lastName}?'),
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
          await ApiService.deleteVictim(victim.vicId!);
          Fluttertoast.showToast(
            msg: "Victim record deleted successfully!",
            backgroundColor: AppColors.successColor,
            textColor: Colors.white,
          );
          _loadVictims(refresh: true);
        } catch (e) {
          Fluttertoast.showToast(
            msg: 'Error deleting victim record: ${e.toString()}',
            backgroundColor: AppColors.errorColor,
            textColor: Colors.white,
          );
        }
      }
    }

    void _editVictim(Victim victim) {
      setState(() {
        _isEditMode = true;
        _editingVictim = victim;
        _idNumberController.text = victim.idNumber;
        _firstNameController.text = victim.firstName;
        _lastNameController.text = victim.lastName;
        _selectedGender = victim.gender;
        _selectedDateOfBirth = victim.dateOfBirth;
        _selectedMaritalStatus = victim.maritalStatus;
        _selectedIdType = victim.idType;
        _countryController.text = victim.country ?? '';
        _provinceController.text = victim.province ?? '';
        _districtController.text = victim.district ?? '';
        _sectorController.text = victim.sector ?? '';
        _cellController.text = victim.cell ?? '';
        _villageController.text = victim.village ?? '';
        _addressNowController.text = victim.addressNow ?? '';
        _phoneController.text = victim.phone ?? '';
        _emailController.text = victim.victimEmail ?? '';
        _sinnerIdController.text = victim.sinnerIdentification ?? '';
        _crimeTypeController.text = victim.crimeType;
        _evidenceDescriptionController.text = victim.evidence?['description'] ?? '';
        _selectedDateCommitted = victim.dateCommitted;
      });
      
      _showAddVictimDialog();
    }

    void _viewVictimFiles(Victim victim) {
      if (victim.evidence == null || victim.evidence!['files'] == null) {
        Fluttertoast.showToast(
          msg: 'No files attached to this victim record',
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
        return;
      }

      final files = victim.evidence!['files'] as List;
      if (files.isEmpty) {
        Fluttertoast.showToast(
          msg: 'No files attached to this victim record',
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Files for ${victim.firstName} ${victim.lastName}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (victim.evidence!['description'] != null && victim.evidence!['description'].toString().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Description: ${victim.evidence!['description']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Attached Files:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...files.map((file) => Card(
                  child: ListTile(
                    leading: Icon(
                      _getFileIcon(file['type'] ?? ''),
                      color: AppColors.primaryColor,
                    ),
                    title: Text(file['name'] ?? 'Unknown file'),
                    subtitle: Text('Type: ${file['type'] ?? 'Unknown'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () async {
                        try {
                          final fileUrl = await ApiService.downloadVictimEvidence(victim.vicId!);
                          if (fileUrl.isNotEmpty) {
                            // Open the file URL in browser or download
                            Fluttertoast.showToast(
                              msg: 'File downloaded successfully',
                              backgroundColor: AppColors.successColor,
                              textColor: Colors.white,
                            );
                            // You can add url_launcher package to open the URL
                          } else {
                            Fluttertoast.showToast(
                              msg: 'No file available for download',
                              backgroundColor: AppColors.warningColor,
                              textColor: Colors.white,
                            );
                          }
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: 'Error downloading file: ${e.toString()}',
                            backgroundColor: AppColors.errorColor,
                            textColor: Colors.white,
                          );
                        }
                      },
                    ),
                  ),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    IconData _getFileIcon(String fileType) {
      switch (fileType.toLowerCase()) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
          return Icons.image;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'txt':
          return Icons.text_snippet;
        default:
          return Icons.attach_file;
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
      _phoneController.clear();
      _emailController.clear();
      _sinnerIdController.clear();
      _crimeTypeController.clear();
      _evidenceDescriptionController.clear();
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = null;
      _isEditMode = false;
      _editingVictim = null;
      _selectedFiles.clear();
    }

    void _showAddVictimDialog() {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(_isEditMode ? 'Edit Victim Record' : 'Add Victim Record'),
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
                      
                      // Email
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Enter Email Address',
                        label: 'Email Address',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      // Sinner Identification
                      CustomTextField(
                        controller: _sinnerIdController,
                        hintText: 'Enter Sinner Identification',
                        label: 'Sinner Identification',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Crime Type
                      CustomTextField(
                        controller: _crimeTypeController,
                        hintText: 'Enter Crime Type',
                        label: 'Crime Type *',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter crime type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Evidence Description
                      CustomTextField(
                        controller: _evidenceDescriptionController,
                        hintText: 'Enter Evidence Description',
                        label: 'Evidence Description',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // File Upload Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evidence Files',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickFiles,
                                    icon: const Icon(Icons.attach_file),
                                    label: const Text('Pick Files'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Pick Image'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedFiles.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Selected Files:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ..._selectedFiles.asMap().entries.map((entry) {
                                final index = entry.key;
                                final file = entry.value;
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.attach_file),
                                    title: Text(file.path.split('/').last),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeFile(index),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
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
                onPressed: _isSubmitting ? null : _submitVictim,
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
          title: const Text('Victims Management'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () => _loadVictims(refresh: true),
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
                  : _filteredVictims.isEmpty
                      ? const Center(
                          child: Text(
                            'No victim records found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadVictims(refresh: true),
                          child: ListView.builder(
                            itemCount: _filteredVictims.length,
                            itemBuilder: (context, index) {
                              final victim = _filteredVictims[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryColor,
                                    child: Text(
                                      victim.firstName[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    '${victim.firstName} ${victim.lastName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${victim.idNumber} (${victim.idType})'),
                                      Text('Crime: ${victim.crimeType}'),
                                      Text('Gender: ${victim.gender}'),
                                      if (victim.maritalStatus != null)
                                        Text('Marital Status: ${victim.maritalStatus}'),
                                      if (victim.victimEmail != null)
                                        Text('Email: ${victim.victimEmail}'),
                                      Text('Date: ${victim.dateCommitted != null ? DateFormat('yyyy-MM-dd').format(victim.dateCommitted!) : 'N/A'}'),
                                      if (victim.evidence != null && victim.evidence!['files'] != null && (victim.evidence!['files'] as List).isNotEmpty)
                                        Text('Files: ${(victim.evidence!['files'] as List).length} attached', 
                                             style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
                                      if (victim.evidence != null && victim.evidence!['files'] != null && (victim.evidence!['files'] as List).isNotEmpty)
                                        PopupMenuItem(
                                          value: 'files',
                                          child: const Row(
                                            children: [
                                              Icon(Icons.attach_file, color: Colors.green),
                                              SizedBox(width: 8),
                                              Text('View Files'),
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
                                        _editVictim(victim);
                                      } else if (value == 'files') {
                                        _viewVictimFiles(victim);
                                      } else if (value == 'delete') {
                                        _deleteVictim(victim);
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
            _clearForm();
            _showAddVictimDialog();
          },
          backgroundColor: AppColors.primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }
}
