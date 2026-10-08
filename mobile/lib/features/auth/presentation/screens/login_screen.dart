import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../controllers/auth_controller.dart';
import 'gmail_verification_screen.dart';
import 'register_screen.dart';
import 'package:pitpulse_mobile/features/patients/presentation/screens/offline_emergency_hub_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({super.key, required this.authController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showUrlConfig = false;
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.authController.apiClient.baseUrl);
    widget.authController.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.authController.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      final err = widget.authController.errorMessage ?? '';
      if (err.contains('verify your Gmail') || err.contains('verification code')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GmailVerificationScreen(
              authController: widget.authController,
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final success = await widget.authController.signInWithGoogle();
    if (!success && mounted) {
      final err = widget.authController.errorMessage;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MaatraTheme.crimsonAlert,
            content: Text(err, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        );
      }
    }
  }

  void _saveUrlConfig() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      widget.authController.apiClient.updateBaseUrl(newUrl);
      setState(() {
        _showUrlConfig = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MaatraTheme.primaryAmethyst,
          content: Text('Backend host updated to: $newUrl', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.authController.status == AuthStatus.loading;
    final errorMessage = widget.authController.errorMessage;

    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showUrlConfig ? Icons.close_rounded : Icons.tune_rounded,
              color: MaatraTheme.textSecondary,
              size: 20,
            ),
            tooltip: 'Configure Backend Host',
            onPressed: () => setState(() => _showUrlConfig = !_showUrlConfig),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // URL config drawer
                  if (_showUrlConfig) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MaatraTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'SERVER CONNECTION SETTINGS',
                            style: GoogleFonts.plusJakartaSans(
                              color: MaatraTheme.accentLilac,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _urlController,
                            style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Base API URL',
                              prefixIcon: Icon(Icons.dns_outlined, color: MaatraTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _saveUrlConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MaatraTheme.primaryAmethyst,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Update Server URL'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // MAATRA Approved Symbol
                  Center(
                    child: Image.asset(
                      'assets/images/maatra_symbol.png',
                      width: 64,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'MAATRA',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: MaatraTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Maternal & Child Health Platform',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: MaatraTheme.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message banner
                  if (errorMessage != null && errorMessage.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
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
                              errorMessage,
                              style: GoogleFonts.plusJakartaSans(
                                color: MaatraTheme.crimsonAlert,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email / Gmail Input
                  TextFormField(
                    key: const Key('login_email_field'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Gmail / Email Address',
                      hintText: 'admin123@gmail.com, doctor, or patient',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: MaatraTheme.textSecondary),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter your email address.';
                      if (!v.contains('@')) return 'Please enter a valid email address.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  TextFormField(
                    key: const Key('login_password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: MaatraTheme.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: MaatraTheme.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter your password.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Sign In Button - Solid Medical Emerald
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('login_submit_button'),
                      onPressed: isLoading ? null : _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MaatraTheme.brandEmerald,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                          : Text(
                              'Sign In to MAATRA',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: MaatraTheme.borderHairline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.textQuiet,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: MaatraTheme.borderHairline)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Direct Google Login Button
                  OutlinedButton(
                    key: const Key('google_signin_button'),
                    onPressed: isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MaatraTheme.borderHairline),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 28,
                          color: MaatraTheme.brandEmerald,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.plusJakartaSans(
                            color: MaatraTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Create Patient Account Button
                  OutlinedButton.icon(
                    key: const Key('nav_to_register_button'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(authController: widget.authController),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MaatraTheme.borderHairline),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: MaatraTheme.brandEmerald, size: 18),
                    label: Text(
                      'Patient? Register with Gmail',
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.brandEmerald,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: MaatraTheme.borderHairline),
                  const SizedBox(height: 16),

                  // ZERO-LOGIN OFFLINE EMERGENCY CARE & RADAR
                  GestureDetector(
                    key: const Key('zero_login_emergency_button'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OfflineEmergencyHubScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC53030).withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFC53030),
                            ),
                            child: const Icon(Icons.emergency_outlined, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Emergency SOS & Hospital Radar',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFC53030),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Zero Login Required • 100% Offline • 108 Calling',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF7A1C1C), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC53030)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // OFFLINE GUEST PATIENT ACCESS
                  TextButton.icon(
                    key: const Key('offline_guest_mode_button'),
                    onPressed: () async {
                      await widget.authController.continueAsGuest();
                    },
                    icon: const Icon(Icons.cloud_off_rounded, size: 16, color: MaatraTheme.brandSage),
                    label: const Text(
                      'No Internet? Continue as Offline Patient',
                      style: TextStyle(
                        color: MaatraTheme.brandSage,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
