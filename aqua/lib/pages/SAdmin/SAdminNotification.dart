import 'package:aqua/NavBar/NotificationDetailPage.dart';
import 'package:flutter/material.dart';

import 'package:aqua/components/colors.dart'; // Assuming this file defines ASColor
import 'package:http/http.dart' as http; // Import for making HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding

void main() {
  runApp(
    MaterialApp(home: SAdminNotification(), debugShowCheckedModeBanner: false),
  );
}

class SAdminNotification extends StatefulWidget {
  const SAdminNotification({super.key});

  @override
  _SAdminNotificationState createState() => _SAdminNotificationState();
}

class _SAdminNotificationState extends State<SAdminNotification> {
  // Use a List of Map<String, dynamic> to accommodate various data types from backend
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> filteredNotifications = [];
  bool _isLoading = true; // To show a loading indicator
  String? _errorMessage; // To display any fetch errors
  String _selectedFilter = 'All'; // Current filter selection

  // Filter options
  final List<String> _filterOptions = [
    'All',
    'Sensor',
    'Schedule',
    'Request',
    'New User',
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications(); // Call the fetch function when the widget initializes
  }

  /// Fetches notifications from the backend API.
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true; // Set loading state to true
      _errorMessage = null; // Clear any previous error messages
    });

    try {
      // The endpoint for Super Admin notifications (unauthenticated)
      final response = await http.get(
        Uri.parse(
          'https://aquas-production.up.railway.app/api/notifications/superadmin',
        ), // <-- Adjust your backend URL if different
        headers: {
          'Content-Type': 'application/json',
          // No 'Authorization' header needed for this unauthenticated endpoint
        },
      );

      if (response.statusCode == 200) {
        // Decode the JSON response. The backend is expected to return a list directly.
        final List<dynamic> fetchedNotifications = json.decode(response.body);

        setState(() {
          notifications =
              fetchedNotifications.map((notif) {
                // Map backend fields to your local notification structure.
                // Ensure the keys match what your backend returns (e.g., 'id', 'type', 'title', 'message', 'createdAt', 'read').
                return {
                  'id':
                      notif['id']
                          .toString(), // Convert ID to string for consistency
                  'title':
                      notif['title'] ?? 'No Title', // Use 'title' from backend
                  'subtitle':
                      notif['message'] ??
                      'No Message', // Use 'message' from backend as 'subtitle'
                  'time': _formatTimestamp(
                    notif['createdAt'],
                  ), // Format 'createdAt' from backend
                  'type':
                      notif['type'] ?? 'default', // Use 'type' for icon mapping
                  'is_read':
                      notif['read'] == 1 ||
                      notif['read'] ==
                          true, // Handle boolean from DB (int 1/0 or actual boolean)
                };
              }).toList();
          _applyFilter(); // Apply the current filter after fetching notifications
        });
      } else {
        // Handle non-200 responses (e.g., 404, 500)
        setState(() {
          _errorMessage =
              'Failed to load notifications: ${response.statusCode} ${response.reasonPhrase}';
        });
        print(
          'Failed to load notifications: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions during the HTTP request
      setState(() {
        _errorMessage = 'Error connecting to the server: $e';
      });
      print('Error fetching notifications: $e');
    } finally {
      setState(() {
        _isLoading = false; // Always set loading to false when done
      });
    }
  }

  /// Applies the current filter to the notifications list
  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'All') {
        filteredNotifications = List.from(notifications);
      } else {
        filteredNotifications =
            notifications.where((notification) {
              return notification['type'].toString().toLowerCase() ==
                  _selectedFilter.toLowerCase();
            }).toList();
      }
    });
  }

  /// Updates the filter and reapplies it
  void _updateFilter(String? newFilter) {
    if (newFilter != null) {
      setState(() {
        _selectedFilter = newFilter;
      });
      _applyFilter();
    }
  }

  /// Deletes a notification from the backend and updates the UI.
  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://aquas-production.up.railway.app/api/notifications/superadmin/$notificationId',
        ), // <-- Adjust your backend URL if different
        headers: {
          'Content-Type': 'application/json',
          // No 'Authorization' header needed for this unauthenticated endpoint
        },
      );

      if (response.statusCode == 200) {
        // If deletion is successful, remove the item from the local list
        setState(() {
          notifications.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully!')),
        );
      } else {
        // Parse error message from backend if available
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete notification: ${errorData['message'] ?? response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  /// Helper function to format a timestamp string into a human-readable relative time.
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      // Parse the timestamp string received from the backend
      final dateTime =
          DateTime.parse(timestamp).toLocal(); // Convert to local time zone
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        // For older notifications, display the date
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      // If parsing fails, return the original timestamp string
      print('Error formatting timestamp: $e');
      return timestamp;
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
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
        child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(
                      color: ASColor.getTextColor(context).withOpacity(0.6),
                      fontFamily: 'Poppins',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ASColor.getTextColor(context),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchNotifications,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : notifications.isEmpty
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: ASColor.getTextColor(context).withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up! No new notifications to display.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ASColor.getTextColor(context).withOpacity(0.6),
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Enhanced Header with Filter
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${filteredNotifications.length} notifications',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ASColor.getTextColor(context).withOpacity(0.6),
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Enhanced Filter Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  color: ASColor.getTextColor(context).withOpacity(0.6),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Filter:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: ASColor.getTextColor(context),
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFilter,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: ASColor.getTextColor(context).withOpacity(0.6),
                                      ),
                                      style: TextStyle(
                                        color: ASColor.getTextColor(context),
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                      ),
                                      dropdownColor: ASColor.getCardColor(context),
                                      items: _filterOptions.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                      onChanged: _updateFilter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Enhanced Notifications List
                    Expanded(
                      child: filteredNotifications.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: ASColor.getTextColor(context).withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Matching Notifications',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: ASColor.getTextColor(context),
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No notifications found for the selected filter.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ASColor.getTextColor(context).withOpacity(0.6),
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification = filteredNotifications[index];
                              final notificationType = notification['type'] ?? 'default';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getNotificationTypeColor(notificationType).withOpacity(0.2),
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NotificationDetailPage(
                                            title: notification['title']!,
                                            subtitle: notification['subtitle']!,
                                            time: notification['time']!,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Enhanced notification icon
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _getNotificationTypeColor(notificationType).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: _getEnhancedNotificationIcon(notificationType),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notification['title']!,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: ASColor.getTextColor(context),
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notification['subtitle']!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: ASColor.getTextColor(context).withOpacity(0.7),
                                                    fontFamily: 'Poppins',
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time_rounded,
                                                      size: 14,
                                                      color: ASColor.getTextColor(context).withOpacity(0.5),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      notification['time']!,
                                                      style: TextStyle(
                                                        color: ASColor.getTextColor(context).withOpacity(0.5),
                                                        fontSize: 12,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Actions
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                Icons.delete_outline_rounded,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                              onPressed: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: Text(
                                                      'Delete Notification',
                                                      style: TextStyle(
                                                        fontFamily: 'Montserrat',
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to delete this notification?',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: Text(
                                                          'Cancel',
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            color: ASColor.getTextColor(context),
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            fontFamily: 'Poppins',
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true && notification['id'] != null) {
                                                  _deleteNotification(notification['id'], index);
                                                }
                                              },
                                              tooltip: 'Delete notification',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),
      ),
    );
  }

  Color _getNotificationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sensor':
        return Colors.red;
      case 'schedule':
        return Colors.blue;
      case 'request':
        return Colors.orange;
      case 'new_user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _getEnhancedNotificationIcon(String type) {
    final color = _getNotificationTypeColor(type);
    IconData iconData;
    
    switch (type.toLowerCase()) {
      case 'sensor':
        iconData = Icons.sensors_rounded;
        break;
      case 'schedule':
        iconData = Icons.calendar_month_rounded;
        break;
      case 'request':
        iconData = Icons.pending_actions_rounded;
        break;
      case 'new_user':
        iconData = Icons.person_add_rounded;
        break;
      default:
        iconData = Icons.notifications_rounded;
    }
    
    return Icon(iconData, color: color, size: 24);
  }
}
