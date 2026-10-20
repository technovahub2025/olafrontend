import 'dart:convert';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxiuuse/core/config.dart';
import 'package:taxiuuse/presentation/screen/login.dart';
import 'package:taxiuuse/presentation/screen/profile_details.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';
import 'package:taxiuuse/data/drivermodel.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // User data
  String name = "John Doe";
  String phone = "+91 9876543210";
  String email = "john.doe@example.com";
  

  // Controllers for editing
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  bool isEditing = false;
  bool isOnline = false; // 🔴 Online / Offline status
  bool isSocketConnected = false;
  
  late IO.Socket socket;
  String? userId;
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: name);
    phoneController = TextEditingController(text: phone);
    emailController = TextEditingController(text: email);
    _loadUserData();
    _initSocket();
  }

  Future<void> _loadUserData() async {
    final userDataJson = await SessionManager.getUserData();
    if (userDataJson != null) {
      final userData = json.decode(userDataJson);
      setState(() {
        currentUser = UserModel.fromJson(userData);
        name = currentUser?.name ?? name;
        phone = currentUser?.phone ?? phone;
        isOnline = currentUser?.isOnline ?? isOnline;
        
        nameController.text = name;
        phoneController.text = phone;
        emailController.text = email;
      });
    }
    
    // Try to get ID from session manager first, then from currentUser
    final storedUserId = await SessionManager.getUserId();
    setState(() {
      userId = storedUserId ?? currentUser?.id;
    });

    if (userId == null) {
      debugPrint("Warning: userId is null in Profile Screen. Sync may fail.");
      return;
    }

    await _loadSavedContactFromBackend();
  }

  Future<void> _loadSavedContactFromBackend() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/profile-contact/$userId'),
      );
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>;
      setState(() {
        name = (data['name'] ?? name).toString();
        phone = (data['phone'] ?? phone).toString();
        email = (data['email'] ?? email).toString();
        nameController.text = name;
        phoneController.text = phone;
        emailController.text = email;
      });
    } catch (_) {}
  }

  Future<void> _saveContactDetails() async {
    final trimmedName = nameController.text.trim();
    final trimmedPhone = phoneController.text.trim();
    final trimmedEmail = emailController.text.trim();
    final resolvedUserId = userId ?? currentUser?.id;

    final localUserData = {
      '_id': resolvedUserId,
      'name': trimmedName,
      'phone': trimmedPhone,
      'email': trimmedEmail,
      'isOnline': isOnline,
    };

    await SessionManager.saveUserData(json.encode(localUserData));
    await SessionManager.saveRegisteredUserName(trimmedName);

    if (resolvedUserId == null || resolvedUserId.isEmpty) return;

    await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/profile-contact'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id': resolvedUserId,
        'name': trimmedName,
        'phone': trimmedPhone,
        'email': trimmedEmail,
      }),
    );
  }

 

  void _initSocket() {
    socket = IO.io(
      dotenv.env['SOCKET_URL'] ?? 'http://localhost:4000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Profile Socket connected');
      setState(() => isSocketConnected = true);
    });

    socket.onDisconnect((_) {
      debugPrint('Profile Socket disconnected');
      setState(() => isSocketConnected = false);
    });
    
    socket.onConnectError((err) {
      debugPrint('Profile Socket connection error: $err');
      setState(() => isSocketConnected = false);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  String _buildProfileQrUrl() {
    final base = AppConfig.baseUrl;
    final uri = Uri.parse('$base/profile').replace(
      queryParameters: {
        'id': userId ?? currentUser?.id ?? '',
        'name': name,
        'phone': phone,
        'email': email,
      },
    );
    return uri.toString();
  }

  Future<void> toggleEditMode() async {
    if (isEditing) {
      // Save changes
      await _saveContactDetails();
      setState(() {
        name = nameController.text;
        phone = phoneController.text;
        email = emailController.text;
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      setState(() {
        isEditing = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with background
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.amber,
                              ),
                            ),
                            if (isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                       
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      onPressed: toggleEditMode,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.amber,
                      child: Icon(
                        isEditing ? Icons.check : Icons.edit,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // Status Toggle
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
               
              ),
            ),

            // Profile Information Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.person,
                    label: "Full Name",
                    value: isEditing ? null : name,
                    controller: nameController,
                    isEditing: isEditing,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.phone,
                    label: "Phone Number",
                    value: isEditing ? null : phone,
                    controller: phoneController,
                    isEditing: isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    icon: Icons.email,
                    label: "Email Address",
                    value: isEditing ? null : email,
                    controller: emailController,
                    isEditing: isEditing,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            if (!isEditing) ...[
             
              _buildActionButton(
                icon: Icons.qr_code,
                text: "View Profile QR",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileQrScreen(
                        name: name,
                        phone: phone,
                        email: email,
                        qrUrl: _buildProfileQrUrl(),
                      ),
                    ),
                  );
                },
              ),
            
              _buildActionButton(
                icon: Icons.business_center,
                text: "Business Details",
                onTap: () {
                  final resolvedUserId = userId ?? currentUser?.id;
                  if (resolvedUserId == null || resolvedUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID not found')),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileDetailsScreen(userId: resolvedUserId),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.support_agent,
                text: "Support Center",
                onTap: () {},
              ),
             
              _buildActionButton(
                icon: Icons.logout,
                text: "Log Out",
                onTap: () {
                  // Logout logic
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                },
                color: Colors.red,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String? value,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.amber, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileQrScreen extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String qrUrl;

  const ProfileQrScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.qrUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile QR'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 72, color: Colors.amber),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(phone),
                    const SizedBox(height: 4),
                    Text(email),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Scan to open this profile page',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: qrUrl,
                      size: 240,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
