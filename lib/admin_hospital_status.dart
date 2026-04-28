import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHospitalStatus extends StatefulWidget {
  const AdminHospitalStatus({Key? key}) : super(key: key);

  @override
  State<AdminHospitalStatus> createState() => _AdminHospitalStatusState();
}

class _AdminHospitalStatusState extends State<AdminHospitalStatus> {
  String _searchQuery = '';

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFBA1A1A);
  static const Color primary = Color(0xFF0059BB);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixedVariant = Color(0xFF004493);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color tertiary = Color(0xFF545D65);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header & Controls
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderTitle(),
                      _buildHeaderControls(),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 16),
                      _buildHeaderControls(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Bento Grid Layout for Hospitals
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 800) {
                  crossAxisCount = 2;
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading hospital status.'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hospitals found.'));
                    }

                    var filteredHospitals = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? data['hospitalName'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                    return Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      children: filteredHospitals.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final status = (data['status'] ?? 'OPERATIONAL').toString().toUpperCase();
                        final isCritical = status == 'AT CAPACITY' || status == 'CRITICAL';
                        
                        String lastUpdatedStr = 'Just now';
                        if (data['last_updated'] != null) {
                          final ts = data['last_updated'] as Timestamp;
                          final diff = DateTime.now().difference(ts.toDate()).inMinutes;
                          if (diff > 0) {
                            lastUpdatedStr = '$diff mins ago';
                          }
                        }
                        
                        final int icuAvailable = data['icu_available'] ?? 0;
                        final int icuTotal = data['icu_total'] ?? 0;
                        final int traumaAvailable = data['trauma_available'] ?? 0;
                        final int traumaTotal = data['trauma_total'] ?? 0;
                        final int wardAvailable = data['ward_available'] ?? 0;
                        final int wardTotal = data['ward_total'] ?? 0;

                        final bool traumaSpecialist = data['trauma_specialist'] ?? false;
                        final bool cardioSpecialist = data['cardio_specialist'] ?? false;
                        final bool orthoSpecialist = data['ortho_specialist'] ?? false;
                        final bool neuroSpecialist = data['neuro_specialist'] ?? false;
                        
                        final String facilityType = data['facility_type'] ?? 'Trauma Center (Level 1)';
                        final String loc = data['location'] ?? 'Unknown Location';

                        return SizedBox(
                          width: constraints.maxWidth >= 1200
                              ? (constraints.maxWidth - 48) / 3
                              : constraints.maxWidth >= 800
                                  ? (constraints.maxWidth - 24) / 2
                                  : double.infinity,
                          child: _buildHospitalCard(
                            context: context,
                            name: data['name'] ?? 'Unknown Hospital',
                            location: '$loc • $facilityType',
                            statusLabel: status,
                            statusColor: isCritical ? errorContainer : primaryFixed,
                            statusTextColor: isCritical ? error : onPrimaryFixedVariant,
                            statusIcon: isCritical ? Icons.warning_amber_rounded : null,
                            statusDotColor: isCritical ? null : primary,
                            icuBedsValue: icuAvailable.toString(),
                            icuBedsTotal: '/ $icuTotal',
                            icuBedsColor: icuAvailable <= 2 ? error : primary,
                            traumaBayValue: traumaAvailable.toString(),
                            traumaBayTotal: '/ $traumaTotal',
                            traumaBayColor: traumaAvailable <= 2 ? error : onSurface,
                            generalWardValue: wardAvailable.toString(),
                            generalWardTotal: '/ $wardTotal',
                            generalWardColor: wardAvailable <= 5 ? error : onSurface,
                            lastUpdated: lastUpdatedStr,
                            isCritical: isCritical,
                            traumaSpecialist: traumaSpecialist,
                            cardioSpecialist: cardioSpecialist,
                            orthoSpecialist: orthoSpecialist,
                            neuroSpecialist: neuroSpecialist,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Regional Hospital Capacity',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.01,
            color: onSurface,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Real-time bed availability and facility status.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderControls() {
    return Row(
      children: [
        // Search - now full width
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: outlineVariant),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 20, color: outline),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase().trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search facilities...',
                      hintStyle: TextStyle(color: outline, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 14, color: onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalCard({
    required BuildContext context,
    required String name,
    required String location,
    required String statusLabel,
    required Color statusColor,
    required Color statusTextColor,
    Color? statusDotColor,
    IconData? statusIcon,
    required String icuBedsValue,
    required String icuBedsTotal,
    required Color icuBedsColor,
    required String traumaBayValue,
    required String traumaBayTotal,
    required Color traumaBayColor,
    required String generalWardValue,
    required String generalWardTotal,
    required Color generalWardColor,
    required String lastUpdated,
    required bool isCritical,
    required bool traumaSpecialist,
    required bool cardioSpecialist,
    required bool orthoSpecialist,
    required bool neuroSpecialist,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCritical ? errorContainer : outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isCritical) Container(height: 4, width: double.infinity, color: error),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (statusDotColor != null) ...[
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusDotColor, shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                            ],
                            if (statusIcon != null) ...[
                              Icon(statusIcon, size: 14, color: statusTextColor),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              statusLabel.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: statusTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: surfaceVariant, height: 1),
                  const SizedBox(height: 16),
                  
                  // Stats
                  _buildStatRow('ICU BEDS', icuBedsValue, icuBedsTotal, icuBedsColor),
                  const SizedBox(height: 12),
                  _buildStatRow('TRAUMA BAY', traumaBayValue, traumaBayTotal, traumaBayColor),
                  const SizedBox(height: 12),
                  _buildStatRow('GENERAL WARD', generalWardValue, generalWardTotal, generalWardColor),
                  
                  Divider(color: Colors.grey.withValues(alpha: 0.3), thickness: 1, height: 24),
                  Text('AVAILABLE MEDICAL SPECIALISTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey[400])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      if (traumaSpecialist) _buildSpecialistTab('Trauma', Icons.healing),
                      if (cardioSpecialist) _buildSpecialistTab('Cardio', Icons.favorite),
                      if (orthoSpecialist) _buildSpecialistTab('Ortho', Icons.personal_injury),
                      if (neuroSpecialist) _buildSpecialistTab('Neuro', Icons.psychology),
                      if (!traumaSpecialist && !cardioSpecialist && !orthoSpecialist && !neuroSpecialist)
                        const Text('No specialists on call', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: outline, fontStyle: FontStyle.italic)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.update, size: 16, color: isCritical ? error : outline),
                          const SizedBox(width: 4),
                          Text(
                            'Last updated: $lastUpdated',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isCritical ? error : outline,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showDetailsDialog(context, name),
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: const [
                            Text(
                              'Details',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 18, color: primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, String total, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.05,
            color: onSurfaceVariant,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              total,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialistTab(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1967D2)),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: Color(0xFF1967D2),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, String hospitalName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            hospitalName,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600, color: onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on, size: 16, color: outline),
                  SizedBox(width: 8),
                  Expanded(child: Text('Wardha Road, Nagpur, Maharashtra', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Icon(Icons.phone, size: 16, color: outline),
                  SizedBox(width: 8),
                  Text('+91 98765 43210', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: onSurfaceVariant)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: outline)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Call Now'),
            ),
          ],
        );
      },
    );
  }
}
