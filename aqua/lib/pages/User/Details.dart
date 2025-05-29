import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding

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
      debugShowCheckedModeBanner: false,
      home: const DetailsScreen(),
    );
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnectedNoData, // No new data received (same as previous)
  disconnectedNetworkError, // Failed to fetch data (network issue, server down, etc.)
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  String selectedStat =
      "Temp"; // Currently selected statistic for the circular indicator

  // State variables to hold the latest fetched RAW data for each parameter
  double _latestTemp = 0.0;
  double _latestTDS = 0.0;
  double _latestPH = 0.0;
  double _latestTurbidity = 0.0;
  double _latestConductivity = 0.0;
  double _latestSalinity = 0.0;
  double _latestECCompensated = 0.0;

  // Connection and Error State
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;

  // To detect if data is the same as the previous fetch
  Map<String, dynamic>? _lastSuccessfulDataPayload;

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

  // Helper to create a comparable payload from current data
  Map<String, dynamic> _createCurrentDataPayload() {
    return {
      "temp": _latestTemp,
      "tds": _latestTDS,
      "ph": _latestPH,
      "turbidity": _latestTurbidity,
      "conductivity": _latestConductivity,
      "salinity": _latestSalinity,
      "ec_compensated": _latestECCompensated,
    };
  }

  // Fetches the latest data (raw value only) for all water quality parameters
  Future<void> _fetchLatestDataForAllStats() async {
    // Set status to connecting/fetching while data is being fetched
    if (_connectionStatus != ConnectionStatus.connecting) {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
        _errorMessage = null;
      });
    }

    try {
      // Fetch data for each statistic
      final temp = await _waterQualityService.fetchHistoricalData(
        "Temp",
        "Daily",
      );
      final tds = await _waterQualityService.fetchHistoricalData(
        "TDS",
        "Daily",
      );
      final ph = await _waterQualityService.fetchHistoricalData(
        "pH Level",
        "Daily",
      );
      final turbidity = await _waterQualityService.fetchHistoricalData(
        "Turbidity",
        "Daily",
      );
      final conductivity = await _waterQualityService.fetchHistoricalData(
        "Conductivity",
        "Daily",
      );
      final salinity = await _waterQualityService.fetchHistoricalData(
        "Salinity",
        "Daily",
      );
      final ecCompensated = await _waterQualityService.fetchHistoricalData(
        "EC",
        "Daily",
      );

      // Check if any data was actually received
      if (temp.isEmpty ||
          tds.isEmpty ||
          ph.isEmpty ||
          turbidity.isEmpty ||
          conductivity.isEmpty ||
          salinity.isEmpty ||
          ecCompensated.isEmpty) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNoData;
          _errorMessage = "No data received from one or more sensors.";
        });
        return; // Exit if no data
      }

      // Update latest values
      final newTemp = temp.first.value;
      final newTDS = tds.first.value;
      final newPH = ph.first.value;
      final newTurbidity = turbidity.first.value;
      final newConductivity = conductivity.first.value;
      final newSalinity = salinity.first.value;
      final newECCompensated = ecCompensated.first.value;

      // Create a payload from the newly fetched data for comparison
      final newPayload = {
        "temp": newTemp,
        "tds": newTDS,
        "ph": newPH,
        "turbidity": newTurbidity,
        "conductivity": newConductivity,
        "salinity": newSalinity,
        "ec_compensated": newECCompensated,
      };

      // Compare with the last successful payload
      if (_lastSuccessfulDataPayload != null &&
          jsonEncode(_lastSuccessfulDataPayload) == jsonEncode(newPayload)) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNoData;
          _errorMessage = "No New Data";
        });
      } else {
        // Data is new or this is the first successful fetch
        _latestTemp = newTemp;
        _latestTDS = newTDS;
        _latestPH = newPH;
        _latestTurbidity = newTurbidity;
        _latestConductivity = newConductivity;
        _latestSalinity = newSalinity;
        _latestECCompensated = newECCompensated;

        _lastSuccessfulDataPayload = newPayload; // Store the new payload

        setState(() {
          _connectionStatus = ConnectionStatus.connected;
          _errorMessage = null;
          _updateCircularIndicatorValues(); // Update the UI with new values
        });
      }
    } catch (e) {
      print('ERROR fetching latest data: $e'); // Debugging print
      setState(() {
        _connectionStatus = ConnectionStatus.disconnectedNetworkError;
        _errorMessage = 'Failed to load latest data: ${e.toString()}';
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
    const double maxTemp = 100.0; // Max expected temperature for 100% progress
    const double maxTDS = 100.0; // Max expected TDS for 100% progress
    const double maxPH = 14.0; // Max pH scale
    const double maxTurbidity = 100.0; // Max turbidity percentage (0-100%)
    const double maxConductivity = 100.0; // Max expected conductivity in mS/cm
    const double maxSalinity = 100.0; // Max expected salinity in ppt
    const double maxECCompensated =
        100.0; // Max expected compensated EC in mS/cm

    switch (selectedStat) {
      case "Temp":
        currentProgress = _latestTemp / maxTemp;
        currentLabel = "${_latestTemp.toStringAsFixed(1)}°C";
        currentColor = Colors.blue; // Example color
        break;
      case "TDS":
        currentProgress = _latestTDS / maxTDS;
        currentLabel = "${_latestTDS.toStringAsFixed(1)} PPM";
        currentColor = Colors.green; // Example color
        break;
      case "pH":
        currentProgress = _latestPH / maxPH;
        currentLabel = "pH ${_latestPH.toStringAsFixed(1)}";
        currentColor = Colors.purple; // Example color
        break;
      case "Turbidity":
        currentProgress = _latestTurbidity / maxTurbidity;
        currentLabel = "${_latestTurbidity.toStringAsFixed(1)}%";
        currentColor = Colors.orange; // Example color
        break;
      case "Conductivity":
        currentProgress = _latestConductivity / maxConductivity;
        currentLabel = "${_latestConductivity.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.red; // Example color
        break;
      case "Salinity":
        currentProgress = _latestSalinity / maxSalinity;
        currentLabel = "${_latestSalinity.toStringAsFixed(1)} ppt";
        currentColor = Colors.teal; // Example color
        break;
      case "Electrical Conductivity (Condensed)":
        currentProgress = _latestECCompensated / maxECCompensated;
        currentLabel = "${_latestECCompensated.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.indigo; // Example color
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

  // Helper to get connection status message
  String _getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.connecting:
        return "Device Status: Connecting...";
      case ConnectionStatus.connected:
        return "Device Status: Connected";
      case ConnectionStatus.disconnectedNoData:
        return "Device Status: Disconnected (No New Data)";
      case ConnectionStatus.disconnectedNetworkError:
        return "Device Status: Disconnected (Network Error)";
    }
  }

  // Helper to get connection status color
  Color _getConnectionStatusColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.disconnectedNoData:
        return Colors.red;
      case ConnectionStatus.disconnectedNetworkError:
        return Colors.red;
    }
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
              Text(
                'Home Water Tank',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                _getConnectionStatusText(),
                style: TextStyle(
                  fontSize: 18,
                  color: _getConnectionStatusColor(),
                ),
              ),
              const SizedBox(height: 20),

              // Circular Indicator
              Center(
                child:
                    _connectionStatus == ConnectionStatus.connecting
                        ? const CircularProgressIndicator() // Show loading for indicator
                        : CustomPaint(
                          size: const Size(250, 250),
                          painter: CircularIndicator(
                            progress: progress,
                            label: label,
                            color: indicatorColor,
                            brightness: Theme.of(context).brightness,
                            // If disconnected, show a specific message in the indicator
                            disconnectedMessage:
                                _connectionStatus != ConnectionStatus.connected
                                    ? (_errorMessage ?? "Disconnected")
                                    : null,
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              // Water Quality Status text
              Text(
                _connectionStatus == ConnectionStatus.connected
                    ? "Water quality: Live Reading"
                    : "Water quality: Not Live",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color:
                      _connectionStatus == ConnectionStatus.connected
                          ? Colors.black
                          : Colors.red,
                  fontFamily: 'Poppins',
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(fontSize: 14, color: Colors.red),
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
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestTemp.toStringAsFixed(1)}°C"
                                  : "...",
                          isSelected: selectedStat == "Temp",
                          onTap: () => _onStatCardTap("Temp"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.water,
                          label: "TDS",
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestTDS.toStringAsFixed(1)} PPM"
                                  : "...",
                          isSelected: selectedStat == "TDS",
                          onTap: () => _onStatCardTap("TDS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.opacity,
                          label: "pH",
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestPH.toStringAsFixed(1)}"
                                  : "...",
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
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestTurbidity.toStringAsFixed(1)}%"
                                  : "...",
                          isSelected: selectedStat == "Turbidity",
                          onTap: () => _onStatCardTap("Turbidity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.flash_on,
                          label: "Conductivity",
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestConductivity.toStringAsFixed(1)} mS/cm"
                                  : "...",
                          isSelected: selectedStat == "Conductivity",
                          onTap: () => _onStatCardTap("Conductivity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.bubble_chart,
                          label: "Salinity",
                          value:
                              _connectionStatus == ConnectionStatus.connected
                                  ? "${_latestSalinity.toStringAsFixed(1)} ppt"
                                  : "...",
                          isSelected: selectedStat == "Salinity",
                          onTap: () => _onStatCardTap("Salinity"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  StatCard(
                    icon: Icons.battery_charging_full,
                    label: "Electrical Conductivity (Condensed)",
                    value:
                        _connectionStatus == ConnectionStatus.connected
                            ? "${_latestECCompensated.toStringAsFixed(1)} mS/cm"
                            : "...",
                    isSelected:
                        selectedStat == "Electrical Conductivity (Condensed)",
                    onTap:
                        () => _onStatCardTap(
                          "Electrical Conductivity (Condensed)",
                        ),
                    width: double.infinity,
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
  final double? width;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isSelected,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine container width
    double cardWidth = width ?? 0.0; // If no width provided, let parent decide

    Color bgColor =
        isSelected
            ? Colors.greenAccent.withOpacity(0.8)
            : isDarkMode
            ? Colors.grey[800]!
            : Colors.white;

    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          width: cardWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, size: 30, color: textColor),
                const SizedBox(height: 10),
                Text(label, style: TextStyle(fontSize: 14, color: textColor)),
                const SizedBox(height: 5),
                Text(
                  value, // Display the raw value
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
      ),
    );
  }
}

class CircularIndicator extends CustomPainter {
  final double progress;
  final String label;
  final Color color;
  final Brightness brightness;
  final String? disconnectedMessage; // New: Message to show when disconnected

  CircularIndicator({
    super.repaint, // Add super.repaint
    required this.progress,
    required this.label,
    required this.color,
    required this.brightness,
    this.disconnectedMessage,
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

    // Only draw the arc if connected, otherwise show a flat circle or nothing
    if (disconnectedMessage == null) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        gradientPaint,
      );
    }

    final textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;

    // Display disconnected message if applicable, otherwise display label
    final displayLabel = disconnectedMessage ?? label;
    final displayFontSize = disconnectedMessage != null ? 18.0 : 26.0;
    final displayFontWeight =
        disconnectedMessage != null ? FontWeight.normal : FontWeight.bold;
    final displayColor = disconnectedMessage != null ? Colors.red : textColor;

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayLabel,
        style: TextStyle(
          fontSize: displayFontSize,
          fontWeight: displayFontWeight,
          color: displayColor,
          shadows: const [
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
  bool shouldRepaint(CircularIndicator oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.label != label ||
        oldDelegate.color != color ||
        oldDelegate.brightness != brightness ||
        oldDelegate.disconnectedMessage != disconnectedMessage;
  }
}
