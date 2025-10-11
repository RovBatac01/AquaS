import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/components/colors.dart';
import 'package:aqua/config/api_config.dart';
import 'package:aqua/pages/SAdmin/SAdminDetails.dart'; // Import SAdminDetails
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final String _baseUrl = ApiConfig.apiBase;

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
  final TextEditingController establishmentName = TextEditingController();
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
          ApiConfig.userProfileEndpoint,
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

  void _showAddEstablishmentDialog(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController nameController = TextEditingController();
    final Map<String, bool> parameters = {
      'Conductivity': false,
      'EC': false,
      'pH Level': false,
      'Salinity': false,
      'TDS': false,
      'Temperature': false,
      'Turbidity': false,
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ASColor.Background(context),
          title: Text(
            'Add Establishment',
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: establishmentName,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fill all the text field';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.white10 : Colors.black12,
                    hintText: 'Establishment Name',
                    hintStyle: TextStyle(
                      color: ASColor.getTextColor(context).withOpacity(0.5),
                      fontFamily: 'Poppins',
                      fontSize: 14.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(
                    color: ASColor.getTextColor(context),
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 20),
                ...parameters.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(
                      key,
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                      ),
                    ),
                    value: parameters[key],
                    onChanged: (value) {
                      parameters[key] = value!;
                      // Required to rebuild UI when checkbox changes
                      (context as Element).markNeedsBuild();
                    },
                    activeColor: Colors.green, // Color of the checkbox when selected
                    checkColor: Colors.white, // Color of the check icon itself
                    controlAffinity: ListTileControlAffinity.leading, // optional: move checkbox to the left
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel',
              style: TextStyle(
                color: ASColor.getTextColor(context),
                fontFamily: 'Poppins',
                fontSize: 12.sp,
              ),),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                // Collect data here
                String name = nameController.text;
                Map<String, bool> selectedParams = {
                  for (var entry in parameters.entries)
                    if (entry.value) entry.key: entry.value,
                };

                // TODO: Send to backend or handle as needed
                print('Name: $name');
                print('Selected: $selectedParams');

                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Confirm',
              style: TextStyle(
                color: ASColor.txt1Color,
                fontFamily: 'Poppins',
                fontSize: 12.sp,
              ),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
              : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back! 👋',
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context).withOpacity(0.7),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _username,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'Montserrat',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Enhanced Search Bar
              Container(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: ASColor.getTextColor(context),
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: ASColor.getTextColor(context).withOpacity(0.6),
                      size: 20,
                    ),
                    hintText: 'Search establishments...',
                    hintStyle: TextStyle(
                      color: ASColor.getTextColor(context).withOpacity(0.5),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: _filterEstablishments,
                ),
              ),

              const SizedBox(height: 30),

              // Enhanced Stats Cards Section
              Text(
                'System Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Montserrat',
                ),
              ),
              
              const SizedBox(height: 16),

              // Stats Cards with better layout
              if (_totalEstablishments == null || _totalSensors == null || _totalUsers == null)
                Container(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    buildEnhancedInfoCard(
                      context: context,
                      title: 'Total Establishments',
                      value: _totalEstablishments?.toString() ?? 'N/A',
                      icon: Icons.business_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildEnhancedInfoCard(
                      context: context,
                      title: 'Active Sensors',
                      value: _totalSensors?.toString() ?? 'N/A',
                      icon: Icons.sensors_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildEnhancedInfoCard(
                      context: context,
                      title: 'Registered Users',
                      value: _totalUsers?.toString() ?? 'N/A',
                      icon: Icons.people_rounded,
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFE65100)],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Enhanced Establishments Section
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Establishments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 6,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_filteredEstablishmentNames.length} Active',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Enhanced Establishments List
              if (_allEstablishmentNames.isEmpty && _searchController.text.isEmpty)
                Container(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                )
              else if (_filteredEstablishmentNames.isEmpty && _searchController.text.isNotEmpty)
                buildEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  subtitle: 'Try adjusting your search terms',
                )
              else if (_filteredEstablishmentNames.isEmpty)
                buildEmptyState(
                  icon: Icons.business_rounded,
                  title: 'No establishments yet',
                  subtitle: 'Establishments will appear here once added',
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredEstablishmentNames.length,
                  itemBuilder: (context, index) {
                    final name = _filteredEstablishmentNames[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: buildEnhancedDetailCard(
                        name: name,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SAdminDetails(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced UI Components
Widget buildEnhancedInfoCard({
  required BuildContext context,
  required String title,
  required String value,
  required IconData icon,
  required Gradient gradient,
}) {
  return Container(
    height: 95,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: gradient.colors.first.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -5,
            bottom: -5,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
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

Widget buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: EdgeInsets.all(40),
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 48,
            color: Colors.grey.withOpacity(0.5),
          ),
        ),
        SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            fontFamily: 'Montserrat',
          ),
        ),
        SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.withOpacity(0.7),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget buildEnhancedDetailCard({
  required String name,
  required VoidCallback onTap,
}) {
  return Builder(
    builder: (context) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white12 : Colors.black12,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Establishment icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.sensors_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Active monitoring',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow icon
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: ASColor.getTextColor(context).withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
