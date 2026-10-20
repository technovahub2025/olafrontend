import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
  loc.Location location = loc.Location();
  bool _serviceEnabled = false;
  loc.PermissionStatus _permissionGranted = loc.PermissionStatus.denied;
  loc.LocationData? _currentLocation;
  bool isRideStarted = false;
  bool isRideCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      print('DEBUG: Initializing Google Maps...');
      
      // Add a small delay to ensure Google Maps is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check location services
      await _checkLocationPermission();
      
      // Get current location
      await _getCurrentLocation();
      
      // Set initial position to current location or pickup location
      if (_currentLocation != null) {
        initialPosition = CameraPosition(
          target: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          zoom: 14,
        );
        print('DEBUG: Using current location for map: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      } else if (widget.booking.pickupCoordinates?['lat'] != null) {
        // Use pickup coordinates as fallback
        initialPosition = CameraPosition(
          target: LatLng(
            widget.booking.pickupCoordinates!['lat']!,
            widget.booking.pickupCoordinates!['lng']!,
          ),
          zoom: 14,
        );
        print('DEBUG: Using pickup coordinates for map: ${widget.booking.pickupCoordinates}');
      } else {
        // Fallback to default coordinates
        initialPosition = const CameraPosition(
          target: LatLng(28.6139, 77.2090), // Delhi coordinates
          zoom: 14,
        );
        print('DEBUG: Using default coordinates for map');
      }
      
      print('DEBUG: Initial position set: $initialPosition');
      
      // Add markers for pickup and dropoff
      _addMarkers();
      
      // Draw route between pickup and dropoff
      await _drawRoute();
      
      setState(() {
        isLoading = false;
      });
      
      print('DEBUG: Google Maps initialized successfully');
    } on NotInitializedError catch (e) {
      print('DEBUG: Google Maps NotInitializedError: $e');
      setState(() {
        isLoading = false;
        mapError = 'Google Maps not initialized. Please check platform configuration.\nError: $e';
      });
    } catch (e) {
      print('DEBUG: Map initialization error: $e');
      setState(() {
        isLoading = false;
        mapError = 'Failed to initialize map: $e';
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      print('DEBUG: Checking location permissions...');
      
      // Check if location services are enabled
      _serviceEnabled = await location.serviceEnabled();
      if (!_serviceEnabled) {
        print('DEBUG: Location services disabled, requesting...');
        _serviceEnabled = await location.requestService();
        if (!_serviceEnabled) {
          print('DEBUG: Location services still disabled');
          return;
        }
      }

      // Check for location permission
      _permissionGranted = await location.hasPermission();
      print('DEBUG: Current permission status: $_permissionGranted');
      
      if (_permissionGranted == loc.PermissionStatus.denied) {
        print('DEBUG: Permission denied, requesting...');
        _permissionGranted = await location.requestPermission();
        print('DEBUG: Permission request result: $_permissionGranted');
        
        if (_permissionGranted != loc.PermissionStatus.granted) {
          print('DEBUG: Permission not granted, using default location');
          return;
        }
      }
      
      print('DEBUG: Location permission granted');
    } catch (e) {
      print('DEBUG: Location permission error: $e');
      // Continue without location - will use default coordinates
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('DEBUG: Getting current location...');
      _currentLocation = await location.getLocation();
      print('DEBUG: Current location: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}');
    } catch (e) {
      print('DEBUG: Error getting location: $e');
      // Set current location to null so it falls back to pickup coordinates
      _currentLocation = null;
    }
  }

  void _addMarkers() {
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Use actual pickup coordinates from booking data
    LatLng pickupCoords;
    if (widget.booking.pickupCoordinates != null) {
      pickupCoords = LatLng(
        widget.booking.pickupCoordinates?['lat'] ?? 28.6139,
        widget.booking.pickupCoordinates?['lng'] ?? 77.2090,
      );
    } else {
      pickupCoords = const LatLng(28.6139, 77.2090); // Fallback
    }

    // Use actual dropoff coordinates from booking data
    LatLng dropoffCoords;
    if (widget.booking.dropoffCoordinates != null) {
      dropoffCoords = LatLng(
        widget.booking.dropoffCoordinates?['lat'] ?? 28.6200,
        widget.booking.dropoffCoordinates?['lng'] ?? 77.2300,
      );
    } else {
      dropoffCoords = const LatLng(28.6200, 77.2300); // Fallback
    }

    // Add pickup marker
    markers.add(
      Marker(
        markerId: MarkerId('pickup_${widget.booking.id}'),
        position: pickupCoords,
        infoWindow: InfoWindow(
          title: 'Pickup: ${widget.booking.pickupLocation}',
          snippet: 'Customer: ${widget.booking.passengerName}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Add dropoff marker
    markers.add(
      Marker(
        markerId: MarkerId('dropoff_${widget.booking.id}'),
        position: dropoffCoords,
        infoWindow: InfoWindow(
          title: 'Dropoff: ${widget.booking.dropoffLocation}',
          snippet: 'Customer: ${widget.booking.passengerName}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    print('DEBUG: Added markers - Pickup: $pickupCoords, Dropoff: $dropoffCoords');
  }

  Future<void> _drawRoute() async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY';
      final polylinePoints = PolylinePoints(apiKey: apiKey);
      final polylineCoordinates = <LatLng>[];

      // Use actual pickup coordinates from booking data
      LatLng pickupCoords;
      if (widget.booking.pickupCoordinates != null) {
        pickupCoords = LatLng(
          widget.booking.pickupCoordinates?['lat'] ?? 28.6139,
          widget.booking.pickupCoordinates?['lng'] ?? 77.2090,
        );
      } else {
        pickupCoords = const LatLng(28.6139, 77.2090); // Fallback
      }

      // Use actual dropoff coordinates from booking data
      LatLng dropoffCoords;
      if (widget.booking.dropoffCoordinates != null) {
        dropoffCoords = LatLng(
          widget.booking.dropoffCoordinates?['lat'] ?? 28.6200,
          widget.booking.dropoffCoordinates?['lng'] ?? 77.2300,
        );
      } else {
        dropoffCoords = const LatLng(28.6200, 77.2300); // Fallback
      }

      print('DEBUG: Drawing route from $pickupCoords to $dropoffCoords');

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(pickupCoords.latitude, pickupCoords.longitude),
          destination: PointLatLng(dropoffCoords.latitude, dropoffCoords.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        setState(() {
          polylines.add(
            Polyline(
              polylineId: PolylineId('route_${widget.booking.id}'),
              color: Colors.blue,
              width: 5,
              points: polylineCoordinates,
            ),
          );
        });
        print('DEBUG: Route drawn successfully with ${polylineCoordinates.length} points');
      } else {
        print('DEBUG: No route points found');
      }
    } catch (e) {
      print('DEBUG: Error drawing route: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('DEBUG: Google Maps controller created');
  }

  Future<void> _startRide() async {
    try {
      setState(() {
        isRideStarted = true;
      });

      // Update booking status to ongoing
      await BookingService.updateBookingStatus(
        widget.booking.id,
        'ongoing',
        bookingDriverId: widget.booking.driverId,
        bookingDriverName: widget.booking.driverName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚗 Ride started! Navigate to pickup location.'),
          backgroundColor: Colors.green,
        ),
      );

      // Start live location updates
      _startLocationUpdates();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    location.onLocationChanged.listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        // Update current location marker
        setState(() {
          markers.removeWhere((marker) => marker.markerId.value == 'current_location');
          markers.add(
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(currentLocation.latitude!, currentLocation.longitude!),
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
          );
        });

        // Center map on current location
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentLocation.latitude!, currentLocation.longitude!),
              16,
            ),
          );
        }
      }
    });
  }

  Future<void> _completeRide() async {
    try {
      setState(() {
        isRideCompleted = true;
      });

      print('DEBUG: Completing ride - Booking ID: ${widget.booking.id}');
      
      await BookingService.updateBookingStatus(
        widget.booking.id,
        'completed',
        bookingDriverId: widget.booking.driverId,
        bookingDriverName: widget.booking.driverName,
      );
      
      print('DEBUG: Ride completed successfully');


      
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ride completed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Go back to bookings list and refresh
      Navigator.of(context).pop(true); // Pass true to indicate refresh needed
    } catch (e) {
      print('DEBUG: Error completing ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error completing ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRideStarted ? 'Ride in Progress' : 'Active Ride'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          if (isRideStarted)
            IconButton(
              icon: const Icon(Icons.gps_fixed),
              onPressed: () {
                // Center on current location
                if (_currentLocation != null && mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      16,
                    ),
                  );
                }
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ride #${widget.booking.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isRideStarted ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isRideStarted ? 'IN PROGRESS' : 'ASSIGNED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
               
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Customer: ${widget.booking.passengerName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '📞 ${widget.booking.passengerPhone}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Google Map or Fallback
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mapError != null
                    ? _buildFallbackMap()
                    : Builder(
                        builder: (context) {
                          try {
                            return GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: initialPosition!,
                              markers: markers,
                              polylines: polylines,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              mapType: MapType.normal,
                              trafficEnabled: true,
                            );
                          } catch (e) {
                            print('DEBUG: GoogleMap widget error: $e');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  mapError = 'GoogleMap widget error: $e';
                                });
                              }
                            });
                            return _buildFallbackMap();
                          }
                        },
                      ),
          ),
          
          // Bottom action button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isRideCompleted 
                    ? null 
                    : isRideStarted 
                        ? _completeRide 
                        : _startRide,
                icon: Icon(isRideStarted 
                    ? Icons.check_circle 
                    : Icons.play_circle),
                label: Text(isRideStarted 
                    ? 'Complete Ride' 
                    : 'Start Ride'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRideStarted ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '🗺️ Ride Navigation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          
          // Show specific error message
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(height: 4),
                Text(
                  mapError ?? 'Google Maps unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Show pickup and dropoff info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                _buildLocationInfo(
                  '📍 Pickup',
                  widget.booking.pickupLocation,
                  Colors.green,
                ),
                const SizedBox(height: 12),
                _buildLocationInfo(
                  '🏁 Dropoff',
                  widget.booking.dropoffLocation,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '👤 ${widget.booking.passengerName}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '📞 ${widget.booking.passengerPhone}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use your phone\'s map app to navigate to pickup location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String location, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
