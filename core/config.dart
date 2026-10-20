import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final envBaseUrl = dotenv.env['BASE_URL'];
    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      return envBaseUrl.trim();
    }

    if (kIsWeb) {
      return 'https://ola-7ii1.onrender.com';
    }
   
    if (Platform.isAndroid) {
      return 'https://ola-7ii1.onrender.com';
    }
    
    return 'https://ola-7ii1.onrender.com';
  }

  static String get apiBaseUrl => '$baseUrl';
  static String get socketUrl => baseUrl;
}
