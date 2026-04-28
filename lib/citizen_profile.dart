import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CitizenProfileScreen extends StatelessWidget {
  const CitizenProfileScreen({Key? key}) : super(key: key);

  // Design System Colors from Stitch
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorColor = Color(0xFFBA1A1A);

  Future<DocumentSnapshot?> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try citizens collection first, then users
      var doc = await FirebaseFirestore.instance.collection('citizens').doc(user.uid).get();
      if (doc.exists) return doc;
      doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) return doc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: surfaceVariant, height: 1),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: outlineVariant),
                  const SizedBox(height: 16),
                  const Text('Could not load profile data.', style: TextStyle(color: outline, fontFamily: 'Inter', fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Please ensure you are registered.', style: TextStyle(color: outlineVariant, fontFamily: 'Inter', fontSize: 13)),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Extract fields safely
          final String fullName = data['fullName'] ?? data['name'] ?? 'Citizen';
          final String email = data['email'] ?? '';
          final String contactNumber = data['contactNumber'] ?? data['phone'] ?? 'Not provided';
          final String bloodGroup = data['bloodGroup'] ?? data['blood_type'] ?? 'Unknown';
          final String allergies = (data['allergies'] is List)
              ? (data['allergies'] as List).join(', ')
              : (data['allergies']?.toString().isNotEmpty == true ? data['allergies'].toString() : 'None reported');
          final String chronicConditions = data['chronicConditions']?.toString().isNotEmpty == true
              ? data['chronicConditions'].toString()
              : (data['conditions'] is List
                  ? (data['conditions'] as List).join(', ')
                  : 'None reported');

          // Emergency contacts
          List<dynamic>? emc = data['emergencyContacts'];
          String emergencyContactsText;
          if (emc != null && emc.isNotEmpty) {
            emergencyContactsText = emc.join('\n');
          } else if (data['emergencyContact']?.toString().isNotEmpty == true) {
            emergencyContactsText = data['emergencyContact'].toString();
          } else {
            emergencyContactsText = 'Not provided';
          }

          // Medical report URL
          final String? reportUrl = data['medicalReportUrl'];
          final bool hasReport = reportUrl != null && reportUrl.isNotEmpty;

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Hero Banner & Avatar Overlap (SOS Red Theme)
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC62828), // Deep SOS Red
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        // Premium Avatar with White Border
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFF5F5F7), shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFC62828), fontFamily: 'Inter'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Inter')),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Inter')),
                        const SizedBox(height: 12),
                        // Upgraded Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('CITIZEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC62828), letterSpacing: 1.2, fontFamily: 'Inter')),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Content Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSectionHeader('ACCOUNT INFORMATION'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.phone_android, 'Contact Number', contactNumber, iconColor: primary),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionHeader('CLINICAL DETAILS'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.water_drop, 'Blood Group', bloodGroup, iconColor: errorColor),
                        const Divider(height: 32, indent: 48),
                        _buildInfoRow(Icons.warning_amber_rounded, 'Allergies', allergies, iconColor: Colors.orange),
                        const Divider(height: 32, indent: 48),
                        _buildInfoRow(Icons.medical_information, 'Chronic Conditions', chronicConditions, iconColor: Colors.teal),
                      ]),

                      const SizedBox(height: 24),

                      _buildSectionHeader('EMERGENCY CONTACTS'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.contact_phone, 'Linked Numbers', emergencyContactsText, iconColor: primary),
                      ]),

                      // Medical Report Section
                      if (hasReport) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('MEDICAL REPORT'),
                        _buildInfoCard([
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F9D58).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.description, size: 22, color: Color(0xFF0F9D58)),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Uploaded Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Inter')),
                                    SizedBox(height: 4),
                                    Text('Medical report on file', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Inter')),
                                  ],
                                ),
                              ),
                              const Icon(Icons.check_circle, size: 22, color: Color(0xFF0F9D58)),
                            ],
                          ),
                        ]),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8, fontFamily: 'Inter')),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {required Color iconColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey, fontFamily: 'Inter')),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.4, fontFamily: 'Inter')),
            ],
          ),
        ),
      ],
    );
  }
}
