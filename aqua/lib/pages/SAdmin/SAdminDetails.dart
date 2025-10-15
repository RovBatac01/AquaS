import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

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
      home: const SAdminDetails(),
    );
  }
}

enum ConnectionStatus {
  connecting,
  connected,
  disconnectedNetworkError,
}

class SAdminDetails extends StatefulWidget {
  final String? deviceId;
  final int? establishmentId;
  final String? establishmentName;
  
  const SAdminDetails({
    super.key,
    this.deviceId,
    this.establishmentId,
    this.establishmentName,
  });

  @override
  State<SAdminDetails> createState() => _SAdminDetailsState();
}

class _SAdminDetailsState extends State<SAdminDetails> with SingleTickerProviderStateMixin {
  String selectedStat = "Temp";

  double _latestTemp = 0.0;
  double _latestTDS = 0.0;
  double _latestPH = 0.0;
  double _latestTurbidity = 0.0;
  double _latestConductivity = 0.0;
  double _latestSalinity = 0.0;
  double _latestECCompensated = 0.0;

  String label = "---";
  Color indicatorColor = Colors.grey;

  ConnectionStatus _connectionStatus = ConnectionStatus.connecting;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  io.Socket? _socket;
  
  // Available sensors from database
  List<Map<String, dynamic>> _availableSensors = [];
  bool _sensorsLoaded = false;
  String? _currentDeviceId;
  int? _establishmentId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
    _loadUserDeviceAndSensors();
    _connectAndListen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
  
  // Load user's device and available sensors
  Future<void> _loadUserDeviceAndSensors() async {
    try {
      // If deviceId and establishmentId are passed from previous screen, use them directly
      if (widget.deviceId != null) {
        setState(() {
          _currentDeviceId = widget.deviceId;
          _establishmentId = widget.establishmentId;
        });
        
        print('🔍 DEBUG: Using passed Device ID: $_currentDeviceId, Establishment ID: $_establishmentId');
        
        // Fetch sensors for this device
        await _loadSensorsForDevice(widget.deviceId!);
        return;
      }
      
      // Otherwise, fetch from API (fallback for backward compatibility)
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken'); // Changed from 'token' to 'userToken'
      
      if (token == null) {
        print('No token found');
        return;
      }
      
      // Get user's accessible devices
      final devicesResponse = await http.get(
        Uri.parse('${ApiConfig.apiBase}/user/accessible-devices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (devicesResponse.statusCode == 200) {
        final devicesData = json.decode(devicesResponse.body);
        print('🔍 DEBUG: Full devices response: $devicesData');
        final devices = devicesData['devices'] as List;
        
        if (devices.isNotEmpty) {
          final device = devices.first;
          print('🔍 DEBUG: First device data: $device');
          print('🔍 DEBUG: Available keys in device: ${device.keys}');
          
          // Try multiple possible field names for device_id
          String? deviceId;
          if (device.containsKey('device_id')) {
            deviceId = device['device_id']?.toString();
          } else if (device.containsKey('id')) {
            deviceId = device['id']?.toString();
          } else if (device.containsKey('deviceId')) {
            deviceId = device['deviceId']?.toString();
          }
          
          setState(() {
            _currentDeviceId = deviceId;
            _establishmentId = device['estab_id'] as int? ?? device['establishment_id'] as int?;
          });
          
          print('🔍 DEBUG: Extracted Device ID: $_currentDeviceId, Establishment ID: $_establishmentId');
          
          // Fetch sensors for this device
          if (_currentDeviceId != null) {
            await _loadSensorsForDevice(_currentDeviceId!);
          } else {
            print('❌ ERROR: Could not extract device_id from device data');
            setState(() {
              _sensorsLoaded = true;
            });
          }
        } else {
          print('No accessible devices found');
          setState(() {
            _sensorsLoaded = true; // Mark as loaded even if empty
          });
        }
      } else {
        print('Failed to fetch devices: ${devicesResponse.statusCode}');
        print('Response body: ${devicesResponse.body}');
        setState(() {
          _sensorsLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading device and sensors: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _sensorsLoaded = true; // Mark as loaded even on error
      });
    }
  }
  
  // Load sensors for a specific device
  Future<void> _loadSensorsForDevice(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken'); // Changed from 'token' to 'userToken'
      
      if (token == null) {
        print('❌ No token found for loading sensors');
        return;
      }
      
      print('🔍 Fetching sensors for device: $deviceId');
      
      final response = await http.get(
        Uri.parse(ApiConfig.deviceSensorsEndpoint(deviceId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📡 Sensors API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sensors = data['sensors'] as List;
        
        print('✅ Loaded ${sensors.length} sensors for device $deviceId');
        print('🔍 Sensors data: $sensors');
        
        setState(() {
          _availableSensors = sensors.cast<Map<String, dynamic>>();
          _sensorsLoaded = true;
        });
      } else if (response.statusCode == 404) {
        print('⚠️ Device not found: $deviceId');
        setState(() {
          _sensorsLoaded = true;
        });
      } else if (response.statusCode == 403) {
        print('⚠️ Access denied to device: $deviceId');
        setState(() {
          _sensorsLoaded = true;
        });
      } else {
        print('❌ Failed to fetch sensors: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _sensorsLoaded = true;
        });
      }
    } catch (e) {
      print('❌ Error loading sensors: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _sensorsLoaded = true;
      });
    }
  }
  
  // Check if a sensor is available for this device
  bool _isSensorAvailable(String sensorName) {
    if (!_sensorsLoaded) return true; // Show all until loaded
    
    // Map sensor names to sensor IDs from the sensors table
    final sensorNameMap = {
      'Total Dissolved Solids': 1,
      'Conductivity': 2,
      'Temperature': 3,
      'Turbidity': 4,
      'ph Level': 5,
      'Salinity': 6,
      'Electrical Conductivity': 7,
    };
    
    final sensorId = sensorNameMap[sensorName];
    if (sensorId == null) return false;
    
    return _availableSensors.any((sensor) => sensor['sensor_id'] == sensorId);
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

  void _connectAndListen() {
    _socket = io.io('https://aquasense-p36u.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      print('Socket.IO connected');
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.connected;
          _errorMessage = null;
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.onDisconnect((_) {
      print('Socket.IO disconnected');
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNetworkError;
          _errorMessage = 'Socket.IO disconnected.';
        });
      }
    });

    _socket?.on('error', (error) => print('Socket.IO error: $error'));

    _socket?.on('newNotification', (data) {
      print('Received real-time notification: $data');
      if (mounted) {
        final readingValue = (data['readingValue'] as num).toDouble();
        final threshold = (data['threshold'] as num).toDouble();
        _showNotificationAlert(readingValue, threshold);
      }
    });

    _socket?.on('updateTemperatureData', (data) {
      if (mounted) {
        setState(() {
          _latestTemp = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updatePHData', (data) {
      if (mounted) {
        setState(() {
          _latestPH = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updateTDSData', (data) {
      if (mounted) {
        setState(() {
          _latestTDS = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updateTurbidityData', (data) {
      if (mounted) {
        setState(() {
          _latestTurbidity = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updateSalinityData', (data) {
      if (mounted) {
        setState(() {
          _latestSalinity = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updateECData', (data) {
      if (mounted) {
        setState(() {
          _latestConductivity = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });

    _socket?.on('updateECCompensatedData', (data) {
      if (mounted) {
        setState(() {
          _latestECCompensated = (data['value'] as num).toDouble();
          _updateCircularIndicatorValues();
        });
      }
    });
  }

  void _showNotificationAlert(double readingValue, double threshold) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Real-Time Water Quality Alert',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Turbidity reading ($readingValue) is below the threshold ($threshold).',
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateCircularIndicatorValues() {
    double targetProgress = 0.0;
    String currentLabel = "N/A";
    Color currentColor = Colors.blue;

    const double maxTemp = 100.0;
    const double maxTDS = 100.0;
    const double maxPH = 14.0;
    const double maxTurbidity = 100.0;
    const double maxConductivity = 100.0;
    const double maxSalinity = 100.0;
    const double maxECCompensated = 100.0;

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

    targetProgress = targetProgress.clamp(0.0, 1.0);
    _animationController.reset();
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    setState(() {
      label = currentLabel;
      indicatorColor = currentColor;
    });
  }

  void _onStatCardTap(String stat) {
    setState(() {
      selectedStat = stat;
      _updateCircularIndicatorValues();
    });
  }



  Color _getConnectionStatusColor() {
    switch (_connectionStatus) {
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
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
    }

    bool displayLiveValues = _connectionStatus == ConnectionStatus.connected;

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
                                  widget.establishmentName ?? 'Home Water Tank',
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
                        child: AnimatedBuilder(
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
                    if (_isSensorAvailable('Temperature') || _isSensorAvailable('Total Dissolved Solids'))
                      Row(
                        children: [
                          if (_isSensorAvailable('Temperature'))
                            Expanded(
                              child: EnhancedStatCard(
                                icon: Icons.thermostat_rounded,
                                label: "Temperature",
                                value: displayLiveValues ? "${_latestTemp.toStringAsFixed(1)}°C" : "---",
                                unit: "°C",
                                isSelected: selectedStat == "Temp",
                                onTap: () => _onStatCardTap("Temp"),
                                color: Colors.orange,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          if (_isSensorAvailable('Temperature') && _isSensorAvailable('Total Dissolved Solids'))
                            const SizedBox(width: 12),
                          if (_isSensorAvailable('Total Dissolved Solids'))
                            Expanded(
                              child: EnhancedStatCard(
                                icon: Icons.water_drop_rounded,
                                label: "TDS",
                                value: displayLiveValues ? "${_latestTDS.toStringAsFixed(1)}" : "---",
                                unit: "ppm",
                                isSelected: selectedStat == "TDS",
                                onTap: () => _onStatCardTap("TDS"),
                                color: Colors.blue,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                        ],
                      ),
                    if (_isSensorAvailable('Temperature') || _isSensorAvailable('Total Dissolved Solids'))
                      const SizedBox(height: 12),
                    if (_isSensorAvailable('ph Level') || _isSensorAvailable('Turbidity'))
                      Row(
                        children: [
                          if (_isSensorAvailable('ph Level'))
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
                          if (_isSensorAvailable('ph Level') && _isSensorAvailable('Turbidity'))
                            const SizedBox(width: 12),
                          if (_isSensorAvailable('Turbidity'))
                            Expanded(
                              child: EnhancedStatCard(
                                icon: Icons.visibility_rounded,
                                label: "Turbidity",
                                value: displayLiveValues ? "${_latestTurbidity.toStringAsFixed(1)}" : "---",
                                unit: "NTU",
                                isSelected: selectedStat == "Turbidity",
                                onTap: () => _onStatCardTap("Turbidity"),
                                color: Colors.brown,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                        ],
                      ),
                    if (_isSensorAvailable('ph Level') || _isSensorAvailable('Turbidity'))
                      const SizedBox(height: 12),
                    if (_isSensorAvailable('Conductivity') || _isSensorAvailable('Salinity'))
                      Row(
                        children: [
                          if (_isSensorAvailable('Conductivity'))
                            Expanded(
                              child: EnhancedStatCard(
                                icon: Icons.flash_on_rounded,
                                label: "Conductivity",
                                value: displayLiveValues ? "${_latestConductivity.toStringAsFixed(1)}" : "---",
                                unit: "μS/cm",
                                isSelected: selectedStat == "Conductivity",
                                onTap: () => _onStatCardTap("Conductivity"),
                                color: Colors.amber,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          if (_isSensorAvailable('Conductivity') && _isSensorAvailable('Salinity'))
                            const SizedBox(width: 12),
                          if (_isSensorAvailable('Salinity'))
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
                    if (_isSensorAvailable('Conductivity') || _isSensorAvailable('Salinity'))
                      const SizedBox(height: 12),
                    if (_isSensorAvailable('Electrical Conductivity'))
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedStatCard(
                          icon: Icons.electrical_services_rounded,
                          label: "EC Compensated",
                          value: displayLiveValues ? "${_latestECCompensated.toStringAsFixed(1)}" : "---",
                          unit: "μS/cm",
                          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
                          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
                          color: Colors.indigo,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    if (!_sensorsLoaded)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (_sensorsLoaded && _availableSensors.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No sensors configured for this device',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontFamily: 'Poppins',
                          ),
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

    Color bgColor = isSelected
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
  final double progress;
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

    final backgroundPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0;
    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12.0;

    if (disconnectedMessage == null) {
      progressPaint.color = color;

      const startAngle = -pi / 2;
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    final textColor = brightness == Brightness.light ? Colors.black : Colors.white;
    final displayLabel = disconnectedMessage ?? label;
    final displayFontSize = disconnectedMessage != null ? 18.0 : 26.0;
    final displayFontWeight = disconnectedMessage != null ? FontWeight.normal : FontWeight.bold;
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
    return oldDelegate.progress != progress ||
        oldDelegate.label != label ||
        oldDelegate.color != color ||
        oldDelegate.brightness != brightness ||
        oldDelegate.disconnectedMessage != disconnectedMessage;
  }
}