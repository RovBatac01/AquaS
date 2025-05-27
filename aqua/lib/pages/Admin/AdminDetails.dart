import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer

import 'package:aqua/water_quality_model.dart'; // Corrected import path
import 'package:aqua/water_quality_service.dart'; // Corrected import path
import 'package:aqua/components/colors.dart'; // Assuming you have this file for ASColor

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Quality',
      debugShowCheckedModeBanner: false, // Removed theme: ThemeData(primarySwatch: Colors.blue) for consistency with previous versions
      home: const AdminDetailsScreen(),
    );
  }
}

class AdminDetailsScreen extends StatefulWidget {
  const AdminDetailsScreen({super.key});

  @override
  State<AdminDetailsScreen> createState() => _AdminDetailsScreenState(); // Changed to _AdminDetailsScreenState
}

class _AdminDetailsScreenState extends State<AdminDetailsScreen> { // Changed to _AdminDetailsScreenState
  String selectedStat = "Temp"; // Currently selected statistic for the circular indicator

  // State variables to hold the latest fetched RAW data for each parameter
  double _latestTemp = 0.0;
  double _latestTDS = 0.0;
  double _latestPH = 0.0;
  double _latestTurbidity = 0.0;
  double _latestConductivity = 0.0; // Corresponds to 'ec_value_mS'
  double _latestSalinity = 0.0;
  double _latestECCompensated = 0.0; // Corresponds to 'ec_compensated_mS'

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timer; // Timer for auto-refresh

  final WaterQualityService _waterQualityService = WaterQualityService();

  @override
  void initState() {
    super.initState();
    _fetchLatestDataForAllStats(); // Initial fetch
    // Set up a timer to fetch data every 1 second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _fetchLatestDataForAllStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }

  // Fetches the latest data (raw value only) for all water quality parameters
  Future<void> _fetchLatestDataForAllStats() async {
    if (_isLoading) {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      // Fetch data for each statistic and update the corresponding state variable
      // We fetch 'Daily' (24h) and take the first element, assuming it's the most recent.
      final temp = await _waterQualityService.fetchHistoricalData("Temp", "Daily");
      if (temp.isNotEmpty) {
        _latestTemp = temp.first.value;
      }

      final tds = await _waterQualityService.fetchHistoricalData("TDS", "Daily");
      if (tds.isNotEmpty) {
        _latestTDS = tds.first.value;
      }

      final ph = await _waterQualityService.fetchHistoricalData("pH Level", "Daily");
      if (ph.isNotEmpty) {
        _latestPH = ph.first.value;
      }

      final turbidity = await _waterQualityService.fetchHistoricalData("Turbidity", "Daily");
      if (turbidity.isNotEmpty) {
        _latestTurbidity = turbidity.first.value;
      }

      final conductivity = await _waterQualityService.fetchHistoricalData("Conductivity", "Daily");
      if (conductivity.isNotEmpty) {
        _latestConductivity = conductivity.first.value;
      }

      final salinity = await _waterQualityService.fetchHistoricalData("Salinity", "Daily");
      if (salinity.isNotEmpty) {
        _latestSalinity = salinity.first.value;
      }

      final ecCompensated = await _waterQualityService.fetchHistoricalData("EC", "Daily");
      if (ecCompensated.isNotEmpty) {
        _latestECCompensated = ecCompensated.first.value;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = null;
        // Update the circular indicator based on the currently selected stat
        _updateCircularIndicatorValues();
      });
    } catch (e) {
      print('ERROR fetching latest data: $e'); // Debugging print
      setState(() {
        _errorMessage = 'Failed to load latest data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Helper to update the circular indicator's progress, label, and color
  // based on the current `selectedStat` and the fetched `_latestX` values.
  void _updateCircularIndicatorValues() {
    double currentProgress = 0.0;
    String currentLabel = "N/A";
    Color currentColor = Colors.blue; // Default color for indicator

    // Define max values for progress calculation (adjust as needed for your sensors)
    // These values determine what 100% on the circular indicator represents.
    const double maxTemp = 50.0; // Example: Max expected temperature in Celsius
    const double maxTDS = 1000.0; // Example: Max expected TDS in PPM
    const double maxPH = 14.0; // Max pH scale
    const double maxTurbidity = 100.0; // Max turbidity percentage (0-100%)
    const double maxConductivity = 2.0; // Example: Max expected conductivity in mS/cm
    const double maxSalinity = 50.0; // Example: Max expected salinity in ppt
    const double maxECCompensated = 2.0; // Example: Max expected compensated EC in mS/cm


    switch (selectedStat) {
      case "Temp":
        currentProgress = _latestTemp / maxTemp;
        currentLabel = "${_latestTemp.toStringAsFixed(1)}°C";
        currentColor = Colors.blue;
        break;
      case "TDS":
        currentProgress = _latestTDS / maxTDS;
        currentLabel = "${_latestTDS.toStringAsFixed(1)} PPM";
        currentColor = Colors.green;
        break;
      case "pH":
        currentProgress = _latestPH / maxPH;
        currentLabel = "pH ${_latestPH.toStringAsFixed(1)}";
        currentColor = Colors.purple;
        break;
      case "Turbidity":
        currentProgress = _latestTurbidity / maxTurbidity;
        currentLabel = "${_latestTurbidity.toStringAsFixed(1)}%";
        currentColor = Colors.orange;
        break;
      case "Conductivity":
        currentProgress = _latestConductivity / maxConductivity;
        currentLabel = "${_latestConductivity.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.red;
        break;
      case "Salinity":
        currentProgress = _latestSalinity / maxSalinity;
        currentLabel = "${_latestSalinity.toStringAsFixed(1)} ppt";
        currentColor = Colors.teal;
        break;
      case "Electrical Conductivity (Condensed)":
        currentProgress = _latestECCompensated / maxECCompensated;
        currentLabel = "${_latestECCompensated.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.indigo;
        break;
    }

    // Ensure progress is between 0 and 1
    currentProgress = currentProgress.clamp(0.0, 1.0);

    setState(() {
      progress = currentProgress;
      label = currentLabel;
      indicatorColor = currentColor;
    });
  }

  // Update the circular indicator when a stat card is tapped
  void _onStatCardTap(String stat) {
    setState(() {
      selectedStat = stat;
      _updateCircularIndicatorValues(); // Recalculate indicator values for the new selection
    });
  }

  // Current values for the circular indicator
  double progress = 0.0;
  String label = "Loading...";
  Color indicatorColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DETAILS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
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
      body: SafeArea( // Added SafeArea for better layout on different devices
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
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _isLoading ? "Device Status: Connecting..." : "Device Status: Connected",
                style: TextStyle(
                  fontSize: 18,
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(height: 20),

              // Circular Indicator
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator() // Show loading for indicator
                    : CustomPaint(
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

              // Simplified Water Quality Status text
              Text(
                _isLoading
                    ? "Water quality: Fetching..."
                    : _errorMessage != null
                        ? "Water quality: Error"
                        : "Water quality: Live Reading", // Simplified status
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _isLoading || _errorMessage != null ? Colors.orange : Colors.black,
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
                          value: _isLoading ? "..." : "${_latestTemp.toStringAsFixed(1)}°C",
                          isSelected: selectedStat == "Temp",
                          onTap: () => _onStatCardTap("Temp"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.water,
                          label: "TDS",
                          value: _isLoading ? "..." : "${_latestTDS.toStringAsFixed(1)} PPM",
                          isSelected: selectedStat == "TDS",
                          onTap: () => _onStatCardTap("TDS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.opacity,
                          label: "pH",
                          value: _isLoading ? "..." : "${_latestPH.toStringAsFixed(1)}",
                          isSelected: selectedStat == "pH",
                          onTap: () => _onStatCardTap("pH"),
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
                          value: _isLoading ? "..." : "${_latestTurbidity.toStringAsFixed(1)}%",
                          isSelected: selectedStat == "Turbidity",
                          onTap: () => _onStatCardTap("Turbidity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.flash_on,
                          label: "Conductivity",
                          value: _isLoading ? "..." : "${_latestConductivity.toStringAsFixed(1)} mS/cm",
                          isSelected: selectedStat == "Conductivity",
                          onTap: () => _onStatCardTap("Conductivity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.bubble_chart,
                          label: "Salinity",
                          value: _isLoading ? "..." : "${_latestSalinity.toStringAsFixed(1)} ppt",
                          isSelected: selectedStat == "Salinity",
                          onTap: () => _onStatCardTap("Salinity"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.battery_charging_full,
                          label: "Electrical Conductivity (Condensed)",
                          value: _isLoading ? "..." : "${_latestECCompensated.toStringAsFixed(1)} mS/cm",
                          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
                          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
                        ),
                      ),
                      // Added empty Expanded widgets to fill space for a consistent 3-column layout
                      const Expanded(child: SizedBox.shrink()),
                      const Expanded(child: SizedBox.shrink()),
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color bgColor =
        isSelected
            ? Colors.greenAccent.withOpacity(0.8)
            : isDarkMode
                ? Colors.grey[800]!
                : Colors.white;

    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [ // Added const for performance
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
                color: textColor,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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

    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, backgroundPaint);

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

    final textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textColor,
          shadows: const [ // Added const for performance
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
