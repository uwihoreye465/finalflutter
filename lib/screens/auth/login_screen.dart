import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.login(_emailController.text.trim(), _passwordController.text);
      
      if (authService.isAuthenticated) {
        Fluttertoast.showToast(
          msg: "Login successful! Welcome ${authService.user?.fullname ?? 'User'}.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.successColor,
          textColor: Colors.white,
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        Fluttertoast.showToast(
          msg: "Login failed: Invalid credentials",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.errorColor,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      String errorMessage = "Login failed";
      if (e.toString().contains('Network error')) {
        errorMessage = "Network error: Please check your internet connection";
      } else if (e.toString().contains('Login failed')) {
        errorMessage = "Invalid email or password";
      } else if (e.toString().contains('Exception')) {
        errorMessage = "Server error: Please try again later";
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
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
                  const SizedBox(height: 50),
                  
                  // User Icon
                  const Icon(
                    Icons.account_circle,
                    size: 100,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Title
                  const Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
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
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Login Button
                  if (_isLoading)
                    const Center(child: LoadingWidget())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Login',
                            onPressed: _login,
                            backgroundColor: AppColors.successColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomButton(
                            text: 'Cancel',
                            onPressed: () {
                              _emailController.clear();
                              _passwordController.clear();
                            },
                            backgroundColor: AppColors.errorColor,
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // Forgot Password
                  TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                      Fluttertoast.showToast(
                        msg: "Feature coming soon",
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                      );
                    },
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have Account? ",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}