import 'package:aqua/pages/User/DetailCard.dart';
import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/SAdmin/SAdminDetails.dart'; // Import SAdminDetails
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SuperAdminHomeScreen(); // Remove inner MaterialApp
  }
}

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<SuperAdminHomeScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SingleChildScrollView(
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: ASColor.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            Column(
              children: [
                Container(
                  height: 36,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? ASColor.BGSecond : ASColor.BGFifth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: isDarkMode ? ASColor.txt1Color : ASColor.txt2Color,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search,
                        color: isDarkMode ? ASColor.txt1Color : ASColor.txt2Color,
                        size: 20,
                      ),
                      hintText: 'Search Establishments...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      contentPadding: EdgeInsets.only(bottom: 10),
                    ),
                    onChanged: (value) {
                      print("Searching Home: $value");
                    },
                  ),
                ),

                SizedBox(height: 10),

                buildInfoCard(
                  context: context,
                  title: 'Total Establishments',
                  value: '125',
                  icon: Icons.window_outlined,
                  color: Colors.blue,
                ),
                buildInfoCard(
                  context: context,
                  title: 'Total Sensors',
                  value: '125',
                  icon: Icons.sensors_rounded,
                  color: const Color(0xFF4BCA8C),
                ),
                buildInfoCard(
                  context: context,
                  title: 'Total Users',
                  value: '125',
                  icon: Icons.people_alt_outlined,
                  color: Colors.redAccent,
                ),
              ],
            ),

            SizedBox(height: 20),

            DetailCard(
              title: 'Home Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SAdminDetails()),
                );
              },
            ),

            DetailCard(
              title: 'School Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SAdminDetails()),
                );
              },
            ),

            DetailCard(
              title: 'Apartment Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SAdminDetails()),
                );
              },
            ),

            DetailCard(
              title: 'Store Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SAdminDetails()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildInfoCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color:  Colors.white,
                    ),
              ),
            ],
          ),
          Icon(
            icon,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }
