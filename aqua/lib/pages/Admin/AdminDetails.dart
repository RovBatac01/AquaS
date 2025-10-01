import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding


import 'package:aqua/water_quality_service.dart';

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
        currentLabel = "${_latestTDS.toStringAsFixed(1)} %";
        currentColor = _getIndicatorColor(selectedStat, _latestTDS);
        break;
      case "pH":
        targetProgress = _latestPH / maxPH;
        currentLabel = "pH ${_latestPH.toStringAsFixed(1)}";
        currentColor = Colors.purple;
        break;
      case "Turbidity":
        targetProgress = _latestTurbidity / maxTurbidity;
        currentLabel = "${_latestTurbidity.toStringAsFixed(1)} %";
        currentColor = _getIndicatorColor(selectedStat, _latestTurbidity);
        break;
      case "Conductivity":
        targetProgress = _latestConductivity / maxConductivity;
        currentLabel = "${_latestConductivity.toStringAsFixed(1)} %";
        currentColor = _getIndicatorColor(selectedStat, _latestConductivity);
        break;
      case "Salinity":
        targetProgress = _latestSalinity / maxSalinity;
        currentLabel = "${_latestSalinity.toStringAsFixed(1)} %";
        currentColor = _getIndicatorColor(selectedStat, _latestSalinity);
        break;
      case "Electrical Conductivity (Condensed)":
        targetProgress = _latestECCompensated / maxECCompensated;
        currentLabel = "${_latestECCompensated.toStringAsFixed(1)} %";
        currentColor = _getIndicatorColor(selectedStat, _latestECCompensated);
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



  // New function to determine color based on value and parameter ranges
  Color _getIndicatorColor(String stat, double value) {
    switch (stat) {
      case "TDS":
        if (value <= 30) return Colors.red; // Excellent
        if (value <= 70) return Colors.yellow; // Good
        if (value <= 99) return Colors.lightGreen; // Moderate
        return Colors.green; // Critical/Poor
      case "Turbidity":
        if (value <= 30) return Colors.red; // Excellent
        if (value <= 70) return Colors.yellow; // Good
        if (value <= 99) return Colors.lightGreen; // Moderate
        return Colors.green; // Critical/Poor
      case "Conductivity":
        if (value <= 30) return Colors.red; // Excellent
        if (value <= 70) return Colors.yellow; // Good
        if (value <= 99) return Colors.lightGreen; // Moderate
        return Colors.green; // Critical/Poor
      case "Salinity":
        if (value <= 30) return Colors.red; // Excellent
        if (value <= 70) return Colors.yellow; // Good
        if (value <= 99) return Colors.lightGreen; // Moderate
        return Colors.green; // Critical/Poor
      case "Electrical Conductivity (Condensed)":
        if (value <= 30) return Colors.red; // Excellent
        if (value <= 70) return Colors.yellow; // Good
        if (value <= 99) return Colors.lightGreen; // Moderate
        return Colors.green; // Critical/Poor
      default:
        // Temp and pH use a different logic
        return Colors.green;
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String? disconnectedMessageForIndicator;
    if (_connectionStatus == ConnectionStatus.disconnectedNetworkError) {
      disconnectedMessageForIndicator = "Network Error";
    } else if (_connectionStatus == ConnectionStatus.disconnectedNoData) {
      disconnectedMessageForIndicator = "No New Data";
    }

    bool displayLiveValues = _connectionStatus == ConnectionStatus.connected ||
        _connectionStatus == ConnectionStatus.disconnectedNoData;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Water Quality Monitor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getConnectionStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getConnectionStatusColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getConnectionStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connectionStatus == ConnectionStatus.connected
                      ? 'Live'
                      : _connectionStatus == ConnectionStatus.connecting
                          ? 'Connecting'
                          : 'Offline',
                  style: TextStyle(
                    color: _getConnectionStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.business_rounded,
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
                                  'Home Water Tank',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Real-time water quality monitoring',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    fontFamily: 'Poppins',
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
                
                const SizedBox(height: 24),
                
                // Enhanced Circular Indicator
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Current Reading',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: !_hasInitialDataLoaded && _connectionStatus == ConnectionStatus.connecting
                            ? const CircularProgressIndicator()
                            : AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: indicatorColor.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: CustomPaint(
                                      size: const Size(280, 280),
                                      painter: CircularIndicator(
                                        progress: _progressAnimation.value,
                                        label: label,
                                        color: indicatorColor,
                                        brightness: Theme.of(context).brightness,
                                        disconnectedMessage: disconnectedMessageForIndicator,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _connectionStatus == ConnectionStatus.connected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _connectionStatus == ConnectionStatus.connected
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _connectionStatus == ConnectionStatus.connected
                              ? "🟢 Live monitoring active"
                              : "🔴 Connection lost",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _connectionStatus == ConnectionStatus.connected
                                ? Colors.green
                                : Colors.red,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error: $_errorMessage',
                                    style: const TextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Enhanced Parameters Section
                Text(
                  'Water Parameters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Enhanced Stats Grid
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.thermostat_rounded,
                            label: "Temperature",
                            value: displayLiveValues ? "${_latestTemp.toStringAsFixed(1)}" : "---",
                            unit: "°C",
                            isSelected: selectedStat == "Temp",
                            onTap: () => _onStatCardTap("Temp"),
                            color: Colors.orange,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.water_drop_rounded,
                            label: "TDS",
                            value: displayLiveValues ? "${_latestTDS.toStringAsFixed(1)}" : "---",
                            unit: "PPM",
                            isSelected: selectedStat == "TDS",
                            onTap: () => _onStatCardTap("TDS"),
                            color: Colors.blue,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.science_rounded,
                            label: "pH Level",
                            value: displayLiveValues ? "${_latestPH.toStringAsFixed(1)}" : "---",
                            unit: "pH",
                            isSelected: selectedStat == "pH",
                            onTap: () => _onStatCardTap("pH"),
                            color: Colors.purple,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.visibility_rounded,
                            label: "Turbidity",
                            value: displayLiveValues ? "${_latestTurbidity.toStringAsFixed(1)}" : "---",
                            unit: "%",
                            isSelected: selectedStat == "Turbidity",
                            onTap: () => _onStatCardTap("Turbidity"),
                            color: Colors.brown,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.flash_on_rounded,
                            label: "Conductivity",
                            value: displayLiveValues ? "${_latestConductivity.toStringAsFixed(1)}" : "---",
                            unit: "mS/cm",
                            isSelected: selectedStat == "Conductivity",
                            onTap: () => _onStatCardTap("Conductivity"),
                            color: Colors.amber,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: EnhancedStatCard(
                            icon: Icons.grain_rounded,
                            label: "Salinity",
                            value: displayLiveValues ? "${_latestSalinity.toStringAsFixed(1)}" : "---",
                            unit: "ppt",
                            isSelected: selectedStat == "Salinity",
                            onTap: () => _onStatCardTap("Salinity"),
                            color: Colors.teal,
                            isDarkMode: isDarkMode,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: EnhancedStatCard(
                        icon: Icons.electrical_services_rounded,
                        label: "EC Compensated",
                        value: displayLiveValues ? "${_latestECCompensated.toStringAsFixed(1)}" : "---",
                        unit: "mS/cm",
                        isSelected: selectedStat == "Electrical Conductivity (Condensed)",
                        onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
                        color: Colors.indigo,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnhancedStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final VoidCallback onTap;
  final bool isSelected;
  final Color color;
  final bool isDarkMode;

  const EnhancedStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.onTap,
    required this.isSelected,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : isDarkMode
                  ? Colors.grey[800]
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: color,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Poppins',
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