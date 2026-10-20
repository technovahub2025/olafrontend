import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/driverservice/driverservice.dart';
import 'package:taxiuuse/tokenmagemet/drivertoken.dart';



class UsersScreen extends StatefulWidget {
  const UsersScreen({Key? key}) : super(key: key);

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  List<UserModel> _users = [];
  String? _errorMessage;

  String? _userId;
  String? _role; // driver / user / admin

  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initSocket();
    _loadUsers();
    _fetchUserFromToken();
  }

  /// ===============================
  /// FETCH USER ID + ROLE FROM TOKEN
  /// ===============================
  Future<void> _fetchUserFromToken() async {
    final data = await SessionManager.getUserFromToken();

    if (data != null && mounted) {
      setState(() {
        _userId = data['id'];
        _role = data['role'];
      });

      // Only drivers go ONLINE
      if (_role == 'driver') {
        _emitDriverOnline();
      }
    }
  }

  /// ===============================
  /// SOCKET INITIALIZATION
  /// ===============================
  void _initSocket() {
    socket = IO.io(
      'http://127.0.0.1:4000', // replace with your backend IP
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected');
      if (_role == 'driver') _emitDriverOnline();
      setState(() {});
    });

    // Listen for driver online/offline changes
    socket.on('driverStatusChanged', (data) {
      final String driverId = data['driverId'];
      final bool isOnline = data['isOnline'];

      setState(() {
        final index = _users.indexWhere((u) => u.id == driverId);
        if (index != -1) {
          _users[index] = _users[index].copyWith(isOnline: isOnline);
        }
      });
    });

    // Listen for new ride requests
    socket.on('newRideRequest', (data) => _showRideRequestDialog(data));

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
      setState(() {});
    });
  }

  /// ===============================
  /// EMIT DRIVER ONLINE / OFFLINE
  /// ===============================
  void _emitDriverOnline() {
    if (!socket.connected) return;
    if (_role != 'driver') return;
    if (_userId == null || _userId!.isEmpty) return;

    socket.emit('driverOnline', {'userId': _userId});
    debugPrint('DRIVER ONLINE: $_userId');
  }

  void _emitDriverOffline() {
    if (_role != 'driver') return;
    if (_userId == null || _userId!.isEmpty) return;

    socket.emit('driverOffline', {'userId': _userId});
    debugPrint('DRIVER OFFLINE: $_userId');
  }

  /// ===============================
  /// APP LIFECYCLE HANDLER
  /// ===============================
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_role != 'driver') return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _emitDriverOffline();
    }

    if (state == AppLifecycleState.resumed) {
      _emitDriverOnline();
    }
  }

  /// ===============================
  /// API: LOAD USERS
  /// ===============================
  Future<void> _loadUsers() async {
    try {
      final profileService = ProfileService();
      final users = await profileService.getAllUsers();

      setState(() {
        _users = users;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUsers();
  }

  @override
  void dispose() {
    if (_role == 'driver') _emitDriverOffline();
    WidgetsBinding.instance.removeObserver(this);
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  /// ===============================
  /// UI
  /// ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Drivers'),
        centerTitle: true,
        backgroundColor: Colors.amber,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshUsers)
        ],
      ),
      body: Column(
        children: [
          _driverStatusBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _users.isEmpty
                        ? const Center(child: Text('No drivers available'))
                        : RefreshIndicator(
                            onRefresh: _refreshUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _users.length,
                              itemBuilder: (_, i) => _driverCard(_users[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// ONLINE BANNER
  /// ===============================
  Widget _driverStatusBanner() {
    final isOnline =
        socket.connected && _role == 'driver' && _userId != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: isOnline ? Colors.green[100] : Colors.red[100],
      child: Text(
        isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isOnline ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  /// ===============================
  /// DRIVER CARD
  /// ===============================
  Widget _driverCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _profileImage(user.image),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _nameAndStatus(user),
                  const SizedBox(height: 8),
                  _rating(user),
                  const SizedBox(height: 6),
                  Text(user.phone ?? 'No phone'),
                  const SizedBox(height: 6),
                  Text('${user.experience ?? 0} years experience'),
                  if (user.price != null)
                    Text('₹${user.price}/km',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  const SizedBox(height: 10),
                  _bookButton(user),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _profileImage(String? image) {
    return CircleAvatar(
      radius: 35,
      backgroundImage:
          image != null ? CachedNetworkImageProvider(image) : null,
      child: image == null ? const Icon(Icons.person) : null,
    );
  }

  Widget _nameAndStatus(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: Text(user.name ?? 'Unknown',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.isOnline ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.isOnline ? 'ONLINE' : 'OFFLINE',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        )
      ],
    );
  }

  Widget _rating(UserModel user) {
    return RatingBarIndicator(
      rating: user.rating ?? 0,
      itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
      itemSize: 16,
    );
  }

  Widget _bookButton(UserModel user) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: user.isOnline ? () {} : null,
        child: const Text('Book Now'),
      ),
    );
  }

  /// ===============================
  /// RIDE REQUEST DIALOG
  /// ===============================
  void _showRideRequestDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('New Ride Request'),
        content: Text(
            'Pickup: ${data['pickup']}\nDrop: ${data['destination']}\nFare: ₹${data['fare'] ?? '0'}'),
        actions: [
          TextButton(
            onPressed: () {
              socket.emit('rideResponse',
                  {'accepted': false, 'requestId': data['requestId']});
              Navigator.pop(context);
            },
            child: const Text('Decline'),
          ),
          ElevatedButton(
            onPressed: () {
              socket.emit('rideResponse',
                  {'accepted': true, 'requestId': data['requestId']});
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
