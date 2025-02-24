import 'package:aqua/GaugeMeter.dart';
import 'package:aqua/Login.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _temperature = 21; // Default temperature

  // Function to determine water status
  String getWaterStatus(double temp) {
    if (temp < 15) return "Cold Water";
    if (temp < 30) return "Warm Water";
    return "Hot Water";
  }

  int _currentIndex = 0;

  // // List of screens for Bottom Navigation Bar
  // final List<Widget> _screens = [
  //   HomeScreen(),
  //   AboutScreen(),
  //   SettingsScreen(),
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AQUASENSE',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            color: ASColor.txt2Color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: ASColor.secondaryGradient),
        ),
      ),

      // Drawer for navigation
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 200, // Adjust height as needed
              width: double.infinity,
              decoration: BoxDecoration(gradient: ASColor.secondaryGradient),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            // Expanded ListView for menu items
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.home_max_outlined),
                    title: Text('Home Screen'),
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.water_drop),
                    title: Text('Water Set'),
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Management'),
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('History'),
                    onTap: () {
                      setState(() {
                        _currentIndex = 3;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            // Logout Button at the bottom
            Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Display the current screen
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width, // Full screen width
              height: MediaQuery.of(context).size.height, // Full screen height
              decoration: BoxDecoration(gradient: ASColor.secondaryGradient),
              child: Column(
                children: [
                  Container(
                  width: 400,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Temperature",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Icon(
                            Icons.thermostat,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ],
                      ),
                      Text(
                        "${_temperature.toInt()}°C",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        getWaterStatus(_temperature),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Slider(
                        value: _temperature,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        activeColor: Colors.blueAccent,
                        inactiveColor: Colors.grey,
                        onChanged: (value) {
                          setState(() {
                            _temperature = value;
                          });
                        },
                      ),
                    ],
                  ),
                  ),

                  SizedBox(height: 50,),
                
                Container(
                  width: 200,
                  height: 250,
                  child:  GaugeMeter(),
                )
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text(
//         'Home Screen',
//         style: TextStyle(fontSize: 24),
//       ),
//     );
//   }
// }

// // About Screen
// class AboutScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text(
//         'About Screen',
//         style: TextStyle(fontSize: 24),
//       ),
//     );
//   }
// }

// // Settings Screen
// class SettingsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text(
//         'Settings Screen',
//         style: TextStyle(fontSize: 24),
//       ),
//     );
//   }
// }
