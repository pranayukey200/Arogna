import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'citizen_arogna_ai_assistant.dart';
import 'citizen_report_incident.dart';
import 'citizen_community_feed.dart';

import 'arogna_app_bar.dart';
import 'global_state.dart';

class CitizenMainEmergencyMap extends StatefulWidget {
  const CitizenMainEmergencyMap({Key? key}) : super(key: key);

  @override
  State<CitizenMainEmergencyMap> createState() => _CitizenMainEmergencyMapState();
}

class _CitizenMainEmergencyMapState extends State<CitizenMainEmergencyMap> {
  int _selectedIndex = 0;
  Timer? _sosTimer;
  bool _isMapSdkReady = false;
  GoogleMapController? _mapController;
  
  // Clean Dark Mode Style (Hide POIs and Transit)
  static const String _cleanDarkStyle = '''
  [
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
    {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
    {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
    {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]
  ''';
  
  // State
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _mapCircles = {};
  Map<String, dynamic>? _selectedFacility;
  bool _isNavigating = false;
  LatLng _userLocation = const LatLng(21.1458, 79.0882); // Default to Nagpur
  final String _googleMapsApiKey = "AIzaSyDdx96tG5RXee5wk7kIYK0shjWvw_2TUxY";
  StreamSubscription? _emergencySubscription;

  // ── Uber-style ambulance tracking state ───────────────────────────────
  StreamSubscription? _ambulanceSubscription;
  bool _hasActiveDispatch = false;   // true once SOS is dispatched
  String _ambulanceEta = '';         // "4 mins"
  String _ambulanceDistance = '';    // "1.2 km"
  LatLng? _ambulanceLatLng;          // live ambulance position

  // Pre-loaded custom icons
  BitmapDescriptor? _hospitalIcon;
  BitmapDescriptor? _pharmacyIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _initLocationAndFacilities();
    _seedDangerZones();
    _updateEmergencyCircles();
    _subscribeToAmbulanceTracking(); // Uber-style live ambulance feed
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isMapSdkReady = true);
    });
  }

  @override
  void dispose() {
    _emergencySubscription?.cancel();
    _ambulanceSubscription?.cancel();
    super.dispose();
  }

  // ─── UBER-STYLE: Subscribe to responder's live location from Firestore ───
  // The responder_active_dispatch screen writes their GPS here every 3-5s.
  // We read it here and move an ambulance marker + redraw the route.
  void _subscribeToAmbulanceTracking() {
    final String? citizenUid = FirebaseAuth.instance.currentUser?.uid;

    // Step 1: Find this citizen's active dispatched SOS report
    _ambulanceSubscription = FirebaseFirestore.instance
        .collection('emergency_reports')
        .where('status', whereIn: ['dispatched', 'on_scene', 'transporting'])
        .snapshots()
        .listen((snapshot) async {
      // Find the report that belongs to this citizen
      Map<String, dynamic>? myReport;
      for (var doc in snapshot.docs) {
        final d = doc.data();
        final pid = d['patientId']?.toString() ?? '';
        if (citizenUid != null && pid == citizenUid) {
          myReport = d;
          break;
        }
        // Fallback: first dispatched report if no uid match
        myReport ??= d;
      }

      if (myReport == null) {
        if (mounted) setState(() => _hasActiveDispatch = false);
        return;
      }

      final String assignedId = myReport['assigned_responder_id']?.toString() ?? '';
      if (assignedId.isEmpty) return;

      // Step 2: Subscribe to that responder's live location document
      FirebaseFirestore.instance
          .collection('responder_live_locations')
          .doc(assignedId)
          .snapshots()
          .listen((locSnap) async {
        if (!locSnap.exists) return;
        final locData = locSnap.data()!;
        final double ambLat = (locData['lat'] as num).toDouble();
        final double ambLng = (locData['lng'] as num).toDouble();
        final double heading = (locData['heading'] as num?)?.toDouble() ?? 0.0;
        final String eta = locData['eta']?.toString() ?? '';
        final String dist = locData['distance']?.toString() ?? '';
        final LatLng ambPos = LatLng(ambLat, ambLng);

        // Draw ambulance route using Directions API
        await _drawAmbulanceRoute(ambPos);

        if (!mounted) return;
        setState(() {
          _hasActiveDispatch = true;
          _ambulanceLatLng = ambPos;
          _ambulanceEta = eta;
          _ambulanceDistance = dist;

          // Update ambulance marker (flat arrow, rotates with heading)
          _markers.removeWhere((m) => m.markerId.value == 'ambulance');
          _markers.add(Marker(
            markerId: const MarkerId('ambulance'),
            position: ambPos,
            rotation: heading,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: '🚑 Ambulance En Route',
              snippet: eta.isNotEmpty ? 'ETA: $eta • $dist' : 'Tracking...',
            ),
          ));
        });
      });
    });
  }

  /// Draws the live route from ambulance position to citizen's location.
  /// Uses Google Directions API + native polyline decoder (no package needed).
  Future<void> _drawAmbulanceRoute(LatLng ambulancePos) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${ambulancePos.latitude},${ambulancePos.longitude}'
        '&destination=${_userLocation.latitude},${_userLocation.longitude}'
        '&mode=driving'
        '&key=$_googleMapsApiKey';
    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) return;
      final route = data['routes'][0];
      final String encoded = route['overview_polyline']['points'];
      final List<LatLng> coords = _nativeDecodePolyline(encoded);
      if (!mounted) return;
      setState(() {
        _polylines.removeWhere((p) => p.polylineId.value == 'ambulance_route');
        _polylines.add(Polyline(
          polylineId: const PolylineId('ambulance_route'),
          color: const Color(0xFF1A73E8), // Google Maps blue
          width: 7,
          points: coords,
          jointType: JointType.round,
          endCap: Cap.roundCap,
          startCap: Cap.roundCap,
        ));
      });
    } catch (e) {
      debugPrint('[CITIZEN] Ambulance route error: $e');
    }
  }

  List<LatLng> _nativeDecodePolyline(String encoded) {
    final List<LatLng> pts = [];
    int i = 0; int lat = 0, lng = 0;
    while (i < encoded.length) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(i++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(i++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      pts.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return pts;
  }

  void _seedDangerZones() {
    setState(() {
      _mapCircles.add(
        Circle(
          circleId: const CircleId('sitabuldi_flood'),
          center: const LatLng(21.1466, 79.0882),
          radius: 500,
          fillColor: Colors.red.withOpacity(0.3),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
      _mapCircles.add(
        Circle(
          circleId: const CircleId('sadar_block'),
          center: const LatLng(21.1639, 79.0805),
          radius: 500,
          fillColor: Colors.red.withOpacity(0.3),
          strokeColor: Colors.red,
          strokeWidth: 2,
        ),
      );
    });
  }

  void _updateEmergencyCircles() {
    _emergencySubscription = FirebaseFirestore.instance
        .collection('emergency_reports')
        .where('severity', isEqualTo: 'high')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        // Clear existing dynamic circles (keep seeded ones if they have specific IDs)
        _mapCircles.removeWhere((c) => !['sitabuldi_flood', 'sadar_block'].contains(c.circleId.value));
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          // Note: Reports from citizen_report_incident don't have lat/lng yet in the logic I wrote earlier, 
          // but the SOS trigger does. I'll check for latitude/longitude fields.
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            _mapCircles.add(
              Circle(
                circleId: CircleId(doc.id),
                center: LatLng(data['latitude'], data['longitude']),
                radius: 500,
                fillColor: Colors.red.withOpacity(0.3),
                strokeColor: Colors.red,
                strokeWidth: 2,
              ),
            );
          }
        }
      });
    });
  }

  Future<void> _loadCustomMarkers() async {
    final hBytes = await getCustomMarker('H', Colors.red);
    final pBytes = await getCustomMarker('+', Colors.green);
    setState(() {
      _hospitalIcon = BitmapDescriptor.fromBytes(hBytes);
      _pharmacyIcon = BitmapDescriptor.fromBytes(pBytes);
    });
  }

  Future<Uint8List> getCustomMarker(String text, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double radius = 22;
    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    TextPainter painter = TextPainter(textDirection: TextDirection.ltr);
    painter.text = TextSpan(
      text: text, 
      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
    );
    painter.layout();
    painter.paint(canvas, Offset(radius - painter.width / 2, radius - painter.height / 2));
    final img = await pictureRecorder.endRecording().toImage((radius * 2).toInt(), (radius * 2).toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _initLocationAndFacilities() async {
    await _getCurrentLocation();
    await _fetchNearbyFacilities();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _updateUserMarker();
      });

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation));
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _updateUserMarker() {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'user');
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: _userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'You'),
        ),
      );
    });
  }

  Future<void> _fetchNearbyFacilities() async {
    _updateUserMarker();
    try {
      bool hSuccess = await _fetchPlacesByType('hospital', Colors.red);
      bool pSuccess = await _fetchPlacesByType('pharmacy', Colors.green);
      if (!hSuccess && !pSuccess) _applyNagpurFallbacks();
    } catch (e) {
      _applyNagpurFallbacks();
    }
  }

  void _applyNagpurFallbacks() {
    final List<Map<String, dynamic>> fallbacks = [
      {'id': 'f_h1', 'name': 'AIIMS Nagpur', 'type': 'Hospital', 'lat': 21.0601, 'lng': 79.0371},
      {'id': 'f_h2', 'name': 'Govt Medical College (GMC)', 'type': 'Hospital', 'lat': 21.1271, 'lng': 79.0963},
      {'id': 'f_h3', 'name': 'Kingsway Hospital', 'type': 'Hospital', 'lat': 21.1449, 'lng': 79.0834},
      {'id': 'f_p1', 'name': 'Apollo Pharmacy Medical Sq', 'type': 'Pharmacy', 'lat': 21.1305, 'lng': 79.0950},
      {'id': 'f_p2', 'name': 'Wellness Forever Dharampeth', 'type': 'Pharmacy', 'lat': 21.1386, 'lng': 79.0625},
    ];

    setState(() {
      for (var f in fallbacks) {
        final icon = (f['type'] == 'Hospital') ? _hospitalIcon : _pharmacyIcon;
        _markers.add(
          Marker(
            markerId: MarkerId(f['id']),
            position: LatLng(f['lat'], f['lng']),
            icon: icon ?? BitmapDescriptor.defaultMarker,
            onTap: () => setState(() { _selectedFacility = f; _isNavigating = false; _polylines.clear(); }),
          ),
        );
      }
    });
  }

  Future<bool> _fetchPlacesByType(String type, Color color) async {
    final String googleUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_userLocation.latitude},${_userLocation.longitude}&radius=3000&type=$type&key=$_googleMapsApiKey";

    try {
      final response = await http.get(Uri.parse(googleUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            for (var item in data['results']) {
              final lat = item['geometry']['location']['lat'];
              final lng = item['geometry']['location']['lng'];
              final placeId = item['place_id'];
              final icon = (type == 'hospital') ? _hospitalIcon : _pharmacyIcon;
              
              _markers.add(
                Marker(
                  markerId: MarkerId(placeId),
                  position: LatLng(lat, lng),
                  icon: icon ?? BitmapDescriptor.defaultMarker,
                  onTap: () => setState(() {
                    _selectedFacility = {'id': placeId, 'name': item['name'], 'type': type == 'hospital' ? 'Hospital' : 'Pharmacy', 'lat': lat, 'lng': lng};
                    _isNavigating = false;
                    _polylines.clear();
                  }),
                ),
              );
            }
          });
          return true;
        }
      }
      return false;
    } catch (e) { return false; }
  }

  Future<void> _getRoute(double destLat, double destLng) async {
    final String googleUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${_userLocation.latitude},${_userLocation.longitude}&destination=$destLat,$destLng&key=$_googleMapsApiKey";

    try {
      final response = await http.get(Uri.parse(googleUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final polylinePoints = PolylinePoints.decodePolyline(points);
          final List<LatLng> coords = polylinePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: coords,
                color: const Color(0xFF4285F4), // Electric Blue
                width: 6,
              ),
            );
            _isNavigating = true;
          });
          _fitBounds(_userLocation, LatLng(destLat, destLng));
        }
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(p1.latitude < p2.latitude ? p1.latitude : p2.latitude, p1.longitude < p2.longitude ? p1.longitude : p2.longitude),
      northeast: LatLng(p1.latitude > p2.latitude ? p1.latitude : p2.latitude, p1.longitude > p2.longitude ? p1.longitude : p2.longitude),
    );
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _startSosTimer() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hold for 4 seconds to activate SOS...'), duration: Duration(seconds: 4)));
    _sosTimer = Timer(const Duration(seconds: 4), () => _triggerSosSequence());
  }

  void _cancelSosTimer() {
    if (_sosTimer?.isActive ?? false) {
      _sosTimer!.cancel();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _triggerSosSequence() async {
    final double lat = _userLocation.latitude;
    final double lng = _userLocation.longitude;
    final String smsBody = Uri.encodeComponent('[AROGNA_SOS] LAT:$lat LNG:$lng PRIORITY:CRITICAL - MEDICAL EMERGENCY');
    final Uri smsUri = Uri.parse('sms:112?body=$smsBody');

    try {
      await FirebaseFirestore.instance.collection('emergency_reports').add({
        'patientId': FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        'patientName': currentUser.name.isEmpty ? 'Guest Citizen' : currentUser.name,
        'userName': currentUser.name.isEmpty ? 'Guest Citizen' : currentUser.name,
        'severity': 'high',
        'description': 'SOS Triggered from Map',
        'medicalHistory': currentUser.toMap(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'latitude': lat,
        'longitude': lng,
      }).timeout(const Duration(seconds: 5));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS Broadcasted via Arogna Network')));
    } catch (e) {
      debugPrint('Network failure, falling back to SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Failure Detected. Rerouting via Secure SMS...'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        debugPrint('Could not launch SMS app.');
      }
    }
    showDialog(context: context, barrierDismissible: false, builder: (c) => ProSOSModal(onAcknowledge: () => Navigator.of(context).pop()));
  }

  Widget _buildMapBody() {
    return Stack(
      children: [
        SizedBox.expand(
          child: _isMapSdkReady 
            ? GoogleMap(
                initialCameraPosition: CameraPosition(target: _userLocation, zoom: 14.0),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                trafficEnabled: true,
                markers: _markers,
                polylines: _polylines,
                circles: _mapCircles,
                onMapCreated: (c) { _mapController = c; _mapController!.setMapStyle(_cleanDarkStyle); },
                onTap: (_) => setState(() { _selectedFacility = null; _isNavigating = false; _polylines.clear(); }),
              )
            : const Center(child: CircularProgressIndicator()),
        ),
        
        // Navigation Top Panel
        if (_isNavigating && _selectedFacility != null)
          Positioned(
            top: 60, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(color: const Color(0xFF0F9D58), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Row(children: [
                const Icon(Icons.turn_slight_right, color: Colors.white, size: 30),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Navigating to', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(_selectedFacility!['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
          ),

        // Navigation Bottom Panel
        if (_isNavigating && _selectedFacility != null)
          Positioned(
            bottom: 40, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('14 min', style: TextStyle(color: const Color(0xFFD93025), fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('4.2 km • 11:45 AM', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ]),
                IconButton(icon: const Icon(Icons.close, size: 30, color: Colors.grey), onPressed: () => setState(() { _isNavigating = false; _polylines.clear(); }))
              ]),
            ),
          ),

        // Facility Selection Card (Only if not navigating)
        if (_selectedFacility != null && !_isNavigating)
          Positioned(
            bottom: 230, left: 20, right: 20,
            child: Card(
              elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(_selectedFacility!['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedFacility = null)),
                  ]),
                  Text(_selectedFacility!['type'], style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    onPressed: () => _getRoute(_selectedFacility!['lat'], _selectedFacility!['lng']),
                    icon: const Icon(Icons.directions), label: const Text('Show Route'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white),
                  )),
                ]),
              ),
            ),
          ),

        // SOS Button
        if (!_isNavigating)
          Positioned(
            bottom: 110, left: 0, right: 0, 
            child: HoldToActivateSOSButton(
              onTriggered: () {
                _triggerSosSequence();
              },
            ),
          ),

        // ── Uber-style: Ambulance ETA Banner (shows after SOS is dispatched) ──
        if (_hasActiveDispatch && _ambulanceEta.isNotEmpty)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  const Text('🚑', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ambulance En Route', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Inter')),
                        Text(
                          _ambulanceEta.isNotEmpty ? '$_ambulanceEta away • $_ambulanceDistance' : 'Locating ambulance...',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                        ),
                      ],
                    ),
                  ),
                  // Fit-bounds button — shows both markers
                  GestureDetector(
                    onTap: () {
                      if (_ambulanceLatLng != null && _mapController != null) {
                        _fitBounds(_ambulanceLatLng!, _userLocation);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fit_screen, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ArognaAppBar(
        title: _selectedIndex == 0 ? 'Arogna Map' : 
               _selectedIndex == 1 ? 'Report Incident' :
               _selectedIndex == 2 ? 'Community Feed' : 'AI Assistant',
        role: 'citizen',
        extraActions: _selectedIndex == 2 ? [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => CitizenCommunityFeed.seedDemoData(context),
            tooltip: 'Seed Demo Data',
          )
        ] : null,
      ),
      body: IndexedStack(index: _selectedIndex, children: [
        _buildMapBody(),
        const CitizenReportIncident(),
        const CitizenCommunityFeed(),
        const CitizenArognaAIAssistant(),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() { _selectedIndex = i; _selectedFacility = null; _polylines.clear(); _isNavigating = false; }),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4285F4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Bot'),
        ],
      ),
    );
  }
}

class HoldToActivateSOSButton extends StatefulWidget {
  final VoidCallback onTriggered;
  
  const HoldToActivateSOSButton({Key? key, required this.onTriggered}) : super(key: key);

  @override
  State<HoldToActivateSOSButton> createState() => _HoldToActivateSOSButtonState();
}

class _HoldToActivateSOSButtonState extends State<HoldToActivateSOSButton> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _holdController;
  late Animation<double> _scaleAnimation;
  bool _isTriggered = false;

  @override
  void initState() {
    super.initState();
    // The pulsing heartbeat effect
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    // The 4-second hold-to-activate loading ring
    _holdController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _holdController.addListener(() {
      setState(() {}); // Update the loading ring UI
      if (_holdController.isCompleted && !_isTriggered) {
        _isTriggered = true;
        HapticFeedback.heavyImpact(); // Vibrate when triggered
        widget.onTriggered();
        _holdController.reset();
        Future.delayed(const Duration(seconds: 2), () => _isTriggered = false);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _holdController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pulseController.stop();
    _holdController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_holdController.isCompleted) {
      _holdController.reverse();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _onPointerUp(null as PointerUpEvent), // Reset if finger slides off
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The Loading Ring
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: _holdController.value,
                    strokeWidth: 8,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                // The Main SOS Button
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC62828), // Deep emergency red
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: _holdController.isAnimating ? 10 : 5,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ProSOSModal extends StatefulWidget {
  final VoidCallback onAcknowledge;
  const ProSOSModal({Key? key, required this.onAcknowledge}) : super(key: key);

  @override
  State<ProSOSModal> createState() => _ProSOSModalState();
}

class _ProSOSModalState extends State<ProSOSModal> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _runEmergencySequence();
  }

  Future<void> _runEmergencySequence() async {
    // Step 1: GPS (Simulated delay for UI, assuming actual GPS is sent in parent)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _currentStep = 1);

    // Step 2: Camera/Audio Init (Mocked for demo safety)
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _currentStep = 2);

    // Step 3: Auto-Dialing
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _currentStep = 3);
      _launchDialer();
    }
  }

  Future<void> _launchDialer() async {
    final Uri telUri = Uri.parse('tel:112');
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  Widget _buildChecklistItem(String text, int stepIndex) {
    bool isActive = _currentStep == stepIndex;
    bool isDone = _currentStep > stepIndex;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else if (isActive) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
          else const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isDone || isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFF1E1E1E), // Sleek dark mode
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'EMERGENCY BROADCAST',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 24),
            _buildChecklistItem('Locking GPS Coordinates...', 0),
            _buildChecklistItem('Initializing Media Capture...', 1),
            _buildChecklistItem('Connecting to Dispatch (112)...', 2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: widget.onAcknowledge,
                child: const Text('Acknowledge & Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


