import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
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

    final name = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : 'Doctor (${_emailController.text.trim().split('@').first})';

    final success = await widget.adminController.createDoctor(
      email: _emailController.text.trim(),
      fullName: name,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      medicalLicenseNumber: _licenseController.text.trim().isNotEmpty ? _licenseController.text.trim() : null,
      specialization: _specController.text.trim().isNotEmpty ? _specController.text.trim() : null,
      facilityName: _facilityController.text.trim().isNotEmpty ? _facilityController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Doctor account provisioned successfully.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: MaatraTheme.emeraldSafe,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.adminController.status == AdminStateStatus.loading;
    final errorMessage = widget.adminController.errorMessage;

    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatraTheme.textPrimary, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Provision Doctor Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MaatraTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MaatraTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MaatraTheme.borderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_services_rounded, color: MaatraTheme.accentLilac, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Clinical Doctor Access',
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Admin provisions Gmail & credentials. Doctor completes personal details (age, gender, qualifications) on first login.',
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.textTertiary,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MaatraTheme.crimsonAlert.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: MaatraTheme.crimsonAlert.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.plusJakartaSans(color: MaatraTheme.crimsonAlert, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Doctor Email (Gmail)
                TextFormField(
                  key: const Key('doctor_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Doctor Gmail Address *',
                    hintText: 'doctor.name@gmail.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid Gmail address.' : null,
                ),
                const SizedBox(height: 14),

                // Full Name
                TextFormField(
                  key: const Key('doctor_fullname_field'),
                  controller: _fullNameController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name (Optional / Preliminary)',
                    hintText: 'e.g. Dr. Rajesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Specialization
                TextFormField(
                  key: const Key('doctor_specialization_field'),
                  controller: _specController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Specialization (Optional)',
                    hintText: 'e.g. Obstetrics & Gynecology',
                    prefixIcon: Icon(Icons.medical_information_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // License Number
                TextFormField(
                  key: const Key('doctor_license_field'),
                  controller: _licenseController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Medical Registration / License (Optional)',
                    hintText: 'e.g. MCI-987654',
                    prefixIcon: Icon(Icons.badge_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Facility
                TextFormField(
                  key: const Key('doctor_facility_field'),
                  controller: _facilityController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Hospital / Primary Health Center (Optional)',
                    hintText: 'e.g. District General Hospital',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  key: const Key('doctor_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.phone_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 28),

                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    key: const Key('doctor_provision_submit_button'),
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Provision Doctor Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
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
