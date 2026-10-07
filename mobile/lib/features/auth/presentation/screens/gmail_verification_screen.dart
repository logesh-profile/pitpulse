import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/maatra_theme.dart';
import '../controllers/auth_controller.dart';

class GmailVerificationScreen extends StatefulWidget {
  final AuthController authController;
  final String email;
  final String? initialCode;

  const GmailVerificationScreen({
    super.key,
    required this.authController,
    required this.email,
    this.initialCode,
  });

  @override
  State<GmailVerificationScreen> createState() => _GmailVerificationScreenState();
}

class _GmailVerificationScreenState extends State<GmailVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 60;
  Timer? _timer;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Auto-fill in dev mode if provided
    if (widget.initialCode != null && widget.initialCode!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.initialCode![i];
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        t.cancel();
      }
    });
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Future<void> _submitCode() async {
    final code = _enteredCode.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits of your verification code.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.authController.verifyCode(
      email: widget.email,
      code: code,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _errorMessage = widget.authController.errorMessage ?? 'Invalid or expired verification code.';
        }
      });

      if (success) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _errorMessage = null;
    });

    final sent = await widget.authController.resendCode(email: widget.email);
    if (mounted) {
      if (sent) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: MaatraTheme.primaryAmethyst,
            content: Text(
              'A fresh 6-digit code was sent to ${widget.email}',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.authController.errorMessage ?? 'Failed to resend code. Please try again.';
        });
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Icon Header with Royal Amethyst Glow
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: MaatraTheme.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    color: MaatraTheme.accentLilac,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Verify Your Gmail',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: MaatraTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'We sent a 6-digit verification code to:\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: MaatraTheme.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final codeToDisplay = widget.initialCode ?? widget.authController.lastVerificationCode;
                  if (codeToDisplay == null || codeToDisplay.isEmpty) {
                    return const SizedBox(height: 36);
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: MaatraTheme.primaryAmethyst.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.vpn_key_rounded, color: MaatraTheme.accentLilac, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instant Verification Code:',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: MaatraTheme.accentLilac,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    codeToDisplay,
                                    style: GoogleFonts.jetBrainsMono(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                for (int i = 0; i < 6 && i < codeToDisplay.length; i++) {
                                  _controllers[i].text = codeToDisplay[i];
                                }
                                _submitCode();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MaatraTheme.primaryAmethyst,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Auto-fill',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // 6 Digits Input Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 58,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: GoogleFonts.plusJakartaSans(
                        color: MaatraTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: MaatraTheme.cardDark,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: MaatraTheme.borderMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: MaatraTheme.primaryAmethyst, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_enteredCode.length == 6) {
                          _submitCode();
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

              const SizedBox(height: 28),

              // Verify & Continue Button
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
                  onPressed: _isSubmitting ? null : _submitCode,
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
                          'Verify & Activate Account',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend Code timer
              Center(
                child: TextButton(
                  onPressed: _resendCountdown == 0 ? _resendCode : null,
                  child: Text(
                    _resendCountdown > 0
                        ? 'Resend code in ${_resendCountdown}s'
                        : 'Didn’t receive code? Resend Now',
                    style: GoogleFonts.plusJakartaSans(
                      color: _resendCountdown > 0 ? MaatraTheme.textTertiary : MaatraTheme.accentLilac,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
