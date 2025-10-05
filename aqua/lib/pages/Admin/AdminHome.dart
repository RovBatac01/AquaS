import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Admin/AdminDetails.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // Import for json.decode
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:aqua/pages/Login.dart'; // Import LoginScreen for redirection

// --- NEW: Create a separate API service class (similar to SAdmin) ---
class ApiService {
  // IMPORTANT: Use localhost:5000 for web emulator
  final String _baseUrl = 'http://localhost:5000/api'; // Web emulator can access localhost directly

  Future<int?> fetchTotalUsers() async {
    try {
      // Get the stored token for authenticated device-scoped request
      final prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken');
      final int? userId = prefs.getInt('userId');

      if (userToken == null) {
        print('No token found. Cannot fetch device-scoped total users.');
        return null;
      }

      print('DEBUG: Fetching total users for userId: $userId with token');

      final response = await http.get(
        Uri.parse('$_baseUrl/my/total-users'), // Device-scoped authenticated endpoint
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Total users response status: ${response.statusCode}');
      print('DEBUG: Total users response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed total users data: $data');
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
      // Get the stored token for authenticated device-scoped request
      final prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken');
      final int? userId = prefs.getInt('userId');

      if (userToken == null) {
        print('No token found. Cannot fetch device-scoped total sensors.');
        return null;
      }

      print('DEBUG: Fetching total sensors for userId: $userId with token');

      final response = await http.get(
        Uri.parse('$_baseUrl/my/total-sensors'), // Device-scoped authenticated endpoint
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Total sensors response status: ${response.statusCode}');
      print('DEBUG: Total sensors response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed total sensors data: $data');
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

  // Get admin's assigned establishment based on their device_id
  Future<Map<String, dynamic>?> checkDeviceAssociation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken');
      final int? userId = prefs.getInt('userId');

      if (userToken == null) {
        print('No token found. Cannot check device association.');
        return null;
      }

      print('DEBUG: Getting establishment for admin user ID: $userId based on device_id');

      final response = await http.get(
        Uri.parse('$_baseUrl/my/device-info'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      print('DEBUG: Device info response status: ${response.statusCode}');
      print('DEBUG: Device info response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Admin device association data: $data');
        
        // Extract establishment information
        final bool hasDevice = data['hasDevice'] ?? false;
        final bool hasEstablishment = data['hasEstablishment'] ?? false;
        final String? establishmentName = data['establishmentName'];
        final String? deviceId = data['deviceId']?.toString();
        final String? establishmentId = data['establishmentId']?.toString();
        
        print('DEBUG: Admin has device: $hasDevice, has establishment: $hasEstablishment');
        print('DEBUG: Establishment name: $establishmentName');
        
        return {
          'hasDevice': hasDevice,
          'hasEstablishment': hasEstablishment,
          'deviceId': deviceId,
          'establishmentId': establishmentId,
          'establishmentName': establishmentName,
          'deviceMessage': hasEstablishment 
            ? 'Assigned to establishment: $establishmentName'
            : (hasDevice 
              ? 'Device registered but no establishment assigned'
              : 'No device or establishment assigned')
        };
      } else {
        print('Failed to get device info: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error checking device association: $e');
      return null;
    }
  }

  // Enhanced logout method with session destroy
  Future<bool> performLogout() async {
    try {
      // Get stored token
      final prefs = await SharedPreferences.getInstance();
      final String? userToken = prefs.getString('userToken');
      
      // Call logout endpoint with authentication
      if (userToken != null) {
        try {
          final response = await http.post(
            Uri.parse('http://localhost:5000/logout'),
            headers: {
              'Authorization': 'Bearer $userToken',
              'Content-Type': 'application/json',
            },
          ).timeout(Duration(seconds: 10)); // Add 10 second timeout
          
          if (response.statusCode == 200) {
            print('Server logout successful');
          } else {
            print('Server logout failed: ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('Logout API call failed (non-critical): $e');
        }
      }
      
      // Clear local session data
      await prefs.clear();
      
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
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

  // --- State variables for device and establishment association ---
  bool? _hasDeviceAssociation; // null = loading, true = has device, false = no device
  bool? _hasEstablishmentAssociation; // null = loading, true = has establishment, false = no establishment
  String? _establishmentName; // The name of the establishment assigned to this admin
  String? _deviceMessage; // Status message about device/establishment association
  // --- END ---

  final ApiService _apiService = ApiService(); // Instance of your ApiService

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Call the function to load username when the widget initializes
    _fetchDashboardCounts(); // NEW: Fetch total users and sensors
    _checkDeviceAssociation(); // NEW: Check device association
  }

  @override
  void dispose() {
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
        Uri.parse('http://localhost:5000/api/user/profile'), // Web emulator can access localhost directly
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

  // --- Method to check device association and load establishment ---
  Future<void> _checkDeviceAssociation() async {
    print('DEBUG: Starting device association check...');
    
    try {
      final response = await _apiService.checkDeviceAssociation();
      
      if (response != null) {
        print('DEBUG: Device association response received successfully');
        print('DEBUG: Has device: ${response['hasDevice']}');
        print('DEBUG: Has establishment: ${response['hasEstablishment']}');
        print('DEBUG: Establishment name: ${response['establishmentName']}');
        
        setState(() {
          _hasDeviceAssociation = response['hasDevice'] ?? false;
          _hasEstablishmentAssociation = response['hasEstablishment'] ?? false;
          _establishmentName = response['establishmentName'];
          _deviceMessage = response['deviceMessage'] ?? 'No device association';
        });
        
        // Log the final state
        print('DEBUG: Updated UI state - Establishment: $_establishmentName');
      } else {
        print('ERROR: No response received from device association check');
        setState(() {
          _hasDeviceAssociation = false;
          _hasEstablishmentAssociation = false;
          _establishmentName = null;
          _deviceMessage = 'Failed to load establishment information';
        });
      }
    } catch (e) {
      print('ERROR: Exception in device association check: $e');
      setState(() {
        _hasDeviceAssociation = false;
        _hasEstablishmentAssociation = false;
        _establishmentName = null;
        _deviceMessage = 'Error loading establishment information';
      });
    }
  }
  // --- END ---



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
                            _loggedInUsername,
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
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white12 : Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: ASColor.getTextColor(context),
                        ),
                        onPressed: () {
                          _fetchDashboardCounts();
                          _checkDeviceAssociation();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Device Association Status
              if (_hasDeviceAssociation == null)
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
                  ),
                  child: Center(
                    child: Text(
                      'Checking device association...',
                      style: TextStyle(
                        color: ASColor.getTextColor(context).withOpacity(0.6),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_hasEstablishmentAssociation == true ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasEstablishmentAssociation == true ? Colors.green : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasEstablishmentAssociation == true ? Icons.business : Icons.info_outline,
                        color: _hasEstablishmentAssociation == true ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _hasEstablishmentAssociation == true 
                            ? 'Assigned to: ${_establishmentName ?? 'Unknown'}'
                            : _deviceMessage ?? 'No establishment assigned',
                          style: TextStyle(
                            color: _hasEstablishmentAssociation == true ? Colors.green : Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              // Enhanced Stats Cards Section
              Text(
                'Your Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Montserrat',
                ),
              ),
              
              const SizedBox(height: 16),

              // Stats Cards with better layout
              if (_totalSensors == null || _totalUsers == null)
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
                      'Your Establishments',
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
                          _hasEstablishmentAssociation == true ? '1 Active' : '0 Active',
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

              // Admin's Establishment Display
              if (_hasDeviceAssociation == null)
                Container(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                )
              else if (_hasEstablishmentAssociation == false)
                buildEmptyState(
                  icon: Icons.business_rounded,
                  title: 'No establishment assigned',
                  subtitle: 'Please contact administrator to assign an establishment to your account',
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: buildEnhancedDetailCard(
                    name: _establishmentName ?? 'Unknown Establishment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDetailsScreen(),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
  }
}