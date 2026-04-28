import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResponderEmergencyDialer extends StatelessWidget {
  const ResponderEmergencyDialer({Key? key}) : super(key: key);

  // Stitch Design Tokens
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color primary = Color(0xFF0059BB);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color primaryFixedDim = Color(0xFFADC7FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color secondary = Color(0xFFB6152E);
  static const Color secondaryFixed = Color(0xFFFFDAD9);
  static const Color secondaryFixedDim = Color(0xFFFFB3B2);
  static const Color onSecondaryFixed = Color(0xFF410008);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color tertiaryContainer = Color(0xFF6D767E);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        children: [
          // Header
          const Text(
            'Quick Helplines',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.32,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap to initiate an immediate emergency call.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Dialer Grid — 2 columns
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: [
              _buildDialerCard(
                icon: Icons.local_police,
                label: 'Police',
                number: '100',
                numberColor: primary,
                iconBgColor: primaryFixed,
                iconColor: onPrimaryFixed,
                borderColor: outlineVariant,
                onTap: () => _launchDialer('100'),
              ),
              _buildDialerCard(
                icon: Icons.local_hospital,
                label: 'Ambulance',
                number: '108',
                numberColor: secondary,
                iconBgColor: secondaryFixed,
                iconColor: onSecondaryFixed,
                borderColor: secondaryFixedDim,
                onTap: () => _launchDialer('108'),
              ),
              _buildDialerCard(
                icon: Icons.local_fire_department,
                label: 'Fire',
                number: '101',
                numberColor: error,
                iconBgColor: errorContainer,
                iconColor: onErrorContainer,
                borderColor: outlineVariant,
                onTap: () => _launchDialer('101'),
              ),
              _buildDialerCard(
                icon: Icons.headset_mic,
                label: 'Dispatch',
                number: 'Command Center',
                numberColor: primary,
                iconBgColor: surfaceVariant,
                iconColor: onSurfaceVariant,
                borderColor: outlineVariant,
                isSmallNumber: true,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Dispatch Contacts
          const Text(
            'Recent Dispatch Contacts',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineVariant),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildContactItem(
                  icon: Icons.local_hospital,
                  iconBgColor: primaryFixedDim,
                  iconColor: onPrimaryFixed,
                  name: 'City General ER',
                  time: 'Today, 14:32',
                ),
                Divider(height: 1, color: outlineVariant.withValues(alpha: 0.3)),
                _buildContactItem(
                  icon: Icons.shield,
                  iconBgColor: secondaryFixedDim,
                  iconColor: onSecondaryFixed,
                  name: 'Precinct 44 Backup',
                  time: 'Yesterday, 09:15',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialerCard({
    required IconData icon,
    required String label,
    required String number,
    required Color numberColor,
    required Color iconBgColor,
    required Color iconColor,
    required Color borderColor,
    bool isSmallNumber = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              number,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isSmallNumber ? 14 : 24,
                fontWeight: isSmallNumber ? FontWeight.w600 : FontWeight.w600,
                color: numberColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String name,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: onSurface)),
                Text(time, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call, color: primary),
          ),
        ],
      ),
    );
  }

  void _launchDialer(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
