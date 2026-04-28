import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'web_js_stub.dart' if (dart.library.js) 'dart:js' as js;

class ResponderActiveDispatch extends StatefulWidget {
  final String responderUsername;
  const ResponderActiveDispatch({Key? key, this.responderUsername = ''}) : super(key: key);

  @override
  State<ResponderActiveDispatch> createState() => _ResponderActiveDispatchState();
}

class _ResponderActiveDispatchState extends State<ResponderActiveDispatch> {
  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EE);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFB6152E);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  String _responderUsername = '';

  // ─── Live Navigation State ────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  Timer? _routeRefreshTimer;

  // Destination coords — synced from Firestore dispatch data
  double _destLat = 21.1458;
  double _destLng = 79.0882;
  bool _trackingStarted = false;

  // Navigation HUD state
  String _etaText = '--';
  String _distanceText = '--';
  LatLng? _responderLatLng;
  double _responderBearing = 0.0;
  bool _isNavigationMode = true; // camera follows responder like Google Maps

  static const String _googleApiKey = 'AIzaSyDdx96tG5RXee5wk7kIYK0shjWvw_2TUxY';

  @override
  void initState() {
    super.initState();
    // Priority 1: Use the username passed directly from the login screen
    if (widget.responderUsername.isNotEmpty) {
      _responderUsername = widget.responderUsername;
      debugPrint('[DISPATCH] Username from login: $_responderUsername');
    } else {
      // Priority 2: Try to resolve from Firebase Auth (fallback)
      _resolveResponderUsername();
    }
    // Start live GPS tracking — works on both mobile and web
    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _routeRefreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Fallback: Fetch the logged-in responder's username from Firestore
  /// when it wasn't passed from the login screen (Firebase Auth path).
  Future<void> _resolveResponderUsername() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String uid = currentUser.uid;
    final String email = currentUser.email?.toLowerCase().trim() ?? '';

    try {
      // Try by UID
      var byUid = await FirebaseFirestore.instance
          .collection('responders')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (byUid.docs.isNotEmpty) {
        final username = byUid.docs.first.data()['username']?.toString() ?? '';
        if (username.isNotEmpty && mounted) {
          setState(() => _responderUsername = username);
          debugPrint('[DISPATCH] Resolved username by UID: $_responderUsername');
          return;
        }
      }

      // Try by email
      if (email.isNotEmpty) {
        var byEmail = await FirebaseFirestore.instance
            .collection('responders')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          final username = byEmail.docs.first.data()['username']?.toString() ?? '';
          if (username.isNotEmpty && mounted) {
            setState(() => _responderUsername = username);
            debugPrint('[DISPATCH] Resolved username by email: $_responderUsername');
            return;
          }
        }

        // Try email prefix as username
        final emailPrefix = email.split('@')[0];
        var byPrefix = await FirebaseFirestore.instance
            .collection('responders')
            .where('username', isEqualTo: emailPrefix)
            .limit(1)
            .get();
        if (byPrefix.docs.isNotEmpty && mounted) {
          setState(() => _responderUsername = emailPrefix);
          debugPrint('[DISPATCH] Resolved username by email prefix: $_responderUsername');
        }
      }
    } catch (e) {
      debugPrint('[DISPATCH] Error resolving responder username: $e');
    }
  }

  // ─── Live Tracking Engine ────────────────────────────────────────────────

  Future<void> _getRoute(double startLat, double startLng) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$_destLat,$_destLng&key=$_googleApiKey&mode=driving';
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final String encodedPolyline = route['overview_polyline']['points'];
        final List<LatLng> coords = _decodePolyline(encodedPolyline);

        // Parse ETA and Distance from the API response
        final leg = route['legs'][0];
        final String etaVal = leg['duration']['text'] ?? '--';
        final String distVal = leg['distance']['text'] ?? '--';

        if (mounted) {
          setState(() {
            _etaText = etaVal;
            _distanceText = distVal;
            _polylines
              ..removeWhere((p) => p.polylineId == const PolylineId('route'))
              ..add(Polyline(
                polylineId: const PolylineId('route'),
                color: const Color(0xFF1A73E8), // Google Maps blue
                width: 7,
                points: coords,
                jointType: JointType.round,
                endCap: Cap.roundCap,
                startCap: Cap.roundCap,
              ));
          });
        }
      }
    } catch (e) {
      debugPrint('[DISPATCH] Route error: $e');
    }
  }

  /// Publishes this responder's live coordinates to Firestore.
  /// Any screen (citizen, admin) can subscribe to responder_live_locations/{username}
  /// to track the ambulance in real-time — exactly like Uber's driver tracking.
  Future<void> _publishLocationToFirestore(double lat, double lng, double heading) async {
    final String id = _responderUsername.isNotEmpty
        ? _responderUsername
        : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown');
    try {
      await FirebaseFirestore.instance
          .collection('responder_live_locations')
          .doc(id)
          .set({
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
        'responder_id': id,
        'dest_lat': _destLat,
        'dest_lng': _destLng,
        'eta': _etaText,
        'distance': _distanceText,
      });
    } catch (e) {
      debugPrint('[DISPATCH] Firestore publish error: $e');
    }
  }

  /// Web-specific: uses browser Geolocation API via dart:js
  void _startWebTracking() {
    if (!kIsWeb) return;
    try {
      // Use browser's navigator.geolocation.watchPosition
      js.context.callMethod('eval', [
        '''
        (function() {
          if (!navigator.geolocation) return;
          window._arognaWatchId = navigator.geolocation.watchPosition(
            function(pos) {
              window._arognaLat = pos.coords.latitude;
              window._arognaLng = pos.coords.longitude;
              window._arognaHeading = pos.coords.heading || 0;
            },
            function(err) { console.warn('Geolocation error:', err); },
            { enableHighAccuracy: true, maximumAge: 3000, timeout: 10000 }
          );
        })()
        '''
      ]);

      // Poll the JS values every 3 seconds
      _routeRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        try {
          final dynamic lat = js.context['_arognaLat'];
          final dynamic lng = js.context['_arognaLng'];
          final dynamic hdg = js.context['_arognaHeading'];
          if (lat == null || lng == null) return;

          final double dLat = (lat as num).toDouble();
          final double dLng = (lng as num).toDouble();
          final double dHdg = (hdg as num?)?.toDouble() ?? 0.0;
          final LatLng pos = LatLng(dLat, dLng);

          _responderLatLng = pos;
          _responderBearing = dHdg;

          await _getRoute(dLat, dLng);
          await _publishLocationToFirestore(dLat, dLng, dHdg);

          if (!mounted) return;
          setState(() {
            _markers
              ..removeWhere((m) => m.markerId == const MarkerId('responder'))
              ..add(Marker(
                markerId: const MarkerId('responder'),
                position: pos,
                rotation: dHdg,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                anchor: const Offset(0.5, 0.5),
                flat: true,
                infoWindow: const InfoWindow(title: 'You (Ambulance)'),
              ))
              ..add(Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(_destLat, _destLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ));
          });

          if (_isNavigationMode) {
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: pos,
                  zoom: 18.0,
                  bearing: dHdg,
                  tilt: 60.0,
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('[DISPATCH] Web poll error: $e');
        }
      });
    } catch (e) {
      debugPrint('[DISPATCH] Web tracking setup error: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _startLiveTracking() async {
    if (_trackingStarted) return;
    _trackingStarted = true;

    // Web: use browser geolocation + JS polling
    if (kIsWeb) {
      _startWebTracking();
      return;
    }

    // Mobile: use Geolocator
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final Position initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _responderLatLng = LatLng(initial.latitude, initial.longitude);
      await _getRoute(initial.latitude, initial.longitude);
      await _publishLocationToFirestore(initial.latitude, initial.longitude, initial.heading);

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position pos) async {
        final LatLng currentLatLng = LatLng(pos.latitude, pos.longitude);
        _responderLatLng = currentLatLng;
        _responderBearing = pos.heading;

        // —— Uber-style: publish live location to Firestore ——
        await _publishLocationToFirestore(pos.latitude, pos.longitude, pos.heading);
        await _getRoute(pos.latitude, pos.longitude);

        if (!mounted) return;
        setState(() {
          _markers
            ..removeWhere((m) => m.markerId == const MarkerId('responder'))
            ..add(Marker(
              markerId: const MarkerId('responder'),
              position: currentLatLng,
              rotation: pos.heading,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              anchor: const Offset(0.5, 0.5),
              flat: true,
              infoWindow: const InfoWindow(title: 'You (Ambulance)'),
            ))
            ..add(Marker(
              markerId: const MarkerId('destination'),
              position: LatLng(_destLat, _destLng),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ));
        });

        if (_isNavigationMode) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: currentLatLng,
                zoom: 18.0,
                bearing: pos.heading,
                tilt: 60.0,
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('[DISPATCH] Mobile tracking error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String uid = currentUser?.uid ?? '';
    final String email = currentUser?.email?.toLowerCase().trim() ?? '';
    final String emailPrefix = email.isNotEmpty ? email.split('@')[0] : '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_reports')
          .where('status', whereIn: ['dispatched', 'on_scene', 'transporting'])
          .snapshots(),
      builder: (context, snapshot) {
        // Default data (shown while loading or if no active dispatch)
        String emergencyType = 'No Active Dispatch';
        String priorityText = 'Awaiting assignment';
        String patientName = '—';
        String patientAge = '';
        String patientGender = '';
        String severity = 'None';
        String timer = '00:00';
        bool hasActiveDispatch = false;
        String? activeDocId;
        double citizenLat = 21.1458;
        double citizenLng = 79.0882;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          Map<String, dynamic>? activeData;

          // CLIENT-SIDE FILTERING: Find the report assigned to THIS responder
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String assignedId = (data['assigned_responder_id'] ?? '').toString().toLowerCase().trim();

            // Match against ALL possible identifiers for this responder
            final bool isMyDispatch =
                (assignedId.isNotEmpty) && (
                  assignedId == uid.toLowerCase().trim() ||
                  assignedId == email ||
                  (emailPrefix.isNotEmpty && assignedId == emailPrefix) ||
                  (_responderUsername.isNotEmpty && assignedId == _responderUsername.toLowerCase().trim())
                );

            if (isMyDispatch) {
              activeData = data;
              activeDocId = doc.id;
              break;
            }
          }

        if (activeData != null) {
          if (activeData['location'] is GeoPoint) {
            citizenLat = (activeData['location'] as GeoPoint).latitude;
            citizenLng = (activeData['location'] as GeoPoint).longitude;
          } else if (activeData['lat'] != null && activeData['lng'] != null) {
            citizenLat = (activeData['lat'] as num).toDouble();
            citizenLng = (activeData['lng'] as num).toDouble();
          } else if (activeData['latitude'] != null && activeData['longitude'] != null) {
            citizenLat = (activeData['latitude'] as num).toDouble();
            citizenLng = (activeData['longitude'] as num).toDouble();
          }

          // Keep destination in sync with live dispatch coords
          if (_destLat != citizenLat || _destLng != citizenLng) {
            _destLat = citizenLat;
            _destLng = citizenLng;
            // Update the static destination marker
            _markers
              ..removeWhere((m) => m.markerId == const MarkerId('destination'))
              ..add(Marker(
                markerId: const MarkerId('destination'),
                position: LatLng(citizenLat, citizenLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(title: 'Victim: $patientName'),
              ));
          }

          emergencyType = activeData['issue'] ?? activeData['description'] ?? 'Emergency';
          priorityText = activeData['triageLevel'] == 'Red'
                ? 'Priority 1 - Immediate Response Required'
                : 'Priority 2 - Urgent';
            patientName = activeData['patientName'] ?? 'Unknown Citizen';
            patientAge = activeData['patientAge']?.toString() ?? '--';
            patientGender = activeData['patientGender'] ?? '--';
            severity = activeData['triageLevel'] == 'Red' ? 'Critical' : 'Urgent';
            timer = '02:14';
            hasActiveDispatch = true;
          }
        }

        return Container(
          color: surfaceContainerLow,
          child: Column(
            children: [
              // Red Alert Banner
              Container(
                color: hasActiveDispatch ? secondary : outline,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: onSecondary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasActiveDispatch
                                ? 'Active Dispatch: $emergencyType'
                                : 'No Active Dispatch',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            priorityText,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasActiveDispatch) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: onSecondary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          timer,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.navigation, color: Colors.white),
                        onPressed: () => _launchNavigation(citizenLat, citizenLng),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ),

              // Map Container
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasActiveDispatch ? GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          // Fly camera to citizen location on first load
                          if (_responderLatLng == null) {
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                  target: LatLng(citizenLat, citizenLng),
                                  zoom: 15,
                                  tilt: 45,
                                ),
                              ),
                            );
                          }
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(citizenLat, citizenLng),
                          zoom: 15,
                          tilt: 45,
                        ),
                        markers: _markers.isNotEmpty ? _markers : {
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: LatLng(citizenLat, citizenLng),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                            infoWindow: InfoWindow(title: 'Victim: $patientName'),
                          ),
                          Marker(
                            markerId: const MarkerId('responder_static'),
                            position: LatLng(citizenLat - 0.005, citizenLng - 0.005),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            flat: true,
                            anchor: const Offset(0.5, 0.5),
                            infoWindow: const InfoWindow(title: 'You (Ambulance)'),
                          ),
                        },
                        polylines: _polylines.isNotEmpty ? _polylines : {
                          Polyline(
                            polylineId: const PolylineId('route_static'),
                            points: [
                              LatLng(citizenLat - 0.005, citizenLng - 0.005),
                              LatLng(citizenLat, citizenLng),
                            ],
                            color: const Color(0xFF1A73E8),
                            width: 7,
                            endCap: Cap.roundCap,
                            startCap: Cap.roundCap,
                          ),
                        },
                        myLocationEnabled: false,
                        compassEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        rotateGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        onCameraMoveStarted: () {
                          // User manually moved the camera — pause auto-follow
                          if (_isNavigationMode) setState(() => _isNavigationMode = false);
                        },
                      ) : Container(
                        color: surfaceContainerHigh,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 64, color: primary.withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              const Text(
                                'All clear — no active dispatches',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: onSurfaceVariant),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Awaiting Active Dispatch...',
                                style: TextStyle(fontFamily: 'Inter', color: onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Navigation HUD: ETA bar (top of map) ────────────────
                    if (hasActiveDispatch)
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A73E8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _etaText,
                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                                  ),
                                  Text(
                                    _distanceText,
                                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontFamily: 'Inter'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Recenter / navigation mode toggle
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _isNavigationMode = true);
                                      if (_responderLatLng != null) {
                                        _mapController?.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: _responderLatLng!,
                                              zoom: 18.0,
                                              bearing: _responderBearing,
                                              tilt: 60.0,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _isNavigationMode ? Icons.navigation : Icons.my_location,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Open in Google Maps
                                  GestureDetector(
                                    onTap: () => _launchNavigation(_destLat, _destLng),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.open_in_new, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Floating Victim Profile Card (bottom of map)
                    if (hasActiveDispatch)
                      _buildDispatchCard(activeDocId, patientName, patientAge, patientGender, severity),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDispatchCard(String? activeReportId, String patientName, String patientAge, String patientGender, String severity) {
    if (activeReportId == null || activeReportId.isEmpty) {
      return _buildStaticCard(patientName, patientAge, patientGender, severity, activeReportId);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('emergency_reports').doc(activeReportId).snapshots(),
      builder: (context, reportSnap) {
        if (!reportSnap.hasData || !reportSnap.data!.exists) {
          return _buildStaticCard(patientName, patientAge, patientGender, severity, activeReportId);
        }

        final reportData = reportSnap.data!.data() as Map<String, dynamic>? ?? {};
        final String citizenUid = reportData['patientId'] ?? reportData['uid'] ?? '';
        String currentStatus = reportData['status'] ?? '';

        // Read medical data embedded directly in the emergency report
        final Map<String, dynamic> embeddedMedical = (reportData['medicalHistory'] is Map)
            ? Map<String, dynamic>.from(reportData['medicalHistory'])
            : {};

        // Extract what we can from the report itself
        final String reportName = reportData['patientName'] ?? reportData['userName'] ?? patientName;
        final String reportBlood = embeddedMedical['bloodGroup'] ?? '';
        final reportAllergies = embeddedMedical['allergies'];
        final reportConditions = embeddedMedical['conditions'];
        final String reportEmergencyContact = embeddedMedical['emergencyContact'] ?? '';

        if (citizenUid.isEmpty || citizenUid == 'anonymous') {
          // No UID — use embedded data directly
          final String allergiesStr = (reportAllergies is List && reportAllergies.isNotEmpty)
              ? reportAllergies.join(', ')
              : (reportAllergies is String && reportAllergies.isNotEmpty ? reportAllergies : 'None reported');
          final String conditionsStr = (reportConditions is List && reportConditions.isNotEmpty)
              ? reportConditions.join(', ')
              : (reportConditions is String && reportConditions.isNotEmpty ? reportConditions : 'None');
          return _renderCard(
            reportName.isNotEmpty && reportName != '—' ? reportName : 'Guest Citizen',
            patientAge, patientGender, severity,
            reportBlood.isNotEmpty ? reportBlood : 'Unknown',
            allergiesStr, conditionsStr, reportEmergencyContact,
            activeReportId, currentStatus,
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('citizens').doc(citizenUid).get(),
          builder: (context, citizenSnap) {
            Map<String, dynamic> citizenData = {};
            if (citizenSnap.hasData && citizenSnap.data!.exists) {
              citizenData = citizenSnap.data!.data() as Map<String, dynamic>? ?? {};
            }

            // Priority: citizens collection > embedded medicalHistory > fallback
            final displayName = citizenData['name'] ?? reportName;
            final displayAge = citizenData['age']?.toString() ?? (patientAge != '--' ? patientAge : '--');
            final displayGender = citizenData['gender'] ?? (patientGender != '--' ? patientGender : '--');
            final displayBlood = citizenData['bloodGroup'] ?? (reportBlood.isNotEmpty ? reportBlood : 'Unknown');

            // Allergies
            final dynamic rawAllergies = citizenData['allergies'] ?? reportAllergies;
            final String displayAllergies = (rawAllergies is List && rawAllergies.isNotEmpty)
                ? rawAllergies.join(', ')
                : (rawAllergies is String && rawAllergies.isNotEmpty ? rawAllergies : 'None reported');

            // Chronic conditions
            final dynamic rawConditions = citizenData['chronicConditions'] ?? citizenData['conditions'] ?? reportConditions;
            final String displayConditions = (rawConditions is List && rawConditions.isNotEmpty)
                ? rawConditions.join(', ')
                : (rawConditions is String && rawConditions.isNotEmpty ? rawConditions : 'None');

            // Emergency contact
            final String displayEmergencyContact = citizenData['emergencyContact1'] ?? citizenData['emergencyContact'] ?? reportEmergencyContact;

            return _renderCard(displayName, displayAge, displayGender, severity, displayBlood, displayAllergies, displayConditions, displayEmergencyContact, activeReportId, currentStatus);
          },
        );
      },
    );
  }

  Widget _buildStaticCard(String patientName, String patientAge, String patientGender, String severity, String? activeReportId) {
    return _renderCard(
      patientName.isNotEmpty && patientName != '—' ? patientName : 'Guest Citizen',
      patientAge, patientGender, severity,
      'Unknown', 'None reported', 'None', '',
      activeReportId, '',
    );
  }

  Widget _renderCard(String patientName, String patientAge, String patientGender, String severity, String bloodType, String allergies, String conditions, String emergencyContact, String? activeDocId, String currentStatus) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surfaceContainerHighest),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Patient Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientName,
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
                          ),
                          if (patientAge.isNotEmpty || patientGender.isNotEmpty)
                            Text(
                              [if (patientAge.isNotEmpty) '$patientAge yrs', if (patientGender.isNotEmpty) patientGender].join(' • '),
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severity == 'Critical' ? errorContainer : const Color(0xFFFFDAD9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severity,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: severity == 'Critical' ? onErrorContainer : secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: surfaceContainerHighest),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BLOOD TYPE', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(bloodType, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: error)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: surfaceContainerHighest),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ALLERGIES', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                allergies,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // View Medical Certificate Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showMedicalDetails(patientName, patientAge, patientGender, bloodType, allergies, conditions, emergencyContact),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: surfaceContainerLow,
                        foregroundColor: primary,
                        side: const BorderSide(color: outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.medical_information, size: 18),
                      label: const Text('View Medical Certificate', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              color: background,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: activeDocId == null || activeDocId.isEmpty ? null : () => FirebaseFirestore.instance.collection('emergency_reports').doc(activeDocId).update({'status': 'on_scene', 'updatedAt': FieldValue.serverTimestamp()}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStatus == 'on_scene' ? primary : surfaceContainerHigh,
                        foregroundColor: currentStatus == 'on_scene' ? onPrimary : onSurface,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.directions_car, size: 20),
                      label: const Text('On Scene', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: activeDocId == null || activeDocId.isEmpty ? null : () => FirebaseFirestore.instance.collection('emergency_reports').doc(activeDocId).update({'status': 'transporting', 'updatedAt': FieldValue.serverTimestamp()}),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentStatus == 'transporting' ? primary : surfaceContainerHigh,
                            foregroundColor: currentStatus == 'transporting' ? onPrimary : onSurface,
                            side: BorderSide(color: currentStatus == 'transporting' ? primary : outlineVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Transporting', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: activeDocId == null || activeDocId.isEmpty ? null : () async {
                            // 1. Mark the emergency as resolved
                            await FirebaseFirestore.instance.collection('emergency_reports').doc(activeDocId).update({
                              'status': 'resolved',
                              'resolved_at': FieldValue.serverTimestamp(),
                            });

                            // 2. Free up this specific responder back to active
                            final String username = _responderUsername;
                            if (username.isNotEmpty) {
                              var responderQuery = await FirebaseFirestore.instance
                                  .collection('responders')
                                  .where('username', isEqualTo: username)
                                  .get();
                              if (responderQuery.docs.isNotEmpty) {
                                await responderQuery.docs.first.reference.update({'status': 'active'});
                              }
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Emergency Resolved. Unit available.')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: currentStatus == 'resolved' ? primary : surfaceContainerHigh,
                            foregroundColor: currentStatus == 'resolved' ? onPrimary : onSurface,
                            side: BorderSide(color: currentStatus == 'resolved' ? primary : outlineVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Resolved', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicalDetails(String name, String age, String gender, String blood, String allergies, String conditions, String emergencyContact) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medical_services, color: onErrorContainer, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Medical Certificate', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: onSurface)),
                          Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: outline),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: outlineVariant, height: 1),
                const SizedBox(height: 16),

                // Patient Info Row
                Row(
                  children: [
                    _medicalDetailChip('AGE', age.isNotEmpty && age != '--' ? '$age yrs' : 'N/A'),
                    const SizedBox(width: 12),
                    _medicalDetailChip('GENDER', gender.isNotEmpty && gender != '--' ? gender : 'N/A'),
                  ],
                ),
                const SizedBox(height: 12),

                // Blood Group — large highlight
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: error.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bloodtype, color: onErrorContainer, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BLOOD GROUP', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: onErrorContainer)),
                          const SizedBox(height: 2),
                          Text(blood, style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: onErrorContainer)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Allergies
                _medicalSection('Allergies', allergies, Icons.warning_amber_rounded, const Color(0xFFFFF3E0), Colors.orange.shade800),
                const SizedBox(height: 12),

                // Chronic Conditions
                _medicalSection('Chronic Conditions', conditions, Icons.monitor_heart, const Color(0xFFE3F2FD), primary),
                const SizedBox(height: 12),

                // Emergency Contact
                if (emergencyContact.isNotEmpty)
                  _medicalSection('Emergency Contact', emergencyContact, Icons.phone, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _medicalDetailChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _medicalSection(String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: iconColor)),
                const SizedBox(height: 4),
                Text(content, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: iconColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final Uri gMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(gMapsUrl)) {
      await launchUrl(gMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Maps')),
        );
      }
    }
  }
}
