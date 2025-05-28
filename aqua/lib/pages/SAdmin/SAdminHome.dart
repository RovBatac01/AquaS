import 'package:aqua/pages/User/DetailCard.dart';
import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/SAdmin/SAdminDetails.dart'; // Import SAdminDetails
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import for json.decode
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage
import 'package:aqua/pages/Login.dart'; // Import your LoginScreen for redirection

// NOTE: It's generally better to have only one main() function, usually in main.dart.
// If this file is not your primary entry point, you can remove this main() function.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SuperAdminHomeScreen(),
      debugShowCheckedModeBanner: false, // Optional: remove debug banner
    );
  }
}

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<SuperAdminHomeScreen> {
  String _username = 'Loading...'; // State variable to hold the fetched username

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Call the function to fetch the username when the widget initializes
  }

  /// Fetches the username for the currently logged-in user.
  /// This function assumes the user's ID or authentication token is stored locally
  /// after a successful login.
  Future<void> _loadUsername() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken'); // Assuming you store a token

      // --- NEW: Try to get locally stored username first for quicker display ---
      final String? locallySavedUsername = prefs.getString('loggedInUsername');
      if (locallySavedUsername != null && locallySavedUsername.isNotEmpty) {
        setState(() {
          _username = locallySavedUsername;
        });
      }
      // --- END NEW ---

      if (userToken == null) {
        setState(() {
          _username = 'Guest'; // User not logged in or token expired/missing
        });
        print('User token not found. Cannot fetch username. Navigating to Login.');
        // If token is null, redirect to login screen
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        return; // Exit if no token
      }

      final response = await http.get(
        // IMPORTANT: The URL should NOT have ?userId=1
        Uri.parse('http://10.0.2.2:5000/api/user/profile'), // Corrected URL: Backend identifies user from token
        headers: {
          'Authorization': 'Bearer $userToken', // Send JWT for backend to identify user
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username = data['username'] ?? 'User'; // Use 'User' as fallback if username is null
        });
        print('Username fetched successfully: $_username');
      } else if (response.statusCode == 401) {
        // Handle unauthorized access (e.g., token invalid or expired)
        setState(() {
          _username = 'Unauthorized';
        });
        print('Unauthorized: Token invalid or expired. Please log in again.');
        // Clear token and navigate to login page
        await prefs.remove('userToken');
        await prefs.remove('userId');
        await prefs.remove('loggedInUsername');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      else {
        print('Failed to load username: ${response.statusCode} - ${response.body}');
        setState(() {
          _username = 'Error'; // Indicate an error
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        _username = 'Error'; // Indicate a general error
      });
    }
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
                    'Hi, $_username', // Display the fetched username
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
                    color: Colors.white,
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
