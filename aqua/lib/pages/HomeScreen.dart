import 'package:aqua/components/Details.dart';
import 'package:aqua/tanks/TankOne.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Quality',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: PreferredSize(
  preferredSize: Size.fromHeight(90.0), // Adjust this value for the desired height
  child: ClipRRect(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30.0), // Adjust these values for the desired radius
      bottomRight: Radius.circular(30.0),
    ),
    child: AppBar(
      title: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Text(
          'Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: false,
      backgroundColor: Color(0xFF0a782f),
    ),
  ),
),
      backgroundColor: const Color(0xfff0ecec),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, (Fetch who logged in)',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  const HomeWaterTankCard(), 
                  const HomeWaterTankCard(),  
                  const HomeWaterTankCard(),   // Use the new widget here
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
