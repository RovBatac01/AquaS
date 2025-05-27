import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'package:aqua/components/colors.dart';

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
      home: const SAdminDetails(),
    );
  }
}

class SAdminDetails extends StatefulWidget {
  const SAdminDetails({super.key});

  @override
  State<SAdminDetails> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<SAdminDetails> {
  String selectedStat = "Temp";
  double progress = 28 / 100;
  String label = "28°C";
  Color indicatorColor = Colors.green; // Default to green for good quality
  String quality = "good"; // Track quality: 'good', 'bad', 'warning'

  void updateIndicator(String stat) {
    setState(() {
      selectedStat = stat;
      switch (stat) {
        case "Temp":
          progress = 28 / 100;
          label = "28°C";
          if (28 >= 10 && 28 <= 35) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (28 < 10 || 28 > 40) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "TDS":
          progress = 35 / 100;
          label = "35 PPM";
          if (35 >= 0 && 35 <= 300) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (35 > 500) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "pH":
          progress = 7.2 / 14;
          label = "pH 7.2";
          if (7.2 >= 6.5 && 7.2 <= 8.5) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (7.2 < 5.5 || 7.2 > 9.5) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "Turbidity":
          progress = 0.5 / 10;
          label = "0.5 NTU";
          if (0.5 <= 1) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (0.5 > 5) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "Conductivity":
          progress = 35 / 100;
          label = "35 PPM";
          if (35 >= 0 && 35 <= 100) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (35 > 200) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "Salinity":
          progress = 0.7;
          label = "0.7 ppt";
          if (0.7 < 1) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (0.7 > 2) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
        case "Electrical Conductivity (Condensed)":
          progress = 400 / 1000;
          label = "400 mV";
          if (400 < 500) {
            indicatorColor = Colors.green;
            quality = "good";
          } else if (400 > 800) {
            indicatorColor = Colors.red;
            quality = "bad";
          } else {
            indicatorColor = Colors.orange;
            quality = "warning";
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home Water Tank',
                style: TextStyle(
                  color: ASColor.getTextColor(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Montserrat',
                ),
              ),

              Text(
                "Device Status: Connected",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green,
                  fontFamily: 'Poppins',
                ),
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

              Text(
                "Water quality: Great",
                style: TextStyle(
                  color: ASColor.getTextColor(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
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
                          onTap: () => updateIndicator("Conductivity"),
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
                          isSelected:
                              selectedStat ==
                              "Electrical Conductivity (Condensed)",
                          onTap:
                              () => updateIndicator(
                                "Electrical Conductivity (Condensed)",
                              ),
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
    Color textColor = isDarkMode ? ASColor.txt1Color : ASColor.txt2Color;

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
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor, // Apply the textColor here
                  fontFamily: 'Poppins',
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

    // Solid progress circle (no gradient)
    final progressPaint =
        Paint()
          ..color = color
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
      progressPaint,
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
