import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../models/criminal_record.dart';
import '../../models/victim.dart';
import '../../models/rwandan_citizen.dart';
import '../../models/passport_holder.dart';
import '../../services/api_service.dart';
import '../../services/autofill_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/validators.dart';

class CrimeReportingScreen extends StatefulWidget {
  const CrimeReportingScreen({super.key});

  @override
  State<CrimeReportingScreen> createState() => _CrimeReportingScreenState();
}

class _CrimeReportingScreenState extends State<CrimeReportingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _crimeDescriptionController = TextEditingController();
  final _evidenceController = TextEditingController();

  String? _selectedIdType;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSector;
  String? _selectedCrimeType;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateCommitted;

  bool _isLoading = false;
  bool _isSearching = false;
  bool _isCriminal = false;
  bool _isVictim = false;
  RwandanCitizen? _foundCitizen;
  PassportHolder? _foundPassportHolder;

  @override
  void initState() {
    super.initState();
    _selectedDateCommitted = DateTime.now();
  }

  Future<void> _searchPersonById() async {
    if (_idNumberController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      // Search in criminal records first
      final criminal = await ApiService.searchCriminalRecord(_idNumberController.text.trim());
      
      if (criminal != null) {
        setState(() {
          _isCriminal = true;
          _isVictim = false;
          _foundCitizen = null;
          _foundPassportHolder = null;
        });
        
        _showCriminalFoundDialog(criminal);
        return;
      }

      // Search in citizen database
      final citizen = await AutofillService.searchRwandanCitizen(_idNumberController.text.trim());
      
      if (citizen != null) {
        setState(() {
          _isCriminal = false;
          _isVictim = false;
          _foundCitizen = citizen;
          _foundPassportHolder = null;
        });
        
        _autofillFromCitizen(citizen);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Citizen found and data auto-filled'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Search in passport holders
      final passportHolder = await AutofillService.searchPassportHolder(_idNumberController.text.trim());
      
      if (passportHolder != null) {
        setState(() {
          _isCriminal = false;
          _isVictim = false;
          _foundCitizen = null;
          _foundPassportHolder = passportHolder;
        });
        
        _autofillFromPassportHolder(passportHolder);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passport holder found and data auto-filled'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // No person found
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No person found with this ID number'),
          backgroundColor: Colors.orange,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching person: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showCriminalFoundDialog(CriminalRecord criminal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Criminal Record Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${criminal.firstName} ${criminal.lastName}'),
            Text('Crime: ${criminal.crimeType}'),
            Text('Date: ${criminal.dateCommitted?.day}/${criminal.dateCommitted?.month}/${criminal.dateCommitted?.year}'),
            const SizedBox(height: 16),
            const Text(
              'This person has an existing criminal record. Proceed with caution.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autofillFromCriminal(criminal);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _autofillFromCitizen(RwandanCitizen citizen) {
    setState(() {
      _firstNameController.text = citizen.firstName;
      _lastNameController.text = citizen.lastName;
      _selectedGender = citizen.gender;
      _selectedDateOfBirth = citizen.dateOfBirth;
      _selectedMaritalStatus = citizen.maritalStatus;
      _selectedProvince = citizen.province;
      _selectedDistrict = citizen.district;
      _selectedSector = citizen.sector;
      _phoneController.text = citizen.phone ?? '';
      _addressController.text = '${citizen.cell ?? ''}, ${citizen.village ?? ''}';
    });
  }

  void _autofillFromPassportHolder(PassportHolder passportHolder) {
    setState(() {
      _firstNameController.text = passportHolder.firstName;
      _lastNameController.text = passportHolder.lastName;
      _selectedGender = passportHolder.gender;
      _selectedDateOfBirth = passportHolder.dateOfBirth;
      _selectedMaritalStatus = passportHolder.maritalStatus;
      _phoneController.text = passportHolder.phone ?? '';
      _addressController.text = passportHolder.addressInRwanda ?? '';
    });
  }

  void _autofillFromCriminal(CriminalRecord criminal) {
    setState(() {
      _firstNameController.text = criminal.firstName;
      _lastNameController.text = criminal.lastName;
      _selectedGender = criminal.gender;
      _selectedDateOfBirth = criminal.dateOfBirth;
      _selectedMaritalStatus = criminal.maritalStatus;
      _selectedProvince = criminal.province;
      _selectedDistrict = criminal.district;
      _selectedSector = criminal.sector;
      _phoneController.text = criminal.phone ?? '';
      _addressController.text = criminal.addressNow ?? '';
    });
  }

  Future<void> _selectDate(BuildContext context, {required bool isDateOfBirth}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth ? (_selectedDateOfBirth ?? DateTime(2000)) : (_selectedDateCommitted ?? DateTime.now()),
      firstDate: isDateOfBirth ? DateTime(1900) : DateTime(2000),
      lastDate: isDateOfBirth ? DateTime.now() : DateTime.now(),
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

  Future<void> _submitCrimeReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create criminal record
      final criminalRecord = CriminalRecord(
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender!,
        dateOfBirth: _selectedDateOfBirth,
        maritalStatus: _selectedMaritalStatus,
        province: _selectedProvince,
        district: _selectedDistrict,
        sector: _selectedSector,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        addressNow: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        crimeType: _selectedCrimeType!,
        description: _crimeDescriptionController.text.trim().isEmpty ? null : _crimeDescriptionController.text.trim(),
        dateCommitted: _selectedDateCommitted,
        citizenId: _foundCitizen?.id,
        passportHolderId: _foundPassportHolder?.id,
      );

      // Create victim record if this is a victim case
      Victim? victim;
      if (_isVictim) {
        victim = Victim(
          idType: _selectedIdType!,
          idNumber: _idNumberController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          gender: _selectedGender!,
          dateOfBirth: _selectedDateOfBirth,
          province: _selectedProvince,
          district: _selectedDistrict,
          sector: _selectedSector,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          addressNow: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          crimeType: _selectedCrimeType!,
          evidence: _evidenceController.text.trim().isEmpty ? null : _evidenceController.text.trim(),
          dateCommitted: _selectedDateCommitted!,
          citizenId: _foundCitizen?.id,
          passportHolderId: _foundPassportHolder?.id,
        );
      }

      // Submit criminal record
      await ApiService.addCriminalRecord(criminalRecord);
      
      // Submit victim record if applicable
      if (victim != null) {
        await ApiService.addVictim(victim);
      }

      // Send notification
      await ApiService.sendNotification({
        'near_rib': 'General Public',
        'fullname': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'message': 'ALERT: New crime reported - ${_selectedCrimeType} committed by ${_firstNameController.text.trim()} ${_lastNameController.text.trim()} on ${_selectedDateCommitted!.day}/${_selectedDateCommitted!.month}/${_selectedDateCommitted!.year}. Stay vigilant.',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crime report submitted successfully'),
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
            content: Text('Error submitting crime report: $e'),
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
    _formKey.currentState?.reset();
    _idNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _crimeDescriptionController.clear();
    _evidenceController.clear();
    
    setState(() {
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedProvince = null;
      _selectedDistrict = null;
      _selectedSector = null;
      _selectedCrimeType = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = DateTime.now();
      _isCriminal = false;
      _isVictim = false;
      _foundCitizen = null;
      _foundPassportHolder = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Reporting'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID Search Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Person Identification',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // ID Type Selection
                            DropdownSearch<String>(
                              popupProps: const PopupProps.menu(showSearchBox: true),
                              items: const [
                                'indangamuntu_yumunyarwanda',
                                'indangamuntu_yumunyamahanga', 
                                'indangampunzi',
                                'passport'
                              ],
                              dropdownDecoratorProps: const DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  labelText: "ID Type",
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
                            
                            // ID Number with Search
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _idNumberController,
                                    labelText: 'ID Number',
                                    hintText: 'Enter ID number to search',
                                    validator: Validators.validateRequired,
                                    onChanged: (value) {
                                      if (value.length >= 8) {
                                        _searchPersonById();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isSearching ? null : _searchPersonById,
                                  child: _isSearching 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text('Search'),
                                ),
                              ],
                            ),
                            
                            // Status indicators
                            if (_isCriminal)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Criminal record found',
                                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (_foundCitizen != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  border: Border.all(color: Colors.green[200]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Citizen data found and auto-filled',
                                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Personal Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _firstNameController,
                                    labelText: 'First Name',
                                    validator: Validators.validateRequired,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomTextField(
                                    controller: _lastNameController,
                                    labelText: 'Last Name',
                                    validator: Validators.validateRequired,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownSearch<String>(
                                    items: AutofillService.getCommonGenders(),
                                    dropdownDecoratorProps: const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: "Gender",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    onChanged: (value) => setState(() => _selectedGender = value),
                                    selectedItem: _selectedGender,
                                    validator: (value) => value == null ? 'Please select gender' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownSearch<String>(
                                    items: AutofillService.getCommonMaritalStatuses(),
                                    dropdownDecoratorProps: const DropDownDecoratorProps(
                                      dropdownSearchDecoration: InputDecoration(
                                        labelText: "Marital Status",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    onChanged: (value) => setState(() => _selectedMaritalStatus = value),
                                    selectedItem: _selectedMaritalStatus,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Date of Birth
                            GestureDetector(
                              onTap: () => _selectDate(context, isDateOfBirth: true),
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
                                      _selectedDateOfBirth != null
                                          ? 'Date of Birth: ${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                                          : 'Select Date of Birth',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _phoneController,
                              labelText: 'Phone Number',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _addressController,
                              labelText: 'Address',
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Crime Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crime Information',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              validator: (value) => value == null ? 'Please select crime type' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Date Committed
                            GestureDetector(
                              onTap: () => _selectDate(context, isDateOfBirth: false),
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
                                      'Date Committed: ${_selectedDateCommitted!.day}/${_selectedDateCommitted!.month}/${_selectedDateCommitted!.year}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _crimeDescriptionController,
                              labelText: 'Crime Description',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            CustomTextField(
                              controller: _evidenceController,
                              labelText: 'Evidence/Additional Information',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            
                            // Victim case checkbox
                            CheckboxListTile(
                              title: const Text('This person is also a victim'),
                              value: _isVictim,
                              onChanged: (value) => setState(() => _isVictim = value ?? false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    CustomButton(
                      text: 'Submit Crime Report',
                      onPressed: _isLoading ? null : _submitCrimeReport,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _crimeDescriptionController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }
}
