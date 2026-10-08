import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../controllers/auth_controller.dart';
import 'gmail_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthController authController;

  const RegisterScreen({super.key, required this.authController});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final user = await widget.authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GmailVerificationScreen(
              authController: widget.authController,
              email: _emailController.text.trim(),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.authController.errorMessage ?? 'Registration failed. Please check your details.';
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    final success = await widget.authController.signInWithGoogle();
    if (mounted) {
      if (success) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final err = widget.authController.errorMessage;
        if (err != null && err.isNotEmpty) {
          setState(() {
            _errorMessage = err;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaatraTheme.bgDark,
      appBar: AppBar(
        backgroundColor: MaatraTheme.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: MaatraTheme.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Patient Account',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up with your genuine Gmail address. A 6-digit verification code will be sent to confirm your identity.',
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Error message banner
                if (_errorMessage != null) ...[
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
                            _errorMessage!,
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

                // Full Name
                TextFormField(
                  controller: _fullNameController,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Legal Name *',
                    hintText: 'e.g. Priya Sundaram',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 16),

                // Gmail ID
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Gmail / Email ID *',
                    hintText: 'yourname@gmail.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your Gmail address';
                    final email = v.trim().toLowerCase();
                    if (!email.contains('@') || !email.contains('.')) return 'Please enter a valid email address';
                    if (!email.endsWith('@gmail.com') && !email.endsWith('@googlemail.com')) {
                      return 'Please enter a valid Gmail address (@gmail.com)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Phone Number (Optional)',
                    hintText: '+91 9876543210',
                    prefixIcon: Icon(Icons.phone_outlined, color: MaatraTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    hintText: 'Minimum 8 characters',
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
                    if (v == null || v.isEmpty) return 'Please enter a password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: Icon(Icons.lock_reset_rounded, color: MaatraTheme.textSecondary),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button - Solid Medical Emerald
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaatraTheme.brandEmerald,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                            'Send Verification Code',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Or Divider
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: MaatraTheme.borderHairline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR CONTINUE WITH',
                        style: GoogleFonts.plusJakartaSans(
                          color: MaatraTheme.textQuiet,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: MaatraTheme.borderHairline)),
                  ],
                ),
                const SizedBox(height: 18),

                // Direct Google Sign In Button
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: MaatraTheme.borderHairline),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata_rounded, size: 28, color: MaatraTheme.brandEmerald),
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
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already registered? ',
                      style: GoogleFonts.plusJakartaSans(color: MaatraTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          color: MaatraTheme.accentLilac,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
