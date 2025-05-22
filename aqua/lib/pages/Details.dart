import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Quality',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.light().copyWith(
      //   primaryColor: Colors.blue,
      //   scaffoldBackgroundColor: Colors.white,
      // ),
      // themeMode:
      //     ThemeMode
      //         .light, // Uses system theme. Use ThemeMode.dark to force dark mode.
      home: const DetailsScreen(),
    );
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String selectedStat = "Temp";
  double progress = 28 / 100;
  String label = "28°C";
  Color indicatorColor = Colors.blue;

  void updateIndicator(String stat) {
    setState(() {
      selectedStat = stat;
      switch (stat) {
        case "Temp":
          progress = 28 / 100;
          label = "28°C";
          indicatorColor = Colors.blue;
          break;
        case "TDS":
          progress = 35 / 100;
          label = "35 PPM";
          indicatorColor = Colors.green;
          break;
        case "pH":
          progress = 7.2 / 14;
          label = "pH 7.2";
          indicatorColor = Colors.purple;
          break;
        case "Turbidity":
          progress = 0.5 / 10;
          label = "0.5 NTU";
          indicatorColor = Colors.orange;
          break;
        case "Conductivity":
          progress = 35 / 100;
          label = "35 PPM";
          indicatorColor = Colors.red;
          break;
        case "Salinity":
          progress = 0.7;
          label = "0.7 ppt";
          indicatorColor = Colors.teal;
          break;

        case "Electrical Conductivity (Condensed)":
          progress = 400 / 1000; // Assume 1000 mV max
          label = "400 mV";
          indicatorColor = Colors.indigo;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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

              // Circular Indicator
              Center(
                child: CustomPaint(
                  size: const Size(250, 250),
                  painter: CircularIndicator(
                    progress: progress,
                    label: label,
                    color: indicatorColor,
                    brightness: Theme.of(context).brightness,
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

              // Cards
              Column(
                children: [
                  Row(
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
                  const SizedBox(height: 12),
                  Row(
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
                          label: "Conductivity",
                          value: "35 PPM",
                          isSelected: selectedStat == "Conductivity",
                          onTap:
                              () => updateIndicator("Conductivity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.bubble_chart,
                          label: "Salinity",
                          value: "0.7 ppt",
                          isSelected: selectedStat == "Salinity",
                          onTap: () => updateIndicator("Salinity"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.battery_charging_full,
                          label: "Electrical Conductivity (Condensed)",
                          value: "400 mV",
                          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
                          onTap: () => updateIndicator("Electrical Conductivity (Condensed)"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isSelected;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Get the current theme brightness (light or dark)
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Set the background color depending on the theme
    Color bgColor =
        isSelected
            ? Colors.greenAccent.withOpacity(0.8)
            : isDarkMode
            ? Colors.grey[800]! // Dark mode background color
            : Colors.white; // Light mode background color

    // Set text color based on the theme
    Color textColor = isDarkMode ? Colors.white : Colors.black;

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
                color: textColor, // Apply the textColor here
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor, // Apply the textColor here
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Apply the textColor here
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularIndicator extends CustomPainter {
  final double progress;
  final String label;
  final Color color;
  final Brightness brightness;

  CircularIndicator({
    required this.progress,
    required this.label,
    required this.color,
    required this.brightness,
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
            colors: [color, Colors.greenAccent],
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

    // Text in center
    final textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textColor,
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
