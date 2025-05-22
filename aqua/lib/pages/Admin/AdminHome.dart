import 'package:aqua/pages/DetailCard.dart';
import 'package:aqua/pages/Details.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW: Import shared_preferences


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
      home: const AdminHomeScreen(),
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  // Note: It's common practice to name this _AdminHomeScreenState,
  // but keeping _HomeScreenState as per your original code.
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<AdminHomeScreen> {
  // NEW: Declare the state variable to hold the username
  String _loggedInUsername = 'Guest'; // Default value until fetched

  @override
  void initState() {
    super.initState();
    _loadUsername(); // NEW: Call the function to load username when the widget initializes
  }

  // NEW: Function to load the username from SharedPreferences
  Future<void> _loadUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Retrieve the username using the key 'loggedInUsername'
      // Use 'Guest' as a fallback if no username is found
      _loggedInUsername = prefs.getString('loggedInUsername') ?? 'Guest';
    });
  }

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
                    // MODIFIED: Use the state variable here
                    'Hi, $_loggedInUsername',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Column(
              children: [
                Container(
                  height: 36,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? Colors.grey[800]
                            : const Color.fromARGB(255, 167, 232, 201),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextField(
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        size: 20,
                      ),
                      hintText: 'Search Establishments...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                      contentPadding: const EdgeInsets.only(bottom: 10),
                    ),
                    onChanged: (value) {
                      print("Searching Home: $value");
                    },
                  ),
                ),

                const SizedBox(
                  height: 10,
                ), // Spacing between the two containers

                const SizedBox(
                  height: 10,
                ), // Spacing between the two containers// Spacing between the two containers

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

            const SizedBox(height: 20),

            DetailCard(
              title: 'Home Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailsScreen()),
                );
              },
            ),

            DetailCard(
              title: 'School Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailsScreen()),
                );
              },
            ),

            DetailCard(
              title: 'Apartment Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailsScreen()),
                );
              },
            ),

            DetailCard(
              title: 'Store Water Tank',
              quality: 'Good',
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetailsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Icon(icon, color: Colors.white, size: 40),
        ],
      ),
    );
  }
}
