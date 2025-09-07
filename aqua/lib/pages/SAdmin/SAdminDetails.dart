import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'package:socket_io_client/socket_io_client.dart' as io;

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
  const SAdminDetails({super.key});

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_animationController);
    _connectAndListen();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
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

  String _getConnectionStatusText() {
    switch (_connectionStatus) {
      case ConnectionStatus.connecting:
        return "Device Status: Connecting...";
      case ConnectionStatus.connected:
        return "Device Status: Connected";
      case ConnectionStatus.disconnectedNetworkError:
        return "Device Status: Disconnected (Network Error)";
    }
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
    String? disconnectedMessageForIndicator;
    if (_connectionStatus == ConnectionStatus.disconnectedNetworkError) {
      disconnectedMessageForIndicator = "Network Error";
    }

    bool displayLiveValues = _connectionStatus == ConnectionStatus.connected;

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
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(250, 250),
                      painter: CircularIndicator(
                        progress: _progressAnimation.value,
                        label: label,
                        color: indicatorColor,
                        brightness: Theme.of(context).brightness,
                        disconnectedMessage: disconnectedMessageForIndicator,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
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
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.thermostat,
                          label: "Temp",
                          value: displayLiveValues ? "${_latestTemp.toStringAsFixed(1)}°C" : "...",
                          isSelected: selectedStat == "Temp",
                          onTap: () => _onStatCardTap("Temp"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.water,
                          label: "TDS",
                          value: displayLiveValues ? "${_latestTDS.toStringAsFixed(1)} %" : "...",
                          isSelected: selectedStat == "TDS",
                          onTap: () => _onStatCardTap("TDS"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.opacity,
                          label: "pH",
                          value: displayLiveValues ? "${_latestPH.toStringAsFixed(1)}" : "...",
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
                          value: displayLiveValues ? "${_latestTurbidity.toStringAsFixed(1)} %" : "...",
                          isSelected: selectedStat == "Turbidity",
                          onTap: () => _onStatCardTap("Turbidity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.flash_on,
                          label: "Conductivity",
                          value: displayLiveValues ? "${_latestConductivity.toStringAsFixed(1)} %" : "...",
                          isSelected: selectedStat == "Conductivity",
                          onTap: () => _onStatCardTap("Conductivity"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.bubble_chart,
                          label: "Salinity",
                          value: displayLiveValues ? "${_latestSalinity.toStringAsFixed(1)} %" : "...",
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
                          value: displayLiveValues ? "${_latestECCompensated.toStringAsFixed(1)} %" : "...",
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