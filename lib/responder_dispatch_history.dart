import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'responder_active_dispatch.dart';

class ResponderDispatchHistory extends StatefulWidget {
  final String responderUsername;
  const ResponderDispatchHistory({Key? key, this.responderUsername = ''}) : super(key: key);

  @override
  State<ResponderDispatchHistory> createState() => _ResponderDispatchHistoryState();
}

class _ResponderDispatchHistoryState extends State<ResponderDispatchHistory> {
  String selectedFilter = 'All Alerts';

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHigh = Color(0xFFE5E8EE);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);

  final List<String> filterCategories = [
    'All Alerts',
    'Pending',
    'En Route',
    'Resolved'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alert History',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.32,
                        color: onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Past and pending dispatches.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: filterCategories.map((category) {
                bool isSelected = selectedFilter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = category;
                      });
                    },
                    child: _buildFilterChip(category, isSelected: isSelected),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // StreamBuilder for Alerts List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emergency_reports')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // CLIENT-SIDE FILTERING: Match against all possible responder identifiers
                final currentUser = FirebaseAuth.instance.currentUser;
                final String uid = currentUser?.uid ?? '';
                final String email = currentUser?.email?.toLowerCase().trim() ?? '';
                final String emailPrefix = email.isNotEmpty ? email.split('@')[0] : '';
                final String username = widget.responderUsername.toLowerCase().trim();

                final rawDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String assignedId = (data['assigned_responder_id'] ?? '').toString().toLowerCase().trim();
                  if (assignedId.isEmpty) return false;
                  return assignedId == username ||
                         assignedId == uid.toLowerCase().trim() ||
                         assignedId == email ||
                         (emailPrefix.isNotEmpty && assignedId == emailPrefix);
                }).toList();

                if (rawDocs.isEmpty) {
                  return _buildEmptyState();
                }

                // Helper to map raw Firebase status to our UI categories
                String getMappedStatus(String rawStatus) {
                  final s = rawStatus.toLowerCase();
                  if (s == 'pending' || s == 'dispatched') return 'Pending';
                  if (s == 'on_scene' || s == 'transporting') return 'En Route';
                  if (s == 'resolved') return 'Resolved';
                  return 'Pending'; // Default
                }

                // Helper to assign weight for sorting
                int getStatusWeight(String mappedStatus) {
                  if (mappedStatus == 'Pending') return 1;
                  if (mappedStatus == 'En Route') return 2;
                  return 3; // Resolved
                }

                // 1. Convert to List and Sort by Priority
                var sortedDocs = rawDocs.toList();
                sortedDocs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final statusA = getMappedStatus(dataA['status'] ?? 'pending');
                  final statusB = getMappedStatus(dataB['status'] ?? 'pending');
                  
                  int weightA = getStatusWeight(statusA);
                  int weightB = getStatusWeight(statusB);
                  
                  // Primary sort: Priority (Pending -> En Route -> Resolved)
                  if (weightA != weightB) {
                    return weightA.compareTo(weightB);
                  }
                  
                  // Secondary sort: Timestamp (newest first)
                  final timeA = dataA['timestamp'] as Timestamp?;
                  final timeB = dataB['timestamp'] as Timestamp?;
                  if (timeA != null && timeB != null) {
                    return timeB.compareTo(timeA);
                  }
                  return 0;
                });

                // 2. Filter based on selected chip
                var filteredDocs = sortedDocs.where((doc) {
                  if (selectedFilter == 'All Alerts') return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final mappedStatus = getMappedStatus(data['status'] ?? 'pending');
                  return mappedStatus == selectedFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final rawStatus = data['status'] ?? 'pending';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeString = timestamp != null
                        ? DateFormat('MMM d, HH:mm').format(timestamp.toDate())
                        : 'Unknown Time';

                    String displayStatus = getMappedStatus(rawStatus);
                    Color statusColor;
                    Color statusBgColor;
                    Color statusTextColor;
                    IconData statusIcon;
                    double opacity = 1.0;

                    if (displayStatus == 'Pending') {
                      displayStatus = 'Pending Dispatch';
                      statusColor = error;
                      statusBgColor = errorContainer;
                      statusTextColor = onErrorContainer;
                      statusIcon = Icons.warning;
                    } else if (displayStatus == 'En Route') {
                      statusColor = primary;
                      statusBgColor = primaryContainer;
                      statusTextColor = onPrimaryContainer;
                      statusIcon = Icons.directions_car;
                    } else {
                      statusColor = Colors.transparent;
                      statusBgColor = surfaceContainerHighest;
                      statusTextColor = onSurfaceVariant;
                      statusIcon = Icons.check_circle;
                      opacity = 0.8;
                    }

                    final patientName = data['patientName'] ?? 'Unknown Patient';
                    final patientAge = data['patientAge']?.toString() ?? '';
                    final patientGender = data['patientGender'] ?? '';
                    String patientDetails = patientName;
                    if (patientAge.isNotEmpty || patientGender.isNotEmpty) {
                      patientDetails += ' • ' + [if (patientGender.isNotEmpty) patientGender, if (patientAge.isNotEmpty) '$patientAge yrs'].join(', ');
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          // Note: ResponderActiveDispatch automatically fetches the current active report.
                          // Navigating here focuses on the active screen.
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ResponderActiveDispatch()));
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: _buildAlertCard(
                          status: displayStatus,
                          statusColor: statusColor,
                          statusBgColor: statusBgColor,
                          statusTextColor: statusTextColor,
                          statusIcon: statusIcon,
                          time: timeString,
                          title: data['description'] ?? 'SOS Triggered',
                          detail1Icon: Icons.location_on,
                          detail1Text: data['location_text'] ?? data['location'] ?? 'Unknown Location',
                          detail2Icon: Icons.person,
                          detail2Text: patientDetails,
                          opacity: opacity,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            selectedFilter == 'All Alerts' ? 'No alert history found' : 'No $selectedFilter alerts found',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, color: onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? primary : surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? onPrimary : onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String status,
    required Color statusColor,
    required Color statusBgColor,
    required Color statusTextColor,
    required IconData statusIcon,
    required String time,
    required String title,
    required IconData detail1Icon,
    required String detail1Text,
    IconData? detail2Icon,
    String? detail2Text,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineVariant),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (statusColor != Colors.transparent)
                Container(
                  width: 4,
                  color: statusColor,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
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
                      const SizedBox(height: 12),
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Details
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(detail1Icon, size: 18, color: onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  detail1Text,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    color: onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (detail2Icon != null && detail2Text != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(detail2Icon, size: 18, color: onSurfaceVariant),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    detail2Text,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color: onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
