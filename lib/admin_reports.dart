import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({Key? key}) : super(key: key);

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  bool _sortNewest = true;

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  static const Color error = Color(0xFFBA1A1A);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color surfaceTint = Color(0xFF005BC0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderTitle(),
                      _buildHeaderActions(),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 16),
                      _buildHeaderActions(),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 32),

            // Reports List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('citizen_reports').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Something went wrong'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // In-Memory Filtering & Sorting — show all non-rejected reports
                final allDocs = snapshot.data?.docs ?? [];
                final activeDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  return data['status'] != 'rejected';
                }).toList();
                
                activeDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>? ?? {};
                  final bData = b.data() as Map<String, dynamic>? ?? {};
                  final aTime = aData['timestamp'] as Timestamp?;
                  final bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return _sortNewest ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
                });

                if (activeDocs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(child: Text('No active reports.', style: TextStyle(color: onSurfaceVariant))),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeDocs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = activeDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final Map<String, dynamic> reportData = doc.data() as Map<String, dynamic>;
                    final String rawPriority = (reportData['priority'] ?? reportData['severity'] ?? 'Routine').toString().toUpperCase();

                    Color badgeColor;
                    Color textColor;
                    String displayText = rawPriority;
                    IconData pIcon = Icons.info_outline;

                    if (rawPriority.contains('HIGH') || rawPriority.contains('CRITICAL')) {
                      badgeColor = Colors.red.shade50;
                      textColor = Colors.red;
                      pIcon = Icons.warning_amber_rounded;
                    } else if (rawPriority.contains('MEDIUM')) {
                      badgeColor = Colors.orange.shade50;
                      textColor = Colors.orange.shade800;
                    } else if (rawPriority.contains('LOW')) {
                      badgeColor = Colors.green.shade50;
                      textColor = Colors.green.shade800;
                    } else {
                      badgeColor = Colors.blue.shade50;
                      textColor = Colors.blue.shade800;
                      displayText = 'ROUTINE';
                    }
                    
                    final timestamp = data['timestamp'] as Timestamp?;
                    String timeStr = 'Just now';
                    if (timestamp != null) {
                      final diff = DateTime.now().difference(timestamp.toDate()).inMinutes;
                      if (diff > 0) timeStr = '$diff mins ago';
                    }

                    // ✅ Extract image URL from multiple possible field names
                    final String? uploadedImageUrl = (data['imageUrl'] ?? data['photoUrl'] ?? data['image_url'])?.toString();
                    final bool hasUploadedImage = uploadedImageUrl != null && uploadedImageUrl.isNotEmpty;

                    final bool isApproved = data['status'] == 'approved';

                    return _buildReportCard(
                      isApproved: isApproved,
                      priorityLabel: displayText,
                      priorityColor: badgeColor,
                      priorityTextColor: textColor,
                      priorityIcon: pIcon,
                      reportId: doc.id.substring(0, min(8, doc.id.length)).toUpperCase(),
                      timeAgo: timeStr,
                      title: 'Citizen Incident Report',
                      reporter: data['userName'] ?? 'Unknown Citizen',
                      location: data['location'] ?? 'Location unknown',
                      description: '"${data['description'] ?? 'No description'}"',
                      hasImage: hasUploadedImage,
                      imageUrl: hasUploadedImage ? uploadedImageUrl : null,
                      onApprove: () async {
                        await doc.reference.update({'status': 'approved'});
                      },
                      onReject: () async {
                        await doc.reference.update({'status': 'rejected'});
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 32),

            // Load More
            Center(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.expand_more, size: 18, color: onSurface),
                label: const Text(
                  'Load More Reports',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
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
          'Citizen Reports',
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
          'Review and triage incoming reports from the community.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _buildActionButton(
          Icons.sort, 
          _sortNewest ? 'Sort by: Newest' : 'Sort by: Oldest',
          onTap: () => setState(() => _sortNewest = !_sortNewest),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E8EE), // surface-container-high
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required bool isApproved,
    required String priorityLabel,
    required Color priorityColor,
    required Color priorityTextColor,
    required IconData priorityIcon,
    required String reportId,
    required String timeAgo,
    required String title,
    required String reporter,
    required String location,
    required String description,
    required bool hasImage,
    String? imageUrl,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 600;
          
          List<Widget> children = [
            // Meta Info Column
            SizedBox(
              width: isDesktop ? 192 : double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 14, color: priorityTextColor),
                        const SizedBox(width: 4),
                        Text(
                          priorityLabel.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: priorityTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reportId,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: outline),
                      const SizedBox(width: 4),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (!isDesktop) const SizedBox(height: 16),
                ],
              ),
            ),

            // Core Detail Column
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: Container(
                padding: isDesktop ? const EdgeInsets.only(left: 24) : const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: isDesktop
                      ? const Border(left: BorderSide(color: outlineVariant))
                      : const Border(top: BorderSide(color: outlineVariant)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 14, color: onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              reporter,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 14, color: onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: outlineVariant),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: onSurface,
                        ),
                      ),
                    ),
                    if (hasImage && imageUrl != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'ATTACHED EVIDENCE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, color: Colors.grey, size: 32),
                                  SizedBox(height: 4),
                                  Text('Image failed to load', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (!isDesktop) const SizedBox(height: 16),

            // Action Column
            SizedBox(
              width: isDesktop ? 128 : double.infinity,
              child: Container(
                padding: isDesktop ? const EdgeInsets.only(left: 16) : const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: isDesktop ? null : const Border(top: BorderSide(color: outlineVariant)),
                ),
                child: isDesktop
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildApproveBtn(isApproved: isApproved, fullWidth: true, onPressed: isApproved ? null : onApprove),
                          const SizedBox(height: 12),
                          _buildRejectBtn(fullWidth: true, onPressed: onReject),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildApproveBtn(isApproved: isApproved, fullWidth: true, onPressed: isApproved ? null : onApprove)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRejectBtn(fullWidth: true, onPressed: onReject)),
                        ],
                      ),
              ),
            ),
          ];

          return isDesktop
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: children)
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
        },
      ),
    );
  }

  Widget _buildApproveBtn({required bool fullWidth, required bool isApproved, VoidCallback? onPressed}) {
    Widget btn = isApproved
        ? OutlinedButton.icon(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              disabledBackgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.check_circle, size: 14, color: Colors.grey),
            label: const Text(
              'Approved',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.check_circle, size: 14),
            label: const Text(
              'Approve',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
            ),
          );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  Widget _buildRejectBtn({required bool fullWidth, VoidCallback? onPressed}) {
    Widget btn = OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: error,
        side: const BorderSide(color: error),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: const Icon(Icons.cancel, size: 14),
      label: const Text(
        'Reject',
        style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
