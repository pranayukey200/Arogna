import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'login_premium_3d_experience.dart';

class CitizenOnboardingPermissionsScreen extends StatefulWidget {
  const CitizenOnboardingPermissionsScreen({Key? key}) : super(key: key);

  @override
  State<CitizenOnboardingPermissionsScreen> createState() => _CitizenOnboardingPermissionsScreenState();
}

class _CitizenOnboardingPermissionsScreenState extends State<CitizenOnboardingPermissionsScreen> with WidgetsBindingObserver {
  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color onBackground = Color(0xFF181C20);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color primary = Color(0xFF0059BB);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color outline = Color(0xFF717786);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);

  bool _locationGranted = false;
  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _smsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detects when the user comes back from Phone Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    // On web, all permissions are auto-granted (hardware APIs not applicable)
    if (kIsWeb) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPremium3DExperience()),
          (route) => false,
        );
      }
      return;
    }

    _locationGranted = await Permission.location.isGranted;
    _cameraGranted = await Permission.camera.isGranted;
    _micGranted = await Permission.microphone.isGranted;
    _smsGranted = await Permission.sms.isGranted;
    if (mounted) setState(() {});

    // If everything is granted, auto-navigate to login
    if (_locationGranted && _cameraGranted && _micGranted && _smsGranted) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPremium3DExperience()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      // Web doesn't need hardware permissions — navigate directly
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPremium3DExperience()),
          (route) => false,
        );
      }
      return;
    }

    await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.sms,
    ].request();

    await _checkAllPermissions();

    // If still not all granted after the request, force open settings
    if (!_locationGranted || !_cameraGranted || !_micGranted || !_smsGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All permissions are MANDATORY. Please enable them in settings.'),
            backgroundColor: Color(0xFFBA1A1A),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        openAppSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: surfaceVariant, width: 1)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: outline, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Arogna',
              style: TextStyle(
                color: primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration Placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBBbJLVuKbtVZTfEt3yUYSk9ira8qjWEp9wWb7TQv_pkMDk7lbpPJbcOY1fF-IdVUhHGTen6EnOUid05KIFyRrqK_A90rSZJwzFPRgA4iAD5wb9XwsITGNnpVFvdTPSD5_q9JK_ZedWUmDmYp9JgW3w2i_TePaed7WmFAbjoI-G-v5LTZ01jRDNNjMyMXmeVqj4V73ipra-wTrqpnbjxJ6t5aAbFzr3kTtmltoGntLUk54yqv9YXJ9chY8VXIwL96iyTDLsvhei6ps',
                            fit: BoxFit.cover,
                            opacity: const AlwaysStoppedAnimation(0.9),
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.medical_services_outlined, size: 64, color: outlineVariant)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                background.withOpacity(0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Header Text
                const Text(
                  'System Setup',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                    fontFamily: 'Inter',
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'To ensure full functionality and rapid response times, Arogna requires access to the following device features.',
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Permissions List
                _buildPermissionItem(
                  icon: Icons.location_on,
                  title: 'Location',
                  subtitle: 'Vital for emergency dispatch routing.',
                  value: _locationGranted,
                  onChanged: (val) => _requestPermissions(),
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  icon: Icons.photo_camera,
                  title: 'Camera',
                  subtitle: 'Upload visual incident reports.',
                  value: _cameraGranted,
                  onChanged: (val) => _requestPermissions(),
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  icon: Icons.mic,
                  title: 'Microphone',
                  subtitle: 'Required for voice dictation notes.',
                  value: _micGranted,
                  onChanged: (val) => _requestPermissions(),
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  icon: Icons.sms,
                  title: 'SMS',
                  subtitle: 'Receive critical alert broadcasts.',
                  value: _smsGranted,
                  onChanged: (val) => _requestPermissions(),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Grant Access',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () async {
                      // Hard block: no skipping. Open settings so they can grant.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All permissions are mandatory. Opening settings...'),
                          backgroundColor: Color(0xFFBA1A1A),
                        ),
                      );
                      await Future.delayed(const Duration(seconds: 1));
                      openAppSettings();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: outline,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Open App Settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: onPrimaryFixed, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: onPrimary,
            activeTrackColor: primary,
            inactiveThumbColor: outline,
            inactiveTrackColor: surfaceContainerHighest,
          ),
        ],
      ),
    );
  }
}
