import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/api_config.dart';
import 'water_quality_model.dart';

class DeviceAwareService {
  
  /// Get all devices accessible to the current user
  Future<List<Map<String, dynamic>>> getAccessibleDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/user/accessible-devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['devices']);
        } else {
          throw Exception('Failed to fetch accessible devices');
        }
      } else {
        throw Exception('Failed to fetch accessible devices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching accessible devices: $e');
      rethrow;
    }
  }

  /// Get available sensors for a specific device
  Future<List<Map<String, dynamic>>> getAvailableSensors(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/device/available-sensors?device_id=$deviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['availableSensors']);
        } else {
          throw Exception('Failed to fetch available sensors');
        }
      } else {
        throw Exception('Failed to fetch available sensors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching available sensors: $e');
      rethrow;
    }
  }

  /// Fetch device-specific sensor data
  Future<List<WaterQualityData>> fetchDeviceData(String statType, String period, String deviceId) async {
    String endpoint;
    switch (statType) {
      case "Temp":
        endpoint = "temperature";
        break;
      case "TDS":
        endpoint = "tds";
        break;
      case "pH Level":
        endpoint = "ph";
        break;
      case "Turbidity":
        endpoint = "turbidity";
        break;
      case "Conductivity":
        endpoint = "ec";
        break;
      case "Salinity":
        endpoint = "salinity";
        break;
      case "EC":
        endpoint = "ec_compensated";
        break;
      default:
        endpoint = "ph";
    }

    // Map frontend period names to backend query parameters
    String periodParam;
    switch (period) {
      case "Daily":
        periodParam = "24h";
        break;
      case "Weekly":
        periodParam = "7d";
        break;
      case "Monthly":
        periodParam = "30d";
        break;
      default:
        periodParam = "24h";
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/device/$endpoint?device_id=$deviceId&period=$periodParam'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Fetching $endpoint data for device $deviceId, response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          List<dynamic> data = responseData['data'];
          return data.map((json) => WaterQualityData.fromJson(json)).toList();
        } else {
          throw Exception('API returned error: ${responseData['message'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Access denied to device $deviceId');
      } else {
        throw Exception('Failed to load device data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching device data: $e');
      rethrow;
    }
  }

  /// Get the primary device for a user (first accessible device)
  Future<String?> getPrimaryDeviceId() async {
    try {
      final devices = await getAccessibleDevices();
      if (devices.isNotEmpty) {
        return devices.first['device_id'];
      }
      return null;
    } catch (e) {
      print('Error getting primary device: $e');
      return null;
    }
  }

  /// Check if a user has access to multiple devices
  Future<bool> hasMultipleDevices() async {
    try {
      final devices = await getAccessibleDevices();
      return devices.length > 1;
    } catch (e) {
      return false;
    }
  }
}