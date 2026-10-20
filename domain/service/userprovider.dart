// lib/data/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/domain/driverservice.dart';


class UserProvider with ChangeNotifier {
  final ProfileService _userService = ProfileService();
  
  List<UserModel> _users = [];
  bool _isLoading = false;
  String _error = '';

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _users = await _userService.getAllUsers();
      _error = '';
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Clear users
  void clearUsers() {
    _users.clear();
    notifyListeners();
  }
}