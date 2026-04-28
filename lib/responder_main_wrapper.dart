import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_premium_3d_experience.dart';
import 'responder_active_dispatch.dart';
import 'responder_dispatch_history.dart';
import 'responder_nearby_hospitals.dart';
import 'responder_emergency_dialer.dart';
import 'responder_profile.dart';

class ResponderMainWrapper extends StatefulWidget {
  final String responderUsername;
  const ResponderMainWrapper({Key? key, this.responderUsername = ''}) : super(key: key);

  @override
  State<ResponderMainWrapper> createState() => _ResponderMainWrapperState();
}

class _ResponderMainWrapperState extends State<ResponderMainWrapper> {
  int _selectedIndex = 0;

  // Stitch Design Tokens
  static const Color primary = Color(0xFF0059BB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFF717786);
  static const Color secondary = Color(0xFFB6152E);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 1,
        shadowColor: const Color(0x0D000000),
        title: Row(
          children: [
            const Icon(Icons.medical_services, color: primary),
            const SizedBox(width: 8),
            const Text(
              'Arogna',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: Color(0xFF1D4ED8), // blue-700
              ),
            ),
          ],
        ),
        actions: [
          // Active status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
          // Online pill
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: surfaceContainerHigh,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Online',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Color(0xFF181C20),
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Color(0xFF181C20)),
            color: Colors.white,
            elevation: 8,
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ResponderProfileScreen()));
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
        index: _selectedIndex,
        children: [
          ResponderActiveDispatch(responderUsername: widget.responderUsername),
          ResponderDispatchHistory(responderUsername: widget.responderUsername),
          const ResponderNearbyHospitals(),
          const ResponderEmergencyDialer(),
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
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications_active),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Hospitals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_outlined),
            activeIcon: Icon(Icons.phone),
            label: 'Dialer',
          ),
        ],
      ),
    );
  }
}
