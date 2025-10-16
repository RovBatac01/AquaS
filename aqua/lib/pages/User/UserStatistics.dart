import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:aqua/water_quality_model.dart'; // Import your data model
import '../../device_aware_service.dart'; // Import device-aware service instead

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Quality Stats',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserStatistics(),
    );
  }
}

class UserStatistics extends StatefulWidget {
  const UserStatistics({super.key});

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<UserStatistics> {
  String selectedStat = "Loading...";
  String selectedPeriod =
      "Real-time"; // Default selection: "Daily" (maps to 24h)

  List<WaterQualityData> _currentData = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasApprovedAccess = false;
  String? _approvalMessage;
  String? _currentDeviceId;
  List<Map<String, dynamic>> _availableSensors = [];
  List<String> _availableSensorNames = ["Loading..."];

  final DeviceAwareService _deviceService = DeviceAwareService();

  // Map backend sensor type to frontend display name
  String _mapSensorTypeToDisplayName(String backendType) {
    switch (backendType.toLowerCase()) {
      case 'temperature':
        return 'Temp';
      case 'tds':
        return 'TDS';
      case 'ph':
        return 'pH Level';
      case 'turbidity':
        return 'Turbidity';
      case 'ec':
        return 'Conductivity';
      case 'salinity':
        return 'Salinity';
      case 'ec_compensated':
        return 'EC';
      default:
        return backendType;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAccessAndFetchData(); // Check access first, then fetch data
  }

  // Check device access approval before fetching data
  Future<void> _checkAccessAndFetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user has any approved device access
      _hasApprovedAccess = await _deviceService.hasApprovedDeviceAccess();

      if (_hasApprovedAccess) {
        // User has approved access, get the first accessible device
        final devices = await _deviceService.getAccessibleDevices();
        if (devices.isNotEmpty) {
          _currentDeviceId = devices.first['device_id'];

          // Fetch available sensors for this device
          _availableSensors = await _deviceService.getAvailableSensors(
            _currentDeviceId!,
          );

          // Map backend sensor names to frontend display names
          _availableSensorNames =
              _availableSensors.map((sensor) {
                String sensorType = sensor['type'].toString();
                return _mapSensorTypeToDisplayName(sensorType);
              }).toList();

          // Set the first available sensor as default, or fallback to "No Sensors"
          if (_availableSensorNames.isNotEmpty) {
            selectedStat = _availableSensorNames.first;
          } else {
            selectedStat = "No Sensors";
          }

          await _fetchData(); // Fetch data for the accessible device
        } else {
          setState(() {
            _hasApprovedAccess = false;
            _availableSensors = [];
            _availableSensorNames = [];
            _approvalMessage = 'No accessible devices found.';
            _isLoading = false;
          });
        }
      } else {
        // No approved access - check for pending requests
        List<Map<String, dynamic>> pendingRequests =
            await _deviceService.getPendingDeviceRequests();
        List<Map<String, dynamic>> allRequests =
            await _deviceService.getUserDeviceRequests();

        setState(() {
          _isLoading = false;

          if (pendingRequests.isNotEmpty) {
            _approvalMessage =
                'Your device access request is pending approval. Statistics will be available once approved.';
          } else if (allRequests.any((req) => req['status'] == 'rejected')) {
            _approvalMessage =
                'Your device access request was rejected. Please contact your administrator to view statistics.';
          } else {
            _approvalMessage =
                'No device access found. Please request access from your administrator to view statistics.';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to check device access: $e';
      });
    }
  }

  // Modified to use device-aware service
  Future<void> _fetchData() async {
    if (!_hasApprovedAccess || _currentDeviceId == null) return;

    // Don't fetch data if no sensors are available
    if (selectedStat == "No Sensors" || _availableSensorNames.isEmpty) {
      setState(() {
        _currentData = [];
        _isLoading = false;
        _errorMessage = "No sensors available for this device";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentData = []; // Clear previous data
    });

    try {
      final data = await _deviceService.fetchDeviceData(
        selectedStat,
        selectedPeriod,
        _currentDeviceId!,
      );

      if (mounted) {
        setState(() {
          _currentData =
              data.reversed.toList(); // Reverse to show oldest first on chart
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error fetching data: $error';
          _isLoading = false;
        });
      }
    }
  }

  List<double> getCurrentChartData() {
    return _currentData.map((e) => e.value).toList();
  }

  List<DateTime> getTimeData() {
    return _currentData.map((e) => e.timestamp).toList();
  }

  Color getStatColor() {
    switch (selectedStat) {
      case "Temp":
        return ASColor.getTextColor(context);
      case "TDS":
        return ASColor.getTextColor(context);
      case "pH Level":
        return ASColor.getTextColor(context);
      case "Turbidity":
        return ASColor.getTextColor(context);
      case "Conductivity":
        return ASColor.getTextColor(context);
      case "Salinity":
        return ASColor.getTextColor(context);
      case "EC":
        return ASColor.getTextColor(context);
      default:
        return ASColor.getTextColor(context);
    }
  }

  double getStatMaxValue() {
    if (_currentData.isEmpty) return 0.0;
    return _currentData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
  }

  double getStatMinValue() {
    if (_currentData.isEmpty) return 0.0;
    return _currentData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
  }

  double getStatAverage() {
    if (_currentData.isEmpty) return 0.0;
    final sum = _currentData.map((e) => e.value).reduce((a, b) => a + b);
    return sum / _currentData.length;
  }

  // Get the last (most recent) reading from the fetched data
  double getStatLastValue() {
    if (_currentData.isEmpty) return 0.0;
    return _currentData
        .last
        .value; // Assuming _currentData is sorted oldest to newest
  }

  /// Build approval pending UI for statistics
  Widget _buildApprovalPendingUI(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDarkMode ? ASColor.Background(context) : ASColor.BGfirst,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  size: 60,
                  color: Colors.orange[600],
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Statistics Unavailable',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ASColor.getTextColor(context),
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
                  _approvalMessage ??
                      'Device access required to view statistics.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange[700],
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    // If no approved access, show approval pending UI
    if (!_hasApprovedAccess && !_isLoading) {
      return _buildApprovalPendingUI(context);
    }

    // Helper function to create a highlight card structure
    Widget buildHighlightCard(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? color.withOpacity(0.1)
                  : ASColor.BGfirst,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // subtle shadow
              blurRadius: 6,
              offset: Offset(0, 2), // horizontal and vertical offset
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ASColor.getTextColor(context),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ASColor.getTextColor(context),
              ),
            ),
          ],
        ),
      );
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : ASColor.BGfirst,
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? null : ASColor.BGfirst,
          gradient:
              isDarkMode
                  ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[900]!, Colors.grey[850]!],
                  )
                  : null,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Enhanced Controls Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      // Enhanced Period Selector
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.grey[600]!
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedPeriod,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedPeriod = newValue!;
                                  _fetchData();
                                });
                              },
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color:
                                    isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                              ),
                              items:
                                  <String>[
                                    'Real-time',
                                    "Daily",
                                    "Weekly",
                                    "Monthly",
                                  ].map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enhanced Chart Section
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sensor Data Trends',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 300,
                        child:
                            _isLoading
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.blue,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Loading sensor data...',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : _errorMessage != null
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 48,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _errorMessage!,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.red,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                                : _currentData.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 48,
                                        color:
                                            isDarkMode
                                                ? Colors.grey[600]
                                                : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No data available for this selection",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          color:
                                              isDarkMode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : LineChart(
                                  LineChartData(
                                    minY: 0,
                                    maxY: 100,
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget:
                                              (value, _) => Text(
                                                value.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                          interval:
                                              _getBottomTitleInterval(), // Dynamic interval
                                          getTitlesWidget: (value, _) {
                                            List<DateTime> timeData =
                                                getTimeData();
                                            int index = value.toInt();
                                            if (index >= 0 &&
                                                index < timeData.length) {
                                              String formattedTime =
                                                  _formatTimestamp(
                                                    timeData[index],
                                                  );
                                              return Transform.rotate(
                                                angle:
                                                    -45 *
                                                    (3.141592653589793 / 180),
                                                child: Text(
                                                  formattedTime,
                                                  style: const TextStyle(
                                                    fontSize: 9,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text("");
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: const Border(
                                        left: BorderSide(color: Colors.black),
                                        bottom: BorderSide(color: Colors.black),
                                        right: BorderSide.none,
                                        top: BorderSide.none,
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: List.generate(
                                          getCurrentChartData().length,
                                          (index) => FlSpot(
                                            index.toDouble(),
                                            getCurrentChartData()[index],
                                          ),
                                        ),
                                        isCurved: true,
                                        color: getStatColor(),
                                        barWidth: 4,
                                        isStrokeCapRound: true,
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: getStatColor().withOpacity(
                                            0.3,
                                          ),
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

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Water Quality Highlights',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),

                // Enhanced Sensor Selection and Highlights Section
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Select Sensor Type:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Container(
                            width: 160, // Set specific width for the dropdown
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? Colors.grey[600]!
                                        : Colors.grey[300]!,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStat,
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedStat = newValue!;
                                    _fetchData();
                                  });
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[700],
                                ),
                                items:
                                    _availableSensorNames.isNotEmpty
                                        ? _availableSensorNames
                                            .map<DropdownMenuItem<String>>((
                                              String value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Poppins',
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        isDarkMode
                                                            ? Colors.white
                                                            : Colors.black87,
                                                  ),
                                                ),
                                              );
                                            })
                                            .toList()
                                        : <DropdownMenuItem<String>>[
                                          DropdownMenuItem<String>(
                                            value: "No Sensors",
                                            child: Text(
                                              "No Sensors",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins',
                                                color:
                                                    isDarkMode
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      IntrinsicHeight(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: buildHighlightCard(
                                // Using the new inline helper
                                "Highest",
                                getStatMaxValue().toStringAsFixed(2),
                                getStatColor(),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: buildHighlightCard(
                                // Using the new inline helper
                                "Lowest",
                                getStatMinValue().toStringAsFixed(2),
                                getStatColor(),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: buildHighlightCard(
                                // Using the new inline helper
                                "Average",
                                getStatAverage().toStringAsFixed(2),
                                getStatColor(),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: buildHighlightCard(
                                // Using the new inline helper
                                "Last Reading",
                                getStatLastValue().toStringAsFixed(2),
                                getStatColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to format timestamp based on selected period
  String _formatTimestamp(DateTime timestamp) {
    switch (selectedPeriod) {
      case "Daily":
        return DateFormat(
          'HH:mm',
        ).format(timestamp); // Show hour and minute for daily
      case "Weekly":
      case "Monthly":
        return DateFormat(
          'MMM d',
        ).format(timestamp); // Show month and day for weekly/monthly
      default:
        return DateFormat('HH:mm:ss').format(timestamp);
    }
  }

  // Helper to determine interval for bottom titles based on selected period
  double _getBottomTitleInterval() {
    if (_currentData.length <= 1)
      return 1.0; // Avoid division by zero or single point
    // Adjust interval based on the number of data points to prevent overcrowding
    return (_currentData.length / 5).ceilToDouble(); // Show approx 5 labels
  }
}
