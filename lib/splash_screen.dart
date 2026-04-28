import 'dart:ui';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _pulseController;

  // Staggered animations
  late Animation<double> _iconFade;
  late Animation<double> _ecgDraw;
  late Animation<double> _brandSlide;
  late Animation<double> _brandFade;
  late Animation<double> _tag1Slide;
  late Animation<double> _tag1Fade;
  late Animation<double> _tag2Slide;
  late Animation<double> _tag2Fade;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    // Master timeline: 2.5 seconds total (show animations then fade out)
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Pulsing red dot (infinite loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Icon fades in: 0ms → 200ms
    _iconFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.0, 0.08, curve: Curves.easeOut)),
    );

    // ECG draws: 150ms → 550ms
    _ecgDraw = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.06, 0.22, curve: Curves.easeInOut)),
    );

    // Brand name slides up: 100ms → 400ms
    _brandSlide = Tween<double>(begin: 15, end: 0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.04, 0.16, curve: Curves.easeOut)),
    );
    _brandFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.04, 0.16, curve: Curves.easeOut)),
    );

    // Tagline 1: 200ms → 500ms
    _tag1Slide = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.08, 0.20, curve: Curves.easeOut)),
    );
    _tag1Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.08, 0.20, curve: Curves.easeOut)),
    );

    // Tagline 2: 300ms → 600ms
    _tag2Slide = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.12, 0.24, curve: Curves.easeOut)),
    );
    _tag2Fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.12, 0.24, curve: Curves.easeOut)),
    );

    // Fade out entire screen: 2000ms → 2500ms
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _masterController, curve: const Interval(0.80, 1.0, curve: Curves.easeIn)),
    );

    _masterController.forward();

    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionDuration: Duration.zero,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_masterController, _pulseController]),
      builder: (context, _) {
        return Opacity(
          opacity: _fadeOut.value,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0d1b3e), Color(0xFF1a2f5e), Color(0xFF0d1b3e)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Animated Icon Box ──
                    Opacity(
                      opacity: _iconFade.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: const Color(0x12FFFFFF),
                          border: Border.all(color: const Color(0xFF64A0DC).withOpacity(0.35), width: 1.5),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circle bg
                            Container(
                              width: 96, height: 96,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x10FFFFFF)),
                            ),
                            // Medical Cross
                            Container(
                              width: 84, height: 24,
                              decoration: BoxDecoration(color: const Color(0xD996AFD2), borderRadius: BorderRadius.circular(4)),
                            ),
                            Container(
                              width: 24, height: 84,
                              decoration: BoxDecoration(color: const Color(0xD996AFD2), borderRadius: BorderRadius.circular(4)),
                            ),
                            // ECG Pulse
                            CustomPaint(
                              size: const Size(140, 140),
                              painter: _ECGSplashPainter(progress: _ecgDraw.value),
                            ),
                            // Pulsing Red Dot
                            Positioned(
                              top: 20,
                              right: 26,
                              child: Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.4),
                                child: Opacity(
                                  opacity: 1.0 - (_pulseController.value * 0.3),
                                  child: Container(
                                    width: 14, height: 14,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE8405A)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Brand Name ──
                    Transform.translate(
                      offset: Offset(0, _brandSlide.value),
                      child: Opacity(
                        opacity: _brandFade.value,
                        child: const Text(
                          'AROGNA',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 5,
                            color: Colors.white,
                            shadows: [Shadow(color: Color(0x4D64A0FF), blurRadius: 40)],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tagline 1 ──
                    Transform.translate(
                      offset: Offset(0, _tag1Slide.value),
                      child: Opacity(
                        opacity: _tag1Fade.value,
                        child: const Text(
                          'RAPID CRISIS RESPONSE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 4,
                            color: Color(0xE6A0C3F0),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Tagline 2 ──
                    Transform.translate(
                      offset: Offset(0, _tag2Slide.value),
                      child: Opacity(
                        opacity: _tag2Fade.value,
                        child: const Text(
                          'आरोग्ना  ·  the pulse of crisis response',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.5,
                            fontStyle: FontStyle.italic,
                            color: Color(0xB38CAFDC),
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
      },
    );
  }
}

class _ECGSplashPainter extends CustomPainter {
  final double progress;
  _ECGSplashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF3ECFCF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    final path = Path()
      ..moveTo(cx - 60, cy)
      ..lineTo(cx - 38, cy)
      ..lineTo(cx - 28, cy)
      ..lineTo(cx - 18, cy - 25)
      ..lineTo(cx - 8, cy + 25)
      ..lineTo(cx + 2, cy - 15)
      ..lineTo(cx + 10, cy)
      ..lineTo(cx + 28, cy)
      ..lineTo(cx + 60, cy);

    // Draw only the visible portion based on animation progress
    for (final metric in path.computeMetrics()) {
      final visibleLength = metric.length * progress;
      canvas.drawPath(metric.extractPath(0, visibleLength), paint);
    }
  }

  @override
  bool shouldRepaint(_ECGSplashPainter old) => old.progress != progress;
}
