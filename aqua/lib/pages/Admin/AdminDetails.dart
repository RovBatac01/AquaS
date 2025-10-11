import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding


import '../../device_aware_service.dart'; // New device-aware service
import '../../water_quality_model.dart'; // For WaterQualityData type

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
  double? _latestTemp;
  double? _latestTDS;
  double? _latestPH;
  double? _latestTurbidity;
  double? _latestConductivity; // Corresponds to 'ec_value_mS'
  double? _latestSalinity;
  double? _latestECCompensated; // Corresponds to 'ec_compensated_mS'

  // Connection and Error State
  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;

  // To detect if data is the same as the previous fetch
  Map<String, dynamic>? _lastSuccessfulDataPayload;

  Timer? _timer; // Timer for auto-refresh

  final DeviceAwareService _deviceService = DeviceAwareService();

  // Device management fields
  List<Map<String, dynamic>> _accessibleDevices = [];
  String? _currentDeviceId;
  String? _currentDeviceName;
  bool _hasMultipleDevices = false;
  List<String> _availableSensors = []; // Track which sensors are available for current device

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

    _initializeDeviceData(); // Initialize device data and set up timer
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    _animationController.dispose(); // Dispose of the animation controller
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
        
        print('DEBUG: Admin has access to ${_accessibleDevices.length} device(s)');
        print('DEBUG: Current device: $_currentDeviceId ($_currentDeviceName)');
        
        // Start fetching data for the current device
        _fetchLatestDataForAllStats(isInitialFetch: true);
        
        // Set up timer for auto-refresh
        _timer = Timer.periodic(const Duration(milliseconds: 1500), (Timer t) {
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
    _fetchLatestDataForAllStats(isInitialFetch: true);
  }

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
      // Check if we have a current device selected
      if (_currentDeviceId == null) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNetworkError;
          _errorMessage = "No device selected.";
          _hasInitialDataLoaded = true;
        });
        return;
      }

      // Get available sensors for this device
      List<Map<String, dynamic>> availableSensorsData = await _deviceService.getAvailableSensors(_currentDeviceId!);
      List<String> availableSensors = availableSensorsData.map((sensor) => sensor['type'] as String).toList();
      
      // Store available sensors for UI rendering
      _availableSensors = availableSensors;
      
      print('DEBUG: Admin device $_currentDeviceId has sensors: ${availableSensors.join(", ")}');

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
          _hasInitialDataLoaded = true;
        });
        return;
      }

      // Update latest values from the fetched data (use null for unavailable sensors)
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
        if (_latestTemp != null) {
          targetProgress = _latestTemp! / maxTemp;
          currentLabel = "${_latestTemp!.toStringAsFixed(1)}°C";
          currentColor = Colors.blue;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "TDS":
        if (_latestTDS != null) {
          targetProgress = _latestTDS! / maxTDS;
          currentLabel = "${_latestTDS!.toStringAsFixed(1)} %";
          currentColor = _getIndicatorColor(selectedStat, _latestTDS!);
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "pH":
        if (_latestPH != null) {
          targetProgress = _latestPH! / maxPH;
          currentLabel = "pH ${_latestPH!.toStringAsFixed(1)}";
          currentColor = Colors.purple;
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Turbidity":
        if (_latestTurbidity != null) {
          targetProgress = _latestTurbidity! / maxTurbidity;
          currentLabel = "${_latestTurbidity!.toStringAsFixed(1)} %";
          currentColor = _getIndicatorColor(selectedStat, _latestTurbidity!);
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Conductivity":
        if (_latestConductivity != null) {
          targetProgress = _latestConductivity! / maxConductivity;
          currentLabel = "${_latestConductivity!.toStringAsFixed(1)} %";
          currentColor = _getIndicatorColor(selectedStat, _latestConductivity!);
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Salinity":
        if (_latestSalinity != null) {
          targetProgress = _latestSalinity! / maxSalinity;
          currentLabel = "${_latestSalinity!.toStringAsFixed(1)} %";
          currentColor = _getIndicatorColor(selectedStat, _latestSalinity!);
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
        break;
      case "Electrical Conductivity (Condensed)":
        if (_latestECCompensated != null) {
          targetProgress = _latestECCompensated! / maxECCompensated;
          currentLabel = "${_latestECCompensated!.toStringAsFixed(1)} %";
          currentColor = _getIndicatorColor(selectedStat, _latestECCompensated!);
        } else {
          currentLabel = "No Data";
          currentColor = Colors.grey;
        }
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

  // Helper methods to check if sensors are available for current device
  bool _isTemperatureAvailable() => _availableSensors.contains('temperature');
  bool _isTDSAvailable() => _availableSensors.contains('tds');
  bool _isPHAvailable() => _availableSensors.contains('ph');
  bool _isTurbidityAvailable() => _availableSensors.contains('turbidity');
  bool _isConductivityAvailable() => _availableSensors.contains('ec');
  bool _isSalinityAvailable() => _availableSensors.contains('salinity');
  bool _isECCompensatedAvailable() => _availableSensors.contains('ec_compensated');

  // Build available sensor cards dynamically
  List<Widget> _buildAvailableSensorCards(bool isDarkMode, bool displayLiveValues) {
    List<Widget> availableCards = [];
    
    if (_isTemperatureAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.thermostat_rounded,
          label: "Temperature",
          value: displayLiveValues && _latestTemp != null ? "${_latestTemp!.toStringAsFixed(1)}" : "---",
          unit: "°C",
          isSelected: selectedStat == "Temp",
          onTap: () => _onStatCardTap("Temp"),
          color: Colors.orange,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isTDSAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.water_drop_rounded,
          label: "TDS",
          value: displayLiveValues && _latestTDS != null ? "${_latestTDS!.toStringAsFixed(1)}" : "---",
          unit: "PPM",
          isSelected: selectedStat == "TDS",
          onTap: () => _onStatCardTap("TDS"),
          color: Colors.blue,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isPHAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.science_rounded,
          label: "pH Level",
          value: displayLiveValues && _latestPH != null ? "${_latestPH!.toStringAsFixed(1)}" : "---",
          unit: "pH",
          isSelected: selectedStat == "pH",
          onTap: () => _onStatCardTap("pH"),
          color: Colors.purple,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isTurbidityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.blur_on_rounded,
          label: "Turbidity",
          value: displayLiveValues && _latestTurbidity != null ? "${_latestTurbidity!.toStringAsFixed(1)}" : "---",
          unit: "NTU",
          isSelected: selectedStat == "Turbidity",
          onTap: () => _onStatCardTap("Turbidity"),
          color: Colors.brown,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isConductivityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.electrical_services_rounded,
          label: "Conductivity",
          value: displayLiveValues && _latestConductivity != null ? "${_latestConductivity!.toStringAsFixed(1)}" : "---",
          unit: "mS/cm",
          isSelected: selectedStat == "Conductivity",
          onTap: () => _onStatCardTap("Conductivity"),
          color: Colors.amber,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isSalinityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.grain_rounded,
          label: "Salinity",
          value: displayLiveValues && _latestSalinity != null ? "${_latestSalinity!.toStringAsFixed(1)}" : "---",
          unit: "ppt",
          isSelected: selectedStat == "Salinity",
          onTap: () => _onStatCardTap("Salinity"),
          color: Colors.teal,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    if (_isECCompensatedAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.settings_input_component_rounded,
          label: "EC Compensated",
          value: displayLiveValues && _latestECCompensated != null ? "${_latestECCompensated!.toStringAsFixed(1)}" : "---",
          unit: "mS/cm",
          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
          color: Colors.indigo,
          isDarkMode: isDarkMode,
        ),
      );
    }
    
    return availableCards;
  }

  // Build dynamic grid layout for available sensors
  Widget _buildSensorGrid(bool isDarkMode, bool displayLiveValues) {
    List<Widget> availableCards = _buildAvailableSensorCards(isDarkMode, displayLiveValues);
    
    if (availableCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.sensors_off,
              size: 48,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              'No sensors available for this device',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }
    
    // Build grid with 2 columns
    List<Widget> rows = [];
    for (int i = 0; i < availableCards.length; i += 2) {
      List<Widget> rowChildren = [
        Expanded(child: availableCards[i]),
      ];
      
      if (i + 1 < availableCards.length) {
        rowChildren.addAll([
          const SizedBox(width: 12),
          Expanded(child: availableCards[i + 1]),
        ]);
      } else {
        rowChildren.add(const Expanded(child: SizedBox())); // Empty space for odd number
      }
      
      rows.add(Row(children: rowChildren));
      if (i + 2 < availableCards.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    
    return Column(children: rows);
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
                
                // Device Selector (shown when admin has multiple devices)
                if (_hasMultipleDevices && _accessibleDevices.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.device_hub,
                          color: isDarkMode ? Colors.blue[300] : Colors.blue[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _currentDeviceId,
                            hint: Text(
                              'Select Device',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(),
                            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
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
                
                // Dynamic Stats Grid - Only shows sensors available for current device
                _buildSensorGrid(isDarkMode, displayLiveValues),
                
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