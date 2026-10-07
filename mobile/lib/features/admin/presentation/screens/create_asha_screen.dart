import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../controllers/admin_controller.dart';

class CreateAshaScreen extends StatefulWidget {
  final AdminController adminController;

  const CreateAshaScreen({super.key, required this.adminController});

  @override
  State<CreateAshaScreen> createState() => _CreateAshaScreenState();
}

class _CreateAshaScreenState extends State<CreateAshaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workerCodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _phcController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workerCodeController.dispose();
    _areaController.dispose();
    _phcController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final name = _fullNameController.text.trim().isNotEmpty
        ? _fullNameController.text.trim()
        : 'ASHA Worker (${_emailController.text.trim().split('@').first})';

    final success = await widget.adminController.createAsha(
      email: _emailController.text.trim(),
      fullName: name,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      workerIdCode: _workerCodeController.text.trim().isNotEmpty ? _workerCodeController.text.trim() : null,
      assignedArea: _areaController.text.trim().isNotEmpty ? _areaController.text.trim() : null,
      primaryHealthCenter: _phcController.text.trim().isNotEmpty ? _phcController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ASHA worker account provisioned successfully.',
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
          'Provision ASHA Worker',
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
                          color: MaatraTheme.deepAmethyst.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.volunteer_activism_rounded, color: MaatraTheme.accentLightAmethyst, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Healthcare Worker',
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Admin provisions Gmail & credentials. Worker completes personal details (age, gender, locality) upon first login.',
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

                // ASHA Email (Gmail)
                TextFormField(
                  key: const Key('asha_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'ASHA Gmail Address *',
                    hintText: 'asha.worker@gmail.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid Gmail address.' : null,
                ),
                const SizedBox(height: 14),

                // Full Name
                TextFormField(
                  key: const Key('asha_fullname_field'),
                  controller: _fullNameController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Worker Name (Optional / Preliminary)',
                    hintText: 'e.g. Priya Devi',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Worker ID Code
                TextFormField(
                  key: const Key('asha_worker_code_field'),
                  controller: _workerCodeController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'ASHA Worker ID Code (Optional)',
                    hintText: 'e.g. ASHA-TN-042',
                    prefixIcon: Icon(Icons.badge_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Assigned Area
                TextFormField(
                  key: const Key('asha_area_field'),
                  controller: _areaController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Assigned Village / Ward / Sector (Optional)',
                    hintText: 'e.g. Ward 4, North Sector',
                    prefixIcon: Icon(Icons.location_on_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Primary Health Center
                TextFormField(
                  key: const Key('asha_phc_field'),
                  controller: _phcController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Primary Health Center (Optional)',
                    hintText: 'e.g. Community Health Center',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  key: const Key('asha_phone_field'),
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
                    key: const Key('asha_provision_submit_button'),
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
                            'Provision ASHA Worker',
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
