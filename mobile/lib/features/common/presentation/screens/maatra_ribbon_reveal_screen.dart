import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Harmonious Ribbon Loop Reveal Screen for MAATRA.
/// Plays immediately upon successful authentication before transitioning
/// to the user's role-specific dashboard.
class MaatraRibbonRevealScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const MaatraRibbonRevealScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<MaatraRibbonRevealScreen> createState() => _MaatraRibbonRevealScreenState();
}

class _MaatraRibbonRevealScreenState extends State<MaatraRibbonRevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ribbonController;
  late final AnimationController _textController;

  late final Animation<double> _ribbonStrokeProgress;
  late final Animation<double> _ribbonScale;
  late final Animation<double> _ribbonGlow;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;
  late final Animation<double> _letterSpacing;

  @override
  void initState() {
    super.initState();

    // 1. Ribbon Loop Motion (0.0 to 1.0 over 1400ms)
    _ribbonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _ribbonStrokeProgress = CurvedAnimation(
      parent: _ribbonController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
    );

    _ribbonScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _ribbonController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _ribbonGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ribbonController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Text Reveal (MAATRA wordmark over 900ms)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _textSlide = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _letterSpacing = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Sequence the animations
    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _ribbonController.forward();
    if (!mounted) return;
    await _textController.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _ribbonController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Classy Obsidian Black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Harmonious Ribbon Loop Reveal
            AnimatedBuilder(
              animation: _ribbonController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _ribbonScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radiant Breathing Ambient Glow
                      Opacity(
                        opacity: _ribbonGlow.value * 0.35,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.45),
                                blurRadius: 40,
                                spreadRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Custom Dynamic Interlocking Ribbon Painter
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: _HarmoniousRibbonPainter(
                            progress: _ribbonStrokeProgress.value,
                            color: const Color(0xFFFFFFFF),
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),
                      ),

                      // High-res MAATRA Logo Asset Overlay
                      Opacity(
                        opacity: (_ribbonStrokeProgress.value - 0.4).clamp(0.0, 1.0) / 0.6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/maatra_logo.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            // Wordmark Typography Reveal: MAATRA
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Opacity(
                  opacity: _textFade.value,
                  child: Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: Column(
                      children: [
                        Text(
                          'MAATRA',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F5F5),
                            letterSpacing: _letterSpacing.value,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'INTELLIGENT HEALTH & MATERNAL WELLNESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFA3A3A3),
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Painter for the Harmonious Trefoil Ribbon Loop
class _HarmoniousRibbonPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color accentColor;

  _HarmoniousRibbonPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85);

    // Three symmetrical loop centers arranged in an equilateral triangle
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - (math.pi / 2);
      final loopCenter = Offset(
        center.dx + (radius * 0.6) * math.cos(angle),
        center.dy + (radius * 0.6) * math.sin(angle),
      );

      final sweep = (2 * math.pi) * (progress * 1.25).clamp(0.0, 1.0);
      final rect = Rect.fromCircle(center: loopCenter, radius: radius * 0.85);

      canvas.drawArc(rect, angle, sweep, false, paintStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _HarmoniousRibbonPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
