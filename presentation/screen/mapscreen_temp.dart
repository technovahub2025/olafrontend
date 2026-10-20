import 'dart:convert';
import 'dart:math';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:taxiuuse/presentation/screen/bookingtaxi.dart';
import 'package:share_plus/share_plus.dart';

class TaxiMapScreen extends StatefulWidget {
  const TaxiMapScreen({Key? key}) : super(key: key);

  @override
  State<TaxiMapScreen> createState() => _TaxiMapScreenState();
}

class _TaxiMapScreenState extends State<TaxiMapScreen> {
  GoogleMapController? _mapController;

  LatLng? pickupLatLng;
  LatLng? dropLatLng;

  String pickupAddress = '';
  String dropAddress = '';

  double distanceInKm = 0;
  int durationInMinutes = 0;
  double estimatedFare = 0;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? _currentLocation;
  String _currentAddress = 'Fetching location...';

  bool _mapsLoaded = false;
  bool _mapsError = false;

  static const CameraPosition _initialCamera =
      CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 5);

  @override
  void initState() {
    super.initState();
    _checkMapsAvailability();
    _moveToCurrentLocation();
  }

  void _checkMapsAvailability() {
    // Check if Google Maps loaded properly
    Future.delayed(const Duration(seconds: 2), () {
      final dynamic windowObject = html.window;
      if (windowObject['mapsLoadError'] != null) {
        setState(() {
          _mapsError = true;
          _mapsLoaded = false;
        });
        print('❌ Google Maps failed to load');
      } else if (windowObject['mapsLoaded'] != null) {
        setState(() {
          _mapsLoaded = true;
          _mapsError = false;
        });
        print('✅ Google Maps loaded successfully');
      }
    });
  }

  Widget _buildMapWidget() {
    if (_mapsError) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Google Maps Unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection\nor try using the mobile app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  html.window.location.reload();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: _initialCamera,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onTap: _onMapTap,
      onMapCreated: (controller) async {
        _mapController = controller;
        if (!_mapsLoaded) {
          setState(() {
            _mapsLoaded = true;
          });
        }
      },
    );
  }

  // ---------------- GET CURRENT LOCATION ----------------
  Future<void> _moveToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentAddress = await _getAddress(_currentLocation!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          _currentLocation!,
          16,
        ),
      );

      setState(() {});
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        _currentAddress = 'Location unavailable';
      });
    }
  }

  // ---------------- SHARE CURRENT LOCATION ----------------
  Future<void> _shareCurrentLocation() async {
    if (_currentLocation == null) {
      // If current location not fetched yet, get it first
      await _moveToCurrentLocation();
    }

    // Create share message
    final shareMessage = '''
📍 My Current Location

📍 Coordinates: 
Latitude: ${_currentLocation!.latitude.toStringAsFixed(6)}
Longitude: ${_currentLocation!.longitude.toStringAsFixed(6)}

📍 Address: $_currentAddress

📍 Google Maps Link:
https://www.google.com/maps/search/?api=1&query=${_currentLocation!.latitude},${_currentLocation!.longitude}
''';

    // Share the location
    await Share.share(
      shareMessage,
      subject: 'My Current Location',
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'Please enable location permissions in your device settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<String> _getAddress(LatLng latLng) async {
    String coordsLabel() =>
        '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isEmpty) return coordsLabel();

      final p = placemarks.first;
      final parts = <String>[
        p.name ?? '',
        p.street ?? '',
        p.subLocality ?? '',
        p.locality ?? '',
        p.administrativeArea ?? '',
        p.postalCode ?? '',
        p.country ?? '',
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

      return parts.isEmpty ? coordsLabel() : parts.join(', ');
    } catch (e) {
      return coordsLabel();
    }
  }

  // ---------------- FARE CALCULATION ----------------
  double _calculateFare(double distanceInKm) {
    const double baseFare = 20.0;        // Base fare (first 2 km)
    const double perKmRate = 12.0;       // Rate per kilometer after base
    const double freeKm = 2.0;           // First 2 km included in base fare
    
    if (distanceInKm <= freeKm) {
      return baseFare;
    } else {
      double chargeableKm = distanceInKm - freeKm;
      print('📊 Chargeable km: $chargeableKm');
      return baseFare + (chargeableKm * perKmRate);
    }
  }

  // ---------------- HAVERSINE DISTANCE CALCULATION (FREE) ----------------
  double _calculateStraightLineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = start.latitude * (3.14159265359 / 180);
    double lat2Rad = end.latitude * (3.14159265359 / 180);
    double deltaLatRad = (end.latitude - start.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (end.longitude - start.longitude) * (3.14159265359 / 180);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    double distance = earthRadius * c;
    print('📏 Straight-line distance: ${distance.toStringAsFixed(2)} km');
    
    return distance;
  }

  // ---------------- ENHANCED ROUTE DRAWING WITH FALLBACK ----------------
  Future<void> _drawRoute() async {
    if (pickupLatLng == null || dropLatLng == null) return;

    print('🔍 Attempting Google Directions API...');
    
    try {
      final url = 
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${pickupLatLng!.latitude},${pickupLatLng!.longitude}"
        "&destination=${dropLatLng!.latitude},${dropLatLng!.longitude}"
        "&mode=driving"
        "&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}";
      
      print('🔍 Directions API URL: $url');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          distanceInKm = leg['distance']['value'] / 1000;
          durationInMinutes = (leg['duration']['value'] / 60).round();
          
          print('✅ Google API Success!');
          print('📏 Distance: ${leg['distance']['text']} ($distanceInKm km)');
          print('⏱️ Duration: ${leg['duration']['text']} ($durationInMinutes mins)');
          
          estimatedFare = _calculateFare(distanceInKm);
          print('💰 Fare: ₹$estimatedFare');

          final polylineResult = PolylinePoints.decodePolyline(route['overview_polyline']['points']);
          final List<LatLng> pointsList = polylineResult
              .map((e) => LatLng(e.latitude, e.longitude))
              .toList();

          setState(() {
            _polylines = {
              Polyline(
                polylineId: const PolylineId("route"),
                color: Colors.blue,
                width: 5,
                points: pointsList,
              ),
            };
          });
          return;
        }
      }
      
      print('❌ Google API failed, using fallback...');
    } catch (e) {
      print('❌ Google API error: $e');
    }

    // FALLBACK: Use straight-line distance and simple line
    print('🔄 Using fallback distance calculation...');
    
    distanceInKm = _calculateStraightLineDistance(pickupLatLng!, dropLatLng!);
    // Estimate duration (assuming 30 km/h average speed in city)
    durationInMinutes = ((distanceInKm / 30) * 60).round();
    estimatedFare = _calculateFare(distanceInKm);
    
    print('📏 Fallback Distance: ${distanceInKm.toStringAsFixed(2)} km');
    print('⏱️ Estimated Duration: $durationInMinutes mins');
    print('💰 Fallback Fare: ₹$estimatedFare');

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("fallback_route"),
          color: Colors.orange,
          width: 3,
          points: [pickupLatLng!, dropLatLng!],
        ),
      };
    });
  }

  Future<void> _onMapTap(LatLng latLng) async {
    if (pickupLatLng == null) {
      pickupLatLng = latLng;
      pickupAddress = await _getAddress(latLng);

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId("pickup"),
            position: latLng,
            infoWindow: const InfoWindow(title: "Pickup"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      });
    } else if (dropLatLng == null) {
      dropLatLng = latLng;
      dropAddress = await _getAddress(latLng);

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId("drop"),
            position: latLng,
            infoWindow: const InfoWindow(title: "Drop"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });

      await _drawRoute();
    }
  }

  void _reset() {
    setState(() {
      pickupLatLng = null;
      dropLatLng = null;
      pickupAddress = '';
      dropAddress = '';
      distanceInKm = 0;
      durationInMinutes = 0;
      estimatedFare = 0;
      _markers.clear();
      _polylines.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Taxi Location Picker"),
        actions: [
          // Share Current Location Button
          IconButton(
            icon: const Icon(Icons.share_location),
            onPressed: _shareCurrentLocation,
            tooltip: 'Share Current Location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset Selection',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        child: const Icon(Icons.my_location),
        tooltip: 'Go to Current Location',
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMapWidget(),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Location Info
                if (_currentLocation != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Current: $_currentAddress",
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Pickup Location
                Text(
                  "Pickup: ${pickupAddress.isEmpty ? 'Tap on map' : pickupAddress}",
                ),
                const SizedBox(height: 6),
                
                // Drop Location
                Text(
                  "Drop: ${dropAddress.isEmpty ? 'Tap on map' : dropAddress}",
                ),
                
                // Distance, ETA and Fare
                if (distanceInKm > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Distance: ${distanceInKm.toStringAsFixed(2)} km"),
                          Text("ETA: $durationInMinutes mins"),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "₹${estimatedFare.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "Estimated Fare",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        pickupLatLng != null && dropLatLng != null ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Bookingtaxi(
                                pickupLatLng: pickupLatLng!,
                                dropLatLng: dropLatLng!,
                                pickupAddress: pickupAddress,
                                dropAddress: dropAddress,
                                estimatedFare: estimatedFare,
                              ),
                            ),
                          );
                        } : null,
                    child: const Text("CONFIRM RIDE"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
