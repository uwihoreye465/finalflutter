import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../home/home_screen.dart';
import '../admin/admin_dashboard.dart';
import '../user/enhanced_report_screen.dart';

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
        
        // Navigate based on user role
        final userRole = authService.user?.role?.toLowerCase();
        if (userRole == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else {
          // For staff or other roles, go to report screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedReportScreen()),
          );
        }
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
      String errorString = e.toString();
      
      if (errorString.contains('Network error')) {
        errorMessage = "Network error: Please check your internet connection";
      } else if (errorString.contains('Unable to connect to server')) {
        errorMessage = "Unable to connect to server. Please check your internet connection.";
      } else if (errorString.contains('Please verify your email')) {
        errorMessage = "Please verify your email before logging in. Check your email for verification link.";
      } else if (errorString.contains('pending admin approval')) {
        errorMessage = "Your account is pending admin approval. Please wait for approval.";
      } else if (errorString.contains('Invalid email or password') || errorString.contains('401')) {
        errorMessage = "Invalid email or password";
      } else if (errorString.contains('Server error') || errorString.contains('500')) {
        errorMessage = "Server error: Please try again later";
      } else if (errorString.contains('Request timeout')) {
        errorMessage = "Request timeout: Please try again";
      } else if (errorString.contains('Invalid input data') || errorString.contains('422')) {
        errorMessage = "Invalid input data: Please check your email and password";
      } else {
        // Extract the actual error message from the exception
        if (errorString.contains('Exception: ')) {
          errorMessage = errorString.split('Exception: ')[1];
        } else {
          errorMessage = "Login failed: Please try again";
        }
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
                  // Back button
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
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
                    validator: Validators.validateEmail,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
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