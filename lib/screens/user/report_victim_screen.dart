import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/victim.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

class ReportVictimScreen extends StatefulWidget {
  const ReportVictimScreen({super.key});

  @override
  State<ReportVictimScreen> createState() => _ReportVictimScreenState();
}

class _ReportVictimScreenState extends State<ReportVictimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  // Controllers
  final _idNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressNowController = TextEditingController();
  final _countryController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _sectorController = TextEditingController();
  final _cellController = TextEditingController();
  final _villageController = TextEditingController();
  final _sinnerIdentificationController = TextEditingController();
  final _crimeTypeController = TextEditingController();
  final _evidenceController = TextEditingController();
  
  // State variables
  String? _selectedIdType;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateCommitted;
  bool _isLoading = false;
  bool _isSearching = false;

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

  Future<void> _autofillById() async {
    final id = _idNumberController.text.trim();
    if (id.isEmpty) return;
    final isPassport = RegExp(r'^[A-Za-z]').hasMatch(id) || id.length != 16;
    setState(() {
      _selectedIdType = isPassport ? 'passport' : 'indangamuntu_yumunyarwanda';
      _isSearching = true;
    });
    try {
      final record = await ApiService.searchCriminalRecord(id);
      if (record != null) {
        _firstNameController.text = record.firstName;
        _lastNameController.text = record.lastName;
        _selectedGender = record.gender;
        _selectedMaritalStatus = record.maritalStatus;
        _countryController.text = record.country ?? '';
        _provinceController.text = record.province ?? '';
        _districtController.text = record.district ?? '';
        _sectorController.text = record.sector ?? '';
        _cellController.text = record.cell ?? '';
        _villageController.text = record.village ?? '';
        _addressNowController.text = record.addressNow ?? '';
        _selectedDateOfBirth = record.dateOfBirth;
      }
    } catch (_) {
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _submitVictimReport() async {
    if (!_formKey.currentState!.validate()) {
      _scrollToFirstError();
      return;
    }

    if (_selectedDateCommitted == null) {
      Fluttertoast.showToast(
        msg: "Please select crime committed date",
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final victim = Victim(
        idType: _selectedIdType!,
        idNumber: _idNumberController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender!,
        dateOfBirth: _selectedDateOfBirth,
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        addressNow: _addressNowController.text.trim().isEmpty ? null : _addressNowController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        province: _provinceController.text.trim().isEmpty ? null : _provinceController.text.trim(),
        district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        sector: _sectorController.text.trim().isEmpty ? null : _sectorController.text.trim(),
        cell: _cellController.text.trim().isEmpty ? null : _cellController.text.trim(),
        village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        victimEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
        sinnerIdentification: _sinnerIdentificationController.text.trim().isEmpty ? null : _sinnerIdentificationController.text.trim(),
        crimeType: _crimeTypeController.text.trim(),
        evidence: _evidenceController.text.trim().isEmpty ? null : _evidenceController.text.trim(),
        dateCommitted: _selectedDateCommitted!,
      );

      await ApiService.addVictim(victim);
      
      Fluttertoast.showToast(
        msg: "Victim report submitted successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      
      _clearForm();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error submitting report: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToFirstError() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _idNumberController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _addressNowController.clear();
    _countryController.clear();
    _provinceController.clear();
    _districtController.clear();
    _sectorController.clear();
    _cellController.clear();
    _villageController.clear();
    _sinnerIdentificationController.clear();
    _crimeTypeController.clear();
    _evidenceController.clear();
    
    setState(() {
      _selectedIdType = null;
      _selectedGender = null;
      _selectedMaritalStatus = null;
      _selectedDateOfBirth = null;
      _selectedDateCommitted = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        title: const Text('Victim Record', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ID Type Selection
              _buildDropdownField(
                label: 'Select ID Type',
                value: _selectedIdType,
                items: AppConstants.idTypes,
                onChanged: (value) => setState(() => _selectedIdType = value),
                validator: (value) => value == null ? 'Please select ID type' : null,
              ),
              
              const SizedBox(height: 15),
              
              // ID Number
              CustomTextField(
                controller: _idNumberController,
                hintText: 'Enter ID Number',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter ID number';
                  }
                  final isPassport = RegExp(r'^[A-Za-z]').hasMatch(value) || value.length != 16;
                  if (!isPassport && !RegExp(r'^\d{16}$').hasMatch(value)) {
                    return 'National ID must be 16 digits';
                  }
                  return null;
                },
                onChanged: (v) {
                  final trimmed = v.trim();
                  if (trimmed.length == 16 || (trimmed.length >= 6 && RegExp(r'^[A-Za-z]').hasMatch(trimmed))) {
                    _autofillById();
                  }
                },
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
              _buildDropdownField(
                label: 'Select Gender',
                value: _selectedGender,
                items: AppConstants.genderOptions,
                onChanged: (value) => setState(() => _selectedGender = value),
                validator: (value) => value == null ? 'Please select gender' : null,
              ),
              
              const SizedBox(height: 15),
              
              // Date of Birth
              _buildDateField(
                label: 'Date of Birth',
                selectedDate: _selectedDateOfBirth,
                onTap: () => _selectDate(context, isDateOfBirth: true),
              ),
              
              const SizedBox(height: 15),
              
              // Marital Status
              _buildDropdownField(
                label: 'Marital Status',
                value: _selectedMaritalStatus,
                items: AppConstants.maritalStatusOptions,
                onChanged: (value) => setState(() => _selectedMaritalStatus = value),
              ),
              
              const SizedBox(height: 15),
              
              // Phone
              CustomTextField(
                controller: _phoneController,
                hintText: 'Enter Phone Number',
                keyboardType: TextInputType.phone,
              ),
              
              const SizedBox(height: 15),
              
              // Email
              CustomTextField(
                controller: _emailController,
                hintText: 'Enter Email',
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 15),
              
              // Address
              CustomTextField(
                controller: _addressController,
                hintText: 'Enter Address',
                maxLines: 2,
              ),
              
              const SizedBox(height: 15),
              
              // Current Address
              CustomTextField(
                controller: _addressNowController,
                hintText: 'Enter Current Address',
                maxLines: 2,
              ),
              
              const SizedBox(height: 15),
              
              // Country (for passport holders)
              if (_selectedIdType == 'passport') ...[
                CustomTextField(
                  controller: _countryController,
                  hintText: 'Enter Country',
                ),
                const SizedBox(height: 15),
              ],
              
              // Rwanda Address Fields (for Rwandan IDs)
              if (_selectedIdType != 'passport') ...[
                // Province
                _buildDropdownField(
                  label: 'Province',
                  value: _provinceController.text.isEmpty ? null : _provinceController.text,
                  items: AppConstants.provinces,
                  onChanged: (value) {
                    _provinceController.text = value ?? '';
                  },
                ),
                
                const SizedBox(height: 15),
                
                // District
                CustomTextField(
                  controller: _districtController,
                  hintText: 'Enter District',
                ),
                
                const SizedBox(height: 15),
                
                // Sector
                CustomTextField(
                  controller: _sectorController,
                  hintText: 'Enter Sector',
                ),
                
                const SizedBox(height: 15),
                
                // Cell
                CustomTextField(
                  controller: _cellController,
                  hintText: 'Enter Cell',
                ),
                
                const SizedBox(height: 15),
                
                // Village
                CustomTextField(
                  controller: _villageController,
                  hintText: 'Enter Village',
                ),
                
                const SizedBox(height: 15),
              ],
              
              // Sinner Identification
              CustomTextField(
                controller: _sinnerIdentificationController,
                hintText: 'Sinner Identification (Suspect Info)',
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
              
              // Evidence
              CustomTextField(
                controller: _evidenceController,
                hintText: 'Enter Evidence Description',
                maxLines: 3,
              ),
              
           const SizedBox(height: 15),
             
             // Date Committed
             _buildDateField(
               label: 'Date Crime Committed',
               selectedDate: _selectedDateCommitted,
               onTap: () => _selectDate(context, isDateOfBirth: false),
               isRequired: true,
             ),
             
             const SizedBox(height: 30),
             
             // Submit Button
             if (_isLoading || _isSearching)
               const Center(child: LoadingWidget())
             else
               CustomButton(
                 text: 'Submit',
                 onPressed: _submitVictimReport,
                 backgroundColor: AppColors.successColor,
               ),
             
             const SizedBox(height: 20),
           ],
         ),
       ),
     ),
   );
 }

 Widget _buildDropdownField({
   required String label,
   required String? value,
   required List<String> items,
   required void Function(String?) onChanged,
   String? Function(String?)? validator,
 }) {
   return DropdownSearch<String>(
     popupProps: const PopupProps.menu(
       showSearchBox: true,
       searchFieldProps: TextFieldProps(
         decoration: InputDecoration(
           hintText: "Search...",
           prefixIcon: Icon(Icons.search),
         ),
       ),
     ),
     items: items,
     dropdownDecoratorProps: DropDownDecoratorProps(
       dropdownSearchDecoration: InputDecoration(
         labelText: label,
         filled: true,
         fillColor: Colors.white,
         border: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
           borderSide: BorderSide.none,
         ),
       ),
     ),
     onChanged: onChanged,
     selectedItem: value,
     validator: validator,
   );
 }

 Widget _buildDateField({
   required String label,
   required DateTime? selectedDate,
   required VoidCallback onTap,
   bool isRequired = false,
 }) {
   return GestureDetector(
     onTap: onTap,
     child: Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(8),
       ),
       child: Row(
         children: [
           Expanded(
             child: Text(
               selectedDate != null
                   ? DateFormat('yyyy-MM-dd').format(selectedDate)
                   : '$label${isRequired ? ' *' : ''}',
               style: TextStyle(
                 color: selectedDate != null ? Colors.black : Colors.grey[600],
                 fontSize: 16,
               ),
             ),
           ),
           Icon(Icons.calendar_today, color: Colors.grey[600]),
         ],
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
   _emailController.dispose();
   _addressController.dispose();
   _addressNowController.dispose();
   _countryController.dispose();
   _provinceController.dispose();
   _districtController.dispose();
   _sectorController.dispose();
   _cellController.dispose();
   _villageController.dispose();
   _sinnerIdentificationController.dispose();
   _crimeTypeController.dispose();
   _evidenceController.dispose();
   _scrollController.dispose();
   super.dispose();
 }
}