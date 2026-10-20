
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taxiuuse/data/bookingmodel.dart';

class UserAppService {
  late IO.Socket socket;
  final String userId;
  final Function(BookingModel) onBookingAccepted;
  final Function(String) onError;

  UserAppService({
    required this.userId,
    required this.onBookingAccepted,
    required this.onError,
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
      print('User app connected to server');
      
      // Join as user
      socket.emit('user_join', {
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    socket.onDisconnect((_) {
      print('User app disconnected from server');
    });

    // Listen for booking acceptance by drivers
    socket.on('booking_accepted', (data) {
      try {
        final booking = BookingModel.fromJson(data);
        
        onBookingAccepted(booking);
      } catch (e) {
        print('Error parsing booking acceptance: $e');
      }
    });

    // Handle errors
    socket.on('error', (error) {
      print('Socket error: $error');
      onError(error.toString());
    });
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }

  bool get isConnected => socket.connected;
}
