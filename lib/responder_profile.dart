import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResponderProfileScreen extends StatelessWidget {
  const ResponderProfileScreen({Key? key}) : super(key: key);

  Future<DocumentSnapshot?> _getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try responders collection first, then users
      var doc = await FirebaseFirestore.instance.collection('responders').doc(user.uid).get();
      if (doc.exists) return doc;
      doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) return doc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text('Responder Profile', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontFamily: 'Inter')),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)));
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_off_outlined, size: 64, color: Color(0xFFC1C6D7)),
                  SizedBox(height: 16),
                  Text('Profile not found.', style: TextStyle(color: Color(0xFF717786), fontFamily: 'Inter', fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Contact admin to register your profile.', style: TextStyle(color: Color(0xFFC1C6D7), fontFamily: 'Inter', fontSize: 13)),
                ],
              ),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? data['fullName'] ?? 'Responder';
          final String agency = data['agency'] ?? 'Arogna Fleet';
          final String plate = data['plate'] ?? data['vehiclePlate'] ?? 'Unassigned';
          final String contact = data['contact'] ?? data['phone'] ?? data['contactNumber'] ?? 'Not provided';
          final String email = data['email'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Hero Banner & Avatar Overlap (Stitch Blue)
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D47A1),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFFF5F5F7), shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'R',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontFamily: 'Inter'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Inter')),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(email, style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Inter')),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ACTIVE DISPATCH UNIT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), letterSpacing: 1.2, fontFamily: 'Inter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Content Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSectionHeader('OPERATIONAL DETAILS'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.badge, 'Responder ID / Agency', agency, iconColor: const Color(0xFF0D47A1)),
                        const Divider(height: 32, indent: 48),
                        _buildInfoRow(Icons.directions_car, 'Vehicle Plate', plate, iconColor: Colors.orange),
                        const Divider(height: 32, indent: 48),
                        _buildInfoRow(Icons.phone_android, 'Dispatch Contact', contact, iconColor: Colors.teal),
                      ]),
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
