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
      final response = await http.get(Uri.parse('http://localhost:5000/data'));
      if (response.statusCode == 200) {
        setState(() {
          value = json.decode(response.body)['value'].toDouble();
        });
      }
    } catch (e) {
      print("Error fetching initial value: $e");
    }
  }

  void setupSocket() {
    socket = IO.io('http://localhost:5000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.onConnect((_) {
      print('Connected to WebSocket');
    });

    socket.on('updateData', (newData) {
      setState(() {
        value = (newData['value'] as num).toDouble();
      });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container with Gauge inside
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Color(0xFF131b42),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter, // Align everything to the bottom
            children: [
              // Quarter-circle gauge positioned at the bottom
              Positioned(
                bottom: 10, // Adjust this to fit well
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 100, // Half the height of the container
                  child: SfRadialGauge(
                    axes: <RadialAxis>[
                      RadialAxis(
                        minimum: 0,
                        maximum: 100,
                        startAngle: 180, // Makes it a bottom quarter-circle
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
                            color: Color(0xFF6FCF97),
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

        // Display the percentage outside the box
        SizedBox(height: 10), // Space between box and text
        Text(
          '${value.toInt()}%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
