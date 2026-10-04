import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';

class CreateDoctorScreen extends StatefulWidget {
  final AdminController adminController;

  const CreateDoctorScreen({super.key, required this.adminController});

  @override
  State<CreateDoctorScreen> createState() => _CreateDoctorScreenState();
}

class _CreateDoctorScreenState extends State<CreateDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specController = TextEditingController();
  final _facilityController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _specController.dispose();
    _facilityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.adminController.createDoctor(
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      medicalLicenseNumber: _licenseController.text.trim().isNotEmpty ? _licenseController.text.trim() : null,
      specialization: _specController.text.trim().isNotEmpty ? _specController.text.trim() : null,
      facilityName: _facilityController.text.trim().isNotEmpty ? _facilityController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor account provisioned successfully.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.adminController.status == AdminStateStatus.loading;
    final errorMessage = widget.adminController.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision Doctor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Doctor Account Registration',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an authorized clinical doctor account with initial temporary credentials.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),

                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red[200], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  key: const Key('doctor_fullname_field'),
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (e.g. Dr. Ramesh Kumar)*',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter full name.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('doctor_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Email Address*',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('doctor_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('doctor_license_field'),
                  controller: _licenseController,
                  decoration: const InputDecoration(
                    labelText: 'Medical Registration / License No.',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('doctor_specialization_field'),
                  controller: _specController,
                  decoration: const InputDecoration(
                    labelText: 'Specialization (e.g. Cardiology, OB-GYN)',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('doctor_facility_field'),
                  controller: _facilityController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital / Primary Health Center',
                    prefixIcon: Icon(Icons.local_hospital_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  key: const Key('doctor_provision_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Provision Doctor Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
