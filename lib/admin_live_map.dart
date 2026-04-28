import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminLiveMap extends StatefulWidget {
  const AdminLiveMap({Key? key}) : super(key: key);

  @override
  State<AdminLiveMap> createState() => _AdminLiveMapState();
}

class _AdminLiveMapState extends State<AdminLiveMap> with SingleTickerProviderStateMixin {
  bool _isMapSdkReady = false;
  Timer? _movementTimer;
  final Random _random = Random();
  BitmapDescriptor? _ambulanceIcon;
  final Map<MarkerId, Marker> _ambulances = {};
  
  // Blinking SOS Animation
  late AnimationController _blinkController;
  double _sosOpacity = 1.0;
  
  // Phase State
  StreamSubscription? _emergencySubscription;
  final Map<String, Marker> _sosMarkers = {};
  BitmapDescriptor? _sosIcon;
  GoogleMapController? _mapController;
  
  Map<String, dynamic>? _selectedEmergency;
  String? _selectedEmergencyId;
  Map<String, dynamic>? _selectedResponder;
  double _avgResponseTime = 4.2;

  // Ghost Fleet Initial Positions (Nagpur)
  final List<LatLng> _initialPositions = [
    const LatLng(21.1466, 79.0882), // Sitabuldi
    const LatLng(21.1386, 79.0625), // Dharampeth
    const LatLng(21.1028, 79.0805), // Manish Nagar
    const LatLng(21.1639, 79.0805), // Sadar
    const LatLng(21.1271, 79.0963), // Medical Sq
    const LatLng(21.1555, 79.0725), // Civil Lines
    const LatLng(21.0898, 79.0525), // Sonegaon
    const LatLng(21.1815, 79.0950), // Indora
    const LatLng(21.1550, 79.1450), // Pardi
    const LatLng(21.1200, 79.0450), // Trimurti Nagar
    const LatLng(21.1950, 79.0650), // Mankapur
    const LatLng(21.1500, 79.0050), // Wadi
  ];

  static const String _neonDarkStyle = '''
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

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        setState(() {
          _sosOpacity = _blinkController.value;
        });
      })..repeat(reverse: true);

    _loadCustomAssets();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isMapSdkReady = true;
          _initAmbulances();
          _startSimulation();
          _listenToEmergencies();
        });
      }
    });
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _emergencySubscription?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  void _listenToEmergencies() {
    _emergencySubscription = FirebaseFirestore.instance
        .collection('emergency_reports')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      _sosMarkers.clear();
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>? ?? {};
        
        // In-memory filter: only show active emergencies
        final status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'dispatched' || status == 'resolved' || status == 'approved' || status == 'rejected') {
          continue;
        }
        
        double lat = 0.0;
        double lng = 0.0;

        // 1. Check for direct lat/lng fields
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          lat = double.tryParse(data['latitude'].toString()) ?? 0.0;
          lng = double.tryParse(data['longitude'].toString()) ?? 0.0;
        }
        // 2. Check for Firebase GeoPoint or nested map inside 'location' field
        else if (data.containsKey('location')) {
          var loc = data['location'];
          if (loc.runtimeType.toString() == 'GeoPoint') {
            lat = loc.latitude;
            lng = loc.longitude;
          } else if (loc is Map) {
            lat = double.tryParse(loc['latitude']?.toString() ?? loc['lat']?.toString() ?? '0.0') ?? 0.0;
            lng = double.tryParse(loc['longitude']?.toString() ?? loc['lng']?.toString() ?? '0.0') ?? 0.0;
          }
        }

        // 3. Fallback to Borkhedi location so we at least see a pin
        if (lat == 0.0 && lng == 0.0) {
          lat = 20.8931;
          lng = 79.0201;
        }

        // Create the Red SOS Marker
        _sosMarkers[doc.id] = Marker(
          markerId: MarkerId('sos_${doc.id}'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 100,
          consumeTapEvents: true,
          onTap: () {
            setState(() {
              _selectedEmergency = data;
              _selectedEmergencyId = doc.id;
              _selectedResponder = null;
            });
          },
        );

        // Instantly pan camera to the emergency
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15.0));
      }
      setState(() {});
    });
  }

  Future<void> _dispatchUnit() async {
    if (_selectedEmergencyId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('emergency_reports')
          .doc(_selectedEmergencyId)
          .update({
        'status': 'dispatched',
        'assignedUnit': 'UNIT 4',
        'dispatchTime': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UNIT 4 Dispatched Successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedEmergency = null;
        _selectedEmergencyId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error dispatching unit: $e')),
      );
    }
  }

  Future<void> _loadCustomAssets() async {
    final aBytes = await _generateAmbulanceIcon();
    final sBytes = await _generateSosIcon();
    if (mounted) {
      setState(() {
        _ambulanceIcon = BitmapDescriptor.fromBytes(aBytes);
        _sosIcon = BitmapDescriptor.fromBytes(sBytes);
      });
    }
  }

  Future<Uint8List> _generateSosIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint outerPaint = Paint()..color = error.withOpacity(0.3);
    final Paint innerPaint = Paint()..color = error;

    canvas.drawCircle(const Offset(24, 24), 20, outerPaint);
    canvas.drawCircle(const Offset(24, 24), 12, innerPaint);

    final img = await pictureRecorder.endRecording().toImage(48, 48);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _generateAmbulanceIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint bodyPaint = Paint()..color = const Color(0xFF0059BB);
    final Paint crossPaint = Paint()..color = Colors.white;

    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 48, 32), const Radius.circular(6)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(36, 4, 12, 24), const Radius.circular(2)),
      bodyPaint,
    );

    canvas.drawRect(const Rect.fromLTWH(12, 14, 16, 4), crossPaint);
    canvas.drawRect(const Rect.fromLTWH(18, 8, 4, 16), crossPaint);

    final img = await pictureRecorder.endRecording().toImage(48, 32);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  void _initAmbulances() {
    final indianNames = ['Rajesh Kumar', 'Suresh Deshmukh', 'Amit Gondane', 'Priya Sharma', 'Rahul Varma', 'Sneha Patil', 'Vikas Rao', 'Anjali Gupta', 'Deepak Singh', 'Megha Joshi', 'Karan Mehta', 'Pooja Nair'];

    for (int i = 0; i < _initialPositions.length; i++) {
      final id = MarkerId('ambulance_$i');
      final name = indianNames[i % indianNames.length];
      final phone = '98${_random.nextInt(90000000) + 10000000}';
      
      _ambulances[id] = Marker(
        markerId: id,
        position: _initialPositions[i],
        icon: _ambulanceIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        consumeTapEvents: true,
        onTap: () {
          setState(() {
            _selectedResponder = {
              'unitId': 'UNIT ${i + 1}',
              'driver': name,
              'contact': phone,
              'distance': '${(1.2 + i * 0.4).toStringAsFixed(1)} km',
            };
            _selectedEmergency = null;
            _selectedEmergencyId = null;
          });
        },
      );
    }
  }

  void _startSimulation() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updatePositions();
    });
  }

  void _updatePositions() {
    if (!mounted) return;
    setState(() {
      for (var id in _ambulances.keys) {
        final currentPos = _ambulances[id]!.position;
        final latJitter = (_random.nextDouble() * 0.0001 + 0.0001) * (_random.nextBool() ? 1 : -1);
        final lngJitter = (_random.nextDouble() * 0.0001 + 0.0001) * (_random.nextBool() ? 1 : -1);

        _ambulances[id] = _ambulances[id]!.copyWith(
          positionParam: LatLng(currentPos.latitude + latJitter, currentPos.longitude + lngJitter),
        );
      }
      _avgResponseTime = 4.0 + (_random.nextDouble() * 0.5);
    });
  }

  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 500,
              decoration: BoxDecoration(
                color: surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outlineVariant),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  _isMapSdkReady 
                  ? GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(21.1458, 79.0882),
                      zoom: 13.0,
                    ),
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    trafficEnabled: true,
                    markers: {
                      ..._ambulances.values,
                      ..._sosMarkers.values,
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                      controller.setMapStyle(_neonDarkStyle);
                    },
                    onTap: (_) {
                      setState(() {
                        _selectedEmergency = null;
                        _selectedEmergencyId = null;
                        _selectedResponder = null;
                      });
                    },
                  )
                  : const Center(child: CircularProgressIndicator()),

                  Positioned(
                    right: 16,
                    top: 16,
                    child: Column(
                      children: [
                        _buildMapControlBtn(Icons.add),
                        const SizedBox(height: 8),
                        _buildMapControlBtn(Icons.remove),
                        const SizedBox(height: 16),
                        _buildMapControlBtn(Icons.my_location),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedEmergency != null)
              _buildEmergencyDetailPanel()
            else if (_selectedResponder != null)
              _buildResponderDetailPanel()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isDesktop = constraints.maxWidth > 768;
                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Active SOS Count',
                            value: _sosMarkers.length.toString(),
                            subtitle: 'Critical Alert',
                            valueColor: error,
                            icon: Icons.emergency,
                            iconBgColor: errorContainer,
                            iconColor: onErrorContainer,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Online Responders',
                            value: _ambulances.length.toString(),
                            subtitle: 'Units Available',
                            valueColor: primary,
                            icon: Icons.local_shipping,
                            iconBgColor: primaryContainer,
                            iconColor: onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Avg Response Time',
                            value: _avgResponseTime.toStringAsFixed(1),
                            subtitle: 'Minutes (trailing 24h)',
                            valueColor: onSurface,
                            icon: Icons.timer,
                            iconBgColor: surfaceContainerHighest,
                            iconColor: onSurface,
                            iconHasBorder: true,
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildStatCard(
                          title: 'Active SOS Count',
                          value: _sosMarkers.length.toString(),
                          subtitle: 'Critical Alert',
                          valueColor: error,
                          icon: Icons.emergency,
                          iconBgColor: errorContainer,
                          iconColor: onErrorContainer,
                        ),
                        const SizedBox(height: 24),
                        _buildStatCard(
                          title: 'Online Responders',
                          value: _ambulances.length.toString(),
                          subtitle: 'Units Available',
                          valueColor: primary,
                          icon: Icons.local_shipping,
                          iconBgColor: primaryContainer,
                          iconColor: onPrimaryContainer,
                        ),
                        const SizedBox(height: 24),
                        _buildStatCard(
                          title: 'Avg Response Time',
                          value: _avgResponseTime.toStringAsFixed(1),
                          subtitle: 'Minutes (trailing 24h)',
                          valueColor: onSurface,
                          icon: Icons.timer,
                          iconBgColor: surfaceContainerHighest,
                          iconColor: onSurface,
                          iconHasBorder: true,
                        ),
                      ],
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponderDetailPanel() {
    final responder = _selectedResponder!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary, width: 2),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      responder['unitId'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    responder['driver'],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() { _selectedResponder = null; }),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _buildDetailItem('Status', 'Available', Icons.check_circle, Colors.green),
              const SizedBox(width: 48),
              _buildDetailItem('Contact', responder['contact'], Icons.phone, primary),
              const SizedBox(width: 48),
              _buildDetailItem('Live Distance', responder['distance'], Icons.near_me, Colors.blue),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('MESSAGE DRIVER', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: responder['contact'],
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  icon: const Icon(Icons.call, size: 20),
                  label: const Text('CALL UNIT', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDetailPanel() {
    final victim = _selectedEmergency!;
    final medicalData = victim['medicalHistory'] as Map<String, dynamic>? ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error, width: 2),
        boxShadow: [
          BoxShadow(color: error.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CRITICAL SOS',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    victim['patientName'] ?? 'Unknown Victim',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() { _selectedEmergency = null; _selectedEmergencyId = null; }),
              ),
            ],
          ),
          const Divider(height: 32),
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            children: [
              _buildDetailItem('Blood Type', medicalData['bloodGroup'] ?? 'N/A', Icons.bloodtype, Colors.red),
              _buildDetailItem('Chronic Conditions', medicalData['chronicConditions'] ?? 'None Reported', Icons.history, Colors.orange),
              _buildDetailItem('Emergency Contact', medicalData['emergencyContact'] ?? 'N/A', Icons.contact_phone, primary),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _dispatchUnit,
              icon: const Icon(Icons.local_shipping, size: 24),
              label: const Text('DISPATCH UNIT-04 NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label, style: const TextStyle(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface), overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildMapControlBtn(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Icon(icon, size: 20, color: onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color valueColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    bool iconHasBorder = false,
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: iconHasBorder ? Border.all(color: outlineVariant) : null,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.02,
                  color: valueColor,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
