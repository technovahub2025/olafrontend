import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxiuuse/driverscreen/login.dart';
import 'package:taxiuuse/driverscreen/ridescreen.dart';

import 'package:taxiuuse/driverservice/bookingservice.dart';

import 'package:taxiuuse/tokenmagemet/drivertoken.dart';

String _safeText(dynamic value) => value?.toString() ?? '';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<Booking> bookings = [];
  bool isLoading = true;
  String? error;
  final TextEditingController _nameFilterController = TextEditingController();
  String _nameQuery = '';
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  CameraPosition? initialPosition;
  String? _currentDriverId;
  String? _currentDriverName;
  DateTime? _selectedDate;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _nameFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final userData = await SessionManager.getUserFromToken();
      _currentDriverId = userData?['id']?.toString();
      final rawUser = userData?['userData'] as Map<String, dynamic>?;
      _currentDriverName = rawUser?['name']?.toString().trim();
      final driverBookings = await BookingService.getDriverBookings();
      setState(() {
        bookings = driverBookings;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Booking> get _filteredBookings {
    final query = _safeText(_nameQuery).trim().toLowerCase();

    return bookings.where((booking) {
      final passengerName = _safeText(booking.passengerName).toLowerCase();
      final driverName = _safeText(booking.driverName).toLowerCase();

      final matchesName =
          query.isEmpty || passengerName.contains(query) || driverName.contains(query);

      final matchesDate = _selectedDate == null
          ? true
          : booking.createdAt.year == _selectedDate!.year &&
              booking.createdAt.month == _selectedDate!.month &&
              booking.createdAt.day == _selectedDate!.day;

      return matchesName && matchesDate;
    }).toList();
  }

  Future<void> _pickBookingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _nameFilterController.clear();
      _nameQuery = '';
      _selectedDate = null;
    });
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      final booking = bookings.firstWhere((item) => item.id == bookingId);
      await BookingService.updateBookingStatus(
        bookingId,
        status,
        bookingDriverId: booking.driverId,
        bookingDriverName: booking.driverName,
      );
      _loadBookings(); // Refresh the list
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startRide(Booking booking) async {
    // Get detailed booking info with coordinates
    try {
      final detailedBooking = await BookingService.getBookingById(booking.id);
      if (detailedBooking != null) {
        // Navigate to ride screen with Google Maps
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RideScreen(booking: booking),
          ),
        ).then((refresh) {
          // Refresh bookings if coming back from completed ride
          if (refresh == true) {
            print('DEBUG: Refreshing bookings after ride completion');
            _loadBookings();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading ride details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _acceptRide(Booking booking) async {
    try {
      if (_currentDriverId != null &&
          _hasText(booking.driverId) &&
          booking.driverId != _currentDriverId) {
        throw Exception('This ride is booked for another driver');
      }

      await BookingService.updateBookingStatus(
        booking.id,
        'assigned',
        bookingDriverId:
            _hasText(booking.driverId) ? booking.driverId : _currentDriverId,
        bookingDriverName: _hasText(booking.driverName)
            ? booking.driverName
            : _currentDriverName,
      );
      if (!mounted) return;
      await _loadBookings();
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RideScreen(booking: booking)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    try {
      print('DEBUG: Starting logout from bookings page...');
      
      // Get current token before clearing (for debugging)
      final currentToken = await SessionManager.getToken();
      print('DEBUG: Current token before logout: $currentToken');
      
      // Get current user data before clearing (for debugging)
      final currentUserData = await SessionManager.getUserFromToken();
      print('DEBUG: Current user data before logout: $currentUserData');
      
      // Clear all session data (JWT token + user data)
      await SessionManager.clearSession();
      print('DEBUG: Session cleared successfully');
      
      // Verify token is removed
      final tokenAfterClear = await SessionManager.getToken();
      print('DEBUG: Token after clearing: $tokenAfterClear');
      
      // Verify user data is removed
      final userDataAfterClear = await SessionManager.getUserFromToken();
      print('DEBUG: User data after clearing: $userDataAfterClear');
      
      // Check login status after clearing
      final isLoggedInAfter = await SessionManager.isLoggedIn();
      print('DEBUG: Is logged in after clearing: $isLoggedInAfter');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged out successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to login screen and clear all previous routes
       Navigator.push(context, MaterialPageRoute(builder: (context)=>driverLoginScreen()));
        
        print('DEBUG: Navigated to login screen');
      }
    } catch (e) {
      print('DEBUG: Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Logout error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout? This will clear your session and you will need to login again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _logout(); // Perform logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh bookings',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: _clearFilters,
            tooltip: 'Clear filters',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading bookings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_online, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No rides available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('All rides will appear here for every driver'),
          ],
        ),
      );
    }

    final filteredBookings = _filteredBookings;
    final currentQuery = _safeText(_nameQuery).trim();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                  controller: _nameFilterController,
                  onChanged: (value) {
                    setState(() {
                      _nameQuery = value.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Filter by passenger name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                            setState(() {
                              _nameFilterController.clear();
                              _nameQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickBookingDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter by date'
                            : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                      ),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear date',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing ${filteredBookings.length} of ${bookings.length} bookings',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filteredBookings.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 120),
            child: Center(
              child: Text(
                'No bookings match the selected filters',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ...filteredBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: BookingCard(
                booking: booking,
                onStatusUpdate: (status) =>
                    _updateBookingStatus(booking.id, status),
                onStartRide: (booking) => _startRide(booking),
                onAcceptRide: (booking) => _acceptRide(booking),
              ),
            ),
          ),
      ],
    );
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Function(String) onStatusUpdate;
  final Function(Booking) onStartRide;
  final Function(Booking) onAcceptRide;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onStatusUpdate,
    required this.onStartRide,
    required this.onAcceptRide,
  });

  Color _getStatusColor() {
    switch (booking.status) {
      case 'assigned':
        return Colors.orange;
      case 'ongoing':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _safeValue(dynamic value) => value?.toString() ?? '';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeValue(booking.passengerName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking #${booking.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLocationRow('Pickup', _safeValue(booking.pickupLocation), Icons.location_on),
            const SizedBox(height: 8),
            _buildLocationRow('Dropoff', _safeValue(booking.dropoffLocation), Icons.flag),
            const SizedBox(height: 12),
            Text(
              'Created: ${_formatDate(booking.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (booking.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onAcceptRide(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onStatusUpdate('cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'assigned' || booking.status == 'ongoing') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => onStartRide(booking),
                  icon: const Icon(Icons.directions_car),
                  label: Text(booking.status == 'assigned' ? 'Start Service' : 'Resume Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String location, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    final second = localDate.second.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute:$second';
  }
}
