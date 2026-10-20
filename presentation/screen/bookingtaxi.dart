import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxiuuse/data/bookingmodel.dart';
import 'package:taxiuuse/presentation/screen/livetracking.dart';
import 'package:taxiuuse/presentation/widegts/button.dart';
import 'package:taxiuuse/presentation/widegts/textfield.dart';
import 'package:taxiuuse/domain/bookingservice.dart';
import 'package:taxiuuse/domain/userappservice.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';
import 'dart:async';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class Bookingtaxi extends StatefulWidget {
  final LatLng pickupLatLng;
  final LatLng dropLatLng;
  final String pickupAddress;
  final String dropAddress;
  final double estimatedFare;
  final String? selectedDriverId;
  final String? selectedDriverName;

  const Bookingtaxi({
    super.key,
    required this.pickupLatLng,
    required this.dropLatLng,
    required this.pickupAddress,
    required this.dropAddress,
    required this.estimatedFare,
    this.selectedDriverId,
    this.selectedDriverName,
  });

  @override
  State<Bookingtaxi> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<Bookingtaxi> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late UserAppService _userAppService;
  BookingModel? _currentBooking;
  bool _isWaitingForDriver = false;

  @override
  void initState() {
    super.initState();
    _initializeUserAppService();
  }

  void _initializeUserAppService() {
    _userAppService = UserAppService(
      userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
      onBookingAccepted: (booking) {
        setState(() {
          _currentBooking = booking;
          _isWaitingForDriver = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driver accepted your booking! Driver ID:'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    _userAppService.connect();
  }

  double _calculateRidePrice() {
    if (widget.estimatedFare > 0) {
      return double.parse(widget.estimatedFare.toStringAsFixed(2));
    }

    const earthRadiusKm = 6371.0;
    final lat1 = widget.pickupLatLng.latitude;
    final lon1 = widget.pickupLatLng.longitude;
    final lat2 = widget.dropLatLng.latitude;
    final lon2 = widget.dropLatLng.longitude;

    double toRadians(double degree) => degree * (3.141592653589793 / 180.0);

    final dLat = toRadians(lat2 - lat1);
    final dLon = toRadians(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(toRadians(lat1)) *
            cos(toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distanceKm = earthRadiusKm * c;

    // Dynamic pricing based on real trip distance
    const baseFare = 80.0;
    const pricePerKm = 22.0;
    const minFare = 100.0;
    double amount = baseFare + (distanceKm * pricePerKm);

    // Add time-based pricing (night charge)
    final now = DateTime.now();
    if (now.hour >= 18 || now.hour <= 6) {
      amount += 30.0;
    }

    if (amount < minFare) {
      amount = minFare;
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  String _normalizePhoneForWhatsApp(String phone) {
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 10) {
      digits = '91$digits';
    }
    return digits;
  }

  Future<void> _sendOtpToWhatsApp(String phone) async {
    final whatsappPhone = _normalizePhoneForWhatsApp(phone);
    if (whatsappPhone.isEmpty) {
      throw Exception('Invalid phone number for WhatsApp OTP');
    }

    final otp = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    final text = Uri.encodeComponent('Your TaxiUUse OTP is: $otp');
    final uri = Uri.parse('https://wa.me/$whatsappPhone?text=$text');

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Unable to open WhatsApp');
    }
  }

  Future<void> _bookRide() async {
    if (!_formKey.currentState!.validate()) return;
    final userName = _nameCtrl.text.trim();
    final userPhone = _phoneCtrl.text.trim();
    final rawPickupAddress = widget.pickupAddress.trim();
    final rawDropAddress = widget.dropAddress.trim();
    final pickupAddress = rawPickupAddress.toLowerCase() == 'address not available'
        ? '${widget.pickupLatLng.latitude}, ${widget.pickupLatLng.longitude}'
        : rawPickupAddress;
    final dropAddress = rawDropAddress.toLowerCase() == 'address not available'
        ? '${widget.dropLatLng.latitude}, ${widget.dropLatLng.longitude}'
        : rawDropAddress;

    if (pickupAddress.isEmpty || dropAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and drop locations are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (rawPickupAddress.toLowerCase() == 'address not available' ||
        rawDropAddress.toLowerCase() == 'address not available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address lookup failed. Using map coordinates for booking.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final token = await SessionManager.getToken();
    if (token == null || token.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to book your ride'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Create booking model
      // Save booking to API (this will also notify drivers)
      final bookingService = BookingService();
      final createdBooking = await bookingService.createBooking(
        pickupLocation: pickupAddress,
        dropoffLocation: dropAddress,
        pickupCoordinates: {
          'lat': widget.pickupLatLng.latitude,
          'lng': widget.pickupLatLng.longitude,
        },
        dropoffCoordinates: {
          'lat': widget.dropLatLng.latitude,
          'lng': widget.dropLatLng.longitude,
        },
        price: _calculateRidePrice(),
        customerName: userName,
        customerPhone: userPhone,
        driverId: widget.selectedDriverId,
        driverName: widget.selectedDriverName,
      
      );

      // Close loading dialog
      Navigator.pop(context);

      setState(() {
        _currentBooking = createdBooking;
        _isWaitingForDriver = true;
      });

      // Send OTP to WhatsApp using registered mobile number
      await _sendOtpToWhatsApp(userPhone);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed! OTP sent to your WhatsApp.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate to live tracking after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(
                pickupLatLng: widget.pickupLatLng,
                dropLatLng: widget.dropLatLng,
              ),
            ),
          );
        }
      });

    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create booking: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _userAppService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),
                    const Expanded(
                      child: Text(
                        "Book a Ride",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // USER NAME FIELD
                CustomTextField(
                  label: "Your Name",
                  hintText: "Enter your name",
                  controller: _nameCtrl,
                  prefixIcon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // USER PHONE FIELD
                CustomTextField(
                  label: "Phone Number",
                  hintText: "Enter your phone number",
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (phone.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // PICKUP LOCATION - Read-only with proper overflow handling
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              "Pickup Location",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: Text(
                          widget.pickupAddress.isNotEmpty ? widget.pickupAddress : "Select pickup location",
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.pickupAddress.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // DROP LOCATION - Read-only with proper overflow handling
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.flag, size: 18, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              "Drop Location",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                        child: Text(
                          widget.dropAddress.isNotEmpty ? widget.dropAddress : "Select drop location",
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.dropAddress.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // BOOKING BUTTON
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Confirm & Track Ride",
                    onPressed: _bookRide,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





