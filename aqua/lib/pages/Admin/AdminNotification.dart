import 'package:aqua/config/api_config.dart';
import 'package:aqua/NavBar/NotificationDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aqua/components/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminNotification extends StatefulWidget {
  const AdminNotification({super.key});

  @override
  _AdminNotification createState() => _AdminNotification();
}

class _AdminNotification extends State<AdminNotification> {
  List<Map<String, dynamic>> notifications = [];
  List<Map<String, dynamic>> deviceRequests = [];
  bool _isLoading = true;
  bool _isDeviceRequestsLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0; // 0 for notifications, 1 for device requests

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _fetchDeviceRequests();
  }

  /// Fetches notifications from the backend
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/notifications/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications =
              (data['notifications'] as List).map((notif) {
                return {
                  'id': notif['id'].toString(),
                  'title': notif['title'] ?? 'No Title',
                  'subtitle': notif['message'] ?? 'No Message',
                  'time': _formatTimestamp(notif['createdAt']),
                  'type': notif['type'] ?? 'default',
                  'is_read': notif['read'] == 1 || notif['read'] == true,
                };
              }).toList();
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load notifications: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetches pending device requests for the admin
  Future<void> _fetchDeviceRequests() async {
    print('DEBUG: Starting to fetch device requests...');
    setState(() {
      _isDeviceRequestsLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        print('DEBUG: No authentication token found');
        setState(() {
          _errorMessage = 'Authentication token not found';
          _isDeviceRequestsLoading = false;
        });
        return;
      }

      print('DEBUG: Making API call to fetch device requests...');
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/device-requests/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: API response status: ${response.statusCode}');
      print('DEBUG: API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('DEBUG: Parsed device requests data: $data');
        setState(() {
          deviceRequests =
              (data['requests'] as List).map((request) {
                return {
                  'id': request['id'],
                  'username': request['username'],
                  'email': request['email'],
                  'device_id': request['device_id'],
                  'device_name': request['device_name'] ?? 'Unknown Device',
                  'message': request['message'] ?? '',
                  'created_at': request['created_at'],
                };
              }).toList();
          _isDeviceRequestsLoading = false;
        });
        print('DEBUG: Set ${deviceRequests.length} device requests in state');
      } else {
        print('DEBUG: API call failed with status: ${response.statusCode}');
        setState(() {
          _errorMessage =
              'Failed to load device requests: ${response.statusCode} ${response.reasonPhrase}';
          _isDeviceRequestsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching device requests: $e';
        _isDeviceRequestsLoading = false;
      });
    }
  }

  /// Handle device request approval or rejection
  Future<void> _handleDeviceRequest(
    String requestId,
    String action, {
    String? message,
  }) async {
    print('DEBUG: Handling device request - ID: $requestId, Action: $action');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        print('DEBUG: No authentication token for device request action');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      print('DEBUG: Sending ${action} request for device request $requestId');
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBase}/device-requests/$requestId/respond'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'response_message': message ?? ''}),
      );

      print('DEBUG: Device request response status: ${response.statusCode}');
      print('DEBUG: Device request response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request ${action}d successfully!'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
          ),
        );

        _fetchDeviceRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error'] ?? 'Failed to process request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show device request action dialog
  void _showDeviceRequestDialog(Map<String, dynamic> request) {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Device Access Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User: ${request['username']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Email: ${request['email']}'),
                Text(
                  'Device ID: ${request['device_id']}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (request['device_name'] != 'Unknown Device')
                  Text('Device: ${request['device_name']}'),
                SizedBox(height: 8),
                if (request['message'].isNotEmpty) ...[
                  Text(
                    'User Message:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(request['message']),
                  SizedBox(height: 8),
                ],
                Text('Admin Response (Optional):'),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Enter response message...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleDeviceRequest(
                    request['id'],
                    'reject',
                    message: messageController.text,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Reject', style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleDeviceRequest(
                    request['id'],
                    'approve',
                    message: messageController.text,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Approve', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  /// Delete a notification
  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBase}/notifications/admin/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully')),
        );
      } else {
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

  /// Format timestamp for display
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
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
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  /// Get notification icon based on type
  Icon _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'device_request':
        return Icon(Icons.devices, color: Colors.orange);
      case 'device_response':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'sensor':
        return Icon(Icons.sensors, color: Colors.red);
      case 'schedule':
        return Icon(Icons.calendar_month, color: Colors.blue);
      case 'request':
        return Icon(Icons.help, color: Colors.purple);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  /// Build notifications list
  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 16.sp),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications to display.',
          style: TextStyle(
            fontSize: 16.sp,
            color: ASColor.getTextColor(context),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  /// Build device requests list
  Widget _buildDeviceRequestsList() {
    if (_isDeviceRequestsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deviceRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No device access requests',
              style: TextStyle(
                fontSize: 18,
                color: ASColor.getTextColor(context),
              ),
            ),
            Text(
              'Requests from users will appear here',
              style: TextStyle(
                fontSize: 14,
                color: ASColor.getTextColor(context).withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: deviceRequests.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final request = deviceRequests[index];
        return _buildDeviceRequestItem(request);
      },
    );
  }

  /// Build individual device request item
  Widget _buildDeviceRequestItem(Map<String, dynamic> request) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.devices, color: Colors.orange),
        ),
        title: Text(
          'Device: ${request['device_id']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ASColor.getTextColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User: ${request['username']} (${request['email']})',
              style: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.7),
              ),
            ),
            if (request['message'].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Message: ${request['message']}',
                  style: TextStyle(
                    color: ASColor.getTextColor(context).withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Text(
              _formatTimestamp(request['created_at']),
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.3, // Max 30% of screen width
            minWidth: 90, // Minimum width for three buttons
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: IconButton(
                  onPressed: () => _handleDeviceRequest(request['id'], 'reject'),
                  icon: Icon(Icons.close, color: Colors.red, size: 16.sp),
                  tooltip: 'Reject',
                  constraints: BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.all(1),
                ),
              ),
              Flexible(
                child: IconButton(
                  onPressed: () => _handleDeviceRequest(request['id'], 'approve'),
                  icon: Icon(Icons.check, color: Colors.green, size: 16.sp),
                  tooltip: 'Approve',
                  constraints: BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.all(1),
                ),
              ),
              Flexible(
                child: IconButton(
                  onPressed: () => _showDeviceRequestDialog(request),
                  icon: Icon(
                    Icons.more_vert,
                    color: ASColor.getTextColor(context),
                    size: 16.sp,
                  ),
                  tooltip: 'More options',
                  constraints: BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.all(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => NotificationDetailPage(
                  title: notification['title']!,
                  subtitle: notification['subtitle']!,
                  time: notification['time']!,
                ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        decoration: BoxDecoration(
          color:
              notification['is_read'] == true
                  ? ASColor.Background(context)
                  : ASColor.Background(context).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                notification['is_read'] == true
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.w),
          leading: _getNotificationIcon(notification['type']),
          title: Text(
            notification['title']!,
            style: TextStyle(
              fontWeight:
                  notification['is_read'] == true
                      ? FontWeight.normal
                      : FontWeight.bold,
              fontSize: 16.sp,
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: Text(
            notification['subtitle']!,
            style: TextStyle(
              fontSize: 14.sp,
              color: ASColor.getTextColor(context).withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.22, // Max 22% of screen width
              minWidth: 50, // Minimum width to ensure functionality
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        notification['time']!,
                        style: TextStyle(
                          fontSize: 8.sp, // Smaller responsive font size
                          color: ASColor.getTextColor(context).withOpacity(0.5),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (notification['is_read'] == false)
                      Container(
                        margin: EdgeInsets.only(left: 2.w),
                        width: 4.w,
                        height: 4.h,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 24.h, // Responsive height
                  width: 24.w, // Responsive width
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 14.sp, // Responsive icon size
                    ),
                    onPressed:
                        () => _deleteNotification(notification['id'], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            colors:
                isDarkMode
                    ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
                    : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Tab Bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _selectedIndex == 0
                                    ? Colors.blue
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Notifications (${notifications.length})',
                              style: TextStyle(
                                color:
                                    _selectedIndex == 0
                                        ? Colors.white
                                        : ASColor.getTextColor(context),
                                fontWeight:
                                    _selectedIndex == 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedIndex = 1),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                _selectedIndex == 1
                                    ? Colors.orange
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Device Requests (${deviceRequests.length})',
                              style: TextStyle(
                                color:
                                    _selectedIndex == 1
                                        ? Colors.white
                                        : ASColor.getTextColor(context),
                                fontWeight:
                                    _selectedIndex == 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Content Area
              Expanded(
                child:
                    _selectedIndex == 0
                        ? _buildNotificationsList()
                        : _buildDeviceRequestsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
