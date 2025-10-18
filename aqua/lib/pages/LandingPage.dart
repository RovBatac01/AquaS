import 'package:aqua/pages/Login.dart';
import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:simple_animations/simple_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: ASColor.Background(context),
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
                child: AnimatedWaves(isDarkMode: isDarkMode),
              ),

              // Decorative water drops
              Positioned.fill(child: DropDecorations(isDarkMode: isDarkMode)),

              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(
                              color: isDarkMode 
                                  ? Colors.white.withOpacity(0.2) 
                                  : Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo - Minimal Blue Droplet
                              FadeIn(
                                delay: 300,
                                child: Container(
                                  width: 70.w,
                                  height: 70.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.water_drop,
                                    size: 36.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.h),
                              
                              // Title
                              FadeIn(
                                delay: 600,
                                child: Text(
                                  'AquaSense',
                                  style: TextStyle(
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              
                              // Subtitle
                              FadeIn(
                                delay: 800,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    'Water Monitoring System',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Poppins',
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 32.h),
                              
                              // Get Started Button
                              FadeIn(
                                delay: 1000,
                                child: Container(
                                  width: double.infinity,
                                  height: 54.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                    ),
                                    child: Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 24.h),
                              
                              // Tagline
                              FadeIn(
                                delay: 1200,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Text(
                                    'When it comes to H₂O\nWe do not go with the flow',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontFamily: 'Poppins',
                                      color: isDarkMode 
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.black45,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
  final bool isDarkMode;
  const AnimatedWaves({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return LoopAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 2 * pi),
      duration: const Duration(seconds: 5),
      builder: (context, value, child) {
        return CustomPaint(painter: AnimatedWavePainter(value, isDarkMode));
      },
    );
  }
}

class AnimatedWavePainter extends CustomPainter {
  final double wavePhase;
  final bool isDarkMode;
  AnimatedWavePainter(this.wavePhase, this.isDarkMode);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              isDarkMode
                  ? Colors.lightBlue.shade800
                  : Colors.lightBlueAccent.shade200;
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
  final bool isDarkMode;
  const DropDecorations({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final random = Random();
    final dropletCount = 200; // or your preferred number

    // Place droplets within the visible wave area at the bottom of the screen
    final double waveTop =
        screen.height * 0.6; // Start of the visible wave area
    final double waveBottom =
        screen.height * 0.98; // Just above the bottom edge

    return IgnorePointer(
      child: Stack(
        children: List.generate(dropletCount, (index) {
          // Only place droplets within the wave area
          final top = waveTop + random.nextDouble() * (waveBottom - waveTop);
          final left = random.nextDouble() * screen.width;
          final size = random.nextDouble() * 50;
          final opacity = 0.1 + random.nextDouble() * 0.3;
          return Positioned(
            top: top,
            left: left,
            child: Opacity(
              opacity: opacity,
              child: Icon(
                Icons.water_drop,
                color: isDarkMode ? Colors.white24 : Colors.white,
                size: size,
              ),
            ),
          );
        }),
      ),
    );
  }
}
