import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResponderNearbyHospitals extends StatefulWidget {
  const ResponderNearbyHospitals({Key? key}) : super(key: key);

  @override
  State<ResponderNearbyHospitals> createState() => _ResponderNearbyHospitalsState();
}

class _ResponderNearbyHospitalsState extends State<ResponderNearbyHospitals> {
  String selectedFilter = 'All Hospitals';
  Set<String> _bookedHospitals = {};

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EE);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color primaryFixedDim = Color(0xFFADC7FF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  final List<String> filterCategories = [
    'All Hospitals',
    'Trauma Center',
    'Cardiac Focus',
    'Pediatric'
  ];

  final List<Map<String, dynamic>> mockHospitals = [
    {
      'name': 'Central District Hospital',
      'distance': '2.4 km away',
      'routeTime': '12 mins routing',
      'freeBeds': 12,
      'traumaLevel': 'Level 1',
      'waitTime': '14 mins',
      'isAvailable': true,
      'accentColor': primary,
      'category': 'Trauma Center',
    },
    {
      'name': 'St. Jude Medical Center',
      'distance': '4.1 km away',
      'routeTime': '18 mins routing',
      'freeBeds': 0,
      'traumaLevel': 'Level 2',
      'waitTime': '45 mins',
      'isAvailable': false,
      'accentColor': error,
      'category': 'Cardiac Focus',
    },
    {
      'name': 'Northside General',
      'distance': '6.8 km away',
      'routeTime': '24 mins routing',
      'freeBeds': 4,
      'traumaLevel': 'Level 3',
      'waitTime': '8 mins',
      'isAvailable': true,
      'accentColor': primary,
      'category': 'Pediatric',
    },
    {
      'name': 'City General ER',
      'distance': '5.2 km away',
      'routeTime': '16 mins routing',
      'freeBeds': 2,
      'traumaLevel': 'Level 1',
      'waitTime': '22 mins',
      'isAvailable': true,
      'accentColor': primary,
      'category': 'Trauma Center',
    }
  ];

  @override
  Widget build(BuildContext context) {

    return Container(
      color: background,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No hospitals registered in the network yet.', style: TextStyle(color: outline)),
              ),
            );
          }

          var allDocs = snapshot.data!.docs;
          
          // Apply top chip filter locally if necessary (optional depending on category implementation in DB)
          // For now, we render all that match, or apply basic filter if 'category' exists
          var filteredDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] ?? 'General';
            return selectedFilter == 'All Hospitals' || category == selectedFilter || data['facility_type'] == selectedFilter;
          }).toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Header
              const Text(
                'Available Facilities',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 32 / 24,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterCategories.map((category) {
                    bool isSelected = selectedFilter == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFilter = category;
                          });
                        },
                        child: _buildFilterChip(category, isSelected: isSelected),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Hospital Cards
              if (filteredDocs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.local_hospital, size: 64, color: outline.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'No hospitals found for "$selectedFilter"',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredDocs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  
                  String hospitalName = data['name'] ?? 'Unknown Hospital';
                  String hospitalAddress = data['address'] ?? data['location'] ?? 'Location Unavailable';
                  int bedsFree = data['ward_available'] ?? 0;
                  String traumaLevel = data['facility_type'] ?? 'General Hospital';
                  
                  bool isAvailable = bedsFree > 0;
                  Color accentColor = isAvailable ? primary : error;
                  bool isBooked = _bookedHospitals.contains(doc.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHospitalCard(
                      id: doc.id,
                      context: context,
                      name: hospitalName,
                      address: hospitalAddress,
                      freeBeds: bedsFree,
                      traumaLevel: traumaLevel,
                      isAvailable: isAvailable,
                      isBooked: isBooked,
                      accentColor: accentColor,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Adjusted vertical padding for better tap target
      decoration: BoxDecoration(
        color: isSelected ? primary : surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        border: isSelected ? null : Border.all(color: outlineVariant),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12, // Increased from 11 for better readability
          fontWeight: FontWeight.w500,
          color: isSelected ? onPrimary : onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildHospitalCard({
    required String id,
    required BuildContext context,
    required String name,
    required String address,
    required int freeBeds,
    required String traumaLevel,
    required bool isAvailable,
    required bool isBooked,
    required Color accentColor,
  }) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surfaceContainerHighest),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Line
            Container(height: 4, color: accentColor),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & Bed Count
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 28 / 20,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Icon(Icons.location_on, size: 16, color: onSurfaceVariant),
                                const SizedBox(width: 4),
                              Text(
                                address,
                                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant),
                              ),
                            ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? primaryFixed : errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAvailable ? primaryFixedDim : error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bed,
                              size: 16,
                              color: isAvailable ? onPrimaryFixed : onErrorContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$freeBeds Free',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.6,
                                color: isAvailable ? onPrimaryFixed : onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats Grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: surfaceContainerHighest),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TRAUMA LEVEL',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: outline,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                traumaLevel,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'BEDS AVAILABLE',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: outline,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$freeBeds',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable ? onSurface : error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (address.isNotEmpty && address != 'Location Unavailable') {
                              final Uri googleMapsUrl = Uri.parse('google.navigation:q=${Uri.encodeComponent(address)}&mode=d');
                              if (await canLaunchUrl(googleMapsUrl)) {
                                await launchUrl(googleMapsUrl);
                              } else {
                                // Web fallback
                                launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}'));
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: surfaceContainerLowest,
                            foregroundColor: onSurface,
                            side: const BorderSide(color: outlineVariant),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text(
                            'Navigate',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isAvailable
                            ? ElevatedButton.icon(
                                onPressed: isBooked ? null : () async {
                                  setState(() {
                                    _bookedHospitals.add(id);
                                  });
                                  
                                  // Update the active emergency report with the assigned hospital
                                  final String currentResponderId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                  final reports = await FirebaseFirestore.instance
                                      .collection('emergency_reports')
                                      .where('assigned_responder_id', isEqualTo: currentResponderId)
                                      .where('status', isEqualTo: 'dispatched')
                                      .limit(1)
                                      .get();

                                  if (reports.docs.isNotEmpty) {
                                    await reports.docs.first.reference.update({
                                      'assigned_hospital_id': id,
                                      'status': 'en_route_to_hospital'
                                    });
                                  }
                                  
                                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                                    DocumentReference docRef = FirebaseFirestore.instance.collection('hospitals').doc(id);
                                    DocumentSnapshot snapshot = await transaction.get(docRef);
                                    if (snapshot.exists) {
                                      int currentBeds = snapshot.get('ward_available') ?? 0;
                                      if (currentBeds > 0) {
                                        transaction.update(docRef, {'ward_available': currentBeds - 1});
                                      }
                                    }
                                  });

                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: surfaceContainerLowest,
                                      title: const Row(
                                        children: [
                                          Icon(Icons.check_circle, color: primary),
                                          SizedBox(width: 8),
                                          Text('Bed Booked', style: TextStyle(fontFamily: 'Inter')),
                                        ],
                                      ),
                                      content: Text('Bed booked successfully at $name.', style: const TextStyle(fontFamily: 'Inter')),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('OK', style: TextStyle(fontFamily: 'Inter', color: primary)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isBooked ? outlineVariant : primary,
                                  foregroundColor: onPrimary,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(isBooked ? Icons.check_circle : Icons.add_circle, size: 18),
                                label: Text(
                                  isBooked ? 'Booked' : 'Book Bed',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: surfaceContainerHighest,
                                  foregroundColor: outline,
                                  disabledBackgroundColor: surfaceContainerHighest,
                                  disabledForegroundColor: outline,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.block, size: 18),
                                label: const Text(
                                  'Divert Active',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
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
}
