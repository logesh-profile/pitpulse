import 'package:flutter/material.dart';
import '../controllers/patient_controller.dart';

class EditPatientProfileScreen extends StatefulWidget {
  final PatientController patientController;

  const EditPatientProfileScreen({super.key, required this.patientController});

  @override
  State<EditPatientProfileScreen> createState() => _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState extends State<EditPatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _villageController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _baselineHealthController = TextEditingController();

  String? _selectedSex;
  String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    final profile = widget.patientController.profile;
    if (profile != null) {
      _dobController.text = profile.dateOfBirth ?? '';
      _addressController.text = profile.address ?? '';
      _villageController.text = profile.villageLocality ?? '';
      _emergencyNameController.text = profile.emergencyContactName ?? '';
      _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
      _baselineHealthController.text = profile.baselineHealthInfo ?? '';
      _selectedSex = profile.sex;
      _selectedBloodGroup = profile.bloodGroup;
    }
  }

  @override
  void dispose() {
    _dobController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _baselineHealthController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.patientController.updateProfile(
      dateOfBirth: _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : null,
      sex: _selectedSex,
      address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
      villageLocality: _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : null,
      emergencyContactName: _emergencyNameController.text.trim().isNotEmpty ? _emergencyNameController.text.trim() : null,
      emergencyContactPhone: _emergencyPhoneController.text.trim().isNotEmpty ? _emergencyPhoneController.text.trim() : null,
      bloodGroup: _selectedBloodGroup,
      baselineHealthInfo: _baselineHealthController.text.trim().isNotEmpty ? _baselineHealthController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient profile updated in PostgreSQL.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.patientController.status == PatientStateStatus.loading;
    final errorMessage = widget.patientController.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Patient Profile'),
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
                  'Personal Health & Demographics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your verified personal details stored securely in PostgreSQL.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
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

                // Date of Birth
                TextFormField(
                  key: const Key('patient_dob_field'),
                  controller: _dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (YYYY-MM-DD)',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Sex Selector
                DropdownButtonFormField<String>(
                  key: const Key('patient_sex_dropdown'),
                  initialValue: _selectedSex,
                  decoration: const InputDecoration(
                    labelText: 'Sex',
                    prefixIcon: Icon(Icons.wc_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _selectedSex = v),
                ),
                const SizedBox(height: 14),

                // Blood Group
                DropdownButtonFormField<String>(
                  key: const Key('patient_bloodgroup_dropdown'),
                  initialValue: _selectedBloodGroup,
                  decoration: const InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                  ],
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                ),
                const SizedBox(height: 14),

                // Village / Locality
                TextFormField(
                  key: const Key('patient_village_field'),
                  controller: _villageController,
                  decoration: const InputDecoration(
                    labelText: 'Village / Ward / Locality',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Residential Address
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

                // Emergency Contact Name
                TextFormField(
                  key: const Key('patient_emergency_name_field'),
                  controller: _emergencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Full Name',
                    prefixIcon: Icon(Icons.contact_emergency_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Emergency Contact Phone
                TextFormField(
                  key: const Key('patient_emergency_phone_field'),
                  controller: _emergencyPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone Number',
                    prefixIcon: Icon(Icons.phone_in_talk_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Baseline Health Notes
                TextFormField(
                  key: const Key('patient_health_notes_field'),
                  controller: _baselineHealthController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Baseline Health Info / Known Allergies',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  key: const Key('patient_profile_save_button'),
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
                          'Save Profile Changes',
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
