import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding

import 'package:aqua/water_quality_model.dart'; // Corrected import path

import '../../device_aware_service.dart'; // New device-aware service
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
  double? _latestTemp;
  double? _latestTDS;
  double? _latestPH;
  double? _latestTurbidity;
  double? _latestConductivity;
  double? _latestSalinity;
  double? _latestECCompensated;

  // Connection and Error State
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;

  // To detect if data is the same as the previous fetch
  Map<String, dynamic>? _lastSuccessfulDataPayload;

  Timer? _timer; // Timer for auto-refresh


  final DeviceAwareService _deviceService = DeviceAwareService();

  // Device management
  List<Map<String, dynamic>> _accessibleDevices = [];
  String? _currentDeviceId;
  String? _currentDeviceName;
  bool _hasMultipleDevices = false;
  List<String> _availableSensors = []; // Track which sensors are available for current device

  @override
  void initState() {
    super.initState();
    _initializeDeviceData(); // Initialize device data and set up timer
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }



  /// Initialize device data and start fetching sensor data
  Future<void> _initializeDeviceData() async {
    try {
      // Get accessible devices
      _accessibleDevices = await _deviceService.getAccessibleDevices();
      _hasMultipleDevices = _accessibleDevices.length > 1;
      
      if (_accessibleDevices.isNotEmpty) {
        // Set the first device as current
        _currentDeviceId = _accessibleDevices.first['device_id'];
        _currentDeviceName = _accessibleDevices.first['device_name'];
        
        print('DEBUG: User has access to ${_accessibleDevices.length} device(s)');
        print('DEBUG: Current device: $_currentDeviceId ($_currentDeviceName)');
        
        // Start fetching data for the current device
        _fetchLatestDataForAllStats();
        
        // Set up timer for auto-refresh
        _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
          _fetchLatestDataForAllStats();
        });
      } else {
        // No accessible devices - show error state
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNetworkError;
          _errorMessage = 'No accessible devices found. Please request device access.';
        });
      }
    } catch (e) {
      print('Error initializing device data: $e');
      setState(() {
        _connectionStatus = ConnectionStatus.disconnectedNetworkError;
        _errorMessage = 'Failed to load device information: $e';
      });
    }
  }

  /// Switch to a different device
  Future<void> _switchDevice(String deviceId, String deviceName) async {
    setState(() {
      _currentDeviceId = deviceId;
      _currentDeviceName = deviceName;
      _connectionStatus = ConnectionStatus.connecting;
    });
    
    // Fetch data for the new device
    _fetchLatestDataForAllStats();
  }

  // Fetches the latest data (raw value only) for all water quality parameters
  Future<void> _fetchLatestDataForAllStats() async {
    if (!mounted || _currentDeviceId == null) return;

    // Set status to connecting/fetching while data is being fetched
    if (_connectionStatus != ConnectionStatus.connecting) {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
        _errorMessage = null;
      });
    }

    try {
      // Get available sensors for this device
      List<Map<String, dynamic>> availableSensorsData = await _deviceService.getAvailableSensors(_currentDeviceId!);
      List<String> availableSensors = availableSensorsData.map((sensor) => sensor['type'] as String).toList();
      
      // Store available sensors for UI rendering
      _availableSensors = availableSensors;
      
      print('DEBUG: Device $_currentDeviceId has sensors: ${availableSensors.join(", ")}');

      // Initialize variables for sensor data
      List<WaterQualityData> temp = [];
      List<WaterQualityData> tds = [];
      List<WaterQualityData> ph = [];
      List<WaterQualityData> turbidity = [];
      List<WaterQualityData> conductivity = [];
      List<WaterQualityData> salinity = [];
      List<WaterQualityData> ecCompensated = [];

      // Fetch data for available sensors only
      if (availableSensors.contains('temperature')) {
        temp = await _deviceService.fetchDeviceData('Temp', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('tds')) {
        tds = await _deviceService.fetchDeviceData('TDS', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('ph')) {
        ph = await _deviceService.fetchDeviceData('pH Level', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('turbidity')) {
        turbidity = await _deviceService.fetchDeviceData('Turbidity', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('ec')) {
        conductivity = await _deviceService.fetchDeviceData('Conductivity', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('salinity')) {
        salinity = await _deviceService.fetchDeviceData('Salinity', 'Daily', _currentDeviceId!);
      }
      
      if (availableSensors.contains('ec_compensated')) {
        ecCompensated = await _deviceService.fetchDeviceData('EC', 'Daily', _currentDeviceId!);
      }

      // Check if we have at least one sensor with data
      bool hasAnyData = temp.isNotEmpty || tds.isNotEmpty || ph.isNotEmpty || 
                       turbidity.isNotEmpty || conductivity.isNotEmpty || 
                       salinity.isNotEmpty || ecCompensated.isNotEmpty;

      if (!hasAnyData) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNoData;
          _errorMessage = "No data received from device $_currentDeviceId sensors.";
        });
        return;
      }

      // Extract latest values (use null for unavailable sensors)
      final newTemp = temp.isNotEmpty ? temp.first.value : null;
      final newTDS = tds.isNotEmpty ? tds.first.value : null;
      final newPH = ph.isNotEmpty ? ph.first.value : null;
      final newTurbidity = turbidity.isNotEmpty ? turbidity.first.value : null;
      final newConductivity = conductivity.isNotEmpty ? conductivity.first.value : null;
      final newSalinity = salinity.isNotEmpty ? salinity.first.value : null;
      final newECCompensated = ecCompensated.isNotEmpty ? ecCompensated.first.value : null;

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
          _errorMessage = "No new data received from device $_currentDeviceId.";
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
      print('ERROR fetching latest data for device $_currentDeviceId: $e'); // Debugging print
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
        if (_latestTemp != null) {
          currentProgress = _latestTemp! / maxTemp;
          currentLabel = "${_latestTemp!.toStringAsFixed(1)}°C";
          currentColor = Colors.blue;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "TDS":
        if (_latestTDS != null) {
          currentProgress = _latestTDS! / maxTDS;
          currentLabel = "${_latestTDS!.toStringAsFixed(1)} PPM";
          currentColor = Colors.green;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "pH":
        if (_latestPH != null) {
          currentProgress = _latestPH! / maxPH;
          currentLabel = "pH ${_latestPH!.toStringAsFixed(1)}";
          currentColor = Colors.purple;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Turbidity":
        if (_latestTurbidity != null) {
          currentProgress = _latestTurbidity! / maxTurbidity;
          currentLabel = "${_latestTurbidity!.toStringAsFixed(1)}%";
          currentColor = Colors.orange;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Conductivity":
        if (_latestConductivity != null) {
          currentProgress = _latestConductivity! / maxConductivity;
          currentLabel = "${_latestConductivity!.toStringAsFixed(1)} mS/cm";
          currentColor = Colors.red;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Salinity":
        if (_latestSalinity != null) {
          currentProgress = _latestSalinity! / maxSalinity;
          currentLabel = "${_latestSalinity!.toStringAsFixed(1)} ppt";
          currentColor = Colors.teal;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Electrical Conductivity (Condensed)":
        if (_latestECCompensated != null) {
          currentProgress = _latestECCompensated! / maxECCompensated;
          currentLabel = "${_latestECCompensated!.toStringAsFixed(1)} mS/cm";
          currentColor = Colors.indigo;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
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

  // Helper methods to check if sensors are available for current device
  bool _isTemperatureAvailable() => _availableSensors.contains('temperature');
  bool _isTDSAvailable() => _availableSensors.contains('tds');
  bool _isPHAvailable() => _availableSensors.contains('ph');
  bool _isTurbidityAvailable() => _availableSensors.contains('turbidity');
  bool _isConductivityAvailable() => _availableSensors.contains('ec');
  bool _isSalinityAvailable() => _availableSensors.contains('salinity');
  bool _isECCompensatedAvailable() => _availableSensors.contains('ec_compensated');

  // Build available sensor cards dynamically
  List<Widget> _buildAvailableSensorCards() {
    List<Widget> availableCards = [];
    
    if (_isTemperatureAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.thermostat,
          label: "Temp",
          value: _connectionStatus == ConnectionStatus.connected && _latestTemp != null
              ? "${_latestTemp!.toStringAsFixed(1)}°C"
              : "...",
          isSelected: selectedStat == "Temp",
          onTap: () => _onStatCardTap("Temp"),
        ),
      );
    }
    
    if (_isTDSAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.water,
          label: "TDS",
          value: _connectionStatus == ConnectionStatus.connected && _latestTDS != null
              ? "${_latestTDS!.toStringAsFixed(1)} %"
              : "...",
          isSelected: selectedStat == "TDS",
          onTap: () => _onStatCardTap("TDS"),
          labelFontSize: 16,
          valueFontSize: 20,
        ),
      );
    }
    
    if (_isPHAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.opacity,
          label: "pH",
          value: _connectionStatus == ConnectionStatus.connected && _latestPH != null
              ? "${_latestPH!.toStringAsFixed(1)}"
              : "...",
          isSelected: selectedStat == "pH",
          onTap: () => _onStatCardTap("pH"),
        ),
      );
    }
    
    if (_isTurbidityAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.water_damage,
          label: "Turbidity",
          value: _connectionStatus == ConnectionStatus.connected && _latestTurbidity != null
              ? "${_latestTurbidity!.toStringAsFixed(1)}%"
              : "...",
          isSelected: selectedStat == "Turbidity",
          onTap: () => _onStatCardTap("Turbidity"),
          labelFontSize: 10,
          valueFontSize: 10,
        ),
      );
    }
    
    if (_isConductivityAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.flash_on,
          label: "Conductivity",
          value: _connectionStatus == ConnectionStatus.connected && _latestConductivity != null
              ? "${_latestConductivity!.toStringAsFixed(1)} %"
              : "...",
          isSelected: selectedStat == "Conductivity",
          onTap: () => _onStatCardTap("Conductivity"),
          labelFontSize: 10,
          valueFontSize: 10,
        ),
      );
    }
    
    if (_isSalinityAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.bubble_chart,
          label: "Salinity",
          value: _connectionStatus == ConnectionStatus.connected && _latestSalinity != null
              ? "${_latestSalinity!.toStringAsFixed(1)} %"
              : "...",
          isSelected: selectedStat == "Salinity",
          onTap: () => _onStatCardTap("Salinity"),
        ),
      );
    }
    
    if (_isECCompensatedAvailable()) {
      availableCards.add(
        StatCard(
          icon: Icons.battery_charging_full,
          label: "Electrical Conductivity (Condensed)",
          value: _connectionStatus == ConnectionStatus.connected && _latestECCompensated != null
              ? "${_latestECCompensated!.toStringAsFixed(1)} %"
              : "...",
          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
          width: double.infinity,
        ),
      );
    }
    
    return availableCards;
  }

  // Build dynamic sensor layout
  Widget _buildSensorGrid() {
    List<Widget> availableCards = _buildAvailableSensorCards();
    
    if (availableCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'No sensors available for this device',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }
    
    // Separate full-width cards (EC Compensated) from regular cards
    List<Widget> regularCards = [];
    List<Widget> fullWidthCards = [];
    
    for (Widget card in availableCards) {
      if (card is StatCard && card.width == double.infinity) {
        fullWidthCards.add(card);
      } else {
        regularCards.add(card);
      }
    }
    
    List<Widget> rows = [];
    
    // Build regular cards in rows of 3
    for (int i = 0; i < regularCards.length; i += 3) {
      List<Widget> rowChildren = [];
      for (int j = 0; j < 3 && i + j < regularCards.length; j++) {
        if (j > 0) rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(Expanded(child: regularCards[i + j]));
      }
      // Fill remaining slots with empty spaces
      while (rowChildren.length < 5) { // 3 cards + 2 spacers = 5 widgets
        if (rowChildren.length % 2 == 1) rowChildren.add(const SizedBox(width: 12));
        rowChildren.add(const Expanded(child: SizedBox()));
      }
      
      rows.add(Row(children: rowChildren));
      if (i + 3 < regularCards.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    // Add full-width cards
    for (Widget card in fullWidthCards) {
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12));
      }
      rows.add(card);
    }
    
    return Column(children: rows);
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
              
              // Device Selector (shown when user has multiple devices)
              if (_hasMultipleDevices && _accessibleDevices.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _currentDeviceId,
                    hint: const Text('Select Device'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _accessibleDevices.map((device) {
                      return DropdownMenuItem<String>(
                        value: device['device_id'],
                        child: Text('Device ${device['device_id']} - ${device['device_name']}'),
                      );
                    }).toList(),
                    onChanged: (String? newDeviceId) {
                      if (newDeviceId != null && newDeviceId != _currentDeviceId) {
                        final selectedDevice = _accessibleDevices.firstWhere(
                          (device) => device['device_id'] == newDeviceId,
                        );
                        _switchDevice(newDeviceId, selectedDevice['device_name']);
                      }
                    },
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

              // Cards - Dynamic grid based on available sensors
              _buildSensorGrid(),
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
  final double? height;
  final double? labelFontSize;
  final double? valueFontSize;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isSelected,
    this.width,
    this.height,
    this.labelFontSize,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine container dimensions
    double cardWidth = width ?? 0.0; // If no width provided, let parent decide
    double cardHeight = height ?? 140.0; // Default height of 120

    Color bgColor =
        isSelected
            ? Colors.greenAccent.withOpacity(0.8)
            : isDarkMode
            ? Colors.grey[800]!
            : Colors.white;

    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          width: cardWidth,
          height: cardHeight,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: textColor),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize ?? 14,
                    color: textColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFontSize ?? 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Poppins',
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
