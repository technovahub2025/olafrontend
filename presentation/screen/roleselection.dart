import 'package:flutter/material.dart';
import 'package:taxiuuse/driverscreen/login.dart';
import 'package:taxiuuse/driverservice/loginservice.dart';
import 'package:taxiuuse/presentation/adminscreen/loginscreen.dart';
import 'package:taxiuuse/presentation/screen/login.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              const Text(
                "SELECT YOUR ROLE",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Please select your role to continue",
                style: TextStyle(fontSize: 14),
              ),

              const SizedBox(height: 60),

              // USER BUTTON
              buildRoleButton(
                text: "USER",
                icon: Icons.person,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginScreen()));
                },
              ),

              const SizedBox(height: 20),

              // ADMIN BUTTON
              buildRoleButton(
                text: "ADMIN",
                icon: Icons.admin_panel_settings,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>adminLoginScreen()));
                },
              ),

              const SizedBox(height: 20),

              // DRIVER BUTTON
              buildRoleButton(
                text: "DRIVER",
                icon: Icons.directions_car,
                onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context)=>driverLoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRoleButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.yellow.shade600,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.black),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}