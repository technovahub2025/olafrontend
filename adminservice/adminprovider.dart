import 'package:flutter/foundation.dart';
import 'package:taxiuuse/adminservice/bookingservice.dart';
import 'package:taxiuuse/adminservice/profileservice.dart';
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/data/profilemodel.dart';
import 'package:taxiuuse/data/registermodel.dart';



class AdminProvider with ChangeNotifier {
  // Booking data
  List<BookingModel> _bookings = [];
  List<BookingModel> _pendingBookings = [];
  List<BookingModel> _assignedBookings = [];
  List<BookingModel> _completedBookings = [];
  List<BookingModel> _cancelledBookings = [];
  
  // User data
  List<UserModel> _users = [];
  List<profilemodel> _drivers = [];
  
  // Statistics
  Map<String, int> _bookingStats = {};
  Map<String, int> _userStats = {};
  Map<String, int> _driverStats = {};
  
  // Loading states
  bool _isLoading = false;
  bool _isBookingLoading = false;
  bool _isUserLoading = false;
  bool _isDriverLoading = false;
  
  // Error messages
  String? _errorMessage;

  // Getters
  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get pendingBookings => _pendingBookings;
  List<BookingModel> get assignedBookings => _assignedBookings;
  List<BookingModel> get completedBookings => _completedBookings;
  List<BookingModel> get cancelledBookings => _cancelledBookings;
  List<UserModel> get users => _users;
  List<profilemodel> get drivers => _drivers;
  Map<String, int> get bookingStats => _bookingStats;
  Map<String, int> get userStats => _userStats;
  Map<String, int> get driverStats => _driverStats;
  bool get isLoading => _isLoading;
  bool get isBookingLoading => _isBookingLoading;
  bool get isUserLoading => _isUserLoading;
  bool get isDriverLoading => _isDriverLoading;
  String? get errorMessage => _errorMessage;

  // Load all dashboard data
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await Future.wait([
        loadBookings(),
        loadUsers(),
        loadDrivers(),
        loadStatistics(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load bookings
  Future<void> loadBookings() async {
    _isBookingLoading = true;
    notifyListeners();
    
    try {
      _bookings = await BookingService.getAllBookings();
      _pendingBookings = await BookingService.getBookingsByStatus('pending');
      _assignedBookings = await BookingService.getBookingsByStatus('assigned');
      _completedBookings = await BookingService.getBookingsByStatus('completed');
      _cancelledBookings = await BookingService.getBookingsByStatus('cancelled');
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isBookingLoading = false;
      notifyListeners();
    }
  }

  // Load users
  Future<void> loadUsers() async {
    _isUserLoading = true;
    notifyListeners();
    
    try {
      _users = await BookingService.getAllUsers();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isUserLoading = false;
      notifyListeners();
    }
  }

  // Load drivers
  Future<void> loadDrivers() async {
    _isDriverLoading = true;
    notifyListeners();
    
    try {
      _drivers = (await ProfileService.getUsers()).cast<profilemodel>();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isDriverLoading = false;
      notifyListeners();
    }
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _bookingStats = await BookingService.getBookingStats();
      _userStats = await BookingService.getUserStats();
      _driverStats = await BookingService.getDriverStats();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await BookingService.updateBookingStatus(bookingId, status);
      await loadBookings(); // Refresh bookings
      await loadStatistics(); // Refresh stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Assign driver to booking
  Future<bool> assignDriver(String bookingId, String driverId) async {
    try {
      await BookingService.assignDriver(bookingId, driverId);
      await loadBookings(); // Refresh bookings
      await loadStatistics(); // Refresh stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Add driver (using existing ProfileService)
  Future<bool> addDriver(Map<String, dynamic> driverData) async {
    try {
      await ProfileService.addUser(driverData);
      await loadDrivers(); // Refresh drivers
      await loadStatistics(); // Refresh stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Update driver (using existing ProfileService)
  Future<bool> updateDriver(String id, Map<String, dynamic> driverData) async {
    try {
      await ProfileService.updateUser(id, driverData);
      await loadDrivers(); // Refresh drivers
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Delete driver (using existing ProfileService)
  Future<bool> deleteDriver(String id) async {
    try {
      await ProfileService.deleteUser(id);
      await loadDrivers(); // Refresh drivers
      await loadStatistics(); // Refresh stats
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDashboardData();
  }
}
