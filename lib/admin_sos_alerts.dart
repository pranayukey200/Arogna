import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_live_map.dart';
import 'admin_reports.dart';
import 'admin_user_directory.dart';
import 'admin_hospital_status.dart';

class AdminSOSAlerts extends StatefulWidget {
  const AdminSOSAlerts({Key? key}) : super(key: key);

  @override
  State<AdminSOSAlerts> createState() => _AdminSOSAlertsState();
}

class _AdminSOSAlertsState extends State<AdminSOSAlerts> {
  int _selectedIndex = 0;

  Future<void> _nuclearResetBoard() async {
    try {
      // 1. Reset all responders to active
      var respondersQuery = await FirebaseFirestore.instance.collection('responders').get();
      for (var doc in respondersQuery.docs) {
        await doc.reference.update({'status': 'active'});
      }

      // 2. Clear all emergency reports
      var reportsQuery = await FirebaseFirestore.instance.collection('emergency_reports').get();
      for (var doc in reportsQuery.docs) {
        // Soft delete everything to clear the screen
        await doc.reference.update({'status': 'resolved'}); 
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('BOARD WIPED. All units active. All alerts resolved.')),
        );
      }
    } catch (e) {
      debugPrint('Reset failed: $e');
    }
  }

  // Stitch Design Tokens
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color outline = Color(0xFF717786);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primaryContainer = Color(0xFF0070EA);

  Future<void> _simulateIncomingSMSWebhook() async {
    try {
      await FirebaseFirestore.instance.collection('emergency_reports').add({
        'citizen_name': 'Unknown (Offline Fallback)',
        'userId': 'sms_gateway',
        'lat': 20.9495, // Hardcoded nearby coordinates for demo
        'lng': 79.0299,
        'status': 'pending',
        'source': 'SMS Webhook',
        'ai_priority_score': 5,
        'ai_analysis_summary': 'SYSTEM NOTE: Received via Offline SMS Gateway. High probability of critical incident due to localized network outage.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Twilio Webhook Received: Offline SMS injected into grid.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Webhook simulation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 1,
        shadowColor: const Color(0x0D000000),
        title: const Row(
          children: [
            Icon(Icons.emergency, color: primary),
            SizedBox(width: 8),
            Text(
              'AROGNA COMMAND',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cell_tower, color: Colors.grey),
            tooltip: 'Simulate Twilio Webhook',
            onPressed: _simulateIncomingSMSWebhook,
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            tooltip: 'Nuclear Reset',
            onPressed: () => _nuclearResetBoard(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const AdminLiveMap(),         // 0 - Map (default)
          _buildSOSAlertsView(),        // 1 - SOS
          const AdminHospitalStatus(),  // 2 - Hospitals
          const AdminReports(),         // 3 - Reports
          const AdminUserDirectory(),   // 4 - Directory
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: outline,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            activeIcon: Icon(Icons.warning_rounded),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_hospital_outlined),
            activeIcon: Icon(Icons.local_hospital),
            label: 'Hospitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Directory',
          ),
        ],
      ),
    );
  }

  Widget _buildSOSAlertsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_reports')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // In-Memory Filtering — keep pending + dispatched visible
        final activeDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final status = data['status']?.toString().toLowerCase();
          if (status == 'resolved') {
            return false;
          }
          return true; // Show pending, dispatched, and any other active status
        }).toList();

        // ✅ AI Triage: Sort by ai_priority_score descending (highest priority first)
        activeDocs.sort((a, b) {
          final Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
          final Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
          int priorityA = dataA['ai_priority_score'] ?? 1;
          int priorityB = dataB['ai_priority_score'] ?? 1;
          return priorityB.compareTo(priorityA);
        });

        Widget gridContent = activeDocs.isEmpty
            ? const Center(child: Text('No active SOS signals.'))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: activeDocs.length,
                itemBuilder: (context, index) {
                  final doc = activeDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final dataString = data.toString();
                  
                  final lat = data['latitude'];
                  final lng = data['longitude'];
                  final locationStr = (lat != null && lng != null) 
                      ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}' 
                      : 'Location unknown';
                  
                  final timestamp = data['timestamp'] as Timestamp?;
                  String timeStr = 'Just now';
                  if (timestamp != null) {
                    final diff = DateTime.now().difference(timestamp.toDate()).inMinutes;
                    if (diff > 0) {
                      timeStr = '$diff mins ago';
                    }
                  }

                  final isCritical = data['severity'] == 'High';
                  
                  final name = dataString.contains('userName') 
                      ? data['userName'] 
                      : (dataString.contains('patientName') ? data['patientName'] : 'Unknown Citizen');

                  final bool isDispatched = data['status']?.toString().toLowerCase() == 'dispatched';

                  // ✅ AI Triage fields
                  final int aiPriority = data['ai_priority_score'] ?? 1;
                  final String aiSummary = data['ai_analysis_summary'] ?? 'Awaiting AI analysis...';
                  final bool hasPhoto = data['has_photo'] == true;
                  final bool hasAudio = data['has_audio'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildEmergencyCard(
                      priorityLevel: isCritical ? 'Critical - Priority 1' : 'Urgent - Priority 2',
                      priorityColor: isCritical ? error : const Color(0xFFD93343),
                      priorityBgColor: isCritical ? errorContainer : const Color(0xFFFFDAD9),
                      time: timeStr,
                      name: name,
                      description: dataString.contains('description') ? data['description'] : 'Emergency SOS Signal',
                      location: locationStr,
                      actionText: isDispatched ? 'Dispatched' : 'Dispatch Unit',
                      actionIcon: isDispatched ? Icons.check_circle : Icons.local_shipping,
                      actionBgColor: isDispatched ? Colors.white : error,
                      actionTextColor: isDispatched ? error : Colors.white,
                      isDimmed: isDispatched,
                      isDispatched: isDispatched,
                      reportId: doc.id,
                      assignedResponderId: data['assigned_responder_id']?.toString(),
                      aiPriority: aiPriority,
                      aiSummary: aiSummary,
                      hasPhoto: hasPhoto,
                      hasAudio: hasAudio,
                      onAction: isDispatched ? null : () {
                        _showTacticalDispatchDialog(
                          context,
                          doc.id,
                          (lat as num?)?.toDouble() ?? 0.0,
                          (lng as num?)?.toDouble() ?? 0.0,
                        );
                      },
                    ),
                  );
                },
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Incoming Emergencies',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Active SOS signals requiring dispatch.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: errorContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${activeDocs.length} Critical',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, indent: 16, endIndent: 16, color: surfaceContainerHighest),
            Expanded(child: gridContent),
          ],
        );
      },
    );
  }

  void _showTacticalDispatchDialog(BuildContext parentContext, String reportId, double reportLat, double reportLng) {
    final List<String> mockedDistances = ['1.2 km away', '2.4 km away', '3.8 km away', '5.1 km away', '0.8 km away', '4.3 km away'];

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: Container(
            width: double.maxFinite,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with X button
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.local_shipping, color: Color(0xFF93000A), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Assign Responder', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF181C20))),
                              SizedBox(height: 2),
                              Text('Select a unit to respond', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF717786))),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE0E3E8)),
                const SizedBox(height: 8),
                // Responder list with nested report stream for live button state
                Flexible(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('emergency_reports')
                        .doc(reportId)
                        .snapshots(),
                    builder: (context, reportSnapshot) {
                      final reportData = reportSnapshot.hasData
                          ? reportSnapshot.data!.data() as Map<String, dynamic>? ?? {}
                          : <String, dynamic>{};
                      final String assignedId = reportData['assigned_responder_id']?.toString() ?? '';

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('responders')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final responders = snapshot.data!.docs;
                          if (responders.isEmpty) {
                            return const Center(
                              child: Text('No responders registered.', style: TextStyle(fontFamily: 'Inter', color: Color(0xFF717786))),
                            );
                          }

                          return Container(
                            width: double.maxFinite,
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: responders.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F4F9)),
                                itemBuilder: (context, index) {
                              final doc = responders[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final String name = data['name'] ?? 'Unknown';
                              final String unitNo = data['plate'] ?? data['vehicleType'] ?? 'N/A';
                              final String status = data['status'] ?? 'active';
                              final bool isAvailable = status.toLowerCase() == 'active';
                              final String distance = mockedDistances[index % mockedDistances.length];
                              final String responderUsername = data['username'] ?? doc.id;
                              // Only mark as dispatched if this responder is assigned to THIS report
                              final bool isThisResponderDispatched = assignedId.isNotEmpty && assignedId == responderUsername;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD8E2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0059BB)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF181C20)), overflow: TextOverflow.ellipsis),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: isAvailable ? const Color(0xFF10B981) : const Color(0xFFBA1A1A),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Unit: $unitNo  •  $distance',
                                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF717786)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(24),
                                          onTap: () async {
                                            final String phoneNum = data['phone'] ?? data['contactNumber'] ?? '';
                                            if (phoneNum.isNotEmpty) {
                                              final Uri telUri = Uri.parse('tel:$phoneNum');
                                              if (await canLaunchUrl(telUri)) {
                                                await launchUrl(telUri);
                                              } else {
                                                if (parentContext.mounted) {
                                                  ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('Cannot launch dialer.')));
                                                }
                                              }
                                            } else {
                                              if (parentContext.mounted) {
                                                ScaffoldMessenger.of(parentContext).showSnackBar(const SnackBar(content: Text('No contact number on file.')));
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.blue.shade600, width: 1.5),
                                            ),
                                            child: Icon(Icons.phone_outlined, color: Colors.blue.shade600, size: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          height: 32,
                                          child: isThisResponderDispatched
                                              ? OutlinedButton(
                                                  onPressed: null, // Disabled! Admin no longer controls this.
                                                  style: OutlinedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    side: const BorderSide(color: Color(0xFF8C1D18)),
                                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: const Text('Dispatched', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C1D18))),
                                                )
                                              : ElevatedButton(
                                                  onPressed: () async {
                                                    final String targetResponderId = data['username'] ?? doc.id; // MUST be the exact login username
                                                    await FirebaseFirestore.instance.collection('emergency_reports').doc(reportId).update({
                                                      'assigned_responder_id': targetResponderId,
                                                      'status': 'dispatched',
                                                      'dispatched_at': FieldValue.serverTimestamp(),
                                                    });
                                                    await FirebaseFirestore.instance.collection('responders').doc(doc.id).update({
                                                      'status': 'busy',
                                                    });
                                                    // Dialog stays open — button state updates via stream
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF8C1D18),
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  child: const Text('Dispatch', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600)),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard({
    required String priorityLevel,
    required Color priorityColor,
    required Color priorityBgColor,
    required String time,
    required String name,
    required String description,
    required String location,
    required String actionText,
    required IconData actionIcon,
    required Color actionBgColor,
    required Color actionTextColor,
    bool isDimmed = false,
    bool isDispatched = false,
    String? reportId,
    String? assignedResponderId,
    int aiPriority = 1,
    String aiSummary = 'Awaiting AI analysis...',
    bool hasPhoto = false,
    bool hasAudio = false,
    VoidCallback? onAction,
  }) {
    // AI Triage styling
    Color badgeColor = aiPriority >= 4 ? Colors.red : (aiPriority == 3 ? Colors.orange : Colors.green);
    String badgeText = aiPriority >= 4 ? 'CRITICAL' : (aiPriority == 3 ? 'URGENT' : 'STANDARD');
    return Opacity(
      opacity: isDimmed ? 0.8 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surfaceContainerHighest),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Line
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          priorityLevel,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: priorityColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Patient Info
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.my_location, size: 14, color: outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  // ✅ Gemini AI Triage Badge
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: badgeColor, size: 16),
                                const SizedBox(width: 6),
                                Text('GEMINI TRIAGE: $badgeText', style: TextStyle(fontFamily: 'Inter', color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                if (hasPhoto) const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.grey),
                                if (hasPhoto) const SizedBox(width: 4),
                                if (hasAudio) const Icon(Icons.mic_none_outlined, size: 16, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aiSummary,
                          style: TextStyle(fontFamily: 'Inter', color: Colors.grey[800], fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: surfaceContainerLow,
                border: Border(top: BorderSide(color: surfaceContainerHighest)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('View Details', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: isDispatched
                      ? OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(actionIcon, size: 16, color: error),
                          label: Text(actionText, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFBA1A1A))),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFBA1A1A)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: onAction,
                          icon: Icon(actionIcon, size: 16),
                          label: Text(actionText, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionBgColor,
                            foregroundColor: actionTextColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            if (reportId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('emergency_reports').doc(reportId).update({
                        'status': 'resolved',
                        'resolved_at': FieldValue.serverTimestamp(),
                      });
                      if (assignedResponderId != null) {
                        var responderQuery = await FirebaseFirestore.instance.collection('responders').where('username', isEqualTo: assignedResponderId).get();
                        if (responderQuery.docs.isNotEmpty) {
                          await responderQuery.docs.first.reference.update({'status': 'active'});
                        }
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mission accomplished. Alert cleared from board.')),
                        );
                      }
                    },
                    child: const Text(
                      'Mark as Resolved',
                      style: TextStyle(fontFamily: 'Inter', color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
