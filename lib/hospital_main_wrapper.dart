import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_premium_3d_experience.dart';
import 'hospital_incoming_patients.dart';
import 'hospital_resource_status.dart';
import 'hospital_profile.dart';

class HospitalMainWrapper extends StatefulWidget {
  final String hospitalId;
  const HospitalMainWrapper({Key? key, required this.hospitalId}) : super(key: key);

  @override
  State<HospitalMainWrapper> createState() => _HospitalMainWrapperState();
}

class _HospitalMainWrapperState extends State<HospitalMainWrapper> {
  int _currentIndex = 0;

  // Stitch colors
  static const Color primary = Color(0xFF0059BB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  late final List<Widget> _pages = [
    const HospitalIncomingPatients(),
    HospitalResourceStatus(hospitalId: widget.hospitalId),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_hospital, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Arogna',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181C20),
                letterSpacing: -0.02,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Color(0xFF181C20)),
            color: Colors.white,
            elevation: 8,
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HospitalProfileScreen()));
              } else if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPremium3DExperience()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 16)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                enabled: false, 
                height: 12, 
                padding: EdgeInsets.zero, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'history',
                child: Center(
                  child: Text('Record History', style: TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 16)),
                ),
              ),
              PopupMenuItem<String>(
                enabled: false, 
                height: 12, 
                padding: EdgeInsets.zero, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(fontFamily: 'Inter', color: Colors.red, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emergency_share_outlined),
            selectedIcon: Icon(Icons.emergency_share),
            label: 'Incoming',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Resources',
          ),
        ],
      ),
    );
  }
}
