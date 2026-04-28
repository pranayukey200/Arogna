import re

# 1. hospital_incoming_patients.dart
path = r'd:\Hackathon_projects\arogna\lib\hospital_incoming_patients.dart'
with open(path, 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';"
)

grid_pattern = re.compile(r'return GridView\.count\(.*?\n\s+children: \[.*?_buildPatientCard\(.*?\),\n\s+\],\n\s+\);', re.DOTALL)

stream_builder = '''return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('sos_events').where('status', isEqualTo: 'Dispatched').snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No Incoming Patients.'));
                        }
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final docId = docs[index].id;
                            final data = docs[index].data() as Map<String, dynamic>;
                            final name = data['patientName'] ?? 'Unknown';
                            
                            return _buildPatientCard(
                              status: 'Confirmed',
                              statusColor: const Color(0xFF0059BB),
                              statusBgColor: const Color(0xFFD8E2FF),
                              name: name,
                              etaTime: '5 mins',
                              etaLabel: 'ETA',
                              etaColor: const Color(0xFF0059BB),
                              assignedBedIcon: Icons.bed,
                              assignedBedLabel: 'Assigned Bed',
                              assignedBedValue: 'ER Bay 3',
                              responderIcon: Icons.flight_takeoff,
                              responderValue: data['responderAssigned'] ?? 'Unit',
                              buttons: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('sos_events').doc(docId).update({'status': 'Arrived'});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0059BB),
                                      foregroundColor: const Color(0xFFFFFFFF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text('Patient Arrived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );'''

code = grid_pattern.sub(stream_builder, code)
with open(path, 'w', encoding='utf-8') as f:
    f.write(code)

# 2. responder_active_dispatch.dart
path2 = r'd:\Hackathon_projects\arogna\lib\responder_active_dispatch.dart'
with open(path2, 'r', encoding='utf-8') as f:
    code2 = f.read()

code2 = code2.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';"
)

body_pattern = re.compile(r'body: Column\(.*?bottomNavigationBar:', re.DOTALL)

stream_body = '''body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sos_events').where('status', isEqualTo: 'Dispatched').limit(1).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No Active Dispatches. You are on standby.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 18, color: Color(0xFF414754)),
              ),
            );
          }
          
          final docId = docs.first.id;
          final data = docs.first.data() as Map<String, dynamic>;
          final name = data['patientName'] ?? 'Unknown';
          final description = data['description'] ?? 'No description';

          return Column(
            children: [
              // Red Alert Banner
              Container(
                color: const Color(0xFFB6152E), // secondary
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Active Dispatch: $name',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Immediate Response Required',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Map Area & Floating Card
              Expanded(
                child: Stack(
                  children: [
                    // Simulated Map Background
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFE0E3E8), // surface-variant
                      child: const Center(
                        child: Text(
                          'Routing Map Placeholder',
                          style: TextStyle(color: Color(0xFF717786)),
                        ),
                      ),
                    ),
                    
                    // Destination Marker
                    Positioned(
                      top: 50,
                      right: 80,
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB6152E),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 8,
                            height: 8,
                            color: const Color(0xFFB6152E),
                          )
                        ],
                      ),
                    ),
                    
                    // Responder Marker
                    Positioned(
                      bottom: 250,
                      left: 80,
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0059BB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: const Text('Unit 4', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                    
                    // Floating Bottom Card
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 4))],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        description,
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF414754)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF7F9FF),
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                                  ),
                                  child: Column(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('sos_events').doc(docId).update({'status': 'Resolved'});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0059BB),
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(double.infinity, 48),
                                        ),
                                        child: const Text('Resolved'),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar:'''

code2 = body_pattern.sub(stream_body, code2)
with open(path2, 'w', encoding='utf-8') as f:
    f.write(code2)
