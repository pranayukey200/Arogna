import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyReportsHistoryScreen extends StatelessWidget {
  const MyReportsHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        title: const Text('Emergency History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_reports')
            .where('patientId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No reports found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildReportCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending_dispatch';
    final severity = data['severity'] ?? 'low';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final dateStr = timestamp != null ? DateFormat('dd MMM, hh:mm a').format(timestamp) : 'Pending...';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _showDetails(context, data),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSeverityColor(severity).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            status == 'resolved' ? Icons.check_circle_outline : Icons.emergency_outlined,
            color: _getSeverityColor(severity),
          ),
        ),
        title: Text(
          data['description'] ?? 'Emergency SOS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text('Severity: ${severity.toUpperCase()}', style: TextStyle(color: _getSeverityColor(severity), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: _buildStatusChip(status),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending_dispatch':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'dispatched':
        color = Colors.blue;
        label = 'Dispatched';
        break;
      case 'resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelled';
        break;
      default:
        color = Colors.blue;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final medicalHistory = data['medicalHistory'] as Map<String, dynamic>? ?? {};
    final responder = data['assignedResponderName'] ?? 'Searching...';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Incident Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', data['description'] ?? 'N/A'),
              _buildDetailRow('Responder', responder),
              const Divider(height: 24),
              const Text('MEDICAL DATA SENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildDetailRow('Blood Group', medicalHistory['bloodGroup'] ?? 'N/A'),
              _buildDetailRow('Allergies', medicalHistory['allergies'] ?? 'None'),
              _buildDetailRow('Conditions', medicalHistory['chronicConditions'] ?? 'None'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
