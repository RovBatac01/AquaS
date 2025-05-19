import 'package:aqua/components/colors.dart';
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
        return ASColor.BGSixth;
      case "Turbidity":
        return ASColor.BGSixth;
      case "EC":
        return ASColor.BGSixth;
      case "Temp":
        return ASColor.BGSixth;
      case "TDS":
        return ASColor.BGSixth;
      default:
        return ASColor.BGSixth;
    }
  }

  String selectedPeriod = "Daily"; // Default selection

  @override
  Widget build(BuildContext context) {
    List<double> data = getCurrentData();
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
                          });
                        },
                        items: <String>[
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
                          color: Colors.green
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
                child: LineChart(
                  LineChartData(
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
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(
                          color: Colors.black,
                        ),
                        bottom: BorderSide(
                          color: Colors.black,
                        ),
                        right: BorderSide.none,
                        top: BorderSide.none,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          getCurrentData().length,
                          (index) => FlSpot(
                            index.toDouble(),
                            getCurrentData()[index],
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
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.green,
                        width: 1.5,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStat,
                        onChanged: (newValue) {
                          setState(() {
                            selectedStat = newValue!;
                          });
                        },
                        isExpanded: true,
                        iconSize: 24,
                        style: const TextStyle(
                          fontSize: 8,
                          fontFamily: 'Poppins',
                        ),
                        items: <String>[
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
                                fontFamily: 'Poppins',
                                color: Colors.green
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
                      child: _highlightCard("Highest", getStatMaxValue().toString(), getStatColor()),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _highlightCard("Lowest", getStatMinValue().toString(), getStatColor()),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _highlightCard("Average", getStatAverage().toString(), getStatColor()),
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

  double getStatMaxValue() {
    switch (selectedStat) {
      case "pH Level":
        return phData.reduce((a, b) => a > b ? a : b).toDouble();
      case "Turbidity":
        return turbidityData.reduce((a, b) => a > b ? a : b).toDouble();
      case "EC":
        return ecData.reduce((a, b) => a > b ? a : b).toDouble();
      case "Temp":
        return tempData.reduce((a, b) => a > b ? a : b).toDouble();
      case "TDS":
        return tdsData.reduce((a, b) => a > b ? a : b).toDouble();
      default:
        return phData.reduce((a, b) => a > b ? a : b).toDouble();
    }
  }

  double getStatMinValue() {
    switch (selectedStat) {
      case "pH Level":
        return phData.reduce((a, b) => a < b ? a : b).toDouble();
      case "Turbidity":
        return turbidityData.reduce((a, b) => a < b ? a : b).toDouble();
      case "EC":
        return ecData.reduce((a, b) => a < b ? a : b).toDouble();
      case "Temp":
        return tempData.reduce((a, b) => a < b ? a : b).toDouble();
      case "TDS":
        return tdsData.reduce((a, b) => a < b ? a : b).toDouble();
      default:
        return phData.reduce((a, b) => a < b ? a : b).toDouble();
    }
  }

  double getStatAverage() {
    switch (selectedStat) {
      case "pH Level":
        return phData.reduce((a, b) => a + b) / phData.length.toDouble();
      case "Turbidity":
        return turbidityData.reduce((a, b) => a + b) / turbidityData.length.toDouble();
      case "EC":
        return ecData.reduce((a, b) => a + b) / ecData.length.toDouble();
      case "Temp":
        return tempData.reduce((a, b) => a + b) / tempData.length.toDouble();
      case "TDS":
        return tdsData.reduce((a, b) => a + b) / tdsData.length.toDouble();
      default:
        return phData.reduce((a, b) => a + b) / phData.length.toDouble();
    }
  }

  Widget _highlightCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color,
          width: 1.2,
        ),
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
