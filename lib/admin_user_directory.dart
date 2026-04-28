import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AdminUserDirectory extends StatefulWidget {
  const AdminUserDirectory({Key? key}) : super(key: key);

  @override
  State<AdminUserDirectory> createState() => _AdminUserDirectoryState();
}

class _AdminUserDirectoryState extends State<AdminUserDirectory> {
  String _currentFilter = 'All';

  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color outline = Color(0xFF717786);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color tertiaryFixed = Color(0xFFDBE4ED);
  static const Color onTertiaryFixed = Color(0xFF141D23);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color secondary = Color(0xFFB6152E);
  static const Color secondaryContainer = Color(0xFFD93343);
  
  // Custom colors for this specific UI
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald700 = Color(0xFF047857);

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
                      _buildHeaderAction(context),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderTitle(),
                      const SizedBox(height: 16),
                      _buildHeaderAction(context),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // Data Table Card
            Container(
              decoration: BoxDecoration(
                color: surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: outlineVariant),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Toolbar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC), // surface-container-low/50 roughly
                      border: Border(bottom: BorderSide(color: surfaceVariant)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        List<Widget> children = [
                          // Search
                          SizedBox(
                            width: isMobile ? double.infinity : 320,
                            height: 40,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search by name, ID, or phone...',
                                hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: outline),
                                prefixIcon: const Icon(Icons.search, size: 20, color: outline),
                                filled: true,
                                fillColor: surfaceContainerLowest,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: outlineVariant),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: outlineVariant),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: primary),
                                ),
                              ),
                            ),
                          ),
                          if (!isMobile) const Spacer(),
                          if (isMobile) const SizedBox(height: 12),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                flex: 1, // Let it stretch fully on mobile, or just use 1 since it's the only item
                                child: Builder(
                                  builder: (btnContext) => _buildToolbarBtn(Icons.filter_list, 'Filters', onTap: () async {
                                    final RenderBox button = btnContext.findRenderObject() as RenderBox;
                                    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                                    final RelativeRect position = RelativeRect.fromRect(
                                      Rect.fromPoints(button.localToGlobal(Offset.zero, ancestor: overlay), button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay)),
                                      Offset.zero & overlay.size,
                                    );

                                    final String? selected = await showMenu<String>(
                                      context: context,
                                      position: position,
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      items: const [
                                        PopupMenuItem(value: 'All', child: Text('All Directory', style: TextStyle(fontFamily: 'Inter'))),
                                        PopupMenuItem(value: 'Responder', child: Text('Responders Only', style: TextStyle(fontFamily: 'Inter'))),
                                        PopupMenuItem(value: 'Hospital', child: Text('Hospitals Only', style: TextStyle(fontFamily: 'Inter'))),
                                      ],
                                    );

                                    if (selected != null) {
                                      setState(() { _currentFilter = selected; });
                                    }
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ];

                        return isMobile
                            ? Column(children: children)
                            : Row(children: children);
                      },
                    ),
                  ),

                  // Table Container (Scrollable horizontally) — Triple StreamBuilder Merge
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('citizens').snapshots(),
                    builder: (context, citizenSnap) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('responders').snapshots(),
                        builder: (context, responderSnap) {
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('hospitals').snapshots(),
                            builder: (context, hospitalSnap) {
                              // 1. Check waiting states
                              if (citizenSnap.connectionState == ConnectionState.waiting &&
                                  responderSnap.connectionState == ConnectionState.waiting &&
                                  hospitalSnap.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(48.0),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }

                              // 2. Combine all documents
                              List<Map<String, dynamic>> allUsers = [];

                              if (citizenSnap.hasData) {
                                allUsers.addAll(citizenSnap.data!.docs.map((d) =>
                                    {'type': 'Citizen', 'id': d.id, ...d.data() as Map<String, dynamic>}));
                              }
                              if (responderSnap.hasData) {
                                allUsers.addAll(responderSnap.data!.docs.map((d) =>
                                    {'type': 'Responder', 'id': d.id, ...d.data() as Map<String, dynamic>}));
                              }
                              if (hospitalSnap.hasData) {
                                allUsers.addAll(hospitalSnap.data!.docs.map((d) =>
                                    {'type': 'Hospital', 'id': d.id, ...d.data() as Map<String, dynamic>}));
                              }

                              if (allUsers.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(48.0),
                                  child: Center(child: Text('No directory entries found.', style: TextStyle(fontFamily: 'Inter', color: outline))),
                                );
                              }

                              List<Map<String, dynamic>> filteredUsers = allUsers.where((user) {
                                if (_currentFilter == 'All') return true;
                                return user['type'] == _currentFilter;
                              }).toList();

                              return Column(
                                children: [
                                  Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(minWidth: 800),
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(surfaceContainerLow),
                                          headingTextStyle: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.05,
                                            color: onSurfaceVariant,
                                          ),
                                          dataRowMinHeight: 72,
                                          dataRowMaxHeight: 72,
                                          dividerThickness: 1,
                                          columnSpacing: 24,
                                          columns: const [
                                            DataColumn(label: Text('CITIZEN PROFILE')),
                                            DataColumn(label: Text('CONTACT NUMBER')),
                                            DataColumn(label: Text('TYPE')),
                                            DataColumn(label: Text('SYSTEM STATUS')),
                                            DataColumn(label: Text('ACTIONS')),
                                          ],
                                          rows: filteredUsers.map((data) {
                                            final name = data['name'] ?? 'Unknown';
                                            String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'XX';
                                            if (name.trim().contains(' ')) {
                                              var parts = name.trim().split(' ');
                                              initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                                            }

                                            // Dynamic sub-labels based on user type
                                            String subtitle = '';
                                            String bloodOrType = '';

                                            if (data['type'] == 'Citizen') {
                                              subtitle = 'ID: ${data['uid'] ?? data['id']}';
                                              bloodOrType = data['bloodGroup'] ?? data['blood_type'] ?? 'O+';
                                            } else if (data['type'] == 'Responder') {
                                              subtitle = 'Responder • Plate: ${data['plate'] ?? 'N/A'}';
                                              bloodOrType = data['vehicleType'] ?? 'ALS';
                                            } else if (data['type'] == 'Hospital') {
                                              subtitle = 'Hospital • User: ${data['username'] ?? 'N/A'}';
                                              bloodOrType = 'Facility';
                                            }

                                            return _buildDataRow(
                                              initials: initials,
                                              avatarColor: primaryFixed,
                                              avatarTextColor: onPrimaryFixed,
                                              name: name,
                                              id: subtitle,
                                              phone: data['phone'] ?? data['contact1'] ?? 'N/A',
                                              bloodGroup: bloodOrType,
                                              status: data['status']?.toString().toLowerCase() ?? '',
                                              isCritical: false,
                                              userId: data['id'] ?? '',
                                              userType: data['type'] ?? '',
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Pagination Footer
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFAFCFF), // surface-container-low/30 roughly
                                      border: Border(top: BorderSide(color: surfaceVariant)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Showing ${filteredUsers.length} total entries',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        Row(
                                          children: [
                                            _buildPageBtn(Icons.chevron_left, null, disabled: true),
                                            const SizedBox(width: 4),
                                            _buildPageBtn(null, '1', isActive: true),
                                            const SizedBox(width: 4),
                                            _buildPageBtn(null, '2'),
                                            const SizedBox(width: 4),
                                            _buildPageBtn(null, '3'),
                                            const SizedBox(width: 4),
                                            const Text('...', style: TextStyle(color: outline)),
                                            const SizedBox(width: 4),
                                            _buildPageBtn(Icons.chevron_right, null),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
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
          'Directory',
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
          'Manage registered profiles and access critical medical summaries.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showResponderForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.local_shipping, size: 18),
            label: const Text('Register Responder', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showHospitalForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.local_hospital, size: 18),
            label: const Text('Register Hospital', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarBtn(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBtn(IconData? icon, String? text, {bool isActive = false, bool disabled = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? primary : outlineVariant),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, size: 18, color: disabled ? outline.withOpacity(0.3) : outline)
            : Text(
                text!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isActive ? onPrimary : onSurface,
                ),
              ),
      ),
    );
  }

  DataRow _buildDataRow({
    required String initials,
    required Color avatarColor,
    required Color avatarTextColor,
    required String name,
    required String id,
    required String phone,
    required String bloodGroup,
    required String status,
    required bool isCritical,
    required String userId,
    required String userType,
  }) {
    // Derive status display
    final bool isBusy = status == 'busy';
    final bool isActive = status == 'active';
    // inactive / null / anything else = inactive

    Color statusDotColor = outline; // grey default
    Color statusBgColor = surfaceContainer;
    Color statusBorderColor = outlineVariant;
    Color statusTextColor = onSurfaceVariant;
    String statusLabel = 'Inactive';

    if (isBusy) {
      statusDotColor = error;
      statusBgColor = errorContainer;
      statusBorderColor = error;
      statusTextColor = error;
      statusLabel = 'Busy';
    } else if (isActive) {
      statusDotColor = emerald500;
      statusBgColor = emerald50;
      statusBorderColor = emerald200;
      statusTextColor = emerald700;
      statusLabel = 'Active';
    }

    return DataRow(
      color: MaterialStateProperty.resolveWith((states) {
        if (isCritical) return errorContainer.withOpacity(0.2);
        if (states.contains(MaterialState.hovered)) return const Color(0xFFF7F9FF);
        return surfaceContainerLowest;
      }),
      cells: [
        // Profile Column
        DataCell(
          Container(
            decoration: isCritical ? const BoxDecoration(border: Border(left: BorderSide(color: error, width: 4))) : null,
            padding: isCritical ? const EdgeInsets.only(left: 8) : null,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: avatarTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      id,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: isCritical ? FontWeight.w500 : FontWeight.normal,
                        color: isCritical ? error : outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Contact Number Column
        DataCell(
          Text(
            phone,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: onSurfaceVariant,
            ),
          ),
        ),

        // Type Column (was Blood Group)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceContainer,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: outlineVariant),
            ),
            child: Text(
              bloodGroup,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: onSurfaceVariant,
              ),
            ),
          ),
        ),

        // System Status Column — dynamic from Firestore
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusBorderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: statusTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Actions Column — PopupMenuButton with hard delete
        DataCell(
          isCritical
              ? ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: error,
                    foregroundColor: onError,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('View Case', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500)),
                )
              : PopupMenuButton<String>(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  icon: const Icon(Icons.more_vert, size: 20, color: outline),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onSelected: (String value) async {
                    if (value == 'Remove') {
                      String collectionName = userType == 'Responder'
                          ? 'responders'
                          : (userType == 'Hospital' ? 'hospitals' : 'citizens');
                      await FirebaseFirestore.instance.collection(collectionName).doc(userId).delete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name permanently removed.')));
                      }
                    } else if (value == 'Report') {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report flagged for review.')));
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'Report',
                      child: Text('Report', style: TextStyle(fontFamily: 'Inter')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'Remove',
                      child: Text('Remove', style: TextStyle(fontFamily: 'Inter', color: Colors.red)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showResponderForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String phone = '';
    String plate = '';
    String vehicleType = '';
    String username = '';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: surfaceContainerLowest,
          title: const Text('Register Responder', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => name = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => phone = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Ambulance Plate No.', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => plate = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Vehicle Type (ALS/BLS)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => vehicleType = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Login ID (Username)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => username = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => password = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: outline)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  FirebaseFirestore.instance.collection('responders').add({
                    'name': name,
                    'phone': phone,
                    'plate': plate,
                    'vehicleType': vehicleType,
                    'username': username,
                    'password': password,
                    'status': 'active',
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Responder registered successfully!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: onPrimary),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showHospitalForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String contact1 = '';
    String contact2 = '';
    String license = '';
    String address = '';
    String username = '';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: surfaceContainerLowest,
          title: const Text('Register Hospital', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Hospital Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => name = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contact Number 1', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => contact1 = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Contact Number 2', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => contact2 = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'License No.', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => license = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => address = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Login ID (Username)', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => username = val!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                    obscureText: true,
                    validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    onSaved: (val) => password = val!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: outline)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  FirebaseFirestore.instance.collection('hospitals').add({
                    'name': name,
                    'contact1': contact1,
                    'contact2': contact2,
                    'license': license,
                    'address': address,
                    'username': username,
                    'password': password,
                    'status': 'OPERATIONAL',
                    'ward_available': 0,
                    'ward_total': 0,
                    'icu_available': 0,
                    'icu_total': 0,
                    'trauma_available': 0,
                    'trauma_total': 0,
                    'trauma_specialist': false,
                    'cardio_specialist': false,
                    'ortho_specialist': false,
                    'neuro_specialist': false,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hospital registered successfully!')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: onPrimary),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
