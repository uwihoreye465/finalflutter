import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../services/autofill_service.dart';
import '../../models/criminal_record.dart';
import '../../models/victim.dart';
import '../../models/rwandan_citizen.dart';
import '../../models/passport_holder.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/login_screen.dart';

class EnhancedReportScreen extends StatefulWidget {
  const EnhancedReportScreen({super.key});

  @override
  State<EnhancedReportScreen> createState() => _EnhancedReportScreenState();
}

class _EnhancedReportScreenState extends State<EnhancedReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Form keys
  final _victimFormKey = GlobalKey<FormState>();
  final _criminalFormKey = GlobalKey<FormState>();
  
  // Common controllers
  final _idNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressNowController = TextEditingController();
  
  // Citizen-specific controllers
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _villageController = TextEditingController();
  
  // Passport-specific controllers
  final _countryController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _homeAddressController = TextEditingController();
  
  // Victim-specific controllers
  final _sinnerIdController = TextEditingController();
  final _evidenceDescriptionController = TextEditingController();
  
  // Criminal-specific controllers
  final _descriptionController = TextEditingController();
  
  // Common form fields
  String? _selectedIdType;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateCommitted;
  String? _selectedCrimeType;
  
  bool _isAutofilledData = false;
  bool _isSubmitting = false;
  String? _nidaMessage;
  String? _nidaMessageType; // 'success', 'warning', 'error'
  
  // Auto-filled data references
  RwandanCitizen? _autofilledCitizen;
  PassportHolder? _autofilledPassportHolder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        Fluttertoast.showToast(
          msg: 'Logged out successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error logging out: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressNowController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _sectorController.dispose();
    _cellController.dispose();
    _villageController.dispose();
    _countryController.dispose();
    _nationalityController.dispose();
    _homeAddressController.dispose();
    _sinnerIdController.dispose();
    _evidenceDescriptionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchAndAutofill(String idNumber) async {
    if (idNumber.length < 8) return;

    try {
      final personData = await AutofillService.searchPersonData(idNumber);
      
      if (personData != null) {
        setState(() {
          _isAutofilledData = true;
          _nidaMessage = 'Data auto-filled from NIDA records';
          _nidaMessageType = 'success';
          
          if (personData['type'] == 'citizen') {
            final citizen = personData['data'] as RwandanCitizen;
            _autofilledCitizen = citizen;
            _autofilledPassportHolder = null;
            
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
            _phoneController.text = citizen.phone ?? '';
            _emailController.text = citizen.email ?? '';
            _selectedIdType = citizen.idType;
            
          } else if (personData['type'] == 'passport') {
            final passportHolder = personData['data'] as PassportHolder;
            _autofilledPassportHolder = passportHolder;
            _autofilledCitizen = null;
            
            _firstNameController.text = passportHolder.firstName;
            _lastNameController.text = passportHolder.lastName;
            _selectedGender = passportHolder.gender;
            _selectedDateOfBirth = passportHolder.dateOfBirth;
            _selectedMaritalStatus = passportHolder.maritalStatus;
            _countryController.text = passportHolder.nationality ?? '';
            _nationalityController.text = passportHolder.nationality ?? '';
            _addressNowController.text = passportHolder.addressInRwanda ?? '';
            _homeAddressController.text = passportHolder.homeAddress ?? '';
            _phoneController.text = passportHolder.phone ?? '';
            _emailController.text = passportHolder.email ?? '';
            _selectedIdType = 'passport';
          }
        });
        
        Fluttertoast.showToast(
          msg: 'Data auto-filled from NIDA records',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
      } else {
        setState(() {
          _isAutofilledData = false;
          _autofilledCitizen = null;
          _autofilledPassportHolder = null;
        });
        
        Fluttertoast.showToast(
          msg: 'Nta mwirondoro wanyu wanditse muri NIDA. Uzuza amakuru yose wenyine.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.warningColor,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error searching NIDA data: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
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

  Future<void> _submitVictim() async {
    if (!_victimFormKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final victim = Victim(
        citizenId: _autofilledCitizen?.id,
        passportHolderId: _autofilledPassportHolder?.id,
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender!,
        dateOfBirth: _selectedDateOfBirth,
        province: _selectedIdType == 'passport' ? null : (_provinceController.text.trim().isEmpty ? null : _provinceController.text.trim()),
        district: _selectedIdType == 'passport' ? null : (_districtController.text.trim().isEmpty ? null : _districtController.text.trim()),
        sector: _selectedIdType == 'passport' ? null : (_sectorController.text.trim().isEmpty ? null : _sectorController.text.trim()),
        cell: _selectedIdType == 'passport' ? null : (_cellController.text.trim().isEmpty ? null : _cellController.text.trim()),
        village: _selectedIdType == 'passport' ? null : (_villageController.text.trim().isEmpty ? null : _villageController.text.trim()),
        country: _selectedIdType == 'passport' ? (_countryController.text.trim().isEmpty ? null : _countryController.text.trim()) : null,
        addressNow: _addressNowController.text.trim().isEmpty ? null : _addressNowController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        victimEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
        sinnerIdentification: _sinnerIdController.text.trim().isEmpty ? null : _sinnerIdController.text.trim(),
        crimeType: _selectedCrimeType!,
        evidence: _evidenceDescriptionController.text.trim().isEmpty ? null : {
          'description': _evidenceDescriptionController.text.trim(),
          'files': [],
          'uploadedAt': DateTime.now().toIso8601String(),
        },
        dateCommitted: _selectedDateCommitted,
      );

      await ApiService.addVictim(victim);
      
      Fluttertoast.showToast(
        msg: "Victim report submitted successfully!",
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      
      _clearForm();
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error submitting victim report: ${e.toString()}',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitCriminal() async {
    if (!_criminalFormKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final criminalRecord = CriminalRecord(
        citizenId: _autofilledCitizen?.id,
        passportHolderId: _autofilledPassportHolder?.id,
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender!,
        dateOfBirth: _selectedDateOfBirth,
        maritalStatus: _selectedMaritalStatus,
        country: _selectedIdType == 'passport' ? (_countryController.text.trim().isEmpty ? null : _countryController.text.trim()) : null,
        province: _selectedIdType == 'passport' ? null : (_provinceController.text.trim().isEmpty ? null : _provinceController.text.trim()),
        district: _selectedIdType == 'passport' ? null : (_districtController.text.trim().isEmpty ? null : _districtController.text.trim()),
        sector: _selectedIdType == 'passport' ? null : (_sectorController.text.trim().isEmpty ? null : _sectorController.text.trim()),
        cell: _selectedIdType == 'passport' ? null : (_cellController.text.trim().isEmpty ? null : _cellController.text.trim()),
        village: _selectedIdType == 'passport' ? null : (_villageController.text.trim().isEmpty ? null : _villageController.text.trim()),
        addressNow: _addressNowController.text.trim().isEmpty ? null : _addressNowController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        crimeType: _selectedCrimeType!,
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
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error adding criminal record: ${e.toString()}',
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _victimFormKey.currentState?.reset();
    _criminalFormKey.currentState?.reset();
    
    _idNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressNowController.clear();
    _provinceController.clear();
    _districtController.clear();
    _sectorController.clear();
    _cellController.clear();
    _villageController.clear();
    _countryController.clear();
    _nationalityController.clear();
    _homeAddressController.clear();
    _sinnerIdController.clear();
    _evidenceDescriptionController.clear();
    _descriptionController.clear();
    
    setState(() {
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = null;
      _selectedCrimeType = null;
      _isAutofilledData = false;
      _autofilledCitizen = null;
      _autofilledPassportHolder = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Report Crime', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_remove), text: 'Report Victim'),
            Tab(icon: Icon(Icons.warning), text: 'Report Criminal'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVictimForm(),
          _buildCriminalForm(),
        ],
      ),
    );
  }

  Widget _buildVictimForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _victimFormKey,
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report a Victim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter the victim\'s ID number first. If registered in NIDA, personal information will be auto-filled.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            ..._buildCommonFields(),
            
            const SizedBox(height: 20),
            
            // Victim-specific fields
            const Text(
              'Crime Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Suspect/Sinner Identification
            CustomTextField(
              controller: _sinnerIdController,
              hintText: 'Suspect/Criminal Identification',
              label: 'Suspect Description',
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Evidence
            CustomTextField(
              controller: _evidenceDescriptionController,
              hintText: 'Describe the evidence...',
              label: 'Evidence',
              maxLines: 3,
            ),
            
            const SizedBox(height: 30),
            
            // Submit Button
            if (_isSubmitting)
              const LoadingWidget()
            else
              CustomButton(
                text: 'Submit Victim Report',
                onPressed: _submitVictim,
                backgroundColor: AppColors.errorColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriminalForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _criminalFormKey,
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report a Criminal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter the criminal\'s ID number first. If registered in NIDA, personal information will be auto-filled.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            ..._buildCommonFields(),
            
            const SizedBox(height: 20),
            
            // Criminal-specific fields
            const Text(
              'Crime Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Describe the crime in detail...',
              label: 'Crime Description',
              maxLines: 4,
            ),
            
            const SizedBox(height: 30),
            
            // Submit Button
            if (_isSubmitting)
              const LoadingWidget()
            else
              CustomButton(
                text: 'Submit Criminal Report',
                onPressed: _submitCriminal,
                backgroundColor: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommonFields() {
    return [
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
          setState(() => _selectedIdType = value);
        },
        selectedItem: _selectedIdType,
        validator: (value) => value == null ? 'Please select ID type' : null,
      ),
      
      const SizedBox(height: 16),
      
      // ID Number with autofill
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _idNumberController,
              hintText: 'Enter ID Number',
              label: 'ID Number',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ID number';
                }
                return null;
              },
              onChanged: _searchAndAutofill,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_idNumberController.text.isNotEmpty) {
                _searchAndAutofill(_idNumberController.text);
              }
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search NIDA',
          ),
        ],
      ),
      
      if (_isAutofilledData)
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.successColor, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Data auto-filled from NIDA records',
                  style: TextStyle(fontSize: 12, color: AppColors.successColor),
                ),
              ),
            ],
          ),
        ),
      
      const SizedBox(height: 16),
      
      // Personal Information
      const Text(
        'Personal Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      
      // First Name
      CustomTextField(
        controller: _firstNameController,
        hintText: 'Enter First Name',
        label: 'First Name',
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
        label: 'Last Name',
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
        items: AppConstants.genderOptions,
        dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select Gender",
            border: OutlineInputBorder(),
          ),
        ),
        onChanged: (value) {
          setState(() => _selectedGender = value);
        },
        selectedItem: _selectedGender,
        validator: (value) => value == null ? 'Please select gender' : null,
      ),
      
      const SizedBox(height: 16),
      
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
      
      const SizedBox(height: 16),
      
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
          setState(() => _selectedMaritalStatus = value);
        },
        selectedItem: _selectedMaritalStatus,
      ),
      
      const SizedBox(height: 16),
      
      // Address fields based on ID type
      const Text(
        'Address Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
      const SizedBox(height: 16),
      
      if (_selectedIdType == 'passport') ...[
        // Passport holder fields
        CustomTextField(
          controller: _countryController,
          hintText: 'Enter Country',
          label: 'Country',
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _nationalityController,
          hintText: 'Enter Nationality',
          label: 'Nationality',
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _homeAddressController,
          hintText: 'Enter Home Address',
          label: 'Home Address',
          maxLines: 2,
        ),
        const SizedBox(height: 16),
      ] else ...[
        // Citizen fields
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
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _districtController,
          hintText: 'Enter District',
          label: 'District',
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _sectorController,
          hintText: 'Enter Sector',
          label: 'Sector',
        ),
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _cellController,
          hintText: 'Enter Cell',
          label: 'Cell',
        ),
        const SizedBox(height: 16),
        
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
        label: 'Current Address',
        maxLines: 2,
      ),
      
      const SizedBox(height: 16),
      
      // Contact Information
      CustomTextField(
        controller: _phoneController,
        hintText: 'Enter Phone Number',
        label: 'Phone Number',
      ),
      
      const SizedBox(height: 16),
      
      CustomTextField(
        controller: _emailController,
        hintText: 'Enter Email Address',
        label: 'Email Address',
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter email address';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      ),
      
      const SizedBox(height: 16),
      
      // Crime Type
      DropdownSearch<String>(
        popupProps: const PopupProps.menu(showSearchBox: true),
        items: AutofillService.getCommonCrimeTypes(),
        dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select Crime Type",
            border: OutlineInputBorder(),
          ),
        ),
        onChanged: (value) {
          setState(() => _selectedCrimeType = value);
        },
        selectedItem: _selectedCrimeType,
        validator: (value) => value == null ? 'Please select crime type' : null,
      ),
      
      const SizedBox(height: 16),
      
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
    ];
  }
}
