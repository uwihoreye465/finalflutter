import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'sector': _sectorController.text.trim(),
        'fullname': _fullnameController.text.trim(),
        'position': _positionController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'staff', // Default role
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
                  
                  // Sector Field
                  CustomTextField(
                    controller: _sectorController,
                    hintText: 'Enter Sector',
                    validator: Validators.validateRequired,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Full Name Field
                  CustomTextField(
                    controller: _fullnameController,
                    hintText: 'Enter Fullname',
                    validator: Validators.validateRequired,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Position Field
                  CustomTextField(
                    controller: _positionController,
                    hintText: 'Enter Position',
                    validator: Validators.validateRequired,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter your Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  
                  const SizedBox(height: 15),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter your Password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
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
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () => Navigator.pop(context),
                            backgroundColor: AppColors.errorColor,
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