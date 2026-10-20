import 'package:flutter/material.dart';
import 'package:taxiuuse/presentation/adminscreen/loginscreen.dart';
import 'package:taxiuuse/presentation/adminscreen/register.dart';
import 'package:taxiuuse/presentation/adminscreen/splash.dart';
import 'package:taxiuuse/presentation/adminscreen/userlist.dart';




class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const profile = '/profile';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminHome = '/admin-home';
  static const String bookings = '/bookings';
  static const String drivers = '/drivers';
  static const String driverDashboard = '/driver-dashboard';
  static const String orders = '/orders';
  static const String users = '/users';
  static const String statistics = '/statistics';

  static const String driverlist='/driverlist';

  static Map<String, Widget Function(BuildContext)> routes = {
    splash: (context) => SplashScreen(),
    login:(context)=>adminLoginScreen(),
    register: (context) => RegisterScreen(),
    profile: (context) => UserScreen(),
    

    drivers: (context) => UserScreen(),
    
  };
}
