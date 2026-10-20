import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:taxiuuse/data/loginmodel.dart';
import 'package:taxiuuse/domain/service/loginservice.dart';
import 'package:taxiuuse/presentation/screen/register.dart';
import 'package:taxiuuse/presentation/screen/welcomescreen.dart';
import 'package:taxiuuse/presentation/widegts/button.dart';
import 'package:taxiuuse/presentation/widegts/loginfield.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  String? _extractUserId(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;

    final direct = payload['_id'] ?? payload['id'] ?? payload['userId'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    for (final key in ['user', 'data', 'profile', 'account']) {
      final nested = payload[key];
      final nestedId = _extractUserId(nested);
      if (nestedId != null && nestedId.trim().isNotEmpty) {
        return nestedId;
      }
    }

    for (final value in payload.values) {
      final nestedId = _extractUserId(value);
      if (nestedId != null && nestedId.trim().isNotEmpty) {
        return nestedId;
      }
    }

    return null;
  }

  String? _extractDisplayName(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;

    final directName = payload['name'] ??
        payload['fullName'] ??
        payload['username'] ??
        payload['userName'];
    if (directName != null && directName.toString().trim().isNotEmpty) {
      return directName.toString().trim();
    }

    for (final key in ['user', 'data', 'profile', 'account', 'userData']) {
      final nested = payload[key];
      final nestedName = _extractDisplayName(nested);
      if (nestedName != null && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    for (final value in payload.values) {
      final nestedName = _extractDisplayName(value);
      if (nestedName != null && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginRequest = LoginRequest(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final response = await _authService.login(loginRequest);

      if (response.success) {
        // Store remember me preference
         if (response.token != null) {
          await SessionManager.saveToken(response.token!);
        }

        if (response.user != null) {
          final userId = _extractUserId(response.user);
          if (userId != null) {
            await SessionManager.saveUserId(userId);
          }
          final registeredName = _extractDisplayName(response.user);
          if (registeredName != null) {
            await SessionManager.saveRegisteredUserName(registeredName);
          }
          await SessionManager.saveUserData(json.encode(response.user));
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to welcome screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => Welcomescreen()),
            (route) => false,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    final forgotEmailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    
    // Password visibility states
    bool _obscureOldPassword = true;
    bool _obscureNewPassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Forgot Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: forgotEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: oldPasswordCtrl,
                  obscureText: _obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Old Password',
                    hintText: 'Enter old password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureOldPassword = !_obscureOldPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordCtrl,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = forgotEmailCtrl.text.trim();
              final oldPassword = oldPasswordCtrl.text.trim();
              final newPassword = newPasswordCtrl.text.trim();

              if (email.isEmpty || oldPassword.isEmpty || newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final response = await _authService.forgotPassword(
                email: email,
                oldPassword: oldPassword,
                newPassword: newPassword,
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response.message),
                  backgroundColor: response.success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Update Password'),
          ),
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passwordFocusNode.dispose();
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

                // Email Field
                CustomTextField(
                  label: "Email Address",
                  hintText: "Enter your email",
                  controller: _emailCtrl,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                ),

                const SizedBox(height: 24),

                // Password Field
                CustomTextField(
                  label: "Password",
                  hintText: "Enter your password",
                  controller: _passCtrl,
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  showPasswordToggle: true,
                  validator: _validatePassword,
                  focusNode: _passwordFocusNode,
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


              

                const SizedBox(height: 40),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}
