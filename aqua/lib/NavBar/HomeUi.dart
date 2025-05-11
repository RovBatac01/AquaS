import 'package:aqua/NavBar/Details.dart';
import 'package:aqua/components/colors.dart';
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
                    'Hi, (Fetch Username)',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Column(
              children: [
                Container(
                  height: 70, // Increased height for better vertical spacing
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 27, 123, 201),
                  ),
                  padding: const EdgeInsets.only(
                    left: 10,
                  ), // Padding on left and right
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center, // Vertically center the texts
                        children: [
                          Text(
                            'Total Establishments',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 4), // Spacing between the two texts
                          Text(
                            '125',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),

                      Icon(
                        Icons.window_outlined, // You can use any icon here
                        color: Colors.white,
                        size: 100,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10), // Spacing between the two containers

                Container(
                  height: 70, // Increased height for better vertical spacing
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 75, 202, 140),
                  ),
                  padding: const EdgeInsets.only(
                    left: 10,
                  ), // Padding on left and right
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center, // Vertically center the texts
                        children: [
                          Text(
                            'Total Sensors',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 4), // Spacing between the two texts
                          Text(
                            '125',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),

                      Icon(
                        Icons.sensors_rounded, // You can use any icon here
                        color: Colors.white,
                        size: 100,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 10), // Spacing between the two containers

                Container(
                  height: 70, // Increased height for better vertical spacing
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.redAccent),
                  padding: const EdgeInsets.only(
                    left: 10,
                  ), // Padding on left and right
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center, // Vertically center the texts
                        children: [
                          Text(
                            'Total Users',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          SizedBox(height: 4), // Spacing between the two texts
                          Text(
                            '125',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),

                      Icon(
                        Icons.people_alt_outlined, // You can use any icon here
                        color: Colors.white,
                        size: 100,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            
          ],
        ),
      ),
    );
  }
}
