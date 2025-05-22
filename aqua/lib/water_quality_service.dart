import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aqua/water_quality_model.dart'; // Import your data model

class WaterQualityService {
  final String baseUrl = "http://localhost:5000/data"; // Replace with your backend URL and port

  // Modified to accept a 'period' parameter
  Future<List<WaterQualityData>> fetchHistoricalData(String statType, String period) async {
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
      case "Conductivity": // Maps to 'ec' endpoint
        endpoint = "ec";
        break;
      case "Salinity":
        endpoint = "salinity";
        break;
      case "EC": // Using "EC" for the general Electrical Conductivity
        endpoint = "ec_compensated"; // Assuming EC covers both ec_value_mS and ec_compensated_mS, backend will handle specific field.
        break;
      default:
        endpoint = "ph"; // Default to pH if something goes wrong
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
        periodParam = "24h"; // Default to 24 hours if not specified
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint?period=$periodParam'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => WaterQualityData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load historical data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching historical data: $e');
    }
  }
}
