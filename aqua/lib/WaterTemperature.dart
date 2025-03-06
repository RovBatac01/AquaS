import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class TurbidityMonitor extends StatefulWidget {
  final bool isDarkTheme;

  const TurbidityMonitor({Key? key, required this.isDarkTheme}) : super(key: key);

  @override
  _TurbidityMonitorState createState() => _TurbidityMonitorState();
}

class _TurbidityMonitorState extends State<TurbidityMonitor> {
  List<FlSpot> turbidityData = [];
  late Timer _timer;
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _fetchTurbidity();
    _connectSocket();
    _timer = Timer.periodic(Duration(seconds: 10), (timer) => _fetchTurbidity());
  }

  @override
  void dispose() {
    _timer.cancel();
    socket.dispose();
    super.dispose();
  }

  void _fetchTurbidity() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/data'));

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        // Handling both List and Single Object Response
        List<dynamic> dataList = decodedData is List ? decodedData : [decodedData];

        setState(() {
          turbidityData = dataList.map((entry) {
            double time = (entry['id'] ?? turbidityData.length).toDouble();
            double value = (entry['turbidity_value'] ?? 0).toDouble();
            return FlSpot(time, value);
          }).toList();
        });

        print("Fetched Data: $turbidityData"); // Debugging
      } else {
        print("Failed to fetch data. Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching turbidity data: $e");
    }
  }

  void _connectSocket() {
    socket = io.io('http://localhost:3001', io.OptionBuilder()
        .setTransports(['websocket'])
        .setReconnectionAttempts(5)
        .build());

    socket.onConnect((_) => print("Connected to WebSocket"));

    socket.on('updateData', (data) {
      try {
        double time = turbidityData.isNotEmpty ? turbidityData.last.x + 1 : 0;
        double value = (data['turbidity_value'] ?? 0).toDouble();

        setState(() {
          turbidityData = (turbidityData.length >= 20)
              ? turbidityData.sublist(1) + [FlSpot(time, value)]
              : turbidityData + [FlSpot(time, value)];
        });

        print("WebSocket Data Received: $data"); // Debugging
      } catch (e) {
        print("Error parsing WebSocket data: $e");
      }
    });

    socket.onDisconnect((_) => print("Disconnected from WebSocket"));
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
            'Turbidity Levels',
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
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: widget.isDarkTheme ? Colors.white : Colors.black),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minY: 0, // Set minimum Y value
                maxY: 100, // Set maximum Y value
                lineBarsData: [
                  LineChartBarData(
                    spots: turbidityData,
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
