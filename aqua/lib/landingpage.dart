
import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            
            Container(
              decoration: BoxDecoration(
                gradient: ASColor.primaryGradient
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
                child: 
                  Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Home',
                style: TextStyle(
                  fontSize: 12.0,
                  color: ASColor.txt2Color
                ),),
                Text('About Us',
                style: TextStyle(
                  fontSize: 12.0,
                  color: ASColor.txt2Color
                ),),
                Text('Services',
                style: TextStyle(
                  fontSize: 12.0,
                  color: ASColor.txt2Color
                ),),
                Text('Contact Us',
                style: TextStyle(
                  fontSize: 12.0,
                  color: ASColor.txt2Color
                ),)
              ],
            ),
            ),
            
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('AquaSense',
                  style: TextStyle(
                    fontSize: 30,
                    color: ASColor.txt2Color
                ),)
              ],
              ),
            ),
            )
          ],
        ),
      ),
    );
  }
}
