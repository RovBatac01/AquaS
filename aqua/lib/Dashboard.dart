import 'package:aqua/GaugeMeter.dart';
import 'package:aqua/WaterTemperature.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              alignment: Alignment.center,
              child: GaugeMeter(),
            ),

            SizedBox(height: 20,),

            Container(
              alignment: Alignment.center,
              child: GaugeMeter(),
            ),
            SizedBox(height: 20), // Space between widgets
            Container(
              alignment: Alignment.center,
              child: WaterTemperature(
                isDarkTheme: Theme.of(context).brightness == Brightness.dark,
              ),
            ),

            SizedBox(height: 20), // Space between widgets
            Container(
              alignment: Alignment.center,
              child: WaterTemperature(
                isDarkTheme: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ],
          
        ),
      ),
    );
  }
}