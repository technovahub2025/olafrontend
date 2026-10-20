import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationProvider with ChangeNotifier {
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _nearbyTaxis = [];

  LatLng? get currentLocation => _currentLocation;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get destinationLocation => _destinationLocation;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<LatLng> get nearbyTaxis => _nearbyTaxis;

  // Get user's current location
  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation = LatLng(position.latitude, position.longitude);
    
    // Add marker for current location
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
    
    notifyListeners();
  }

  // Set pickup location
  void setPickupLocation(LatLng location) {
    _pickupLocation = location;
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Pickup Point'),
      ),
    );
    notifyListeners();
  }

  // Set destination location
  void setDestinationLocation(LatLng location) {
    _destinationLocation = location;
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    );
    notifyListeners();
  }

  // Simulate finding nearby taxis
  void findNearbyTaxis() {
    if (_currentLocation == null) return;

    _nearbyTaxis.clear();
    
    // Generate random nearby taxi locations (simulation)
    for (int i = 0; i < 5; i++) {
      double latOffset = (Random.nextDouble() - 0.5) * 0.01;
      double lngOffset = (Random.nextDouble() - 0.5) * 0.01;
      
      _nearbyTaxis.add(LatLng(
        _currentLocation!.latitude + latOffset,
        _currentLocation!.longitude + lngOffset,
      ));
    }

    // Add taxi markers
    for (int i = 0; i < _nearbyTaxis.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('taxi_$i'),
          position: _nearbyTaxis[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(title: 'Taxi ${i + 1}'),
        ),
      );
    }
    
    notifyListeners();
  }

  // Clear all markers
  void clearMarkers() {
    _markers.clear();
    _polylines.clear();
    _pickupLocation = null;
    _destinationLocation = null;
    notifyListeners();
  }
}

// Helper class for random number generation
class Random {
  static final _random = math.Random();
  
  static double nextDouble() => _random.nextDouble();
}