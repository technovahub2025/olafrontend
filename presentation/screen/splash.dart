import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taxiuuse/core/color.dart';
import 'package:taxiuuse/presentation/screen/bottomnavbar.dart';
import 'package:taxiuuse/presentation/screen/login.dart';
import 'package:taxiuuse/presentation/screen/roleselection.dart';
import 'package:taxiuuse/presentation/screen/welcomescreen.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';

class userSplashScreen extends StatefulWidget {
  const userSplashScreen({super.key});

  @override
  State<userSplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<userSplashScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      // Reduced splash delay from 3 to 2 seconds
      await Future.delayed(const Duration(seconds: 2));

      bool isLoggedIn = await SessionManager.isLoggedIn();

      if (!mounted) return;

      if (isLoggedIn) {
        print('✅ User logged in, navigating to welcome screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        print('🔐 User not logged in, navigating to login screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } catch (e) {
      print('❌ Splash screen error: $e');
      if (!mounted) return;
      
      // Fallback navigation on error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splash,
      body: Center(
        child: Image.asset('assets/logotaxi.png'),
      ),
    );
  }
}
