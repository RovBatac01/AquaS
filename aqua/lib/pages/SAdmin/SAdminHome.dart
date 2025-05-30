import 'package:aqua/pages/User/DetailCard.dart';
import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/SAdmin/SAdminDetails.dart'; // Import SAdminDetails
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import for json.decode
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage
import 'package:aqua/pages/Login.dart'; // Import your LoginScreen for redirection

// --- NEW/UPDATED: ApiService class ---
class ApiService {
  // IMPORTANT: Replace with your server's actual IP address or domain and port
  // If running on Android emulator, 10.0.2.2 usually maps to your host machine's localhost.
  // If running on a physical device, use your host machine's actual local IP address (e.g., 192.168.1.X).
  // Make sure this matches the port your server.js is listening on (e.g., 5000 if your server.js uses app.listen(5000))
  final String _baseUrl =
      'https://aquasense-p36u.onrender.com/api'; // Changed to 10.0.2.2 for emulator compatibility

  Future<int?> fetchTotalUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/total-users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalUsers'];
      } else {
        print(
          'Failed to fetch total users: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching total users: $e');
      return null;
    }
  }

  Future<int?> fetchTotalEstablishments() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/total-establishments'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalEstablishments'];
      } else {
        print(
          'Failed to fetch total establishments: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching total establishments: $e');
      return null;
    }
  }

  Future<int?> fetchTotalSensors() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/total-sensors'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalSensors'];
      } else {
        print(
          'Failed to fetch total sensors: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching total sensors: $e');
      return null;
    }
  }

  // API endpoint to fetch establishment names
  Future<List<String>?> fetchEstablishmentNames() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/establishments'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((name) => name.toString()).toList();
      } else {
        print(
          'Failed to fetch establishment names: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching establishment names: $e');
      return null;
    }
  }
}
// --- END NEW/UPDATED: API Service ---

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
  String _username =
      'Loading...'; // State variable to hold the fetched username

  // State variables for fetched counts
  int? _totalUsers;
  int? _totalEstablishments;
  int? _totalSensors;

  // --- UPDATED/NEW: State variables for fetched and filtered establishment names ---
  List<String> _allEstablishmentNames = []; // Store all fetched names
  List<String> _filteredEstablishmentNames = []; // Store names for display
  TextEditingController _searchController =
      TextEditingController(); // Controller for the search bar
  // --- END UPDATED/NEW ---

  final ApiService _apiService = ApiService(); // Instance of your ApiService

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Call the function to fetch the username when the widget initializes
    _fetchDashboardCounts(); // Call to fetch dashboard counts
    _fetchEstablishments(); // Call to fetch establishments
  }

  @override
  void dispose() {
    _searchController
        .dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  /// Fetches the username for the currently logged-in user.
  /// This function assumes the user's ID or authentication token is stored locally
  /// after a successful login.
  Future<void> _loadUsername() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString(
        'userToken',
      ); // Assuming you store a token

      final String? locallySavedUsername = prefs.getString('loggedInUsername');
      if (locallySavedUsername != null && locallySavedUsername.isNotEmpty) {
        setState(() {
          _username = locallySavedUsername;
        });
      }

      if (userToken == null) {
        setState(() {
          _username = 'Guest'; // User not logged in or token expired/missing
        });
        print(
          'User token not found. Cannot fetch username. Navigating to Login.',
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return; // Exit if no token
      }

      final response = await http.get(
        Uri.parse(
          'https://aquasense-p36u.onrender.com/api/user/profile',
        ), // Changed to 10.0.2.2 for emulator compatibility
        headers: {
          'Authorization':
              'Bearer $userToken', // Send JWT for backend to identify user
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _username =
              data['username'] ??
              'User'; // Use 'User' as fallback if username is null
        });
        print('Username fetched successfully: $_username');
      } else if (response.statusCode == 401) {
        setState(() {
          _username = 'Unauthorized';
        });
        print('Unauthorized: Token invalid or expired. Please log in again.');
        await prefs.remove('userToken');
        await prefs.remove('userId');
        await prefs.remove('loggedInUsername');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        print(
          'Failed to load username: ${response.statusCode} - ${response.body}',
        );
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

  // Method to fetch dashboard counts
  Future<void> _fetchDashboardCounts() async {
    setState(() {
      _totalUsers = null;
      _totalEstablishments = null;
      _totalSensors = null;
    });

    final usersFuture = _apiService.fetchTotalUsers();
    final establishmentsFuture = _apiService.fetchTotalEstablishments();
    final sensorsFuture = _apiService.fetchTotalSensors();

    final results = await Future.wait([
      usersFuture,
      establishmentsFuture,
      sensorsFuture,
    ]);

    setState(() {
      _totalUsers = results[0];
      _totalEstablishments = results[1];
      _totalSensors = results[2];
    });
  }

  // --- UPDATED: Method to fetch establishment names ---
  Future<void> _fetchEstablishments() async {
    setState(() {
      _allEstablishmentNames = []; // Clear previous data
      _filteredEstablishmentNames = []; // Clear filtered data
    });
    final names = await _apiService.fetchEstablishmentNames();
    if (names != null) {
      setState(() {
        _allEstablishmentNames = names;
        _filteredEstablishmentNames =
            names; // Initially, filtered list is the same as all
      });
    }
  }
  // --- END UPDATED ---

  // --- NEW: Search filtering logic ---
  void _filterEstablishments(String query) {
    List<String> tempFilteredList = [];
    if (query.isEmpty) {
      tempFilteredList = _allEstablishmentNames; // Show all if query is empty
    } else {
      tempFilteredList =
          _allEstablishmentNames.where((name) {
            return name.toLowerCase().contains(query.toLowerCase());
          }).toList();
    }
    setState(() {
      _filteredEstablishmentNames = tempFilteredList;
    });
  }
  // --- END NEW ---

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hi, $_username', // Display the fetched username
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: ASColor.getTextColor(context),
                          fontFamily: 'Poppins'
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          _fetchDashboardCounts();
                          _fetchEstablishments(); // Refresh both counts and establishments
                        },
                      ),
                    ],
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
                    color: isDarkMode ? ASColor.BGSecond : ASColor.BGFifth,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: TextField(
                    controller: _searchController, // Assign the controller
                    style: TextStyle(
                      color: isDarkMode ? ASColor.txt1Color : ASColor.txt2Color,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search,
                        color:
                            isDarkMode ? ASColor.txt1Color : ASColor.txt2Color,
                        size: 20,
                      ),
                      hintText: 'Search Establishments...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(color: Colors.grey),
                      contentPadding: const EdgeInsets.only(bottom: 10),
                    ),
                    onChanged:
                        _filterEstablishments, // Call the new filter method
                  ),
                ),

                const SizedBox(height: 10),

                // Use fetched data for Info Cards
                if (_totalEstablishments == null)
                  const Center(child: CircularProgressIndicator())
                else
                  buildInfoCard(
                    context: context,
                    title: 'Total Establishments',
                    value: _totalEstablishments?.toString() ?? 'N/A',
                    icon: Icons.window_outlined,
                    color: Colors.blue,
                  ),
                const SizedBox(height: 16),

                if (_totalSensors == null)
                  const Center(child: CircularProgressIndicator())
                else
                  buildInfoCard(
                    context: context,
                    title: 'Total Sensors',
                    value: _totalSensors?.toString() ?? 'N/A',
                    icon: Icons.sensors_rounded,
                    color: const Color(0xFF4BCA8C),
                  ),
                const SizedBox(height: 16),

                if (_totalUsers == null)
                  const Center(child: CircularProgressIndicator())
                else
                  buildInfoCard(
                    context: context,
                    title: 'Total Users',
                    value: _totalUsers?.toString() ?? 'N/A',
                    icon: Icons.people_alt_outlined,
                    color: Colors.redAccent,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // --- UPDATED: Dynamically generate DetailCards based on _filteredEstablishmentNames ---
            if (_allEstablishmentNames.isEmpty &&
                _searchController.text.isEmpty)
              const Center(
                child: CircularProgressIndicator(),
              ) // Still loading if all names are empty and no search
            else if (_filteredEstablishmentNames.isEmpty &&
                _searchController.text.isNotEmpty)
              const Center(
                child: Text('No matching establishments found.'),
              ) // No results for search
            else if (_filteredEstablishmentNames.isEmpty)
              const Center(
                child: Text('No establishments found.'),
              ) // No establishments after initial load
            else
              Column(
                children:
                    _filteredEstablishmentNames.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10.0,
                        ), // Add some spacing between cards
                        child: DetailCard(
                          title: name, // Use the filtered establishment name
                          quality:
                              'Good', // Assuming 'Good' is a default or placeholder
                          onEdit: () {
                            // You might want to pass the establishment name or ID to SAdminDetails
                            // For example: MaterialPageRoute(builder: (context) => SAdminDetails(establishmentName: name)),
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SAdminDetails(),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
              ),
            // --- END UPDATED ---
          ],
        ),
      ),
    );
  }
}

// Ensure this function is defined outside the class or in a utility file
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
