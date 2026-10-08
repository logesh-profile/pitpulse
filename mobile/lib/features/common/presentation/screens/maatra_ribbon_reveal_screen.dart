import 'package:flutter/material.dart';
import 'maatra_logo_reveal.dart';

/// MAATRA — Logo Reveal Screen.
/// Plays cinematic, geometric logo-reveal animation before transitioning
/// to the user's role-specific dashboard.
class MaatraRibbonRevealScreen extends StatelessWidget {
  final VoidCallback onCompleted;

  const MaatraRibbonRevealScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return MaatraLogoReveal(
      onCompleted: onCompleted,
      duration: const Duration(milliseconds: 3200),
      backgroundColor: const Color(0xFFFAF9F6), // Warm off-white / pristine ivory
    );
  }
}
