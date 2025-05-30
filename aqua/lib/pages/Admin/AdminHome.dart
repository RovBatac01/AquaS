import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Admin/AdminDetails.dart';
import 'package:aqua/pages/User/DetailCard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // Import for json.decode
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:aqua/pages/Login.dart'; // Import LoginScreen for redirection

// --- NEW: Create a separate API service class (similar to SAdmin) ---
class ApiService {
  // IMPORTANT: Replace with your server's actual IP address or domain and port
  final String _baseUrl = 'https://aquasense-p36u.onrender.com/api'; // Use 10.0.2.2 for emulator, or your PC's IP for physical device

  Future<int?> fetchTotalUsers() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/total-users'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['totalUsers'];
      } else {
        print('Failed to fetch total users: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching total users: $e');
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
        print('Failed to fetch total sensors: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching total sensors: $e');
      return null;
    }
  }

  // API endpoint to fetch establishment names (Admin also needs this to display their specific establishments)
  Future<List<String>?> fetchEstablishmentNames() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/establishments'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((name) => name.toString()).toList();
      } else {
        print('Failed to fetch establishment names: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching establishment names: $e');
      return null;
    }
  }
}
// --- END NEW: API Service ---

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
  _AdminHomeScreenState createState() => _AdminHomeScreenState(); // Renamed for clarity
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _loggedInUsername = 'Loading...'; // State variable to hold the fetched username

  // --- NEW: State variables for fetched counts ---
  int? _totalUsers;
  int? _totalSensors;

  // --- NEW: State variables for fetched and filtered establishment names ---
  List<String> _allEstablishmentNames = []; // Store all fetched names
  List<String> _filteredEstablishmentNames = []; // Store names for display
  TextEditingController _searchController = TextEditingController(); // Controller for the search bar
  // --- END NEW ---

  final ApiService _apiService = ApiService(); // Instance of your ApiService

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Call the function to load username when the widget initializes
    _fetchDashboardCounts(); // NEW: Fetch total users and sensors
    _fetchEstablishments(); // NEW: Fetch establishment names
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller when the widget is removed
    super.dispose();
  }

  // Function to load the username from SharedPreferences and fetch from backend
  Future<void> _loadUsername() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken');

      // Try to get locally stored username first for quicker display
      final String? locallySavedUsername = prefs.getString('loggedInUsername');
      if (locallySavedUsername != null && locallySavedUsername.isNotEmpty) {
        setState(() {
          _loggedInUsername = locallySavedUsername;
        });
      }

      if (userToken == null) {
        setState(() {
          _loggedInUsername = 'Guest';
        });
        print('User token not found. Cannot fetch username. Navigating to Login.');
        // If token is null, redirect to login screen
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
        return; // Exit if no token
      }

      final response = await http.get(
        Uri.parse('https://aquasense-p36u.onrender.com/api/user/profile'), // Adjust URL for physical device
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _loggedInUsername = data['username'] ?? 'User';
        });
        print('Username fetched successfully: $_loggedInUsername');
      } else if (response.statusCode == 401) {
        setState(() {
          _loggedInUsername = 'Unauthorized';
        });
        print('Unauthorized: Token invalid or expired. Please log in again.');
        // Clear token and navigate to login page
        await prefs.remove('userToken');
        await prefs.remove('userId');
        await prefs.remove('loggedInUsername');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        print('Failed to load username: ${response.statusCode} - ${response.body}');
        setState(() {
          _loggedInUsername = 'Error';
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        _loggedInUsername = 'Error';
      });
    }
  }

  // --- NEW: Method to fetch dashboard counts for Admin ---
  Future<void> _fetchDashboardCounts() async {
    // Set state to null to show loading indicators
    setState(() {
      _totalUsers = null;
      _totalSensors = null;
    });

    // Fetch data for sensors and users concurrently
    final sensorsFuture = _apiService.fetchTotalSensors();
    final usersFuture = _apiService.fetchTotalUsers();

    // Wait for all futures to complete
    final results = await Future.wait([sensorsFuture, usersFuture]);

    // Update the state with the fetched data
    setState(() {
      _totalSensors = results[0];
      _totalUsers = results[1];
    });
  }
  // --- END NEW ---

  // --- NEW: Method to fetch establishment names (similar to SAdmin) ---
  Future<void> _fetchEstablishments() async {
    setState(() {
      _allEstablishmentNames = []; // Clear previous data
      _filteredEstablishmentNames = []; // Clear filtered data
    });
    final names = await _apiService.fetchEstablishmentNames();
    if (names != null) {
      setState(() {
        _allEstablishmentNames = names;
        _filteredEstablishmentNames = names; // Initially, filtered list is the same as all
      });
    }
  }
  // --- END NEW ---

  // --- NEW: Search filtering logic ---
  void _filterEstablishments(String query) {
    List<String> tempFilteredList = [];
    if (query.isEmpty) {
      tempFilteredList = _allEstablishmentNames; // Show all if query is empty
    } else {
      tempFilteredList = _allEstablishmentNames.where((name) {
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
                        'Hi, $_loggedInUsername', // Display the fetched username
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: ASColor.getTextColor(context),
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
                        color: isDarkMode ? ASColor.txt1Color : ASColor.txt2Color,
                        size: 20,
                      ),
                      hintText: 'Search Establishments...',
                      border: InputBorder.none,
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      contentPadding: const EdgeInsets.only(bottom: 10),
                    ),
                    onChanged: _filterEstablishments, // Call the new filter method
                  ),
                ),

                const SizedBox(height: 10),

                // --- NEW: Use fetched data for Info Cards (Total Sensors) ---
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
                const SizedBox(height: 16), // Added spacing for consistency

                // --- NEW: Use fetched data for Info Cards (Total Users) ---
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
                // --- END NEW ---
              ],
            ),

            const SizedBox(height: 20),

            // --- NEW: Dynamically generate DetailCards based on filtered establishments ---
            if (_allEstablishmentNames.isEmpty && _searchController.text.isEmpty)
              const Center(child: CircularProgressIndicator()) // Still loading if all names are empty and no search
            else if (_filteredEstablishmentNames.isEmpty && _searchController.text.isNotEmpty)
              const Center(child: Text('No matching establishments found.')) // No results for search
            else if (_filteredEstablishmentNames.isEmpty)
              const Center(child: Text('No establishments found.')) // No establishments after initial load
            else
              Column(
                children: _filteredEstablishmentNames.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0), // Add some spacing between cards
                    child: DetailCard(
                      title: name, // Use the filtered establishment name
                      quality: 'Good', // Assuming 'Good' is a default or placeholder
                      onEdit: () {
                        // You can pass the establishment name or ID to AdminDetailsScreen if needed
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminDetailsScreen()),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            // --- END NEW ---
          ],
        ),
      ),
    );
  }

  // This function was already correctly defined, just included for completeness.
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