import 'package:aqua/WaterTemperature.dart';
import 'package:flutter/material.dart';
import 'colors.dart'; 

class HistoricalData extends StatefulWidget {
  const HistoricalData({super.key});

  @override
  State<HistoricalData> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<HistoricalData> {
  
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? ASColor.fifthGradient
                  : ASColor.thirdGradient
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