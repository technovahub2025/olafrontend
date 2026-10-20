import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxiuuse/domain/service/locationprovider.dart';
import 'package:taxiuuse/domain/service/userprovider.dart' as app_user_provider;
import 'package:taxiuuse/adminservice/provider.dart' as admin_user_provider;
import 'package:taxiuuse/adminservice/adminprovider.dart';
import 'package:taxiuuse/presentation/adminscreen/splash.dart';
// import 'package:taxiuuse/presentation/screen/splash.dart';
import 'package:taxiuuse/presentation/screen/login.dart';
import 'package:taxiuuse/presentation/screen/roleselection.dart';
import 'package:taxiuuse/presentation/screen/splash.dart';
import 'package:taxiuuse/presentation/screen/welcomescreen.dart';


void main() async {
  // Initialize Flutter binding FIRST
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Google Maps for Android
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  
  
  await dotenv.load(fileName: ".env");
  
  // Verify API key is loaded
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  print('Google Maps API Key loaded: ${apiKey != null && apiKey.isNotEmpty}');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<app_user_provider.UserProvider>(
          create: (_) => app_user_provider.UserProvider(),
        ),
        ChangeNotifierProvider<admin_user_provider.UserProvider>(
          create: (_) => admin_user_provider.UserProvider(),
        ),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: 'Taxi App',
        theme: ThemeData(
          primaryColor: Colors.amber,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            elevation: 2,
          ),
        ),
        home: userSplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/welcome': (context) => const Welcomescreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          );
        },
      ),
    );
  }
}
