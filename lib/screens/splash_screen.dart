import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late List<_ShootingStar> _shootingStars;
  late AnimationController _starsController;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for the landing image
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Shooting stars animation
    _starsController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _shootingStars = List.generate(8, (index) => _ShootingStar());

    // Navigate to home after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, '/home');
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Landing image (background)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/landing_without_Shootingstars.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // Animated shooting stars overlay
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _starsController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ShootingStarsPainter(
                      stars: _shootingStars,
                      progress: _starsController.value,
                    ),
                  );
                },
              ),
            ),

            // Shooting stars image overlay with animation
            ..._buildAnimatedStarImages(context),

            // Tap to continue text at bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'Tap anywhere to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnimatedStarImages(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final random = Random(42);
    return List.generate(5, (index) {
      final startX = size.width * 0.6 + random.nextDouble() * size.width * 0.8;
      final startY = random.nextDouble() * (size.height * 0.3); // Top 30% only
      final delay = random.nextDouble();

      return AnimatedBuilder(
        animation: _starsController,
        builder: (context, child) {
          final progress = (_starsController.value + delay) % 1.0;
          // Move right-to-left
          final dx = startX - progress * size.width * 1.5;
          // Move down very slightly to keep it in the top half
          final dy = startY + progress * (size.height * 0.15);
          final opacity = (1.0 - progress).clamp(0.0, 1.0) *
              (progress > 0.1 ? 1.0 : progress * 10);

          return Positioned(
            left: dx,
            top: dy,
            child: Opacity(
              opacity: opacity * 0.8,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi), // Flip horizontally
                child: Transform.rotate(
                  angle: -0.2, // Slight tilt
                  child: Image.asset(
                    'assets/shoting stars.png',
                    width: 60 + index * 10,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _ShootingStar {
  late double x;
  late double y;
  late double speed;
  late double length;
  late double opacity;

  _ShootingStar() {
    _randomize();
  }

  void _randomize() {
    final random = Random();
    x = random.nextDouble();
    y = random.nextDouble();
    speed = 0.3 + random.nextDouble() * 0.7;
    length = 20 + random.nextDouble() * 40;
    opacity = 0.3 + random.nextDouble() * 0.7;
  }
}

class _ShootingStarsPainter extends CustomPainter {
  final List<_ShootingStar> stars;
  final double progress;

  _ShootingStarsPainter({required this.stars, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final star = stars[i];
      final starProgress = (progress + i * 0.12) % 1.0;
      
      // Start at right side + offset, move left
      final startX = size.width * 0.8 + star.x * size.width;
      final x = startX - starProgress * size.width * 1.5;
      
      // Start in top 30%, move down slightly
      final startY = star.y * size.height * 0.3;
      final y = startY + starProgress * size.height * 0.15;

      if (x < 0 || y > size.height) continue;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: star.opacity * (1 - starProgress))
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      final dx = star.length * 0.7;
      final dy = star.length * 0.3; // Flatter angle

      // Tail follows behind (to the right and slightly up)
      canvas.drawLine(
        Offset(x, y),
        Offset(x + dx, y - dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShootingStarsPainter oldDelegate) => true;
}
