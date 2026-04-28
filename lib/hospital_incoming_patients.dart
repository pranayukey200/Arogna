import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HospitalIncomingPatients extends StatelessWidget {
  const HospitalIncomingPatients({Key? key}) : super(key: key);

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color tertiaryFixed = Color(0xFFDBE4ED);
  static const Color onTertiaryFixed = Color(0xFF141D23);
  static const Color tertiary = Color(0xFF545D65);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  @override
  Widget build(BuildContext context) {
    final String currentHospitalId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Incoming Patients',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time tracking of inbound emergency transports.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter Button (Desktop/Tablet)
                if (MediaQuery.of(context).size.width > 600)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.filter_list, size: 18, color: onSurface),
                        SizedBox(width: 4),
                        Text('Filter', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: onSurface)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Patient Feed Grid
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emergency_reports')
                  .where('status', whereIn: ['dispatched', 'on_scene', 'transporting'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No incoming patients at this time.', style: TextStyle(color: outline)),
                    ),
                  );
                }

                final incomingDocs = snapshot.data!.docs;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = 1;
                    if (constraints.maxWidth >= 1024) {
                      crossAxisCount = 3;
                    } else if (constraints.maxWidth >= 600) {
                      crossAxisCount = 2;
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                        children: incomingDocs.map((doc) {
                        final reportData = doc.data() as Map<String, dynamic>;
                        // ✅ Null-safety: Try multiple fields, default to empty string
                        final String citizenId = (reportData['userId'] ?? reportData['citizenUid'] ?? reportData['uid'] ?? reportData['patientId'] ?? '').toString().trim();
                        final status = reportData['status'] ?? 'Unknown';

                        // ✅ Guest SOS Guard: If no citizen ID, return a fallback card immediately
                        if (citizenId.isEmpty) {
                          final bool bedConfirmed = reportData['hospital_status'] == 'bed_confirmed';
                          String statusLabel = status == 'en_route_to_hospital' ? 'En Route' : 'In Transit';
                          Color statusColor = status == 'en_route_to_hospital' ? errorContainer : primaryFixed;
                          Color statusTextColor = status == 'en_route_to_hospital' ? onErrorContainer : onPrimaryFixed;
                          Color statusDotColor = status == 'en_route_to_hospital' ? error : primary;

                          return _buildPatientCard(
                            context,
                            docId: doc.id,
                            statusLabel: statusLabel,
                            statusColor: statusColor,
                            statusTextColor: statusTextColor,
                            statusDotColor: statusDotColor,
                            patientName: reportData['citizen_name'] ?? reportData['patientName'] ?? 'Guest Patient',
                            etaValue: 'In Transit',
                            etaColor: statusDotColor,
                            etaIcon: Icons.timer,
                            reqBedType: 'Blood: N/A',
                            reqBedIcon: Icons.bloodtype,
                            responderName: 'Allergies: Unknown',
                            responderIcon: Icons.warning,
                            buttons: [
                              Expanded(
                                child: bedConfirmed
                                  ? OutlinedButton(
                                      onPressed: null,
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      child: const Text('Bed Confirmed', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        // ✅ Always use doc.id (never null)
                                        await FirebaseFirestore.instance.collection('emergency_reports').doc(doc.id).update({'hospital_status': 'bed_confirmed'});
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                      child: const Text('Confirm Bed', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // ✅ Always use doc.id (never null)
                                    await FirebaseFirestore.instance.collection('emergency_reports').doc(doc.id).update({'status': 'resolved', 'hospital_status': 'arrived', 'resolved_at': FieldValue.serverTimestamp()});
                                    if (reportData['assigned_responder_id'] != null) {
                                      var q = await FirebaseFirestore.instance.collection('responders').where('username', isEqualTo: reportData['assigned_responder_id']).get();
                                      if (q.docs.isNotEmpty) await q.docs.first.reference.update({'status': 'active'});
                                    }
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient Arrived. Unit released.')));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12)),
                                  child: const Text('Patient Arrived', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                            opacity: 1.0,
                          );
                        }

                        // ✅ Normal path: Citizen ID exists, fetch full profile
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('citizens').doc(citizenId).get(),
                          builder: (context, citizenSnapshot) {
                            if (!citizenSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final citizenData = citizenSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                            final patientName = citizenData['name'] ?? 'Unknown Patient';
                            final bloodGroup = citizenData['bloodGroup'] ?? 'N/A';
                            final allergies = citizenData['allergies'] ?? 'None';
                            
                            String statusLabel = 'In Transit';
                            Color statusColor = primaryFixed;
                            Color statusTextColor = onPrimaryFixed;
                            Color statusDotColor = primary;

                            if (status == 'en_route_to_hospital') {
                              statusLabel = 'En Route';
                              statusColor = errorContainer;
                              statusTextColor = onErrorContainer;
                              statusDotColor = error;
                            }

                            final bool bedConfirmed = reportData['hospital_status'] == 'bed_confirmed';

                            return _buildPatientCard(
                              context,
                              docId: doc.id,
                              statusLabel: statusLabel,
                              statusColor: statusColor,
                              statusTextColor: statusTextColor,
                              statusDotColor: statusDotColor,
                              patientName: reportData['citizen_name'] ?? patientName,
                              etaValue: 'In Transit',
                              etaColor: statusDotColor,
                              etaIcon: Icons.timer,
                              reqBedType: 'Blood: $bloodGroup',
                              reqBedIcon: Icons.bloodtype,
                              responderName: 'Allergies: $allergies',
                              responderIcon: Icons.warning,
                              buttons: [
                                Expanded(
                                  child: bedConfirmed 
                                    ? OutlinedButton(
                                        onPressed: null,
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.green),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Bed Confirmed', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold))
                                      )
                                    : ElevatedButton(
                                        onPressed: () async {
                                          // ✅ Always use doc.id (never null)
                                          await FirebaseFirestore.instance.collection('emergency_reports').doc(doc.id).update({
                                            'hospital_status': 'bed_confirmed',
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Confirm Bed', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // ✅ Always use doc.id (never null)
                                      await FirebaseFirestore.instance.collection('emergency_reports').doc(doc.id).update({
                                        'status': 'resolved',
                                        'hospital_status': 'arrived',
                                        'resolved_at': FieldValue.serverTimestamp(),
                                      });
                                      
                                      if (reportData['assigned_responder_id'] != null) {
                                        var responderQuery = await FirebaseFirestore.instance
                                            .collection('responders')
                                            .where('username', isEqualTo: reportData['assigned_responder_id'])
                                            .get();
                                        if (responderQuery.docs.isNotEmpty) {
                                          await responderQuery.docs.first.reference.update({'status': 'active'});
                                        }
                                      }
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient Arrived. Unit released.')));
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Patient Arrived', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                              opacity: 1.0,
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, {
    required String docId,
    required String statusLabel,
    required Color statusColor,
    required Color statusTextColor,
    required Color statusDotColor,
    required String patientName,
    required String etaValue,
    required Color etaColor,
    required IconData etaIcon,
    required String reqBedType,
    required IconData reqBedIcon,
    required String responderName,
    required IconData responderIcon,
    required List<Widget> buttons,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusDotColor, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: statusTextColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      patientName,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(etaIcon, size: 18, color: etaColor),
                        const SizedBox(width: 4),
                        Text(
                          etaValue,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: etaColor),
                        ),
                      ],
                    ),
                    const Text(
                      'ETA',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: surfaceContainer),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: primaryFixed, shape: BoxShape.circle),
                        child: const Icon(Icons.bed, size: 18, color: onPrimaryFixed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Required Bed', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant)),
                            Text(reqBedType, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: tertiaryFixed, shape: BoxShape.circle),
                        child: Icon(responderIcon, size: 18, color: onTertiaryFixed),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Responder', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant)),
                            Text(responderName, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500, color: onSurface)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),

            // Action Buttons
            Row(children: buttons.map((w) => Expanded(child: w)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryBtn(String text, bool enabled, String docId, BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? () async {
        if (text == 'Confirm Bed') {
          try {
            await FirebaseFirestore.instance.collection('sos_events').doc(docId).update({
              'hospital_status': 'bed_reserved',
            });
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        }
      } : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        disabledBackgroundColor: primary.withOpacity(0.5),
        disabledForegroundColor: onPrimary.withOpacity(0.5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSecondaryBtn(String text, bool enabled, String docId, BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? () async {
        if (text == 'Patient Arrived') {
          try {
            await FirebaseFirestore.instance.collection('sos_events').doc(docId).update({
              'status': 'resolved',
            });
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        }
      } : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: onSurface,
        disabledForegroundColor: onSurface.withOpacity(0.5),
        backgroundColor: surfaceContainer,
        side: const BorderSide(color: outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
