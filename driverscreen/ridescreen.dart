import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:taxiuuse/driverservice/bookingservice.dart';

class RideScreen extends StatefulWidget {
  final Booking booking;

  const RideScreen({super.key, required this.booking});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  CameraPosition? initialPosition;
  bool isLoading = true;
  String? mapError;
  late String _rideStatus;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _rideStatus = widget.booking.status;
    _initializeMap();
  }

  void _initializeMap() {
    try {
      // Default position (can be updated with actual coordinates)
      initialPosition = const CameraPosition(
        target: LatLng(28.6139, 77.2090), // Delhi coordinates
        zoom: 14,
      );
      
      // Add markers for pickup and dropoff
      _addMarkers();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Map initialization error: $e');
      setState(() {
        isLoading = false;
        mapError = 'Failed to initialize map: $e';
      });
    }
  }

  void _addMarkers() {
    // Add pickup marker
    markers.add(
      Marker(
        markerId: MarkerId('pickup_${widget.booking.id}'),
        position: const LatLng(28.6139, 77.2090), // Replace with actual pickup coordinates
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.booking.pickupLocation,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add dropoff marker
    markers.add(
      Marker(
        markerId: MarkerId('dropoff_${widget.booking.id}'),
        position: const LatLng(28.6200, 77.2200), // Replace with actual dropoff coordinates
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: widget.booking.dropoffLocation,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Add route polyline (simplified straight line)
    polylines.add(
      Polyline(
        polylineId: PolylineId('route_${widget.booking.id}'),
        color: Colors.orange,
        width: 5,
        points: [
          const LatLng(28.6139, 77.2090), // Pickup
          const LatLng(28.6200, 77.2200), // Dropoff
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Fit map to show both markers
    if (markers.isNotEmpty) {
      final bounds = LatLngBounds(
        southwest: const LatLng(28.6100, 77.2070),
        northeast: const LatLng(28.6220, 77.2220),
      );
      
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  Future<void> _completeRide() async {
    try {
      setState(() {
        _isUpdatingStatus = true;
      });
      await BookingService.updateBookingStatus(
        widget.booking.id,
        'completed',
        bookingDriverId: widget.booking.driverId,
        bookingDriverName: widget.booking.driverName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _startRide() async {
    try {
      setState(() {
        _isUpdatingStatus = true;
      });
      await BookingService.updateBookingStatus(
        widget.booking.id,
        'ongoing',
        bookingDriverId: widget.booking.driverId,
        bookingDriverName: widget.booking.driverName,
      );

      if (!mounted) return;
      setState(() {
        _rideStatus = 'ongoing';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride started successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.navigation),
            onPressed: () {
              
              _startNavigation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Ride details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride #${widget.booking.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLocationDetail(
                  'PICKUP',
                  widget.booking.pickupLocation,
                  Icons.location_on,
                  Colors.green,
                ),
                const SizedBox(height: 8),
                _buildLocationDetail(
                  'DROPOFF',
                  widget.booking.dropoffLocation,
                  Icons.flag,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status: ${_rideStatus.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Started: ${_formatTime(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Google Map
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mapError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Map Error',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(mapError!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: initialPosition!,
                        markers: markers,
                        polylines: polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapType: MapType.normal,
                      ),
          ),
          
          // Bottom action button
          if (_rideStatus != 'completed')
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isUpdatingStatus
                          ? null
                          : () async {
                              if (_rideStatus == 'assigned') {
                                await _startRide();
                              } else if (_rideStatus == 'ongoing') {
                                await _completeRide();
                              }
                            },
                      icon: Icon(_rideStatus == 'assigned'
                          ? Icons.play_arrow
                          : Icons.check_circle),
                      label: Text(_rideStatus == 'assigned'
                          ? 'Start Ride'
                          : 'Complete Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _rideStatus == 'assigned' ? Colors.blue : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (_isUpdatingStatus)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String location, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
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

  void _startNavigation() {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Navigation'),
        content: const Text('Navigate to pickup location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigation started!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
