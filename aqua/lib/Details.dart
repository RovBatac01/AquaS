import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Quality',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DetailsScreen(),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String selectedStat = "Temp";
  double progress = 28 / 100;
  String label = "28°C";
  Color indicatorColor = Colors.blue;

  void updateIndicator(String stat) {
    setState(() {
      selectedStat = stat;
      if (stat == "Temp") {
        progress = 28 / 100;
        label = "28°C";
        indicatorColor = Colors.blue;
      } else if (stat == "TDS") {
        progress = 35 / 100;
        label = "35 PPM";
        indicatorColor = Colors.green;
      } else if (stat == "pH") {
        progress = 7.2 / 14;
        label = "pH 7.2";
        indicatorColor = Colors.purple;
      } else if (stat == "Turbidity") {
        progress = 0.5 / 10;
        label = "0.5 NTU";
        indicatorColor = Colors.orange;
      } else if (stat == "Electrical Conductivity") {
        progress = 35 / 100;
        label = "35 PPM";
        indicatorColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETAILS',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            color: Colors.black,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 15),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Home Water Tank',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
            const Text(
              "Device Status: Connected",
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 20),

            // Circular Temperature Indicator with enhanced style
            Center(
              child: CustomPaint(
                size: const Size(250, 250),
                painter: CircularIndicator(
                  progress: progress,
                  label: label,
                  color: indicatorColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Water quality: Great",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal Scrollable Stats with Spacing
            Column(
              children: [
                // First row with 3 cards
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.thermostat,
                          label: "Temp",
                          value: "28°C",
                          isSelected: selectedStat == "Temp",
                          onTap: () => updateIndicator("Temp"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.water,
                          label: "TDS",
                          value: "35 PPM",
                          isSelected: selectedStat == "TDS",
                          onTap: () => updateIndicator("TDS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.opacity,
                          label: "pH",
                          value: "7.2",
                          isSelected: selectedStat == "pH",
                          onTap: () => updateIndicator("pH"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ), // Spacer between top and bottom rows
                // Second row with 2 cards
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.water_damage,
                          label: "Turbidity",
                          value: "0.5 NTU",
                          isSelected: selectedStat == "Turbidity",
                          onTap: () => updateIndicator("Turbidity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.flash_on,
                          label: "Electrical Conductivity",
                          value: "35 PPM",
                          isSelected: selectedStat == "Electrical Conductivity",
                          onTap:
                              () => updateIndicator("Electrical Conductivity"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for displaying water stats
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isSelected;

  const StatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor =
        isSelected ? Colors.blueAccent.withOpacity(0.8) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : Colors.blue,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Circular Progress Indicator
class CircularIndicator extends CustomPainter {
  final double progress;
  final String label;
  final Color color;

  CircularIndicator({
    required this.progress,
    required this.label,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 12;

    // Background circle
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient progress circle
    final gradientPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [color, Colors.lightBlueAccent],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 12.0;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Text in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          shadows: [
            Shadow(blurRadius: 5.0, color: Colors.grey, offset: Offset(2, 2)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CircularIndicator oldDelegate) => true;
}
