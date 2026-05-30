import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/home/home_screen.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key, required this.startup});

  final Future<void> startup;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );

    _controller.forward();
    unawaited(_openHome());
  }

  Future<void> _openHome() async {
    await Future.wait<void>([
      Future<void>.delayed(const Duration(milliseconds: 1800)),
      widget.startup,
    ]);
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF071C18),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: AppTheme.primaryColor,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF003F34), Color(0xFF005B49)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _SplashPatternPainter()),
                ),
                SafeArea(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SplashLogo(),
                            SizedBox(height: 26),
                            Text(
                              'نور القرآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'رفيقك في تدبر الذكر الحكيم',
                              style: TextStyle(
                                color: Color(0xFFD8E4DF),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                              ),
                            ),
                            SizedBox(height: 42),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Color(0xFFC9A24D),
                                backgroundColor: Color(0x3327A083),
                              ),
                            ),
                          ],
                        ),
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

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 146,
      height: 146,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: CustomPaint(painter: _SplashLogoPainter()),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 146;
    canvas.scale(scale);

    final green = Paint()..color = AppTheme.primaryColor;
    final darkGreen = Paint()..color = const Color(0xFF003F34);
    final gold = Paint()..color = AppTheme.secondaryColor;
    final ivory = Paint()..color = const Color(0xFFFFFDF4);

    canvas.drawCircle(const Offset(73, 73), 66, ivory);
    canvas.drawCircle(
      const Offset(73, 73),
      61,
      Paint()
        ..color = AppTheme.secondaryColor.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final dome = Path()
      ..moveTo(45, 60)
      ..cubicTo(47, 42, 59, 31, 73, 31)
      ..cubicTo(87, 31, 99, 42, 101, 60)
      ..lineTo(101, 65)
      ..lineTo(45, 65)
      ..close();
    canvas.drawPath(dome, gold);

    final base = RRect.fromRectAndRadius(
      const Rect.fromLTWH(39, 61, 68, 36),
      const Radius.circular(8),
    );
    canvas.drawRRect(base, green);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 48, 10, 50),
        const Radius.circular(5),
      ),
      darkGreen,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(105, 48, 10, 50),
        const Radius.circular(5),
      ),
      darkGreen,
    );
    canvas.drawCircle(const Offset(36, 44), 7, gold);
    canvas.drawCircle(const Offset(110, 44), 7, gold);

    final door = Path()
      ..moveTo(62, 96)
      ..lineTo(62, 78)
      ..cubicTo(62, 70, 67, 64, 73, 64)
      ..cubicTo(79, 64, 84, 70, 84, 78)
      ..lineTo(84, 96)
      ..close();
    canvas.drawPath(door, ivory);

    final leftPage = Path()
      ..moveTo(42, 103)
      ..cubicTo(53, 96, 64, 96, 73, 104)
      ..lineTo(73, 119)
      ..cubicTo(62, 112, 52, 112, 42, 118)
      ..close();
    final rightPage = Path()
      ..moveTo(73, 104)
      ..cubicTo(82, 96, 93, 96, 104, 103)
      ..lineTo(104, 118)
      ..cubicTo(94, 112, 84, 112, 73, 119)
      ..close();
    canvas.drawPath(leftPage, ivory);
    canvas.drawPath(rightPage, ivory);

    final linePaint = Paint()
      ..color = AppTheme.secondaryColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(51, 106), const Offset(66, 109), linePaint);
    canvas.drawLine(const Offset(80, 109), const Offset(95, 106), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SplashPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 7; i++) {
      final inset = 24.0 + i * 18;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inset, inset, size.width - inset * 2, 120),
          const Radius.circular(34),
        ),
        paint,
      );
    }

    final bottomPaint = Paint()
      ..color = const Color(0xFFC9A24D).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height + 30),
          radius: 120.0 + i * 28,
        ),
        3.75,
        1.68,
        false,
        bottomPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
