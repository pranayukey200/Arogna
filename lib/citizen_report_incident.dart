import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'global_state.dart';

class CitizenReportIncident extends StatefulWidget {
  const CitizenReportIncident({Key? key}) : super(key: key);

  @override
  State<CitizenReportIncident> createState() => _CitizenReportIncidentState();
}

class _CitizenReportIncidentState extends State<CitizenReportIncident> {
  // Design System Colors from Stitch
  static const Color background = Color(0xFFF7F9FF);
  static const Color onBackground = Color(0xFF181C20);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F4F9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E8);
  static const Color surfaceContainer = Color(0xFFEBEEF3);
  static const Color surfaceVariant = Color(0xFFE0E3E8);
  static const Color surface = Color(0xFFF7F9FF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF0070EA);
  static const Color onPrimaryContainer = Color(0xFFFEFCFF);
  static const Color outline = Color(0xFF717786);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  String _severity = 'high'; // 'high', 'medium', 'low'
  XFile? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primary),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
                if (image != null) setState(() => _imageFile = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primary),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _imageFile = image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description of the incident.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? uploadedImageUrl;

      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('incident_reports/${DateTime.now().millisecondsSinceEpoch}.jpg');

        UploadTask uploadTask;
        
        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else {
          uploadTask = storageRef.putFile(File(_imageFile!.path));
        }

        final snapshot = await uploadTask.whenComplete(() => null);
        uploadedImageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('citizen_reports').add({
        'severity': _severity.toUpperCase(),
        'description': _descriptionController.text.trim(),
        'imageUrl': uploadedImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'userName': currentUser.name.isEmpty ? 'Pranay Ukey' : currentUser.name,
        'location': 'Current Location',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report Transmitted to Command Center'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _severity = 'high';
        _imageFile = null;
        _descriptionController.clear();
        _isSubmitting = false;
      });
    } catch (e) {
      debugPrint('Upload failed: $e');
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  const Text(
                    'Report Emergency',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please provide details about the incident to alert responders.',
                    style: TextStyle(
                      fontSize: 14,
                      color: onSurfaceVariant,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Canvas
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Severity Selector
                        const Text(
                          'SEVERITY LEVEL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildSeverityCard('high', Icons.emergency, 'High')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSeverityCard('medium', Icons.warning_amber_rounded, 'Medium')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSeverityCard('low', Icons.info_outline, 'Low')),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description Field
                        const Text(
                          'INCIDENT DESCRIPTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Describe what happened, injuries, or hazards...',
                            hintStyle: const TextStyle(color: outlineVariant, fontSize: 14),
                            filled: true,
                            fillColor: surfaceContainerLowest,
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
                              borderSide: const BorderSide(color: primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: const TextStyle(fontSize: 14, color: onSurface, fontFamily: 'Inter'),
                        ),
                        const SizedBox(height: 24),

                        // Attach Photo
                        const Text(
                          'ATTACH PHOTO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: _imageFile == null ? const EdgeInsets.all(32) : const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: outlineVariant,
                                width: 2,
                              ),
                            ),
                            child: _imageFile == null 
                              ? Column(
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined, color: outline, size: 32),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tap to upload or take a photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: onSurfaceVariant,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Max size 5MB',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: outline,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: kIsWeb 
                                        ? Image.network(_imageFile!.path, height: 150, fit: BoxFit.cover)
                                        : Image.file(File(_imageFile!.path), height: 150, fit: BoxFit.cover),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Photo attached - Tap to change', style: TextStyle(fontSize: 12, color: primary)),
                                  ],
                                ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Location Note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFADC7FF).withOpacity(0.2), // primary-fixed-dim/20
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.my_location, color: primary, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your current location will be attached to this report automatically.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF001A41), // on-primary-fixed
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Report',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityCard(String value, IconData icon, String label) {
    final bool isSelected = _severity == value;
    
    Color borderColor;
    Color bgColor;
    Color textColor;

    if (value == 'high') {
      borderColor = isSelected ? error : Colors.transparent;
      bgColor = isSelected ? errorContainer : errorContainer.withOpacity(0.3);
      textColor = error;
    } else if (value == 'medium') {
      borderColor = isSelected ? const Color(0xFFB77B00) : surfaceVariant;
      bgColor = isSelected ? const Color(0xFFFFFBEC) : surface;
      textColor = isSelected ? const Color(0xFFB77B00) : onSurfaceVariant;
    } else {
      borderColor = isSelected ? const Color(0xFF146C2E) : surfaceVariant;
      bgColor = isSelected ? const Color(0xFFE8F5E9) : surface;
      textColor = isSelected ? const Color(0xFF146C2E) : onSurfaceVariant;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _severity = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor,
                letterSpacing: 0.5,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
