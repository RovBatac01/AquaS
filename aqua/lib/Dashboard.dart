import 'package:aqua/GaugeMeter.dart';
import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Color getTurbidityColor(double ntu) {
    return ntu < 5 ? Colors.green : Colors.red; // Green = Normal, Red = High
  }

  // Function to determine text based on NTU level
  String getTurbidityStatus(double ntu) {
    return ntu < 5 ? 'Normal Level' : 'High Turbidity Detected!';
  }

  // Example NTU value (replace this with your real sensor data)
  double ntuLevel = 6.2; // Change this dynamically

  @override
  Widget build(BuildContext context) {
    // Detect if the app is in Light or Dark Mode
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? ASColor.fifthGradient
                  : ASColor.fourthGradient,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: 30,
                ), // Add space above the first container
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20), // Side margin
                  padding: EdgeInsets.all(20), // Inner padding
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[900]
                            : Colors.white, // Dynamic background
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(
                                  0.5,
                                ) // Darker shadow in dark mode
                                : Colors.black.withOpacity(
                                  0.1,
                                ), // Light shadow in light mode
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Turbidity',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : Colors.blueAccent, // Adjust text color
                        ),
                      ),
                      SizedBox(height: 10), // Spacing
                      Divider(
                        thickness: 1,
                        color:
                            isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade300, // Adaptive divider
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Turbidity is the key parameter for assessing overall quality of water',
                      ),
                      SizedBox(height: 10),
                      GaugeMeter(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.only(
                  top: 30,
                ), // Add space above the first container
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20), // Side margin
                  padding: EdgeInsets.all(20), // Inner padding
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[900]
                            : Colors.white, // Dynamic background
                    borderRadius: BorderRadius.circular(15), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(
                                  0.5,
                                ) // Darker shadow in dark mode
                                : Colors.black.withOpacity(
                                  0.1,
                                ), // Light shadow in light mode
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Turbidity',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDarkMode
                                  ? Colors.white
                                  : Colors.blueAccent, // Adjust text color
                        ),
                      ),
                      SizedBox(height: 10), // Spacing
                      Divider(
                        thickness: 1,
                        color:
                            isDarkMode
                                ? Colors.grey.shade600
                                : Colors.grey.shade300, // Adaptive divider
                      ),
                      SizedBox(height: 10), // Spacing
                      GaugeMeter(), // Your additional content
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
