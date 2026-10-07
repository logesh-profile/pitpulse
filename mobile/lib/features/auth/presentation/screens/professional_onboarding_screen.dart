import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../controllers/auth_controller.dart';

class ProfessionalOnboardingScreen extends StatefulWidget {
  final AuthController authController;
  final VoidCallback onCompleted;

  const ProfessionalOnboardingScreen({
    super.key,
    required this.authController,
    required this.onCompleted,
  });

  @override
  State<ProfessionalOnboardingScreen> createState() => _ProfessionalOnboardingScreenState();
}

class _ProfessionalOnboardingScreenState extends State<ProfessionalOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  // Doctor fields
  final _specController = TextEditingController();
  final _facilityController = TextEditingController();
  final _licenseController = TextEditingController();

  // ASHA fields
  final _areaController = TextEditingController();
  final _phcController = TextEditingController();

  String _selectedGender = 'Female';
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isDoctor => widget.authController.currentUser?.role == 'DOCTOR';

  @override
  void initState() {
    super.initState();
    final user = widget.authController.currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    if (user?.phone != null) _phoneController.text = user!.phone!;
    if (user?.age != null) _ageController.text = user!.age.toString();
    if (user?.gender != null) _selectedGender = user!.gender!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _specController.dispose();
    _facilityController.dispose();
    _licenseController.dispose();
    _areaController.dispose();
    _phcController.dispose();
    super.dispose();
  }

  Future<void> _submitOnboarding() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'gender': _selectedGender,
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    };

    if (_isDoctor) {
      if (_specController.text.trim().isNotEmpty) {
        data['specialization'] = _specController.text.trim();
      }
      if (_facilityController.text.trim().isNotEmpty) {
        data['facility_name'] = _facilityController.text.trim();
      }
      if (_licenseController.text.trim().isNotEmpty) {
        data['medical_license_number'] = _licenseController.text.trim();
      }
    } else {
      if (_areaController.text.trim().isNotEmpty) {
        data['assigned_area'] = _areaController.text.trim();
      }
      if (_phcController.text.trim().isNotEmpty) {
        data['primary_health_center'] = _phcController.text.trim();
      }
    }

    final success = await widget.authController.completeProfile(data);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        widget.onCompleted();
      } else {
        setState(() {
          _errorMessage = widget.authController.errorMessage ?? 'Failed to complete profile.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleTitle = _isDoctor ? 'Doctor Profile' : 'ASHA Healthcare Worker Profile';

    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: MaatraTheme.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isDoctor ? Icons.medical_services_rounded : Icons.health_and_safety_rounded,
                      color: MaatraTheme.accentLilac,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Welcome to MAATRA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your account was created by the Administrator. Please complete your $roleTitle with your real details to get started.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MaatraTheme.crimsonAlert.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MaatraTheme.crimsonAlert.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: MaatraTheme.crimsonAlert, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.crimsonAlert,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Section 1: Personal Details
                Text(
                  'PERSONAL DETAILS',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.accentLilac,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Dr. Ramesh Kumar',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),

                // Age & Gender Row
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          hintText: '35',
                          prefixIcon: Icon(Icons.cake_outlined, color: MaatraTheme.textSecondary),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter age';
                          final num = int.tryParse(v.trim());
                          if (num == null || num < 18 || num > 100) return 'Valid age (18+)';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: MaatraTheme.inputDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: MaatraTheme.borderMuted),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            dropdownColor: MaatraTheme.surfaceDark,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, color: MaatraTheme.textSecondary),
                            items: const [
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGender = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Phone Number *',
                    hintText: '+91 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 24),

                // Section 2: Professional Details
                Text(
                  _isDoctor ? 'CLINICAL CREDENTIALS' : 'FIELD ASSIGNMENT',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.accentLilac,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isDoctor) ...[
                  TextFormField(
                    controller: _specController,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Specialization / Department',
                      hintText: 'e.g. Obstetrics & Gynecology, General Physician',
                      prefixIcon: Icon(Icons.school_outlined, color: MaatraTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _facilityController,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Hospital / Clinic / PHC Name',
                      hintText: 'e.g. Primary Health Center, Vellanur',
                      prefixIcon: Icon(Icons.local_hospital_outlined, color: MaatraTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _licenseController,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Medical Registration / License No.',
                      hintText: 'e.g. TNMC-2023-8812',
                      prefixIcon: Icon(Icons.badge_outlined, color: MaatraTheme.textSecondary),
                    ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _areaController,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Assigned Village / Ward / Area',
                      hintText: 'e.g. Ward 4, North Zone',
                      prefixIcon: Icon(Icons.location_on_outlined, color: MaatraTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phcController,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Primary Health Center (PHC)',
                      hintText: 'e.g. Vellanur PHC',
                      prefixIcon: Icon(Icons.apartment_outlined, color: MaatraTheme.textSecondary),
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Submit Button
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [MaatraTheme.deepAmethyst, MaatraTheme.primaryAmethyst],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            'Save & Enter Portal',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
