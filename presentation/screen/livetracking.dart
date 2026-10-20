import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class LiveTrackingScreen extends StatefulWidget {
  final LatLng pickupLatLng;
  final LatLng dropLatLng;

  const LiveTrackingScreen({
    Key? key,
    required this.pickupLatLng,
    required this.dropLatLng,
  }) : super(key: key);

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? driverLatLng;
  Timer? _timer;

  double distanceInKm = 0;
  int durationInMinutes = 0;

  @override
  void initState() {
    super.initState();
    _addPickupDropMarkers();
    _drawRoute();
    _startFakeLiveTracking();
  }

 

  void _addPickupDropMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId("pickup"),
        position: widget.pickupLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Pickup"),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId("drop"),
        position: widget.dropLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Drop"),
      ),
    );
  }

  

  Future<void> _drawRoute() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null) {
      debugPrint("❌ GOOGLE_MAPS_API_KEY is NULL");
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${widget.pickupLatLng.latitude},${widget.pickupLatLng.longitude}"
        "&destination=${widget.dropLatLng.latitude},${widget.dropLatLng.longitude}"
        "&mode=driving"
        "&key=$apiKey";

    final response = await http.get(Uri.parse(url));
    debugPrint("Directions API response: ${response.body}");

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    if (data['routes'] == null || data['routes'].isEmpty) return;

    final route = data['routes'][0];
    final leg = route['legs'][0];

    distanceInKm = leg['distance']['value'] / 1000;
    durationInMinutes = (leg['duration']['value'] / 60).round();

    final points = PolylinePoints.decodePolyline(
      route['overview_polyline']['points'],
    );

    final polylineCoordinates =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          width: 6,
          points: polylineCoordinates,
        ),
      };
    });

    // Fit camera to route
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _boundsFromLatLngList(polylineCoordinates),
        80,
      ),
    );
  }

 

  void _startFakeLiveTracking() {
    driverLatLng = widget.pickupLatLng;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (driverLatLng == null) return;

      final newLat = driverLatLng!.latitude +
          (widget.dropLatLng.latitude - driverLatLng!.latitude) * 0.08;
      final newLng = driverLatLng!.longitude +
          (widget.dropLatLng.longitude - driverLatLng!.longitude) * 0.08;

      driverLatLng = LatLng(newLat, newLng);
      _updateDriverMarker(driverLatLng!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(driverLatLng!),
      );

      if (_isArrived(driverLatLng!, widget.dropLatLng)) {
        timer.cancel();
      }
    });
  }

  void _updateDriverMarker(LatLng position) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == "driver");

      _markers.add(
        Marker(
          markerId: const MarkerId("driver"),
          position: position,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "Driver"),
        ),
      );
    });
  }

  bool _isArrived(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.0005 &&
        (a.longitude - b.longitude).abs() < 0.0005;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (LatLng latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }

    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Taxi Tracking")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.pickupLatLng,
              zoom: 14,
            ),
            myLocationEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // 🚖 Distance & ETA
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Distance",
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        "${distanceInKm.toStringAsFixed(2)} km",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ETA",
                          style: TextStyle(color: Colors.grey)),
                      Text(
                        "$durationInMinutes mins",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
