import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class GaugeMeter extends StatefulWidget {
  @override
  _GaugeMeterState createState() => _GaugeMeterState();
}

class _GaugeMeterState extends State<GaugeMeter> {
  double value = 0.0;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    fetchInitialValue();
    setupSocket();
  }

  void fetchInitialValue() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/data'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data.first.containsKey('turbidity_value')) {
          setState(() {
            value = (data.first['turbidity_value'] as num).toDouble();
          });
        }
      } else {
        print("Server responded with status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching initial value: $e");
    }
  }

  void setupSocket() {
    socket = IO.io('http://localhost:3001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Connected to WebSocket');
    });

    socket.on('updateData', (newData) {
      if (newData != null && newData.containsKey('value')) {
        setState(() {
          value = (newData['value'] as num).toDouble();
        });
      }
    });

    socket.onDisconnect((_) {
      print('Disconnected from WebSocket');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Color getWaterQualityColor(double value) {
    return value >= 70
        ? Colors.green
        : (value <= 30 ? Colors.red : Colors.orange);
  }

  String getWaterQualityStatus(double value) {
    if (value >= 70) return 'Clean Water';
    if (value <= 30) return 'Contaminated';
    return 'Moderate Quality';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFF131b42),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 100,
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 100,
                        startAngle: 180,
                        endAngle: 0,
                        showLabels: false,
                        showTicks: false,
                        axisLineStyle: AxisLineStyle(
                          thickness: 0.15,
                          thicknessUnit: GaugeSizeUnit.factor,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        pointers: <GaugePointer>[
                          RangePointer(
                            value: value,
                            cornerStyle: CornerStyle.bothCurve,
                            width: 0.15,
                            sizeUnit: GaugeSizeUnit.factor,
                            color: getWaterQualityColor(value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${value.toInt()}%',
          style: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange // Color for dark mode
                    : Colors.black, // Color for light mode
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 5),
        Text(
          getWaterQualityStatus(value),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: getWaterQualityColor(value),
          ),
        ),
      ],
    );
  }
}
