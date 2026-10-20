import 'package:flutter/material.dart';
import 'package:taxiuuse/drivermodel/loginmodel.dart';
import 'package:taxiuuse/driverscreen/bookingscreen.dart';
import 'package:taxiuuse/driverservice/loginservice.dart';
import 'package:taxiuuse/driverwidegts/button.dart';
import 'package:taxiuuse/driverwidegts/loginfield.dart';
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';


class driverLoginScreen extends StatefulWidget {
  const driverLoginScreen({super.key});

  @override
  State<driverLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<driverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  final LoginService _authService = LoginService();

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters for validation
    final cleanedPhone = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanedPhone.length < 10) {
      return 'Enter a valid phone number (at least 10 digits)';
    }
    
    // Optional: Validate phone format
    if (!RegExp(r'^[+]?[\d\s\-()]+$').hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanedPhone = _phoneCtrl.text.replaceAll(RegExp(r'[^\d+]'), '');
      
      final loginRequest = LoginRequest(
        name: _nameCtrl.text.trim(),
        phone: cleanedPhone,
        // Remove password field if not needed
        // password: '', // Keep if your backend still expects it
      );

      final response = await _authService.login(loginRequest);

      if (response.success) {
        // Store token if available
        if (response.token != null) {
          await SessionManager.saveToken(response.token!);
        }

        // Show success message
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Extract user ID
        final String? userId = response.user?['_id']?.toString() ?? response.user?['id']?.toString();
        
        // Navigate to welcome screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => BookingsScreen()),
            (route) => false,
          );
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _forgotPassword() {
    // Since we're using name+phone, you might want to change this
    // to "Forgot PIN" or "Reset Account" functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Recovery'),
        content: const Text('Contact support to recover your account'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // Welcome Text
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Sign in to continue your journey",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Name Field
                CustomTextField(
                  label: "Full Name",
                  hintText: "Enter your full name",
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  validator: _validateName,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_phoneFocusNode);
                  },
                ),

                const SizedBox(height: 24),

                // Phone Field
                CustomTextField(
                  label: "Phone Number",
                  hintText: "Enter your phone number",
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  focusNode: _phoneFocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),

                const SizedBox(height: 16),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          activeColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Text(
                          "Remember me",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text(
                        "Need Help?",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Login Button
                CustomButton(
                  text: "Sign In",
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 40),

                // Or continue with (optional - you can remove this if not needed)
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Secure login",
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Optional: Add a PIN field if you implement PIN authentication
                /*
                CustomTextField(
                  label: "PIN (Optional)",
                  hintText: "Enter your 4-digit PIN",
                  controller: _pinCtrl,
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  isPassword: true,
                  maxLength: 4,
                ),
                */

                const SizedBox(height: 40),

              ],
            ),
          ),
        ),
      ),
    );
  }
}