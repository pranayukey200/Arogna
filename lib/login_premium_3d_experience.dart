import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seed_auth.dart';
import 'citizen_main_emergency_map.dart';
import 'hospital_incoming_patients.dart';
import 'hospital_main_wrapper.dart';
import 'admin_sos_alerts.dart';
import 'responder_main_wrapper.dart';
import 'registration_profile_page.dart';

class LoginPremium3DExperience extends StatefulWidget {
  const LoginPremium3DExperience({Key? key}) : super(key: key);

  @override
  State<LoginPremium3DExperience> createState() => _LoginPremium3DExperienceState();
}

class _LoginPremium3DExperienceState extends State<LoginPremium3DExperience> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Animated Arogna Logo
                GestureDetector(
                  onDoubleTap: () => seedDatabase(context),
                  child: _buildAnimatedLogo(),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AROGNA',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 6, color: Color(0xFF0D47A1), shadows: [Shadow(color: Color(0x220D47A1), blurRadius: 40)]),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rapid Crisis Response',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 4, color: Color(0xFF414754)),
                ),
                const SizedBox(height: 28),
              // Login Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: const Color(0xFFE0E3E8)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    // Email Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF181C20))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Color(0xFF181C20), fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: const TextStyle(color: Color(0xFFC1C6D7)),
                            prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF717786)),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFC1C6D7))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFC1C6D7))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFF0D47A1))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Password Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF181C20))),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Color(0xFF181C20), fontFamily: 'Inter'),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: const TextStyle(color: Color(0xFFC1C6D7)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF717786)),
                            filled: true,
                            fillColor: const Color(0xFFF7F9FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFC1C6D7))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFC1C6D7))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFF0D47A1))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Primary Action
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });

                          String inputId = _emailController.text.trim();
                          String password = _passwordController.text.trim();

                          debugPrint('--- LOGIN ATTEMPT ---');
                          debugPrint('Input ID: "$inputId"');
                          debugPrint('Input Pass: "$password"');

                          try {
                            // STEP 1: Check 'responders' collection first
                            debugPrint('STEP 1: Querying responders collection...');
                            var responderQuery = await FirebaseFirestore.instance
                                .collection('responders')
                                .where('username', isEqualTo: inputId)
                                .where('password', isEqualTo: password)
                                .get();

                            debugPrint('Responders found: ${responderQuery.docs.length}');
                            if (responderQuery.docs.isNotEmpty) {
                              final matchedUsername = responderQuery.docs.first.data()['username']?.toString() ?? inputId;
                              debugPrint('MATCH! Routing to ResponderMainWrapper with username=$matchedUsername');
                              if (!mounted) return;
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResponderMainWrapper(responderUsername: matchedUsername)));
                              return;
                            }

                            // Also dump all responder docs for field-name verification
                            debugPrint('STEP 1 FAILED. Dumping ALL responder docs for field check...');
                            var allResponders = await FirebaseFirestore.instance.collection('responders').get();
                            debugPrint('Total responder docs in collection: ${allResponders.docs.length}');
                            for (var doc in allResponders.docs) {
                              final d = doc.data();
                              debugPrint('  Doc ${doc.id}: username="${d['username']}", password="${d['password']}", name="${d['name']}"');
                            }

                            // STEP 2: Check 'hospitals' collection second
                            debugPrint('STEP 2: Querying hospitals collection...');
                            var hospitalQuery = await FirebaseFirestore.instance
                                .collection('hospitals')
                                .where('username', isEqualTo: inputId)
                                .where('password', isEqualTo: password)
                                .get();

                            debugPrint('Hospitals found: ${hospitalQuery.docs.length}');
                            if (hospitalQuery.docs.isNotEmpty) {
                              debugPrint('MATCH! Routing to HospitalMainWrapper with id=${hospitalQuery.docs.first.id}');
                              if (!mounted) return;
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HospitalMainWrapper(hospitalId: hospitalQuery.docs.first.id)));
                              return;
                            }

                            // Also dump all hospital docs for field-name verification
                            debugPrint('STEP 2 FAILED. Dumping ALL hospital docs for field check...');
                            var allHospitals = await FirebaseFirestore.instance.collection('hospitals').get();
                            debugPrint('Total hospital docs in collection: ${allHospitals.docs.length}');
                            for (var doc in allHospitals.docs) {
                              final d = doc.data();
                              debugPrint('  Doc ${doc.id}: username="${d['username']}", password="${d['password']}", name="${d['name']}"');
                            }

                            // STEP 3: Fallback to standard Firebase Auth (for Citizens/Admins)
                            debugPrint('STEP 3: Falling back to Firebase Auth with email="$inputId"...');
                            UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: inputId,
                              password: password,
                            );

                            debugPrint('Firebase Auth SUCCESS. UID: ${userCredential.user!.uid}');

                            // Fetch role from Firestore
                            DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).get();
                            debugPrint('User doc exists: ${userDoc.exists}');

                            if (userDoc.exists) {
                              String role = userDoc.get('role');
                              debugPrint('User role: "$role"');
                              if (!mounted) return;
                              if (role == 'admin') {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminSOSAlerts()));
                              } else if (role == 'responder') {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResponderMainWrapper(responderUsername: inputId.split('@')[0])));
                              } else if (role == 'hospital') {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HospitalMainWrapper(hospitalId: userCredential.user!.uid)));
                              } else {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CitizenMainEmergencyMap()));
                              }
                            } else {
                              debugPrint('No user doc found. Routing to CitizenMainEmergencyMap as default.');
                              if (!mounted) return;
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CitizenMainEmergencyMap()));
                            }
                          } catch (e) {
                            debugPrint('LOGIN ERROR: $e');
                            setState(() {
                              _errorMessage = "The supplied auth credential is incorrect, malformed or has expired.";
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 4,
                          shadowColor: const Color(0x800D47A1),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.05 * 12,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                      ),
                    ),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF717786))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // OR divider
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFE0E3E8))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('OR', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF717786))),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE0E3E8))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // SIGN UP button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationProfilePage())),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF181C20),
                          side: const BorderSide(color: Color(0xFFC1C6D7)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Text('SIGN UP', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // GUEST LOGIN button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CitizenMainEmergencyMap())),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF181C20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 2,
                          shadowColor: const Color(0x33000000),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('GUEST LOGIN', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HospitalIncomingPatients())),
                    child: const Text('Staff Login', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF717786))),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double scale = 1.0 + (_pulseController.value * 0.04);
        final double glowOpacity = 0.15 + (_pulseController.value * 0.15);
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0D47A1).withOpacity(glowOpacity), blurRadius: 40, spreadRadius: 4),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFF0D47A1), width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circle background
                  Container(width: 88, height: 88, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                  // Medical Cross — Stitch Blue
                  Container(width: 78, height: 22, decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(4))),
                  Container(width: 22, height: 78, decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(4))),
                  // ECG Pulse Line
                  CustomPaint(size: const Size(130, 130), painter: _ECGPulsePainter(progress: _pulseController.value)),
                  // Pulsing red dot
                  Positioned(
                    top: 18,
                    right: 24,
                    child: Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.4),
                      child: Opacity(
                        opacity: 1.0 - (_pulseController.value * 0.3),
                        child: Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF4444))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ECGPulsePainter extends CustomPainter {
  final double progress;
  _ECGPulsePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3ECFCF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    path.moveTo(cx - 55, cy);
    path.lineTo(cx - 35, cy);
    path.lineTo(cx - 25, cy);
    path.lineTo(cx - 15, cy - 23);
    path.lineTo(cx - 7, cy + 23);
    path.lineTo(cx + 2, cy - 15);
    path.lineTo(cx + 9, cy);
    path.lineTo(cx + 25, cy);
    path.lineTo(cx + 55, cy);

    // Animate dash
    final totalLength = path.computeMetrics().fold<double>(0, (sum, m) => sum + m.length);
    final visibleLength = totalLength * (0.6 + progress * 0.4);
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, visibleLength.clamp(0, metric.length)), paint);
    }
  }

  @override
  bool shouldRepaint(_ECGPulsePainter old) => old.progress != progress;
}
