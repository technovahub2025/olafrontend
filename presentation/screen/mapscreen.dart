import 'dart:convert';
import 'dart:math';
import 'dart:async';

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
  final String? selectedDriverId;
  final String? selectedDriverName;

  const TaxiMapScreen({
    Key? key,
    this.selectedDriverId,
    this.selectedDriverName,
  }) : super(key: key);

  @override
  State<TaxiMapScreen> createState() => _TaxiMapScreenState();
}

class _TaxiMapScreenState extends State<TaxiMapScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();

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
  Timer? _pickupDebounce;
  Timer? _dropDebounce;
  List<_PlaceSuggestion> _pickupSuggestions = [];
  List<_PlaceSuggestion> _dropSuggestions = [];
  bool _isPickupLoadingSuggestions = false;
  bool _isDropLoadingSuggestions = false;

  static const CameraPosition _initialCamera =
      CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 5);

  // ---------------- GET CURRENT LOCATION ----------------
  Future<void> _moveToCurrentLocation() async {
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

        final routes = (data is Map<String, dynamic>)
            ? (data['routes'] as List? ?? const [])
            : const [];

        if (routes.isNotEmpty) {
          final route = routes[0];
          final legs = (route is Map<String, dynamic>)
              ? (route['legs'] as List? ?? const [])
              : const [];
          if (legs.isEmpty) {
            throw Exception('Directions response has no legs');
          }
          final leg = legs[0] as Map<String, dynamic>;

          distanceInKm = leg['distance']['value'] / 1000;
          durationInMinutes = (leg['duration']['value'] / 60).round();
          
          print('✅ Google API Success!');
          print('📏 Distance: ${leg['distance']['text']} ($distanceInKm km)');
          print('⏱️ Duration: ${leg['duration']['text']} ($durationInMinutes mins)');
          
          estimatedFare = _calculateFare(distanceInKm);
          print('💰 Fare: ₹$estimatedFare');

          final overview = (route as Map<String, dynamic>)['overview_polyline'];
          final points = (overview is Map<String, dynamic>)
              ? (overview['points'] as String? ?? '')
              : '';
          if (points.isEmpty) {
            throw Exception('Directions response has no polyline points');
          }
          final polylineResult = PolylinePoints.decodePolyline(points);
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

  Future<void> _setPickupLocation(LatLng latLng, {String? address}) async {
    final resolvedAddress = address ?? await _getAddress(latLng);
    pickupLatLng = latLng;
    pickupAddress = resolvedAddress;
    _pickupController.text = resolvedAddress;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "pickup");
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

    if (dropLatLng != null) {
      await _drawRoute();
    } else {
      setState(() {
        _polylines.clear();
        distanceInKm = 0;
        durationInMinutes = 0;
        estimatedFare = 0;
      });
    }
  }

  Future<void> _setDropLocation(LatLng latLng, {String? address}) async {
    final resolvedAddress = address ?? await _getAddress(latLng);
    dropLatLng = latLng;
    dropAddress = resolvedAddress;
    _dropController.text = resolvedAddress;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "drop");
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

    if (pickupLatLng != null) {
      await _drawRoute();
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    if (pickupLatLng == null) {
      await _setPickupLocation(latLng);
    } else if (dropLatLng == null) {
      await _setDropLocation(latLng);
    }
  }

  void _reset() {
    setState(() {
      pickupLatLng = null;
      dropLatLng = null;
      pickupAddress = '';
      dropAddress = '';
      _pickupController.clear();
      _dropController.clear();
      distanceInKm = 0;
      durationInMinutes = 0;
      estimatedFare = 0;
      _markers.clear();
      _polylines.clear();
    });
  }

  void _clearPickup() {
    setState(() {
      pickupLatLng = null;
      pickupAddress = '';
      _pickupController.clear();
      _pickupSuggestions = [];
      _markers.removeWhere((m) => m.markerId.value == "pickup");
      _polylines.clear();
      distanceInKm = 0;
      durationInMinutes = 0;
      estimatedFare = 0;
    });
  }

  void _clearDrop() {
    setState(() {
      dropLatLng = null;
      dropAddress = '';
      _dropController.clear();
      _dropSuggestions = [];
      _markers.removeWhere((m) => m.markerId.value == "drop");
      _polylines.clear();
      distanceInKm = 0;
      durationInMinutes = 0;
      estimatedFare = 0;
    });
  }

  Future<void> _searchAndSetLocation(
    String query, {
    required bool isPickup,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      final target = await _resolveLocationFromQuery(trimmed);

      if (target == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not found. Try adding area/city name.')),
        );
        return;
      }
      final resolvedAddress = await _getAddress(target);

      if (isPickup) {
        await _setPickupLocation(target, address: resolvedAddress);
      } else {
        await _setDropLocation(target, address: resolvedAddress);
      }

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not search this location right now.')),
      );
    }
  }

  void _onSearchTextChanged(String value, {required bool isPickup}) {
    final query = value.trim();
    final timer = isPickup ? _pickupDebounce : _dropDebounce;
    timer?.cancel();

    if (query.length < 3) {
      setState(() {
        if (isPickup) {
          _pickupSuggestions = [];
          _isPickupLoadingSuggestions = false;
        } else {
          _dropSuggestions = [];
          _isDropLoadingSuggestions = false;
        }
      });
      return;
    }

    setState(() {
      if (isPickup) {
        _isPickupLoadingSuggestions = true;
      } else {
        _isDropLoadingSuggestions = true;
      }
    });

    final newTimer = Timer(const Duration(milliseconds: 450), () async {
      final results = await _fetchSuggestions(query);
      if (!mounted) return;
      setState(() {
        if (isPickup) {
          _pickupSuggestions = results;
          _isPickupLoadingSuggestions = false;
        } else {
          _dropSuggestions = results;
          _isDropLoadingSuggestions = false;
        }
      });
    });

    if (isPickup) {
      _pickupDebounce = newTimer;
    } else {
      _dropDebounce = newTimer;
    }
  }

  Future<List<_PlaceSuggestion>> _fetchSuggestions(String query) async {
    try {
      final normalized = _normalizeLocationQuery(query);
      String extra = '&countrycodes=in';
      if (_currentLocation != null) {
        final west = _currentLocation!.longitude - 0.25;
        final east = _currentLocation!.longitude + 0.25;
        final north = _currentLocation!.latitude + 0.25;
        final south = _currentLocation!.latitude - 0.25;
        extra += '&viewbox=$west,$north,$east,$south&bounded=1';
      }

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(normalized)}'
        '&format=jsonv2'
        '&addressdetails=1'
        '&limit=6$extra',
      );

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'taxiuuse-app/1.0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      if (data is! List) return [];

      final suggestions = <_PlaceSuggestion>[];
      for (final raw in data) {
        if (raw is! Map) continue;
        final map = raw.map((k, v) => MapEntry(k.toString(), v));
        final lat = double.tryParse((map['lat'] ?? '').toString());
        final lon = double.tryParse((map['lon'] ?? '').toString());
        final label = (map['display_name'] ?? '').toString().trim();
        if (lat == null || lon == null || label.isEmpty) continue;
        suggestions.add(_PlaceSuggestion(lat: lat, lon: lon, label: label));
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _selectSuggestion(
    _PlaceSuggestion item, {
    required bool isPickup,
  }) async {
    final title = item.label;
    final target = LatLng(item.lat, item.lon);
    if (isPickup) {
      await _setPickupLocation(target, address: title.isEmpty ? null : title);
      _pickupSuggestions = [];
      _pickupController.text = title;
    } else {
      await _setDropLocation(target, address: title.isEmpty ? null : title);
      _dropSuggestions = [];
      _dropController.text = title;
    }
    if (!mounted) return;
    setState(() {});
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  Widget _buildSuggestionsList({required bool isPickup}) {
    final items = isPickup ? _pickupSuggestions : _dropSuggestions;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final text = items[index].label;
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_on_outlined, size: 18),
            title: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () => _selectSuggestion(items[index], isPickup: isPickup),
          );
        },
      ),
    );
  }

  Future<LatLng?> _resolveLocationFromQuery(String query) async {
    final normalizedQuery = _normalizeLocationQuery(query);
    final attempts = <String>{normalizedQuery};

    final currentParts = _currentAddress
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (currentParts.isNotEmpty) {
      final locality = currentParts.length >= 4
          ? currentParts[3]
          : currentParts.first;
      final adminArea = currentParts.length >= 5 ? currentParts[4] : '';
      final country = currentParts.isNotEmpty ? currentParts.last : '';

      if (locality.isNotEmpty) attempts.add('$query, $locality');
      if (locality.isNotEmpty && adminArea.isNotEmpty) {
        attempts.add('$query, $locality, $adminArea');
      }
      if (country.isNotEmpty) attempts.add('$query, $country');
    }

    attempts.add('$query, India');
    _addTailWordFallbacks(normalizedQuery, attempts);

    for (final attempt in attempts) {
      try {
        final locations = await locationFromAddress(attempt);
        if (locations.isNotEmpty) {
          return LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (_) {
        // Keep trying next query variant.
      }
    }

    // Final fallback: OpenStreetMap Nominatim lookup for POI/company names.
    for (final attempt in attempts) {
      final osmResult = await _resolveFromNominatim(attempt);
      if (osmResult != null) return osmResult;
    }

    return null;
  }

  String _normalizeLocationQuery(String input) {
    var value = input.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    value = value.replaceAll(RegExp(r'\bthrichy\b'), 'tiruchirappalli');
    value = value.replaceAll(RegExp(r'\btrichy\b'), 'tiruchirappalli');
    value = value.replaceAll(RegExp(r'\btrichi\b'), 'tiruchirappalli');
    value = value.replaceAll(RegExp(r'\bthrissy\b'), 'thrissur');
    value = value.replaceAll(RegExp(r'\bpondi\b'), 'pondicherry');
    return value;
  }

  void _addTailWordFallbacks(String query, Set<String> attempts) {
    final words = query
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.length < 2) return;

    // If a business/POI name fails, try likely location tail words.
    final last1 = words[words.length - 1];
    final last2 = words.length >= 2
        ? words.sublist(words.length - 2).join(' ')
        : '';
    final last3 = words.length >= 3
        ? words.sublist(words.length - 3).join(' ')
        : '';

    if (last1.isNotEmpty) {
      attempts.add(last1);
      attempts.add('$last1, India');
    }
    if (last2.isNotEmpty) {
      attempts.add(last2);
      attempts.add('$last2, India');
    }
    if (last3.isNotEmpty) {
      attempts.add(last3);
      attempts.add('$last3, India');
    }
  }

  Future<LatLng?> _resolveFromNominatim(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=jsonv2'
        '&limit=1'
        '&countrycodes=in',
      );
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'taxiuuse-app/1.0',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        final first = data.first as Map<String, dynamic>;
        final lat = double.tryParse((first['lat'] ?? '').toString());
        final lon = double.tryParse((first['lon'] ?? '').toString());
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildPlacesField({
    required String hint,
    required bool isPickup,
    required TextEditingController controller,
  }) {
    final isLoading = isPickup
        ? _isPickupLoadingSuggestions
        : _isDropLoadingSuggestions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: (value) => _onSearchTextChanged(value, isPickup: isPickup),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: isPickup ? _clearPickup : _clearDrop,
                ),
                IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchAndSetLocation(
                    controller.text,
                    isPickup: isPickup,
                  ),
                ),
              ],
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _searchAndSetLocation(
            value,
            isPickup: isPickup,
          ),
        ),
        _buildSuggestionsList(isPickup: isPickup),
      ],
    );
  }

  Widget _buildFieldResetRow() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: _clearPickup,
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reset Pickup'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _clearDrop,
          icon: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reset Drop'),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Get current location when screen loads
    _moveToCurrentLocation();
  }

  @override
  void dispose() {
    _pickupDebounce?.cancel();
    _dropDebounce?.cancel();
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation,
        child: const Icon(Icons.my_location),
        tooltip: 'Go to Current Location',
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
                initialCameraPosition: _initialCamera,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: _markers,
                polylines: _polylines,
                onTap: _onMapTap,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
            ),
          ),
          Positioned(
            top: topInset + 10,
            left: 12,
            right: 12,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Taxi Location Picker",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
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
                    const SizedBox(height: 10),
                    _buildPlacesField(
                      hint: 'Search pickup location',
                      isPickup: true,
                      controller: _pickupController,
                    ),
                    const SizedBox(height: 8),
                    _buildPlacesField(
                      hint: 'Search drop location',
                      isPickup: false,
                      controller: _dropController,
                    ),
                    _buildFieldResetRow(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
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
                                selectedDriverId: widget.selectedDriverId,
                                selectedDriverName: widget.selectedDriverName,
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
          ),
        ]
      ),
    );
  }
}

class _PlaceSuggestion {
  final double lat;
  final double lon;
  final String label;

  const _PlaceSuggestion({
    required this.lat,
    required this.lon,
    required this.label,
  });
}
