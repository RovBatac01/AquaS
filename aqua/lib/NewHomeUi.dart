import 'package:aqua/Details.dart';
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
      appBar: AppBar(
        title: const Text(
          'HOME',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          // IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 16, ),
              child: Column(
                crossAxisAlignment:CrossAxisAlignment.start, 
                children: [
                  Text(
                    'Hi, Hussin',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Your devices are working hard!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [
                  Container(
                    height: 170,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          15,
                        ), // Rounded corners
                      ),
                      elevation: 5, // Adds a subtle shadow effect
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Home Water Tank',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blueAccent,
                                  ), // Edit icon
                                  onPressed: () {
                                    // Add edit function here
                                  },
                                ),
                              ],
                            ),
                            Text(
                              "Water Quality",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors
                                        .grey, // Green text for "Great" quality
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Great',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w200,
                                    color:
                                        Colors
                                            .blueAccent, // Green text for "Great" quality
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const DetailsScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(
                                      60,
                                      20,
                                    ), // Forces square shape (width = height)
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        4,
                                      ), // Sharp edges (square)
                                    ),
                                    padding:
                                        EdgeInsets
                                            .zero, // Optional: Tightens internal spacing
                                  ),
                                  child: Text(
                                    'Details',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
