import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalResourceStatus extends StatefulWidget {
  final String hospitalId;
  const HospitalResourceStatus({Key? key, required this.hospitalId}) : super(key: key);

  @override
  State<HospitalResourceStatus> createState() => _HospitalResourceStatusState();
}

class _HospitalResourceStatusState extends State<HospitalResourceStatus> {
  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color secondary = Color(0xFFB6152E);
  static const Color secondaryContainer = Color(0xFFD93343);
  static const Color onSecondaryContainer = Color(0xFFFFFBFF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Seed the document if it doesn't exist
            FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).set({
              'name': 'City Memorial',
              'location': 'Downtown',
              'status': 'OPERATIONAL',
              'ward_available': 12,
              'ward_total': 50,
              'icu_available': 5,
              'icu_total': 10,
              'trauma_available': 85,
              'trauma_total': 100,
              'trauma_specialist': true,
              'cardio_specialist': true,
              'ortho_specialist': false,
              'neuro_specialist': true,
              'facility_type': 'Trauma Center (Level 1)',
              'last_updated': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          int wardAvailable = data['ward_available'] ?? 0;
          int icuAvailable = data['icu_available'] ?? 0;
          int traumaAvailable = data['trauma_available'] ?? 0;
          
          bool traumaSpecialist = data['trauma_specialist'] ?? false;
          bool cardioSpecialist = data['cardio_specialist'] ?? false;
          bool orthoSpecialist = data['ortho_specialist'] ?? false;
          bool neuroSpecialist = data['neuro_specialist'] ?? false;
          
          String facilityType = data['facility_type'] ?? 'Trauma Center (Level 1)';
          
          String lastUpdatedStr = 'Just now';
          if (data['last_updated'] != null) {
            final ts = data['last_updated'] as Timestamp;
            final diff = DateTime.now().difference(ts.toDate()).inMinutes;
            if (diff > 0) {
              lastUpdatedStr = '$diff mins ago';
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header / Hospital Info
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 768) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hospital Facility',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: outline),
                            ),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: data['name'] ?? 'Unknown Hospital',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.01),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.only(bottom: 8),
                                border: UnderlineInputBorder(borderSide: BorderSide(color: outlineVariant, width: 2)),
                                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: outlineVariant, width: 2)),
                                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary, width: 2)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 256,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Facility Type',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: outline),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: outlineVariant),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: facilityType,
                                  isExpanded: true,
                                  icon: const Icon(Icons.expand_more, color: outline),
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: onSurface),
                                  items: const [
                                    DropdownMenuItem(value: 'Trauma Center (Level 1)', child: Text('Trauma Center (Level 1)')),
                                    DropdownMenuItem(value: 'General Hospital', child: Text('General Hospital')),
                                    DropdownMenuItem(value: 'Specialty Clinic', child: Text('Specialty Clinic')),
                                  ],
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).update({
                                        'facility_type': newValue,
                                        'last_updated': FieldValue.serverTimestamp()
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hospital Facility',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: outline),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: data['name'] ?? 'Unknown Hospital',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600, color: onSurface, letterSpacing: -0.01),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 8),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: outlineVariant, width: 2)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: outlineVariant, width: 2)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Facility Type',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: outline),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: facilityType,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more, color: outline),
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: onSurface),
                            items: const [
                              DropdownMenuItem(value: 'Trauma Center (Level 1)', child: Text('Trauma Center (Level 1)')),
                              DropdownMenuItem(value: 'General Hospital', child: Text('General Hospital')),
                              DropdownMenuItem(value: 'Specialty Clinic', child: Text('Specialty Clinic')),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).update({
                                  'facility_type': newValue,
                                  'last_updated': FieldValue.serverTimestamp()
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.update, size: 18, color: outline),
                const SizedBox(width: 8),
                Text('Last updated: $lastUpdatedStr', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: outline)),
              ],
            ),
            const SizedBox(height: 32),

            // Content Grid
            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 1024;
                
                List<Widget> children = [
                  // Left Column: Bed Counters
                  Expanded(
                    flex: isDesktop ? 7 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bed, color: primary),
                            SizedBox(width: 8),
                            Text(
                              'Critical Resources',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildCounterCard(
                              title: 'Beds Available',
                              statusLabel: wardAvailable > 5 ? 'Available' : 'Critical',
                              statusColor: wardAvailable > 5 ? surfaceContainer : errorContainer,
                              statusTextColor: wardAvailable > 5 ? onSurfaceVariant : onErrorContainer,
                              icon: Icons.bed,
                              iconColor: primary,
                              value: wardAvailable,
                              onDecrement: () => _updateResource('ward_available', -1),
                              onIncrement: () => _updateResource('ward_available', 1),
                            ),
                            const SizedBox(height: 16),
                            _buildCounterCard(
                              title: 'ICU Capacity',
                              statusLabel: icuAvailable > 2 ? 'Stable' : 'Critical',
                              statusColor: icuAvailable > 2 ? surfaceContainer : errorContainer,
                              statusTextColor: icuAvailable > 2 ? onSurfaceVariant : onErrorContainer,
                              icon: Icons.monitor_heart,
                              iconColor: error,
                              value: icuAvailable,
                              onDecrement: () => _updateResource('icu_available', -1),
                              onIncrement: () => _updateResource('icu_available', 1),
                            ),
                            const SizedBox(height: 16),
                            _buildCounterCard(
                              title: 'Trauma Bay',
                              statusLabel: traumaAvailable > 2 ? 'Good' : 'Low',
                              statusColor: traumaAvailable > 2 ? surfaceContainer : errorContainer,
                              statusTextColor: traumaAvailable > 2 ? onSurfaceVariant : onErrorContainer,
                              icon: Icons.healing,
                              iconColor: primary,
                              value: traumaAvailable,
                              onDecrement: () => _updateResource('trauma_available', -1),
                              onIncrement: () => _updateResource('trauma_available', 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (isDesktop) const SizedBox(width: 32) else const SizedBox(height: 32),

                  // Right Column: Specialist Availability
                  Expanded(
                    flex: isDesktop ? 5 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.medical_services, color: primary),
                            SizedBox(width: 8),
                            Text(
                              'Specialist Availability',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: outlineVariant),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              _buildSpecialistRow(
                                title: 'Trauma Surgery',
                                subtitle: 'Dr. Sarah Jenkins +2',
                                icon: Icons.healing,
                                isActive: traumaSpecialist,
                                isLast: false,
                                onChanged: (val) => _updateSpecialist('trauma_specialist', val),
                              ),
                              _buildSpecialistRow(
                                title: 'Cardiology',
                                subtitle: 'Dr. Michael Chen',
                                icon: Icons.favorite,
                                isActive: cardioSpecialist,
                                isLast: false,
                                onChanged: (val) => _updateSpecialist('cardio_specialist', val),
                              ),
                              _buildSpecialistRow(
                                title: 'Orthopedics',
                                subtitle: 'No specialists on call',
                                icon: Icons.personal_injury,
                                isActive: orthoSpecialist,
                                isLast: false,
                                onChanged: (val) => _updateSpecialist('ortho_specialist', val),
                              ),
                              _buildSpecialistRow(
                                title: 'Neurology',
                                subtitle: 'Dr. Emily Torres',
                                icon: Icons.psychology,
                                isActive: neuroSpecialist,
                                isLast: true,
                                onChanged: (val) => _updateSpecialist('neuro_specialist', val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ];

                return isDesktop
                    ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
              },
            ),
            
            const SizedBox(height: 32),
            const Divider(color: outlineVariant, height: 1),
            const SizedBox(height: 24),

            // Action Area
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: onPrimary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
                icon: const Icon(Icons.cloud_upload, size: 24),
                label: const Text(
                  'Update Status',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32), // Padding for mobile bottom nav if needed
          ],
        ),
      );
    },
  ),
);
}

  Future<void> _updateResource(String field, int delta) async {
    try {
      await FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).update({
        field: FieldValue.increment(delta),
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating resource: $e");
    }
  }

  Future<void> _updateSpecialist(String field, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('hospitals').doc(widget.hospitalId).update({
        field: value,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating specialist: $e");
    }
  }

  Widget _buildCounterCard({
    required String title,
    required String statusLabel,
    required Color statusColor,
    required Color statusTextColor,
    required IconData icon,
    required Color iconColor,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: statusTextColor),
                    ),
                  ),
                ],
              ),
              Icon(icon, color: iconColor, size: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRoundBtn(Icons.remove, onDecrement),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -0.02, color: onSurface, height: 1),
              ),
              _buildRoundBtn(Icons.add, onIncrement),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBtn(IconData icon, VoidCallback onPressed) {
    return Material(
      color: surfaceContainer,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: onSurface, size: 24),
        ),
      ),
    );
  }

  Widget _buildSpecialistRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required bool isLast,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: surfaceVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? primaryContainer.withOpacity(0.2) : surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? primary : outline, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: onSurface),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: outline),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: primary,
            activeTrackColor: primaryFixed,
            inactiveThumbColor: outline,
            inactiveTrackColor: surfaceVariant,
          ),
        ],
      ),
    );
  }
}
