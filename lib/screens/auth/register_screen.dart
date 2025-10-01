import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/beautiful_footer.dart';
import '../home/home_screen.dart';
import '../news/news_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sectorController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _positionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedSector;

  // All RIB Stations in Rwanda
  final List<String> _ribStations = [
    'Bugesera STATIONS',
    'Gatsibo STATIONS',
    'Kayonza STATIONS',
    'Kirehe STATIONS',
    'Ngoma STATIONS',
    'Nyagatare STATIONS',
    'Rwamagana STATIONS',
    'Gasabo STATIONS',
    'Kicukiro STATIONS',
    'Nyarugenge STATIONS',
    'Burera STATIONS',
    'Gakenke STATIONS',
    'Gicumbi STATIONS',
    'Musanze STATIONS',
    'Rulindo STATIONS',
    'Gisagara STATIONS',
    'Huye STATIONS',
    'Kamonyi STATIONS',
    'Muhanga STATIONS',
    'Nyamagabe STATIONS',
    'Nyanza STATIONS',
    'Nyaruguru STATIONS',
    'Ruhango STATIONS',
    'Karongi STATIONS',
    'Ngororero STATIONS',
    'Nyabihu STATIONS',
    'Nyamasheke STATIONS',
    'Rubavu STATIONS',
    'Rusizi STATIONS',
    'Rutsiro STATIONS',
    'Other (Please specify)',
  ];

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate sector selection
    if (_selectedSector == null) {
      Fluttertoast.showToast(
        msg: 'Please select a RIB Station',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorColor,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use selected sector or custom input
      String sector = _selectedSector!;
      if (_selectedSector == 'Other (Please specify)') {
        sector = _sectorController.text.trim();
        if (sector.isEmpty) {
          Fluttertoast.showToast(
            msg: 'Please specify the RIB Station name',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: AppColors.errorColor,
            textColor: Colors.white,
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final userData = {
        'sector': sector,
        'fullname': _fullnameController.text.trim(),
        'position': _positionController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'staff', // Default role for all registrations
      };

      await ApiService.register(userData);
      
      Fluttertoast.showToast(
        msg: "Registration successful! Please check your email for verification.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.successColor,
        textColor: Colors.white,
      );
      
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryColor, AppColors.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  const SizedBox(height: 20),
                  
                  // Back Button
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  // User Icon
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'SIGN UP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // RIB Station Selection - Beautiful Searchable Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownSearch<String>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search RIB Station...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                            ),
                          ),
                        ),
                        menuProps: MenuProps(
                          backgroundColor: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          elevation: 8,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        itemBuilder: (context, item, isSelected) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                item,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primaryColor : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryColor,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                      items: _ribStations,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Select RIB Station *',
                          hintText: 'Choose your RIB Station',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                          ),
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryColor),
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSector = newValue;
                        });
                      },
                      selectedItem: _selectedSector,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a RIB Station';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  // Custom Sector Input (only shown if "Other" is selected)
                  if (_selectedSector == 'Other (Please specify)')
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(top: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _sectorController,
                        decoration: InputDecoration(
                          labelText: 'RIB Station Name *',
                          hintText: 'Enter RIB Station Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (_selectedSector == 'Other (Please specify)') {
                            return Validators.validateRequired(value);
                          }
                          return null;
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 15),
                  
                  // Full Name Field
                  CustomTextField(
                    controller: _fullnameController,
                    hintText: 'Enter Full Name',
                    labelText: 'Full Name *',
                    validator: Validators.validateRequired,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Position Field
                  CustomTextField(
                    controller: _positionController,
                    hintText: 'Enter Position',
                    labelText: 'Position *',
                    validator: Validators.validateRequired,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter your Email',
                    labelText: 'Email Address *',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter your Password',
                    labelText: 'Password *',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: const Color(0xFF2196F3),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: Validators.validateStrongPassword,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Register Button
                  if (_isLoading)
                    const Center(child: LoadingWidget())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Register',
                            onPressed: _register,
                            backgroundColor: AppColors.successColor,
                            borderRadius: 15,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.pop(context),
                            backgroundColor: AppColors.errorColor,
                            borderRadius: 15,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                  
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have Account? ",
                              style: TextStyle(color: Colors.white),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Beautiful Footer
              BeautifulFooter(
                currentIndex: 1,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                      break;
                    case 1:
                      // Already on login/register screen
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewsScreen()),
                      );
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sectorController.dispose();
    _fullnameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}