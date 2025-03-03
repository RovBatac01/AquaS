import 'package:aqua/WaterTemperature.dart';
import 'package:flutter/material.dart';

class HistoricalData extends StatefulWidget {
  const HistoricalData({super.key});

  @override
  State<HistoricalData> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HistoricalData> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? null // Keep dark mode background as is
                  : LinearGradient(
                    colors: [
                      Color(0xFFE0F7FA),
                      Color(0xFFD1C4E9),
                    ], // Ice Blue to Soft Purple
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
               Padding(padding: EdgeInsets.all(20),
              child: 
                Container(
                  alignment: Alignment.center,
                  child: TurbidityMonitor(isDarkTheme: Theme.of(context).brightness == Brightness.dark,),
                )
              ),
        
              SizedBox(height: 20,),
        
              Padding(padding: EdgeInsets.all(20),
              child: 
                Container(
                  alignment: Alignment.center,
                  child: TurbidityMonitor(isDarkTheme: Theme.of(context).brightness == Brightness.dark,),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}