
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taxiuuse/data/bookingmodel.dart';

class DriverAppService {
  late IO.Socket socket;
  final String driverId;
  final Function(BookingModel) onNewBooking;
  final Function(BookingModel) onBookingAccepted;
  final Function(BookingModel) onBookingRejected;
  final Function(String, bool) onDriverStatusChanged;

  DriverAppService({
    required this.driverId,
    required this.onNewBooking,
    required this.onBookingAccepted,
    required this.onBookingRejected,
    required this.onDriverStatusChanged,
  });

  void connect() {
    socket = IO.io(
      'https://olaappbackendcode.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // Connection events
    socket.onConnect((_) {
      print('Driver app connected to server');
      
      // Join as driver
      socket.emit('driver_join', {
        'driverId': driverId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    socket.onDisconnect((_) {
      print('Driver app disconnected from server');
    });

    // Listen for new bookings
    socket.on('new_booking', (data) {
      try {
        if (!_isForCurrentDriver(data)) {
          return;
        }
        final booking = BookingModel.fromJson(data);
        print('New booking received: ${booking.id}');
        onNewBooking(booking);
      } catch (e) {
        print('Error parsing new booking: $e');
      }
    });

    // Listen for booking acceptance notifications
    socket.on('booking_accepted', (data) {
      try {
        if (!_isForCurrentDriver(data)) {
          return;
        }
        final booking = BookingModel.fromJson(data);
        print('Booking accepted: ${booking.id}');
        onBookingAccepted(booking);
      } catch (e) {
        print('Error parsing booking acceptance: $e');
      }
    });

    // Listen for booking rejection notifications
    socket.on('booking_rejected', (data) {
      try {
        final booking = BookingModel.fromJson(data);
        print('Booking rejected: ${booking.id}');
        onBookingRejected(booking);
      } catch (e) {
        print('Error parsing booking rejection: $e');
      }
    });

    // Listen for driver status changes
    socket.on('driver_status_changed', (data) {
      try {
        final driverId = data['driverId'] as String;
        final isOnline = data['isOnline'] as bool;
        print('Driver status changed: $driverId -> $isOnline');
        onDriverStatusChanged(driverId, isOnline);
      } catch (e) {
        print('Error parsing driver status change: $e');
      }
    });

    // Handle errors
    socket.on('error', (error) {
      print('Socket error: $error');
    });
  }

  void acceptBooking(String bookingId) {
    socket.emit('accept_booking', {
      'bookingId': bookingId,
      'driverId': driverId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void rejectBooking(String bookingId) {
    socket.emit('reject_booking', {
      'bookingId': bookingId,
      'driverId': driverId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  bool _isForCurrentDriver(dynamic data) {
    if (data is! Map) return true;

    final dynamic targetDriverId = data['driverId'] ?? data['assignedDriverId'];
    if (targetDriverId == null) {
      return true;
    }

    return targetDriverId.toString() == driverId;
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }

  bool get isConnected => socket.connected;
}
