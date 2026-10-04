import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';

class CreatePatientScreen extends StatefulWidget {
  final AdminController adminController;

  const CreatePatientScreen({super.key, required this.adminController});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _baselineInfoController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _baselineInfoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.adminController.createPatient(
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      bloodGroup: _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : null,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      villageLocality: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
      emergencyContactName: _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : null,
      emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
      baselineHealthInfo: _baselineInfoController.text.trim().isNotEmpty ? _baselineInfoController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient account created with unique Health Record Number.')),
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
        title: const Text('Provision Patient'),
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
                  'Patient Account Registration',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an active maternal/patient record. A unique Health Record Number (HR-XXXX) will be generated automatically.',
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
                  key: const Key('patient_fullname_field'),
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Full Name*',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter full name.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('patient_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Patient Email Address*',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('patient_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('patient_bloodgroup_field'),
                        controller: _bloodGroupController,
                        decoration: const InputDecoration(
                          labelText: 'Blood Group (e.g. O+, B+)',
                          prefixIcon: Icon(Icons.bloodtype_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('patient_village_field'),
                        controller: _villageController,
                        decoration: const InputDecoration(
                          labelText: 'Village / Locality',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('patient_address_field'),
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Residential Address',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('patient_emergency_name_field'),
                        controller: _emergencyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Contact Name',
                          prefixIcon: Icon(Icons.contact_emergency_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('patient_emergency_phone_field'),
                        controller: _emergencyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Phone',
                          prefixIcon: Icon(Icons.phone_callback_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('patient_baseline_info_field'),
                  controller: _baselineInfoController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Baseline Health Notes / Allergies',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  key: const Key('patient_provision_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF10B981),
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
                          'Create Patient Account',
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
