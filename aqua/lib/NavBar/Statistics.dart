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
  String selectedPeriod = "Daily"; // Default selection

  List<WaterQualityData> _currentData = [];
  bool _isLoading = true;
  String? _errorMessage;

  final WaterQualityService _waterQualityService = WaterQualityService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentData = []; // Clear previous data
    });
    try {
      final data = await _waterQualityService.fetchHistoricalData(selectedStat);
      setState(() {
        _currentData = data.reversed.toList(); // Reverse to show oldest first on chart
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // This function now uses the fetched data
  List<double> getCurrentChartData() {
    return _currentData.map((e) => e.value).toList();
  }

  // This function now uses the fetched data for timestamps
  List<DateTime> getTimeData() {
    return _currentData.map((e) => e.timestamp).toList();
  }

  Color getStatColor() {
    switch (selectedStat) {
      case "Temp":
        return ASColor.BGSixth;
      case "TDS":
        return ASColor.BGSixth;
      case "pH Level":
        return ASColor.BGSixth;
      case "Turbidity":
        return ASColor.BGSixth;
      case "Conductivity":
        return ASColor.BGSixth;
      case "Salinity":
        return ASColor.BGSixth;
      case "EC": // Using "EC" as the option for Electrical Conductivity
        return ASColor.BGSixth;
      default:
        return ASColor.BGSixth;
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

  @override
  Widget build(BuildContext context) {
    Color lineColor = getStatColor();

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
                        fontFamily: 'Poppins',
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
                        color: Colors.grey,
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
                      border: Border.all(color: Colors.green, width: 1.5),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPeriod = newValue!;
                            // For now, this dropdown doesn't affect fetching,
                            // but you'd implement logic here to fetch data for
                            // daily, weekly, or monthly periods if your backend supports it.
                          });
                        },
                        items: <String>[
                          "Daily",
                          "Weekly",
                          "Monthly",
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.green,
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? Center(child: Text(_errorMessage!))
                        : _currentData.isEmpty
                            ? const Center(child: Text("No data available for this selection."))
                            : LineChart(
                                LineChartData(
                                  // Set fixed min and max Y values for the graph
                                  minY: 0,
                                  maxY: 100,
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, _) => Text(
                                          value.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 50,
                                        interval: 1,
                                        getTitlesWidget: (value, _) {
                                          List<DateTime> timeData = getTimeData();
                                          int index = value.toInt();
                                          if (index >= 0 && index < timeData.length) {
                                            String formattedTime = DateFormat(
                                              'HH:mm:ss',
                                            ).format(timeData[index]);
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
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                        (index) =>
                                            FlSpot(index.toDouble(), getCurrentChartData()[index]),
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green, width: 1.5),
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
                        items: <String>[
                          "Temp",
                          "TDS",
                          "pH Level",
                          "Turbidity",
                          "Conductivity",
                          "Salinity",
                          "EC", // Changed from "Electrical Conductivity (Condensed)"
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Center(
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: Colors.green,
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
                      child: _highlightCard(
                        "Highest",
                        getStatMaxValue().toStringAsFixed(2), // Format to 2 decimal places
                        getStatColor(),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _highlightCard(
                        "Lowest",
                        getStatMinValue().toStringAsFixed(2), // Format to 2 decimal places
                        getStatColor(),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _highlightCard(
                        "Average",
                        getStatAverage().toStringAsFixed(2), // Format to 2 decimal places
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

  Widget _highlightCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
