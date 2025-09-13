import 'package:flutter/material.dart';

class WaterQualityPopupDemo extends StatefulWidget {
  const WaterQualityPopupDemo({super.key});

  @override
  State<WaterQualityPopupDemo> createState() => _WaterQualityPopupDemoState();
}

class _WaterQualityPopupDemoState extends State<WaterQualityPopupDemo> {
  @override
  void initState() {
    super.initState();

    // Show popup after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWaterQualityPopup(context);
    });
  }

  void _showWaterQualityPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must click "Close"
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Water Quality Color Indicators",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Our system uses color coding to quickly communicate water quality status:",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildIndicatorCard(
                    color: Colors.green.shade100,
                    dotColor: Colors.green,
                    title: "Green - Excellent/Safe",
                    description:
                        "Parameters are within optimal range. Water is safe for intended use.",
                  ),
                  const SizedBox(height: 12),
                  _buildIndicatorCard(
                    color: Colors.lightGreen.shade100,
                    dotColor: Colors.lightGreen,
                    title: "Light Green - Good",
                    description:
                        "Parameters in acceptable range. Minor treatment may be required.",
                  ),
                  const SizedBox(height: 12),
                  _buildIndicatorCard(
                    color: Colors.yellow.shade100,
                    dotColor: Colors.yellow,
                    title: "Yellow - Moderate/Caution",
                    description:
                        "Parameters approaching critical levels. Treatment recommended.",
                  ),
                  const SizedBox(height: 12),
                  _buildIndicatorCard(
                    color: Colors.red.shade100,
                    dotColor: Colors.red,
                    title: "Red - Critical/Poor",
                    description:
                        "Parameters outside safe ranges. Immediate action required.",
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicatorCard({
    required Color color,
    required Color dotColor,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored Dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
    );
  }
}
