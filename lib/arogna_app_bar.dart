import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_provider.dart';
import 'login_premium_3d_experience.dart';
import 'global_state.dart';
import 'my_reports_screen.dart';
import 'citizen_profile.dart';

class ArognaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String role; // 'citizen', 'responder', 'hospital', 'admin'
  final List<Widget>? extraActions;

  const ArognaAppBar({
    Key? key,
    required this.title,
    required this.role,
    this.extraActions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
      elevation: 0,
      centerTitle: false,
      actions: [
        if (extraActions != null) ...extraActions!,
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, value),
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontSize: 12),
            ),
          ),
          itemBuilder: (context) => [
            if (role == 'citizen') ...[
              const PopupMenuItem(value: 'profile', child: _MenuRow(Icons.person_outline, 'Profile')),
              const PopupMenuItem(value: 'reports', child: _MenuRow(Icons.history, 'My Reports')),
            ],
            if (role == 'responder') ...[
              const PopupMenuItem(value: 'profile', child: _MenuRow(Icons.badge_outlined, 'Service ID')),
            ],
            if (role == 'admin') ...[
              const PopupMenuItem(value: 'complaints', child: _MenuRow(Icons.feedback_outlined, 'Complaints')),
            ],
            const PopupMenuItem(value: 'settings', child: _MenuRow(Icons.settings_outlined, 'Settings')),
            PopupMenuItem(
              value: 'theme',
              child: _MenuRow(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                isDark ? 'Light Mode' : 'Dark Mode',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'logout', child: _MenuRow(Icons.logout, 'Logout', color: Colors.red)),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CitizenProfileScreen()));
        break;
      case 'theme':
        themeNotifier.toggleTheme();
        break;
      case 'logout':
        _logout(context);
        break;
      case 'reports':
        _showMyReports(context);
        break;
      case 'settings':
        _showSettings(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action: $value')));
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPremium3DExperience()));
    }
  }

  void _showMyReports(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const MyReportsHistoryScreen()));
  }

  void _showSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurface),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color ?? Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _location = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive real-time hazard alerts'),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          SwitchListTile(
            title: const Text('Live Location Sharing'),
            subtitle: const Text('Allow responders to find you faster'),
            value: _location,
            onChanged: (val) => setState(() => _location = val),
          ),
        ],
      ),
    );
  }
}
