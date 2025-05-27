import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:aqua/water_quality_model.dart'; // Import your data model
import 'package:aqua/water_quality_service.dart'; // Import your service

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
      home: const Statistics(),
    );
  }
}

class Statistics extends StatefulWidget {
  const Statistics({super.key});

  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  String selectedStat = "Temp";
  String selectedPeriod = "Daily"; // Default selection: "Daily" (maps to 24h)

  List<WaterQualityData> _currentData = [];
  bool _isLoading = true;
  String? _errorMessage;

  final WaterQualityService _waterQualityService = WaterQualityService();

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial fetch with default period
  }

  // Modified to accept a 'period' parameter
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentData = []; // Clear previous data
    });
    try {
      // Pass both selectedStat and selectedPeriod to the service
      final data = await _waterQualityService.fetchHistoricalData(
        selectedStat,
        selectedPeriod,
      );
      setState(() {
        _currentData =
            data.reversed.toList(); // Reverse to show oldest first on chart
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
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
        return ASColor.getCardColor(context);
      case "TDS":
        return ASColor.getCardColor(context);
      case "pH Level":
        return ASColor.getCardColor(context);
      case "Turbidity":
        return ASColor.getCardColor(context);
      case "Conductivity":
        return ASColor.getCardColor(context);
      case "Salinity":
        return ASColor.getCardColor(context);
      case "EC":
        return ASColor.getCardColor(context);
      default:
        return ASColor.getCardColor(context);
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

  @override
  Widget build(BuildContext context) {
    Color lineColor = getStatColor();

    // Helper function to create a highlight card structure
    Widget buildHighlightCard(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? color.withOpacity(0.1)
                  : ASColor.BGFourth,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.2),
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

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Water quality at a glance',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        wordSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Take a quick look at your water quality stats',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: ASColor.getTextColor(context),
                        letterSpacing: 0.5,
                        wordSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ASColor.getTextColor(context),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPeriod,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedPeriod = newValue!;
                              _fetchData(); // Trigger data fetch with new period
                            });
                          },
                          items:
                              <String>[
                                "Daily", // Maps to 24h
                                "Weekly", // Maps to 7d
                                "Monthly", // Maps to 30d
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Center(
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: ASColor.getTextColor(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Line Graph
              SizedBox(
                height: 300,
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : _currentData.isEmpty
                        ? const Center(
                          child: Text("No data available for this selection."),
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
                                        style: const TextStyle(fontSize: 12),
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
                                    List<DateTime> timeData = getTimeData();
                                    int index = value.toInt();
                                    if (index >= 0 && index < timeData.length) {
                                      String formattedTime = _formatTimestamp(
                                        timeData[index],
                                      );
                                      return Transform.rotate(
                                        angle: -45 * (3.141592653589793 / 180),
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
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
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
                                  color: getStatColor().withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Water quality highlights',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: ASColor.getTextColor(context),
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStat,
                        onChanged: (newValue) {
                          setState(() {
                            selectedStat = newValue!;
                            _fetchData(); // Fetch new data when statistic changes
                          });
                        },
                        isExpanded: true,
                        iconSize: 24,
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'Poppins',
                        ),
                        items:
                            <String>[
                              "Temp",
                              "TDS",
                              "pH Level",
                              "Turbidity",
                              "Conductivity",
                              "Salinity",
                              "EC",
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Center(
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      color: ASColor.getTextColor(context),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
