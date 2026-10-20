import 'package:flutter/foundation.dart';
import 'package:taxiuuse/adminmodel/profilemodel.dart';
import 'package:taxiuuse/adminservice/profileservice.dart';



class UserProvider with ChangeNotifier {
  List<profilemodel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<profilemodel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

   Future<void> getUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _users = await ProfileService.getUsers();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUser(
    Map<String, dynamic> userData,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await ProfileService.addUser(userData);
      await getUsers(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(
    String id,
    Map<String, dynamic> userData,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await ProfileService.updateUser(id, userData);
      await getUsers(); // Refresh list
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await ProfileService.deleteUser(id);
      _users.removeWhere((user) => user.id == id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  profilemodel? getUserById(String id) {
    try {
      return _users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }
}
