import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding


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
      home: const AdminDetailsScreen(),
    );
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnectedNoData, // No new data received (same as previous)
  disconnectedNetworkError, // Failed to fetch data (network issue, server down, etc.)
}

class AdminDetailsScreen extends StatefulWidget {
  const AdminDetailsScreen({super.key});

  @override
  State<AdminDetailsScreen> createState() => _AdminDetailsState();
}

class _AdminDetailsState extends State<AdminDetailsScreen> with SingleTickerProviderStateMixin {
  // Add SingleTickerProviderStateMixin for AnimationController

  String selectedStat = "Temp"; // Currently selected statistic for the circular indicator

  // State variables to hold the latest fetched RAW data for each parameter
  double _latestTemp = 0.0;
  double _latestTDS = 0.0;
  double _latestPH = 0.0;
  double _latestTurbidity = 0.0;
  double _latestConductivity = 0.0; // Corresponds to 'ec_value_mS'
  double _latestSalinity = 0.0;
  double _latestECCompensated = 0.0; // Corresponds to 'ec_compensated_mS'

  // Connection and Error State
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;

  // To detect if data is the same as the previous fetch
  Map<String, dynamic>? _lastSuccessfulDataPayload;

  Timer? _timer; // Timer for auto-refresh

  final WaterQualityService _waterQualityService = WaterQualityService();

  // Current values for the circular indicator (derived from _latestX values)
  // Initialize with sensible defaults or placeholders if no data yet.
  double _currentProgress = 0.0; // Renamed to differentiate from animated value
  String label = "---"; // Changed initial label to a placeholder
  Color indicatorColor = Colors.grey; // Initial color for indicator

  // Flag to track if initial data has been loaded
  bool _hasInitialDataLoaded = false;

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Duration for smooth animation
    );

    // Initialize progress animation
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController)
      ..addListener(() {
        setState(() {
          // Update the UI as the animation progresses
          _currentProgress = _progressAnimation.value;
        });
      });

    _fetchLatestDataForAllStats(isInitialFetch: true); // Initial fetch
    // Set up a timer to fetch data every 1.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
      _fetchLatestDataForAllStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    _animationController.dispose(); // Dispose of the animation controller
    super.dispose();
  }

  // Helper to create a comparable payload from current data
  // Fetches the latest data (raw value only) for all water quality parameters
  Future<void> _fetchLatestDataForAllStats({bool isInitialFetch = false}) async {
    // Only set to connecting if we don't have any initial data displayed yet.
    // This prevents the UI from clearing during subsequent fetches.
    if (!_hasInitialDataLoaded) {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
        _errorMessage = null;
      });
    }

    try {
      final temp = await _waterQualityService.fetchHistoricalData("Temp", "Daily");
      final tds = await _waterQualityService.fetchHistoricalData("TDS", "Daily");
      final ph = await _waterQualityService.fetchHistoricalData("pH Level", "Daily");
      final turbidity = await _waterQualityService.fetchHistoricalData("Turbidity", "Daily");
      final conductivity = await _waterQualityService.fetchHistoricalData("Conductivity", "Daily");
      final salinity = await _waterQualityService.fetchHistoricalData("Salinity", "Daily");
      final ecCompensated = await _waterQualityService.fetchHistoricalData("EC", "Daily");

      // Check if any data was actually received (all lists should be non-empty)
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
          _hasInitialDataLoaded = true; // Mark as loaded even if no data
        });
        return; // Exit if no data
      }

      // Update latest values from the fetched data
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

      // Compare with the last successful payload using jsonEncode for deep comparison
      if (_lastSuccessfulDataPayload != null &&
          jsonEncode(_lastSuccessfulDataPayload) == jsonEncode(newPayload)) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNoData;
          _errorMessage = "No new data received from device.";
          _hasInitialDataLoaded = true; // Mark as loaded
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
          _hasInitialDataLoaded = true; // Mark as loaded
          _updateCircularIndicatorValues(); // Update the UI with new values
        });
      }
    } catch (e) {
      print('ERROR fetching latest data: $e'); // Debugging print
      setState(() {
        _connectionStatus = ConnectionStatus.disconnectedNetworkError;
        _errorMessage = 'Failed to load latest data: ${e.toString()}';
        _hasInitialDataLoaded = true; // Mark as loaded even on error
      });
    }
  }

  // Helper to update the circular indicator's progress, label, and color
  // based on the current `selectedStat` and the fetched `_latestX` values.
  void _updateCircularIndicatorValues() {
    double targetProgress = 0.0; // This will be the target for the animation
    String currentLabel = "N/A";
    Color currentColor = Colors.blue; // Default color for indicator

    // Define max values for progress calculation (adjust as needed for your sensors)
    const double maxTemp = 100.0; // Max expected temperature for 100% progress
    const double maxTDS = 1000.0; // Adjusted max TDS to a more realistic value (e.g., 1000 PPM)
    const double maxPH = 14.0; // Max pH scale
    const double maxTurbidity = 100.0; // Max turbidity percentage (0-100%)
    const double maxConductivity = 10.0; // Adjusted max conductivity (e.g., 10 mS/cm)
    const double maxSalinity = 40.0; // Adjusted max salinity (e.g., 40 ppt for seawater)
    const double maxECCompensated = 10.0; // Adjusted max compensated EC (e.g., 10 mS/cm)

    switch (selectedStat) {
      case "Temp":
        targetProgress = _latestTemp / maxTemp;
        currentLabel = "${_latestTemp.toStringAsFixed(1)}°C";
        currentColor = Colors.blue;
        break;
      case "TDS":
        targetProgress = _latestTDS / maxTDS;
        currentLabel = "${_latestTDS.toStringAsFixed(1)} PPM";
        currentColor = Colors.green;
        break;
      case "pH":
        targetProgress = _latestPH / maxPH;
        currentLabel = "pH ${_latestPH.toStringAsFixed(1)}";
        currentColor = Colors.purple;
        break;
      case "Turbidity":
        targetProgress = _latestTurbidity / maxTurbidity;
        currentLabel = "${_latestTurbidity.toStringAsFixed(1)}%";
        currentColor = Colors.orange;
        break;
      case "Conductivity":
        targetProgress = _latestConductivity / maxConductivity;
        currentLabel = "${_latestConductivity.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.red;
        break;
      case "Salinity":
        targetProgress = _latestSalinity / maxSalinity;
        currentLabel = "${_latestSalinity.toStringAsFixed(1)} ppt";
        currentColor = Colors.teal;
        break;
      case "Electrical Conductivity (Condensed)":
        targetProgress = _latestECCompensated / maxECCompensated;
        currentLabel = "${_latestECCompensated.toStringAsFixed(1)} mS/cm";
        currentColor = Colors.indigo;
        break;
    }

    // Ensure targetProgress is between 0 and 1
    targetProgress = targetProgress.clamp(0.0, 1.0);

    // Animate the progress
    _animationController.reset();
    _progressAnimation = Tween<double>(
      begin: _currentProgress, // Start from the current animated value
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut, // Smooth curve for animation
    ));
    _animationController.forward();

    setState(() {
      // We don't set _currentProgress directly here, it's updated by the listener
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
    // Determine the disconnected message for the circular indicator
    String? disconnectedMessageForIndicator;
    if (_connectionStatus == ConnectionStatus.disconnectedNoData) {
      disconnectedMessageForIndicator = "No New Data";
    } else if (_connectionStatus == ConnectionStatus.disconnectedNetworkError) {
      disconnectedMessageForIndicator = "Network Error";
    }

    // Determine if data values should be displayed or "..."
    bool displayLiveValues = _connectionStatus == ConnectionStatus.connected ||
        _connectionStatus == ConnectionStatus.disconnectedNoData;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
              : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header with Back Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: ASColor.getTextColor(context),
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Water Quality Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time monitoring data',
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context).withOpacity(0.7),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
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
                child: !_hasInitialDataLoaded && _connectionStatus == ConnectionStatus.connecting
                    ? const CircularProgressIndicator() // Show loading only if no data yet
                    : CustomPaint(
                        size: const Size(250, 250),
                        painter: CircularIndicator(
                          progress: _currentProgress, // Use the animated progress value
                          label: label,
                          color: indicatorColor,
                          brightness: Theme.of(context).brightness,
                          disconnectedMessage: disconnectedMessageForIndicator,
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
                  color: _connectionStatus == ConnectionStatus.connected
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
                          value: displayLiveValues
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
                          value: displayLiveValues
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
                          value: displayLiveValues
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
                          value: displayLiveValues
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
                          value: displayLiveValues
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
                          value: displayLiveValues
                              ? "${_latestSalinity.toStringAsFixed(1)} ppt"
                              : "...",
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
                          value: displayLiveValues
                              ? "${_latestECCompensated.toStringAsFixed(1)} mS/cm"
                              : "...",
                          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
                          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
  final double progress; // This will now be the animated value
  final String label;
  final Color color;
  final Brightness brightness;
  final String? disconnectedMessage;

  CircularIndicator({
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

    // Background circle
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress circle (with gradient if connected)
    final progressPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 12.0;

    if (disconnectedMessage == null) {
      progressPaint.shader = LinearGradient(
        colors: [color, Colors.greenAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress; // Use the animated progress
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final textColor =
        brightness == Brightness.light ? Colors.black : Colors.white;

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
          fontFamily: 'Poppins',
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
    // Only repaint if the progress or other properties have changed
    return oldDelegate.progress != progress ||
        oldDelegate.label != label ||
        oldDelegate.color != color ||
        oldDelegate.brightness != brightness ||
        oldDelegate.disconnectedMessage != disconnectedMessage;
  }
}