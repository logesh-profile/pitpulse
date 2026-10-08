import 'dart:math' as math;
import 'package:flutter/material.dart';

/// MAATRA — Premium Logo Reveal Animation
///
/// Motion reference philosophy inspired by Dribbble:
/// https://dribbble.com/shots/6876503-Logo-Reveal-Animation
///
/// Pacing & Choreography (3.2 seconds total):
/// - 0.00 - 0.50s (0.00..0.16): Minimal pristine opening on warm ivory canvas.
/// - 0.50 - 1.60s (0.16..0.50): Geometric 3-ring motif elements progressively align and converge.
/// - 1.60 - 2.10s (0.50..0.66): Symbol locks cleanly into place; visual breathing pause.
/// - 2.10 - 2.90s (0.66..0.90): MAATRA wordmark smoothly emerges with upward micro-glide.
/// - 2.90 - 3.20s (0.90..1.00): Final lockup holds calmly before completing.
class MaatraLogoReveal extends StatefulWidget {
  final VoidCallback? onCompleted;
  final Duration duration;
  final bool autoPlay;
  final Color backgroundColor;

  const MaatraLogoReveal({
    super.key,
    this.onCompleted,
    this.duration = const Duration(milliseconds: 3200),
    this.autoPlay = true,
    this.backgroundColor = const Color(0xFFFAF9F6), // Warm off-white / ivory
  });

  @override
  State<MaatraLogoReveal> createState() => _MaatraLogoRevealState();
}

class _MaatraLogoRevealState extends State<MaatraLogoReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation intervals
  late final Animation<double> _canvasFade;
  late final Animation<double> _geometricConvergence;
  late final Animation<double> _symbolLockFade;
  late final Animation<double> _symbolScale;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _wordmarkSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 1. Initial fade-in (0.00 -> 0.16)
    _canvasFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.16, curve: Curves.easeIn),
    );

    // 2. Geometric alignment of the 3 rings (0.16 -> 0.50)
    _geometricConvergence = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.16, 0.50, curve: Curves.easeInOutCubic),
    );

    // 3. Symbol lock into authentic asset (0.48 -> 0.62)
    _symbolLockFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.62, curve: Curves.easeOut),
    );

    // Subtle scale settling (0.16 -> 0.66)
    _symbolScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.16, 0.66, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Wordmark emergence (0.66 -> 0.88)
    _wordmarkFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.88, curve: Curves.easeOut),
    );

    _wordmarkSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && widget.onCompleted != null) {
          widget.onCompleted!();
        }
      }
    });

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Opacity(
                opacity: _canvasFade.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==========================================
                    // 1. MAATRA SYMBOL REVEAL
                    // ==========================================
                    Transform.scale(
                      scale: _symbolScale.value,
                      child: SizedBox(
                        width: 130,
                        height: 122,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Geometric animated rings (Phases 1 & 2)
                            if (_symbolLockFade.value < 1.0)
                              Opacity(
                                opacity: (1.0 - _symbolLockFade.value).clamp(0.0, 1.0),
                                child: CustomPaint(
                                  size: const Size(130, 122),
                                  painter: _MaatraGeometricRingsPainter(
                                    progress: _geometricConvergence.value,
                                  ),
                                ),
                              ),

                            // Pixel-perfect approved MAATRA Symbol (Locks in at Phase 3)
                            Opacity(
                              opacity: _symbolLockFade.value,
                              child: Image.asset(
                                'assets/images/maatra_symbol.png',
                                width: 128,
                                height: 120,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 2. MAATRA WORDMARK REVEAL
                    // ==========================================
                    Transform.translate(
                      offset: Offset(0, _wordmarkSlide.value),
                      child: Opacity(
                        opacity: _wordmarkFade.value,
                        child: Image.asset(
                          'assets/images/maatra_wordmark.png',
                          width: 175,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter that choreographs the 3 intersecting geometric rings of the MAATRA symbol.
/// Rings start with graceful radial offsets and sweep angles, converging smoothly into alignment.
class _MaatraGeometricRingsPainter extends CustomPainter {
  final double progress;

  _MaatraGeometricRingsPainter({required this.progress});

  // Deep emerald / forest green of the MAATRA brand identity
  static const Color brandEmerald = Color(0xFF0D483A);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius = size.width * 0.285;

    final paint = Paint()
      ..color = brandEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Triangle of center offsets for the 3 interlocking rings
    const targetApexY = -15.0;
    const targetApexX = 0.0;

    const targetLeftX = -17.5;
    const targetLeftY = 15.0;

    const targetRightX = 17.5;
    const targetRightY = 15.0;

    // Initial offsets (start slightly spread and converge with cubic ease)
    final ease = Curves.easeInOutCubic.transform(progress);

    final apexX = targetApexX;
    final apexY = targetApexY - (22.0 * (1.0 - ease));

    final leftX = targetLeftX - (20.0 * (1.0 - ease));
    final leftY = targetLeftY + (14.0 * (1.0 - ease));

    final rightX = targetRightX + (20.0 * (1.0 - ease));
    final rightY = targetRightY + (14.0 * (1.0 - ease));

    // Sweep angle expands smoothly from 180 degrees to 360 degrees
    final sweepAngle = math.pi + (math.pi * ease);

    // Draw Ring 1 (Top)
    final rect1 = Rect.fromCircle(
      center: center + Offset(apexX, apexY),
      radius: ringRadius,
    );
    canvas.drawArc(rect1, -math.pi / 2, sweepAngle, false, paint);

    // Draw Ring 2 (Bottom Left)
    final rect2 = Rect.fromCircle(
      center: center + Offset(leftX, leftY),
      radius: ringRadius,
    );
    canvas.drawArc(rect2, math.pi / 2, sweepAngle, false, paint);

    // Draw Ring 3 (Bottom Right)
    final rect3 = Rect.fromCircle(
      center: center + Offset(rightX, rightY),
      radius: ringRadius,
    );
    canvas.drawArc(rect3, 0, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _MaatraGeometricRingsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
