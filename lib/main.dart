import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'login_premium_3d_experience.dart';
import 'citizen_onboarding_permissions.dart';
import 'splash_screen.dart';
import 'theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ArognaApp());
}

class ArognaApp extends StatelessWidget {
  const ArognaApp({super.key});

  Future<bool> _checkPermissions() async {
    if (kIsWeb) return true;

    bool loc = await Permission.location.isGranted;
    bool cam = await Permission.camera.isGranted;
    bool mic = await Permission.microphone.isGranted;
    bool sms = await Permission.sms.isGranted;
    
    return loc && cam && mic && sms;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Arogna',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB71C1C),
              brightness: Brightness.light,
            ),
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB71C1C),
              brightness: Brightness.dark,
            ),
            fontFamily: 'Inter',
          ),
          home: FutureBuilder<bool>(
            future: _checkPermissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0d1b3e),
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF3ECFCF))),
                );
              }
              final Widget destination = snapshot.data == true
                  ? const LoginPremium3DExperience()
                  : const CitizenOnboardingPermissionsScreen();
              return SplashScreen(nextScreen: destination);
            },
          ),
        );
      },
    );
  }
}