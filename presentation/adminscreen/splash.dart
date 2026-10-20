import 'package:flutter/material.dart';

import 'dart:async';

import 'package:taxiuuse/routes/adminroutes.dart';


class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "Taxi Admin",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
      ),
    );
  }
}
