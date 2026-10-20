import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:taxiuuse/presentation/screen/login.dart';
import 'package:taxiuuse/presentation/screen/profile.dart';
import 'package:taxiuuse/presentation/screen/recentbook.dart';
import 'package:taxiuuse/presentation/screen/security/aboutus.dart';
import 'package:taxiuuse/presentation/screen/security/condition.dart';
import 'package:taxiuuse/presentation/screen/security/privacypolicy.dart';
import 'package:taxiuuse/presentation/screen/toprate.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListening = false;
  final TextEditingController _searchController = TextEditingController();
  final PageController _mapCarouselController = PageController(viewportFraction: 0.94);
  int _currentMapSlide = 0;
  Timer? _carouselTimer;
  String _userDisplayName = 'User';
  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _startAutoSlide();
    _loadUserDisplayName();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _searchController.dispose();
    _mapCarouselController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _startAutoSlide() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_mapCarouselController.hasClients) return;
      final nextPage = (_currentMapSlide + 1) % 3;
      _mapCarouselController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  String _capitalizeWords(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String? _extractNameFromData(dynamic payload) {
    if (payload is! Map<String, dynamic>) return null;

    final directName = payload['name'] ??
        payload['fullName'] ??
        payload['username'] ??
        payload['userName'];
    if (directName != null && directName.toString().trim().isNotEmpty) {
      return directName.toString().trim();
    }

    final directEmail = payload['email'] ?? payload['mail'];
    if (directEmail != null) {
      final emailText = directEmail.toString().trim();
      if (emailText.contains('@')) {
        final localPart = emailText.split('@').first.trim();
        if (localPart.isNotEmpty) {
          return _capitalizeWords(localPart.replaceAll(RegExp(r'[._-]+'), ' '));
        }
      }
    }

    const nestedKeys = ['user', 'data', 'profile', 'account', 'userData'];
    for (final key in nestedKeys) {
      final nested = payload[key];
      final nestedName = _extractNameFromData(nested);
      if (nestedName != null && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    for (final value in payload.values) {
      final nestedName = _extractNameFromData(value);
      if (nestedName != null && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    return null;
  }

  Future<void> _loadUserDisplayName() async {
    String? resolvedName = await SessionManager.getRegisteredUserName();

    if (resolvedName == null || resolvedName.trim().isEmpty) {
      final userDataJson = await SessionManager.getUserData();
      if (userDataJson != null && userDataJson.trim().isNotEmpty) {
        try {
          final decoded = json.decode(userDataJson);
          resolvedName = _extractNameFromData(decoded);
        } catch (_) {}
      }
    }

    if (resolvedName == null || resolvedName.trim().isEmpty) {
      final userId = await SessionManager.getUserId();
      if (userId != null && userId.trim().isNotEmpty) {
        resolvedName = _capitalizeWords(userId.replaceAll(RegExp(r'[._-]+'), ' '));
      }
    }

    if (!mounted) return;
    setState(() {
      _userDisplayName = (resolvedName == null || resolvedName.trim().isEmpty)
          ? 'User'
          : resolvedName.trim();
    });
  }

  
  
  void _initSpeechToText() async {
    print('🎤 Initializing speech to text...');
    
    try {
      _speechToText = SpeechToText();
      
      // Check current permission status first
      var status = await Permission.microphone.status;
      print('🎤 Current microphone permission status: $status');
      
      if (status == PermissionStatus.denied) {
        // Show permission dialog first
        _showPermissionDialog();
        return;
      }
      
      if (status == PermissionStatus.permanentlyDenied) {
        // Show settings dialog for permanently denied
        _showPermanentDeniedDialog();
        return;
      }
      
      if (status == PermissionStatus.granted) {
        // Permission already granted, initialize speech
        await _initializeSpeechService();
      }
      
    } catch (e) {
      print('🎤 Speech initialization error: $e');
      setState(() {
        _speechEnabled = false;
        _isListening = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled || _isListening) return;

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
        });
      },
      listenMode: ListenMode.search,
      partialResults: true,
    );

    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter something to search')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for "$query"')),
    );
  }

  Widget _searchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search destination or driver',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _isListening ? Colors.red : Colors.amber,
            borderRadius: BorderRadius.circular(12),
            child: IconButton(
              onPressed: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
              ),
              tooltip: _isListening ? 'Stop voice search' : 'Start voice search',
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.mic, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text('Permission'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
               
              },
              child: Text('Use Manual Search'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                var status = await Permission.microphone.request();
                if (status == PermissionStatus.granted) {
                  await _initializeSpeechService();
                } else {
                  
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
              child: Text('Grant Permission'),
            ),
          ],
        );
      },
    );
  }

  void _showPermanentDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Permission Permanently Denied'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permission',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
              },
              child: Text('Use Manual Search'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                bool opened = await openAppSettings();
                if (!opened) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please manually open device settings'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }



  
  Future<void> _initializeSpeechService() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (val) {
          print('🎤 Speech error: $val');
          setState(() {
            _isListening = false;
          });
          
         
        },
        onStatus: (val) {
          print('🎤 Speech status: $val');
          setState(() {
            if (val == 'done' || val == 'notListening') {
              _isListening = false;
            }
          });
        },
      );
      
      print('🎤 Speech initialization available: $available');
      
      if (available) {
        setState(() {
          _speechEnabled = true;
        });
        print('🎤 Speech recognition enabled successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Voice search ready! Tap the microphone to speak a name.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('🎤 Speech recognition not available on this device');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Speech recognition not available on this device'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Manual Search',
              onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('🎤 Speech initialization error: $e');
      setState(() {
        _speechEnabled = false;
        _isListening = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech initialization failed: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Manual Search',
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
        ),
      );
    }
  }


  
  Widget _header() {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Builder(
              builder: (BuildContext context) {
                return Material(
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  color: Colors.amber,
                  child: IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: const Icon(Icons.menu, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hi, $_userDisplayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 MAP IMAGE
    Widget _mapView() {
    final slides = <Map<String, dynamic>>[
      {
        'title': 'Fast Pickup',
        'subtitle': 'Nearest drivers reach you quickly',
        'icon': Icons.local_taxi,
        'colors': [Colors.amber.shade300, Colors.orange.shade500],
      },
      {
        'title': 'Safe Ride',
        'subtitle': 'Verified profiles and live tracking',
        'icon': Icons.shield,
        'colors': [Colors.lightBlue.shade300, Colors.blue.shade700],
      },
      {
        'title': 'Best Drivers',
        'subtitle': 'Top rated drivers above 3.0',
        'icon': Icons.star,
        'colors': [Colors.green.shade300, Colors.teal.shade600],
      },
    ];
    return Container(
      height: 220,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _mapCarouselController,
              itemCount: slides.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMapSlide = index;
                });
              },
              itemBuilder: (context, index) {
                final slide = slides[index];
                final List<Color> colors = slide['colors'] as List<Color>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slide['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slide['subtitle'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide['icon'] as IconData,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentMapSlide == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentMapSlide == index ? Colors.amber : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 QUICK ACTIONS
 

  // 🔹 RECENT BOOKINGS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              _mapView(),
              const SizedBox(height: 16),
              RecentOrdersWidget(),
              toprateWidget(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 DRAWER
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.amber,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_taxi,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Taxi App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your ride, your way',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You are already on the Home dashboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
         
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Aboutus()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
              );
            },
          ),

ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Logout'),
  onTap: () async {
    Navigator.pop(context); // close drawer first

    bool? confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // confirm
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  },
)         
        ],
      ),
    );
  }
}
