import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // For the circular progress indicator

class DissolvedOxygen extends StatefulWidget {
  const DissolvedOxygen({super.key});

  @override
  _DissolvedOxygenState createState() => _DissolvedOxygenState();
}

class _DissolvedOxygenState extends State<DissolvedOxygen> {
  bool isConnected = true;
  final double dissolvedOxygen = 8.5; // Example dissolved oxygen value
  final String waterQuality = "Excellent"; // Example water quality

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double percentage = (dissolvedOxygen / 15) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content
        children: <Widget>[
          // Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                isConnected = !isConnected;
              });
            },
            child: Container(
              width: 120,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isConnected ? const Color(0xFF20a44c) : const Color(0xFFd9534f),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: isConnected ? 64 : 0,
                    top: 3,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                        child: Text(
                          "Connected",
                          style: TextStyle(
                            color: isConnected ? Colors.white : Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                        child: Text(
                          "Disconnected",
                          style: TextStyle(
                            color: isConnected ? Colors.grey[700] : Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Meter
          SizedBox(
            width: 250,
            height: 250,
            child: SfRadialGauge(
              enableLoadingAnimation: true,
              animationDuration: 1500,
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  startAngle: 130,
                  endAngle: 50,
                  radiusFactor: 0.8,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: AxisLineStyle(
                    thickness: 10,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[300]!,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: percentage,
                      width: 10,
                      color: isConnected ? const Color(0xFF20a44c) : const Color(0xFFd9534f),
                      enableAnimation: true,
                      animationDuration: 1500,
                      animationType: AnimationType.ease,
                    ),
                    NeedlePointer(
                      value: percentage,
                      needleLength: 0.6,
                      enableAnimation: true,
                      animationDuration: 1500,
                      animationType: AnimationType.ease,
                      needleColor:
                          theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      angle: 90,
                      positionFactor: 0.1,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text
                            (
                            "Dissolved O₂",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            dissolvedOxygen.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "ppm",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Water Quality Text
          Text(
            'Water Quality: $waterQuality',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500, // Make it bold
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
