import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Required for ImageFilter
import 'dart:async'; // Required for Timer
import 'dart:convert'; // For JSON encoding/decoding
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:aqua/water_quality_model.dart'; // Corrected import path
import '../../config/api_config.dart';
import '../../components/colors.dart'; // Import ASColor

import '../../device_aware_service.dart'; // New device-aware service

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

class _DetailsScreenState extends State<DetailsScreen> with SingleTickerProviderStateMixin {
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

  Timer? _timer; // Timer for auto-refresh (kept as fallback)
  io.Socket? _socket;

  final DeviceAwareService _deviceService = DeviceAwareService();

  // Device management
  List<Map<String, dynamic>> _accessibleDevices = [];
  String? _currentDeviceId;
  String? _currentDeviceName;
  bool _hasMultipleDevices = false;
  List<String> _availableSensors =
      []; // Track which sensors are available for current device

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0)
        .animate(_animationController)
      ..addListener(() {
        if (mounted && !_isDisposed) {
          setState(() {
            progress = _progressAnimation.value;
          });
        }
      });

    _initializeDeviceData(); // Initialize device data and set up timer/socket
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted && !_isDisposed) super.setState(fn);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    try {
      _animationController.dispose();
    } catch (e) {
      // ignore: avoid_print
      print('Warning disposing animation controller: $e');
    }

    try {
      if (_socket != null) {
        try {
          _socket?.off('connect');
          _socket?.off('disconnect');
          _socket?.off('error');
          _socket?.off('newNotification');
          _socket?.off('updateTemperatureData');
          _socket?.off('updatePHData');
          _socket?.off('updateTDSData');
          _socket?.off('updateTurbidityData');
          _socket?.off('updateSalinityData');
          _socket?.off('updateECData');
          _socket?.off('updateECCompensatedData');
        } catch (_) {}
        _socket?.disconnect();
        _socket?.dispose();
      }
    } catch (e) {
      // ignore: avoid_print
      print('Warning disposing socket: $e');
    }

    super.dispose();
  }

  // Map backend sensor_name to frontend type keys
  String _sensorNameToType(String? sensorName) {
    if (sensorName == null) return sensorName ?? '';
    final name = sensorName.trim();
    final mapping = <String, String>{
      'Total Dissolved Solids': 'tds',
      'Conductivity': 'ec',
      'Temperature': 'temperature',
      'Turbidity': 'turbidity',
      'ph Level': 'ph',
      'pH Level': 'ph',
      'Salinity': 'salinity',
      'Electrical Conductivity': 'ec_compensated',
    };

    if (mapping.containsKey(name)) return mapping[name]!;
    final found = mapping.entries.firstWhere(
      (e) => e.key.toLowerCase() == name.toLowerCase(),
      orElse: () => MapEntry('', ''),
    );
    if (found.key != '') return found.value;

    final lower = name.toLowerCase();
    if (lower.contains('tds') || lower.contains('dissolved')) return 'tds';
    if (lower.contains('temp')) return 'temperature';
    if (lower.contains('ph')) return 'ph';
    if (lower.contains('turbidity')) return 'turbidity';
    if (lower.contains('salin')) return 'salinity';
    if (lower.contains('conduct')) return 'ec';

    return name.toLowerCase().replaceAll(' ', '_');
  }

  /// Initialize device data and start fetching sensor data
  Future<void> _initializeDeviceData() async {
    try {
      // Check if user has any approved device access first
      bool hasApprovedAccess = await _deviceService.hasApprovedDeviceAccess();

      if (hasApprovedAccess) {
        // User has approved access, proceed normally
        _accessibleDevices = await _deviceService.getAccessibleDevices();
        _hasMultipleDevices = _accessibleDevices.length > 1;

        // Set the first device as current
        _currentDeviceId = _accessibleDevices.first['device_id'];
        _currentDeviceName = _accessibleDevices.first['device_name'];

        print(
          'DEBUG: User has access to ${_accessibleDevices.length} device(s)',
        );
        print('DEBUG: Current device: $_currentDeviceId ($_currentDeviceName)');

        // Fetch configured sensors for the establishment and start Socket.IO
        try {
          final estabId = _accessibleDevices.first['estab_id'] as int? ??
              _accessibleDevices.first['establishment_id'] as int?;
          if (estabId != null) {
            final sensors = await _deviceService.getEstablishmentSensors(estabId);
            final mapped = sensors.map<String>((s) {
              final typeFromApi = s['type'] as String?;
              final nameFromApi = s['sensor_name'] as String?;
              if (typeFromApi != null && typeFromApi.isNotEmpty) return typeFromApi;
              return _sensorNameToType(nameFromApi);
            }).toList();
            final dedup = mapped.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
            setState(() {
              _availableSensors = dedup;
            });
          }
        } catch (e) {
          print('Warning: failed to fetch estab sensors, falling back to defaults: $e');
          setState(() {
            _availableSensors = [
              'temperature',
              'tds',
              'ph',
              'turbidity',
              'ec',
              'salinity',
              'ec_compensated',
            ];
          });
        }

        // Start socket IO for live updates
        _connectAndListen();
      } else {
        // No approved access - check for pending requests
        List<Map<String, dynamic>> pendingRequests =
            await _deviceService.getPendingDeviceRequests();
        List<Map<String, dynamic>> allRequests =
            await _deviceService.getUserDeviceRequests();

        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNetworkError;

          if (pendingRequests.isNotEmpty) {
            _errorMessage =
                'Your device access request is pending approval. Please wait for admin approval.';
          } else if (allRequests.any((req) => req['status'] == 'rejected')) {
            _errorMessage =
                'Your device access request was rejected. Please contact your administrator.';
          } else {
            _errorMessage =
                'No device access found. Please request access from your administrator.';
          }
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

  void _connectAndListen() async {
    try {
      final base = ApiConfig.baseUrl;
      print('DEBUG: Connecting Socket.IO to $base');

      _socket = io.io(base, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket?.connect();

      _socket?.onConnect((_) {
        print('Socket.IO connected');
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _connectionStatus = ConnectionStatus.connected;
              _errorMessage = null;
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            // ignore: avoid_print
            print('setState skipped on connect: $e');
          }
        }
      });

      _socket?.onDisconnect((_) {
        print('Socket.IO disconnected');
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _connectionStatus = ConnectionStatus.disconnectedNetworkError;
              _errorMessage = 'Socket.IO disconnected.';
            });
          } catch (e) {
            // ignore: avoid_print
            print('setState skipped on disconnect: $e');
          }
        }
      });

      _socket?.on('error', (error) => print('Socket.IO error: $error'));

      _socket?.on('newNotification', (data) {
        print('Received real-time notification: $data');
        if (mounted && !_isDisposed) {
          try {
            final readingValue = (data['readingValue'] as num).toDouble();
            final threshold = (data['threshold'] as num).toDouble();
            _showNotificationAlert(readingValue, threshold);
          } catch (e) {
            print('Notification handler skipped: $e');
          }
        }
      });

      _socket?.on('updateTemperatureData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestTemp = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateTemperatureData handler skipped: $e');
          }
        }
      });

      _socket?.on('updatePHData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestPH = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updatePHData handler skipped: $e');
          }
        }
      });

      _socket?.on('updateTDSData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestTDS = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateTDSData handler skipped: $e');
          }
        }
      });

      _socket?.on('updateTurbidityData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestTurbidity = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateTurbidityData handler skipped: $e');
          }
        }
      });

      _socket?.on('updateSalinityData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestSalinity = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateSalinityData handler skipped: $e');
          }
        }
      });

      _socket?.on('updateECData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestConductivity = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateECData handler skipped: $e');
          }
        }
      });

      _socket?.on('updateECCompensatedData', (data) {
        if (mounted && !_isDisposed) {
          try {
            setState(() {
              _latestECCompensated = (data['value'] as num).toDouble();
              _updateCircularIndicatorValues();
            });
          } catch (e) {
            print('updateECCompensatedData handler skipped: $e');
          }
        }
      });
    } catch (e) {
      print('Error connecting to Socket.IO: $e');
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNetworkError;
          _errorMessage = 'Socket connection failed: $e';
        });
      }
    }
  }

  void _showNotificationAlert(double readingValue, double threshold) {
    if (!mounted) return;
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

  /// Switch to a different device
  Future<void> _switchDevice(String deviceId, String deviceName, [int? estabId]) async {
    setState(() {
      _currentDeviceId = deviceId;
      _currentDeviceName = deviceName;
      _connectionStatus = ConnectionStatus.connecting;
    });

    // Disconnect previous socket and clear it
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;

    // Try to fetch sensors for the new device's establishment if provided
    if (estabId != null) {
      try {
        final sensors = await _deviceService.getEstablishmentSensors(estabId);
        final mapped = sensors.map<String>((s) {
          final typeFromApi = s['type'] as String?;
          final nameFromApi = s['sensor_name'] as String?;
          if (typeFromApi != null && typeFromApi.isNotEmpty) return typeFromApi;
          return _sensorNameToType(nameFromApi);
        }).toList();
        final dedup = mapped.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList();
        setState(() {
          _availableSensors = dedup;
        });
      } catch (e) {
        print('Warning: failed to fetch estab sensors on device switch: $e');
        setState(() {
          _availableSensors = [
            'temperature',
            'tds',
            'ph',
            'turbidity',
            'ec',
            'salinity',
            'ec_compensated',
          ];
        });
      }
    }

    // Reconnect socket for the new device
    _connectAndListen();
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
      List<Map<String, dynamic>> availableSensorsData = await _deviceService
          .getAvailableSensors(_currentDeviceId!);
      List<String> availableSensors =
          availableSensorsData
              .map((sensor) => sensor['type'] as String)
              .toList();

      // Store available sensors for UI rendering
      _availableSensors = availableSensors;

      print(
        'DEBUG: Device $_currentDeviceId has sensors: ${availableSensors.join(", ")}',
      );

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
        temp = await _deviceService.fetchDeviceData(
          'Temp',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('tds')) {
        tds = await _deviceService.fetchDeviceData(
          'TDS',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('ph')) {
        ph = await _deviceService.fetchDeviceData(
          'pH Level',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('turbidity')) {
        turbidity = await _deviceService.fetchDeviceData(
          'Turbidity',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('ec')) {
        conductivity = await _deviceService.fetchDeviceData(
          'Conductivity',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('salinity')) {
        salinity = await _deviceService.fetchDeviceData(
          'Salinity',
          'Daily',
          _currentDeviceId!,
        );
      }

      if (availableSensors.contains('ec_compensated')) {
        ecCompensated = await _deviceService.fetchDeviceData(
          'EC',
          'Daily',
          _currentDeviceId!,
        );
      }

      // Check if we have at least one sensor with data
      bool hasAnyData =
          temp.isNotEmpty ||
          tds.isNotEmpty ||
          ph.isNotEmpty ||
          turbidity.isNotEmpty ||
          conductivity.isNotEmpty ||
          salinity.isNotEmpty ||
          ecCompensated.isNotEmpty;

      if (!hasAnyData) {
        setState(() {
          _connectionStatus = ConnectionStatus.disconnectedNoData;
          _errorMessage =
              "No data received from device $_currentDeviceId sensors.";
        });
        return;
      }

      // Extract latest values (use null for unavailable sensors)
      final newTemp = temp.isNotEmpty ? temp.first.value : null;
      final newTDS = tds.isNotEmpty ? tds.first.value : null;
      final newPH = ph.isNotEmpty ? ph.first.value : null;
      final newTurbidity = turbidity.isNotEmpty ? turbidity.first.value : null;
      final newConductivity =
          conductivity.isNotEmpty ? conductivity.first.value : null;
      final newSalinity = salinity.isNotEmpty ? salinity.first.value : null;
      final newECCompensated =
          ecCompensated.isNotEmpty ? ecCompensated.first.value : null;

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
      print(
        'ERROR fetching latest data for device $_currentDeviceId: $e',
      ); // Debugging print
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
  bool _isECCompensatedAvailable() =>
      _availableSensors.contains('ec_compensated');

  // Build available sensor cards dynamically
  List<Widget> _buildAvailableSensorCards() {
    List<Widget> availableCards = [];

    if (_isTemperatureAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.thermostat_rounded,
          label: "Temperature",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestTemp != null
                  ? "${_latestTemp!.toStringAsFixed(1)}"
                  : "---",
          unit: "°C",
          isSelected: selectedStat == "Temp",
          onTap: () => _onStatCardTap("Temp"),
          color: Colors.orange,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isTDSAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.water_drop_rounded,
          label: "TDS",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestTDS != null
                  ? "${_latestTDS!.toStringAsFixed(1)}"
                  : "---",
          unit: "PPM",
          isSelected: selectedStat == "TDS",
          onTap: () => _onStatCardTap("TDS"),
          color: Colors.blue,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isPHAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.science_rounded,
          label: "pH Level",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestPH != null
                  ? "${_latestPH!.toStringAsFixed(1)}"
                  : "---",
          unit: "pH",
          isSelected: selectedStat == "pH",
          onTap: () => _onStatCardTap("pH"),
          color: Colors.purple,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isTurbidityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.blur_on_rounded,
          label: "Turbidity",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestTurbidity != null
                  ? "${_latestTurbidity!.toStringAsFixed(1)}"
                  : "---",
          unit: "NTU",
          isSelected: selectedStat == "Turbidity",
          onTap: () => _onStatCardTap("Turbidity"),
          color: Colors.brown,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isConductivityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.electrical_services_rounded,
          label: "Conductivity",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestConductivity != null
                  ? "${_latestConductivity!.toStringAsFixed(1)}"
                  : "---",
          unit: "mS/cm",
          isSelected: selectedStat == "Conductivity",
          onTap: () => _onStatCardTap("Conductivity"),
          color: Colors.amber,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isSalinityAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.grain_rounded,
          label: "Salinity",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestSalinity != null
                  ? "${_latestSalinity!.toStringAsFixed(1)}"
                  : "---",
          unit: "ppt",
          isSelected: selectedStat == "Salinity",
          onTap: () => _onStatCardTap("Salinity"),
          color: Colors.teal,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        ),
      );
    }

    if (_isECCompensatedAvailable()) {
      availableCards.add(
        EnhancedStatCard(
          icon: Icons.settings_input_component_rounded,
          label: "EC Compensated",
          value:
              _connectionStatus == ConnectionStatus.connected &&
                      _latestECCompensated != null
                  ? "${_latestECCompensated!.toStringAsFixed(1)}"
                  : "---",
          unit: "mS/cm",
          isSelected: selectedStat == "Electrical Conductivity (Condensed)",
          onTap: () => _onStatCardTap("Electrical Conductivity (Condensed)"),
          color: Colors.indigo,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
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
            Icon(Icons.sensors_off, size: 48, color: Colors.grey[600]),
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

    // Build grid with 2 columns
    List<Widget> rows = [];
    for (int i = 0; i < availableCards.length; i += 2) {
      List<Widget> rowChildren = [Expanded(child: availableCards[i])];

      if (i + 1 < availableCards.length) {
        rowChildren.addAll([
          const SizedBox(width: 12),
          Expanded(child: availableCards[i + 1]),
        ]);
      } else {
        rowChildren.add(
          const Expanded(child: SizedBox()),
        ); // Empty space for odd number
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

  /// Build approval pending UI when user has no approved access
  Widget _buildApprovalPendingUI(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main container with approval message
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : ASColor.BGfirst,
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
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.pending_actions_rounded,
                    size: 60,
                    color: Colors.orange[600],
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Device Access Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage ??
                        'Your device access request is pending approval.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[700],
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Info text
                Text(
                  'You will receive a notification once your request is processed.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // If no approved access, show approval pending UI instead of data
    if (_accessibleDevices.isEmpty &&
        _connectionStatus == ConnectionStatus.disconnectedNetworkError) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 0,
          title: Text(
            'Water Quality Monitor',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montserrat',
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
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
              colors:
                  isDarkMode
                      ? [Colors.grey[900]!, Colors.grey[850]!]
                      : [Colors.grey[50]!, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(child: _buildApprovalPendingUI(isDarkMode)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
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
            colors:
                isDarkMode
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
                              Icons.home_rounded,
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
                                  _currentDeviceName ?? 'Loading...',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentDeviceId != null
                                      ? 'Device ID: $_currentDeviceId'
                                      : 'Real-time water quality monitoring',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
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

                // Device Selector (shown when user has multiple devices)
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
                          color:
                              isDarkMode ? Colors.blue[300] : Colors.blue[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Device Selection',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              DropdownButton<String>(
                                value: _currentDeviceId,
                                hint: const Text('Select Device'),
                                isExpanded: true,
                                underline: const SizedBox(),
                                items:
                                    _accessibleDevices.map((device) {
                                      return DropdownMenuItem<String>(
                                        value: device['device_id'],
                                        child: Text(
                                          'Device ${device['device_id']} - ${device['device_name']}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (String? newDeviceId) {
                                  if (newDeviceId != null &&
                                      newDeviceId != _currentDeviceId) {
                                    final selectedDevice = _accessibleDevices
                                        .firstWhere(
                                          (device) =>
                                              device['device_id'] ==
                                              newDeviceId,
                                        );
                                    _switchDevice(
                                      newDeviceId,
                                      selectedDevice['device_name'],
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Enhanced Circular Indicator Section
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
                        'Water Quality Monitor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child:
                            _connectionStatus == ConnectionStatus.connecting
                                ? const CircularProgressIndicator()
                                : Container(
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
                                      progress: progress,
                                      label: label,
                                      color: indicatorColor,
                                      brightness: Theme.of(context).brightness,
                                      disconnectedMessage:
                                          _connectionStatus !=
                                                  ConnectionStatus.connected
                                              ? (_errorMessage ??
                                                  "Disconnected")
                                              : null,
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _connectionStatus == ConnectionStatus.connected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                _connectionStatus == ConnectionStatus.connected
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
                            color:
                                _connectionStatus == ConnectionStatus.connected
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Sensor Cards Section Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 4,
                  ),
                  child: Text(
                    'Water Quality Sensors',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ),

                // Cards - Dynamic grid based on available sensors
                _buildSensorGrid(),
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
          color:
              isSelected
                  ? color.withOpacity(0.1)
                  : isDarkMode
                  ? Colors.grey[800]
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? color
                    : isDarkMode
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isSelected
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
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 16),
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
