import 'package:aqua/pages/Login.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:simple_animations/simple_animations.dart';

void main() => runApp(const AquaSaverApp());

class AquaSaverApp extends StatelessWidget {
  const AquaSaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Saver',
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screen = MediaQuery.of(context).size;

          return Stack(
            children: [
              // Animated waves background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screen.height * 1.5,
                child: const AnimatedWaves(),
              ),

              // Decorative water drops
              const Positioned.fill(child: DropDecorations()),

              // Main scrollable content
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: SafeArea(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            SizedBox(height: screen.height * 0.08),
                            FadeIn(
                              delay: 300,
                              child: const Icon(
                                Icons.water_drop,
                                size: 100,
                                color: Colors.blueAccent,
                              ),
                            ),
                            SizedBox(height: screen.height * 0.02),
                            FadeIn(
                              delay: 600,
                              child: const Text(
                                'AquaSense',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            FadeIn(
                              delay: 800,
                              child: const Text(
                                'Water Monitoring System',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                            SizedBox(height: screen.height * 0.45),
                            // Move the motivational quote below the button instead
                            FadeIn(
                              delay: 1300,
                              child: Container(
                                width: screen.width * 0.5,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: screen.height * 0.03),
                            FadeIn(
                              delay: 1500,
                              child: const Text(
                                'When it comes to H2O\nWe do not go with the flow',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AnimatedWaves extends StatelessWidget {
  const AnimatedWaves({super.key});

  @override
  Widget build(BuildContext context) {
    return LoopAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 2 * pi),
      duration: const Duration(seconds: 5),
      builder: (context, value, child) {
        return CustomPaint(painter: AnimatedWavePainter(value));
      },
    );
  }
}

class AnimatedWavePainter extends CustomPainter {
  final double wavePhase;
  AnimatedWavePainter(this.wavePhase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.lightBlueAccent.shade200;
    final path = Path();

    double baseHeight = size.height;
    double waveHeight = max(size.height * 0.3, 120);

    path.moveTo(0, baseHeight);
    for (double i = 0; i <= size.width; i++) {
      double y = baseHeight - waveHeight + sin(wavePhase + i * 0.02) * 20;
      path.lineTo(i, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FadeIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const FadeIn({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return PlayAnimationBuilder<double>(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 700),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, _) {
        return Opacity(opacity: value, child: child);
      },
    );
  }
}

class DropDecorations extends StatelessWidget {
  const DropDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final random = Random();
    final dropletCount = 200;

    return IgnorePointer(
      child: Stack(
        children: List.generate(dropletCount, (index) {
          final top = screen.height * 0.1 + (index * 60);
          final left =
              (index.isEven ? index * 30 : index * 25).toDouble() %
              screen.width;
          final size = random.nextDouble() * 50;
          final opacity = 0.1 + random.nextDouble() * 0.3;
          return Positioned(
            top: top,
            left: left,
            child: Opacity(
              opacity: opacity,
              child: Icon(Icons.water_drop, color: Colors.white, size: size),
            ),
          );
        }),
      ),
    );
  }
}
