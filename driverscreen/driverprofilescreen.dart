import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxiuuse/driverservice/driverprofileservice.dart';
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';


class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();

  DriverProfile? profile;
  bool isLoading = true;
  bool isUpdating = false;
  String? error;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final driverProfile = await DriverProfileService.getProfile();
      setState(() {
        profile = driverProfile;
        _nameController.text = driverProfile.name;
        _phoneController.text = driverProfile.phone;
        _vehicleController.text = driverProfile.vehicleNumber;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isUpdating = true;
    });

    try {
      final updatedProfile = await DriverProfileService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleNumber: _vehicleController.text.trim(),
        profileImagePath: _selectedImage?.path,
      );

      setState(() {
        profile = updatedProfile;
        _selectedImage = null;
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      print('DEBUG: Starting logout process...');
      
      // Get current token before clearing (for debugging)
      final currentToken = await SessionManager.getToken();
      print('DEBUG: Current token before logout: $currentToken');
      
      // Get current user data before clearing (for debugging)
      final currentUserData = await SessionManager.getUserFromToken();
      print('DEBUG: Current user data before logout: $currentUserData');
      
      // Clear all session data (JWT token + user data)
      await SessionManager.clearSession();
      print('DEBUG: Session cleared successfully');
      
      // Verify token is removed
      final tokenAfterClear = await SessionManager.getToken();
      print('DEBUG: Token after clearing: $tokenAfterClear');
      
      // Verify user data is removed
      final userDataAfterClear = await SessionManager.getUserFromToken();
      print('DEBUG: User data after clearing: $userDataAfterClear');
      
      // Check login status after clearing
      final isLoggedInAfter = await SessionManager.isLoggedIn();
      print('DEBUG: Is logged in after clearing: $isLoggedInAfter');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged out successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        
        print('DEBUG: Navigated to login screen');
      }
    } catch (e) {
      print('DEBUG: Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Logout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            accountName: Text(profile?.name ?? 'Driver'),
            accountEmail: Text(profile?.email ?? 'driver@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: profile?.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        profile!.profileImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, size: 30, color: Colors.blue);
                        },
                      ),
                    )
                  : Icon(Icons.person, size: 30, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          
          // Profile Section
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text('Edit Profile'),
            subtitle: const Text('Update your information'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Already on profile screen, so just scroll to top
            },
          ),
          
          // Account Status
          ListTile(
            leading: Icon(
              profile?.isOnline == true ? Icons.online_prediction : Icons.offline_bolt,
              color: profile?.isOnline == true ? Colors.green : Colors.grey,
            ),
            title: Text('Status: ${profile?.isOnline == true ? 'Online' : 'Offline'}'),
            subtitle: Text('Last seen: ${_formatDate(profile?.lastSeen ?? DateTime.now())}'),
            onTap: () {
              Navigator.pop(context); // Close drawer
            },
          ),
          
          const Divider(),
          
          // Bookings History
          ListTile(
            leading: const Icon(Icons.history, color: Colors.orange),
            title: const Text('Booking History'),
            subtitle: const Text('View your ride history'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to booking history (you can implement this)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking history coming soon!')),
              );
            },
          ),
          
          // Earnings
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.green),
            title: const Text('Earnings'),
            subtitle: const Text('View your earnings summary'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to earnings (you can implement this)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Earnings dashboard coming soon!')),
              );
            },
          ),
          
          // Settings
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.grey),
            title: const Text('Settings'),
            subtitle: const Text('App preferences and settings'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to settings (you can implement this)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          
          // Help & Support
          ListTile(
            leading: const Icon(Icons.help_center, color: Colors.purple),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Navigate to help (you can implement this)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon!')),
              );
            },
          ),
          
          const Divider(),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout'),
            subtitle: const Text('Sign out of your account'),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showLogoutConfirmation();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _logout(); // Perform logout
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileImage(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _vehicleController,
              label: 'Vehicle Number',
              icon: Icons.directions_car,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your vehicle number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildStatusInfo(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUpdating ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isUpdating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Update Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.blue, width: 3),
              ),
              child: _buildImageContent(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to change photo',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (_selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    }

    if (profile?.profileImage != null) {
      return ClipOval(
        child: Image.network(
          profile!.profileImage!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.camera_alt,
      size: 40,
      color: Colors.grey[400],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildStatusInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Email', profile?.email ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Status',
              profile?.isOnline == true ? 'Online' : 'Offline',
              statusColor: profile?.isOnline == true ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Last Seen',
              _formatDate(profile?.lastSeen ?? DateTime.now()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Row(
          children: [
            if (statusColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
