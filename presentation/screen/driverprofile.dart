import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:taxiuuse/data/drivermodel.dart';
import 'package:taxiuuse/domain/driverservice.dart';
import 'package:taxiuuse/presentation/screen/mapscreen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({Key? key}) : super(key: key);

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  String? _errorMessage;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  late IO.Socket socket;
  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _initSocket();
    _initSpeechToText();
  }

  // ===============================
  // SPEECH TO TEXT INITIALIZATION
  // ===============================
  void _initSpeechToText() async {
    _speechToText = SpeechToText();
    
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      bool available = await _speechToText.initialize(
        onError: (val) => print('Speech error: $val'),
        onStatus: (val) => print('Speech status: $val'),
      );
      if (available) {
        setState(() {
          _speechEnabled = true;
        });
      }
    }
  }

  // ===============================
  // SEARCH FUNCTIONALITY
  // ===============================
  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users.where((user) {
          final searchLower = query.toLowerCase();
          return user.name?.toLowerCase().contains(searchLower) == true ||
                 user.driver?.toLowerCase().contains(searchLower) == true ||
                 user.experience.toString().contains(searchLower) ||
                 user.price.toString().contains(searchLower);
        }).toList();
      }
    });
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    // Clear previous data before starting
    setState(() {
      _searchController.clear();
      _filterUsers('');
      _isListening = true;
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          print('🎤 Speech result: ${result.recognizedWords}');
          print('🎤 Is final: ${result.finalResult}');
          
          // Update text field with current recognized words
          setState(() {
            _searchController.text = result.recognizedWords;
            _filterUsers(result.recognizedWords);
          });
          
          // Auto-stop when final result is received
          if (result.finalResult) {
            _stopListening();
          }
        },
        partialResults: true, // Show live results
        localeId: 'en_US',
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        onSoundLevelChange: (level) => print('🎤 Sound level: $level'),
        onDevice: true,
      );
    } catch (e) {
      print('🎤 Error starting speech: $e');
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start speech recognition: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  // ===============================
  // SOCKET INITIALIZATION
  // ===============================
  void _initSocket() {
    socket = IO.io(
      'http://localhost:4000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      debugPrint('Socket connected');
    });

    // 🔴 Online / Offline updates
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

    socket.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  // ===============================
  // LOAD USERS (API)
  // ===============================
  Future<void> _loadUsers() async {
    try {
      final profileService = ProfileService();
      final users = await profileService.getAllUsers();

      setState(() {
        _users = users;
        _filteredUsers = List.from(users); // Initialize filtered list
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
      _errorMessage = null;
    });
    await _loadUsers();
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Drivers'),
        centerTitle: true,
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Search drivers by name, experience, or price...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isListening
                          ? IconButton(
                              icon: const Icon(Icons.mic, color: Colors.red),
                              onPressed: _stopListening,
                            )
                          : IconButton(
                              icon: const Icon(Icons.mic),
                              onPressed: _startListening,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: _isListening
                        ? const Icon(Icons.stop, color: Colors.white)
                        : const Icon(Icons.mic, color: Colors.white),
                    onPressed: _isListening ? _stopListening : _startListening,
                  ),
                ),
              ],
            ),
          ),
          // Voice Search Status
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Listening... Speak driver name or details',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            ),
          // Driver List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredUsers.isEmpty
                        ? const Center(child: Text('No drivers found'))
                        : RefreshIndicator(
                            onRefresh: _refreshUsers,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                return _driverCard(user);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // DRIVER CARD
  // ===============================
  Widget _driverCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 8),
                  _phone(user.phone),
                  const SizedBox(height: 6),
                  _experience(user.experience),
                  const SizedBox(height: 6),
                  if (user.price != null && user.price! > 0)
                    _price(user.price!),
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
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: image != null && image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, size: 30),
              )
            : const Icon(Icons.person, size: 30),
      ),
    );
  }

  Widget _nameAndStatus(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: Text(
            user.name ?? 'Unknown',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    return Row(
      children: [
        RatingBarIndicator(
          rating: user.rating ?? 0,
          itemBuilder: (_, __) =>
              const Icon(Icons.star, color: Colors.amber),
          itemSize: 16,
        ),
        const SizedBox(width: 8),
        Text('${(user.rating ?? 0).toStringAsFixed(1)}'),
      ],
    );
  }

  Widget _phone(String? phone) {
    return Row(
      children: [
        const Icon(Icons.phone, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(phone ?? 'No phone'),
      ],
    );
  }

  Widget _experience(int? exp) {
    return Row(
      children: [
        const Icon(Icons.work_history, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('${exp ?? 0} years experience'),
      ],
    );
  }

  Widget _price(double price) {
    return Row(
      children: [
        const Icon(Icons.attach_money, size: 16, color: Colors.green),
        const SizedBox(width: 6),
        Text(
          '₹${price.toStringAsFixed(2)}/km',
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _bookButton(UserModel user) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        onPressed: user.isOnline ? () => _showBookingDialog(context, user) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: user.isOnline ? Colors.green : Colors.grey,
        ),
        child: const Text('Book Now'),
      ),
    );
  }

  // ===============================
  // BOOKING DIALOG
  // ===============================
  void _showBookingDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Book Driver'),
        content: Text('Confirm booking with ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => TaxiMapScreen(
                    selectedDriverId: user.id,
                    selectedDriverName: user.name,
                  ),
                )
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
