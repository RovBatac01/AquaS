import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterTemperature extends StatefulWidget {
  final bool isDarkTheme;

  const WaterTemperature({Key? key, required this.isDarkTheme}) : super(key: key);

  @override
  _WaterTemperatureState createState() => _WaterTemperatureState();
}

class _WaterTemperatureState extends State<WaterTemperature> {
  List<FlSpot> temperatureData = [];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchTemperature();
    _timer = Timer.periodic(Duration(seconds: 5), (timer) => _fetchTemperature());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _fetchTemperature() {
    setState(() {
      double simulatedTemperature = Random().nextInt(100).toDouble();
      double time = temperatureData.isNotEmpty ? temperatureData.last.x + 1 : 0;
      temperatureData = (temperatureData.length >= 20)
          ? temperatureData.sublist(1) + [FlSpot(time, simulatedTemperature)]
          : temperatureData + [FlSpot(time, simulatedTemperature)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: widget.isDarkTheme ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Water Temperature',
            style: TextStyle(
              color: widget.isDarkTheme ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.7,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: temperatureData,
                    isCurved: true,
                    color: Colors.cyan,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}