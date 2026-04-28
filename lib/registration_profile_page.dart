import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'global_state.dart';
import 'citizen_main_emergency_map.dart';

class RegistrationProfilePage extends StatefulWidget {
  const RegistrationProfilePage({Key? key}) : super(key: key);

  @override
  State<RegistrationProfilePage> createState() => _RegistrationProfilePageState();
}

class _RegistrationProfilePageState extends State<RegistrationProfilePage> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _emc1Controller = TextEditingController();
  final TextEditingController _emc2Controller = TextEditingController();
  final TextEditingController _emc3Controller = TextEditingController();

  String _selectedBloodGroup = 'O+';
  bool _isLoading = false;
  XFile? _medicalReportFile;
  Uint8List? _medicalReportBytes;

  // Design System Colors
  static const Color background = Color(0xFFF7F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0059BB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF181C20);
  static const Color onSurfaceVariant = Color(0xFF414754);
  static const Color outlineVariant = Color(0xFFC1C6D7);
  static const Color primaryFixed = Color(0xFFD8E2FF);
  static const Color onPrimaryFixed = Color(0xFF001A41);
  static const Color surfaceVariant = Color(0xFFE0E3E8);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _emc1Controller.dispose();
    _emc2Controller.dispose();
    _emc3Controller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in Name, Email, and Password')));
      return;
    }
    if (_emc1Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primary emergency contact is required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      String uid = userCredential.user!.uid;

      // 2. Prepare Data
      final List<String> allergies = _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final List<String> conditions = _conditionsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      // Prepend +91 to all phone numbers before saving
      final String contactNumber = _contactController.text.trim().isNotEmpty
          ? '+91${_contactController.text.trim()}'
          : '';
      final List<String> emergencyContacts = [
        _emc1Controller.text.trim().isNotEmpty ? '+91${_emc1Controller.text.trim()}' : '',
        _emc2Controller.text.trim().isNotEmpty ? '+91${_emc2Controller.text.trim()}' : '',
        _emc3Controller.text.trim().isNotEmpty ? '+91${_emc3Controller.text.trim()}' : '',
      ].where((c) => c.isNotEmpty).toList();

      // 3. Upload Medical Report (if exists)
      String reportUrl = '';
      if (_medicalReportBytes != null) {
        var ref = FirebaseStorage.instance.ref().child('medical_reports').child('$uid.jpg');
        await ref.putData(_medicalReportBytes!, SettableMetadata(contentType: 'image/jpeg'));
        reportUrl = await ref.getDownloadURL();
      }

      // 4. Firestore — users collection (role mapping)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': contactNumber,
        'bloodGroup': _selectedBloodGroup,
        'allergies': allergies,
        'conditions': conditions,
        'emergencyContacts': emergencyContacts,
        'emergencyContact': emergencyContacts.isNotEmpty ? emergencyContacts[0] : '',
        'role': 'citizen',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Firestore — citizens collection (directory listing)
      await FirebaseFirestore.instance.collection('citizens').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contactNumber': contactNumber,
        'phone': contactNumber,
        'bloodGroup': _selectedBloodGroup,
        'blood_type': _selectedBloodGroup,
        'allergies': _allergiesController.text.trim(),
        'chronicConditions': _conditionsController.text.trim(),
        'emergencyContacts': emergencyContacts,
        'emergencyContact': emergencyContacts.isNotEmpty ? emergencyContacts[0] : '',
        'medicalReportUrl': reportUrl,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 6. Update Global State
      currentUser.name = _nameController.text.trim();
      currentUser.bloodGroup = _selectedBloodGroup;
      currentUser.allergies = allergies;
      currentUser.conditions = conditions;
      currentUser.emergencyContact = emergencyContacts.isNotEmpty ? emergencyContacts[0] : '';
      currentUser.role = 'citizen';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!'), backgroundColor: Colors.green));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const CitizenMainEmergencyMap()),
        (route) => false,
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth Error'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surfaceContainerLowest,
        elevation: 0,
        title: const Text('Citizen Registration', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceVariant),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(Icons.person_add, 'Account Information'),
                const SizedBox(height: 16),
                _buildTextField(_nameController, 'LEGAL FULL NAME', 'e.g. Jane Doe', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'EMAIL ADDRESS', 'e.g. jane@example.com', Icons.mail_outline),
                const SizedBox(height: 16),
                // Contact number — 10-digit only, +91 prefix shown
                _buildPhoneField(
                  controller: _contactController,
                  label: 'CONTACT NUMBER',
                  hint: '9876543210',
                  icon: Icons.phone_android_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'PASSWORD', '••••••••', Icons.lock_outline, obscureText: true),
                
                const SizedBox(height: 32),
                _buildSectionHeader(Icons.medical_services_outlined, 'Clinical Details'),
                const SizedBox(height: 16),
                _buildBloodGroupDropdown(),
                const SizedBox(height: 16),
                _buildTextField(_allergiesController, 'ALLERGIES', 'e.g. Penicillin, Peanuts', Icons.warning_amber_rounded),
                const SizedBox(height: 16),
                _buildTextField(_conditionsController, 'CHRONIC CONDITIONS', 'e.g. Diabetes, Asthma', Icons.history_edu, maxLines: 2),
                const SizedBox(height: 16),
                // 3 Emergency Contacts
                const Text('EMERGENCY CONTACTS (UP TO 3)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                _buildContactField(_emc1Controller, 'Primary Contact (Required)', Icons.phone),
                const SizedBox(height: 10),
                _buildContactField(_emc2Controller, 'Secondary Contact (Optional)', Icons.phone_outlined),
                const SizedBox(height: 10),
                _buildContactField(_emc3Controller, 'Tertiary Contact (Optional)', Icons.phone_outlined),
                
                const SizedBox(height: 24),
                // Medical Report Upload
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MEDICAL REPORT (OPTIONAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: onSurfaceVariant)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setState(() {
                            _medicalReportFile = pickedFile;
                            _medicalReportBytes = bytes;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                          color: surfaceContainerLowest,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.upload_file, color: _medicalReportFile != null ? primary : outlineVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _medicalReportFile != null ? _medicalReportFile!.name : 'Tap to upload report image',
                                style: TextStyle(color: _medicalReportFile != null ? onSurface : outlineVariant),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: onPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('Complete Registration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: primary, size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)),
    ]);
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon,
      {bool obscureText = false, int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: outlineVariant, fontSize: 14),
          prefixIcon: Icon(icon, color: outlineVariant, size: 20),
          filled: true,
          fillColor: surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  /// Phone field with +91 prefix text and 10-digit enforced formatter.
  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: outlineVariant, fontSize: 14),
          prefixIcon: Icon(icon, color: outlineVariant, size: 20),
          prefixText: '+91 ',
          prefixStyle: const TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _buildContactField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: outlineVariant, fontSize: 14),
        prefixIcon: Icon(icon, color: outlineVariant, size: 20),
        prefixText: '+91 ',
        prefixStyle: const TextStyle(color: onSurface, fontSize: 15, fontWeight: FontWeight.w500),
        filled: true,
        fillColor: surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildBloodGroupDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('BLOOD GROUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: _selectedBloodGroup,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.bloodtype_outlined, color: outlineVariant, size: 20),
          filled: true,
          fillColor: surfaceContainerLowest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: outlineVariant)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primary, width: 2)),
        ),
        items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _selectedBloodGroup = val!),
      ),
    ]);
  }
}
