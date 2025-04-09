import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

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
  String selectedStat = "pH Level";

  // Dummy data for each statistic
  List<int> phData = [7, 7, 7, 6, 8, 7, 7]; // pH Level
  List<int> turbidityData = [10, 15, 20, 25, 30, 28, 26]; // Turbidity
  List<int> ecData = [
    100,
    120,
    110,
    115,
    125,
    130,
    128,
  ]; // Electrical Conductivity
  List<int> tempData = [28, 29, 30, 31, 30, 29, 28]; // Temperature
  List<int> tdsData = [300, 320, 310, 330, 340, 335, 325]; // TDS

  List<double> _convertToDouble(List<int> intList) {
    return intList.map((e) => e.toDouble()).toList();
  }

  List<DateTime> getTimeData() {
    DateTime now = DateTime.now();
    return List.generate(
      7,
      (index) => now.subtract(Duration(minutes: 5 * (6 - index))),
    );
  }

  List<double> getCurrentData() {
    switch (selectedStat) {
      case "pH Level":
        return _convertToDouble(phData);
      case "Turbidity":
        return _convertToDouble(turbidityData);
      case "EC":
        return _convertToDouble(ecData);
      case "Temp":
        return _convertToDouble(tempData);
      case "TDS":
        return _convertToDouble(tdsData);
      default:
        return _convertToDouble(phData);
    }
  }

  Color getStatColor() {
    switch (selectedStat) {
      case "pH Level":
        return Colors.purple;
      case "Turbidity":
        return Colors.orange;
      case "EC":
        return Colors.red;
      case "Temp":
        return Colors.blue;
      case "TDS":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String selectedPeriod = "Daily"; // Default selection

  @override
  Widget build(BuildContext context) {
    List<double> data = getCurrentData();
    Color lineColor = getStatColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'STATISTICS',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // Added scrollable container
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                alignment: Alignment.centerLeft, // Align text to the left
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Align content to the left
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
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                    child: Center(
                      child: DropdownButton<String>(
                        value: selectedPeriod,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedPeriod = newValue!;
                          });
                        },
                        items:
                            <String>[
                              "Daily",
                              "Weekly",
                              "Monthly",
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Line Graph
              SizedBox(
                height: 300, // Specify a fixed height for the graph
                child: LineChart(
                  LineChartData(
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
                          reservedSize: 50, // Space for time labels
                          interval: 1, // Ensures every timestamp is shown
                          getTitlesWidget: (value, _) {
                            // Fetch timestamps at 5-minute intervals
                            List<DateTime> timeData = getTimeData();
                            int index = value.toInt();
                            if (index >= 0 && index < timeData.length) {
                              String formattedTime = DateFormat(
                                'HH:mm:ss',
                              ).format(timeData[index]);
                              return Transform.rotate(
                                angle:
                                    -45 *
                                    (3.141592653589793 /
                                        180), // Rotate by 45 degrees
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
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(
                          color: Colors.black,
                        ), // Keep left border
                        bottom: BorderSide(
                          color: Colors.black,
                        ), // Keep bottom border
                        right: BorderSide.none, // Remove right border
                        top: BorderSide.none, // Remove top border
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          getCurrentData().length,
                          (index) =>
                              FlSpot(index.toDouble(), getCurrentData()[index]),
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
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),

                  // Wrap DropdownButton inside a SizedBox to control its size
                  Container(
                    width: 90, // Set desired width
                    height: 30, // Set desired height
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Background color
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.blue,
                        width: 1.5,
                      ), // Rounded corners
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStat,
                        onChanged: (newValue) {
                          setState(() {
                            selectedStat = newValue!;
                          });
                        },
                        isExpanded: true, // Make the dropdown take full width
                        iconSize: 24, // Adjust the size of the dropdown icon
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'Poppins',
                          color: Colors.black, // Dropdown text color
                        ),
                        items:
                            <String>[
                              "pH Level",
                              "Turbidity",
                              "EC",
                              "Temp",
                              "TDS",
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors
                                            .black, // Text color inside the dropdown
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _highlightCard("Highest", "8.6", Colors.red),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: _highlightCard("Lowest", "5.3", Colors.green),
                    ),

                    SizedBox(width: 10,),
                    
                    Expanded(
                      child: _highlightCard("Average", "7.2", Colors.blue),
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
}

Widget _highlightCard(String title, String value, Color color) {
  return Container(
    width: 90,
    height: 120,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 8,
          spreadRadius: 4,
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(Icons.water_drop, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          "$title (pH)",
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
