// lib/models/water_quality_model.dart

class WaterQualityData {
  final double value;
  final DateTime timestamp;

  WaterQualityData({required this.value, required this.timestamp});

  factory WaterQualityData.fromJson(Map<String, dynamic> json) {
    // Attempt to find the value field using common column names
    double? parsedValue;
    if (json.containsKey('value') && json['value'] != null) {
      parsedValue = json['value'].toDouble();
    } else if (json.containsKey('turbidity_value') && json['turbidity_value'] != null) {
      parsedValue = json['turbidity_value'].toDouble();
    } else if (json.containsKey('ph_value') && json['ph_value'] != null) {
      parsedValue = json['ph_value'].toDouble();
    } else if (json.containsKey('phlevel_value') && json['phlevel_value'] != null) { // Added for phlevel_readings
      parsedValue = json['phlevel_value'].toDouble();
    } else if (json.containsKey('tds_value') && json['tds_value'] != null) {
      parsedValue = json['tds_value'].toDouble();
    } else if (json.containsKey('salinity_value') && json['salinity_value'] != null) {
      parsedValue = json['salinity_value'].toDouble();
    } else if (json.containsKey('ec_value') && json['ec_value'] != null) { // Original EC value
      parsedValue = json['ec_value'].toDouble();
    } else if (json.containsKey('ec_value_mS') && json['ec_value_mS'] != null) { // Specific EC value in mS
      parsedValue = json['ec_value_mS'].toDouble();
    } else if (json.containsKey('ec_compensated_value') && json['ec_compensated_value'] != null) { // Original EC compensated value
      parsedValue = json['ec_compensated_value'].toDouble();
    } else if (json.containsKey('ec_compensated_mS') && json['ec_compensated_mS'] != null) { // Specific EC compensated in mS
      parsedValue = json['ec_compensated_mS'].toDouble();
    } else if (json.containsKey('temperature_value') && json['temperature_value'] != null) { // Original temperature value
      parsedValue = json['temperature_value'].toDouble();
    } else if (json.containsKey('temperature_celsius') && json['temperature_celsius'] != null) { // Specific temperature in Celsius
      parsedValue = json['temperature_celsius'].toDouble();
    }
    // Add more cases if your database uses other specific column names for values

    // Attempt to find the timestamp field using common column names
    DateTime? parsedTimestamp;
    if (json.containsKey('timestamp') && json['timestamp'] != null) {
      parsedTimestamp = DateTime.parse(json['timestamp']);
    } else if (json.containsKey('created_at') && json['created_at'] != null) {
      parsedTimestamp = DateTime.parse(json['created_at']);
    } else if (json.containsKey('reading_time') && json['reading_time'] != null) { // Another common timestamp name
      parsedTimestamp = DateTime.parse(json['reading_time']);
    }
    // Add more cases if your database uses other specific column names for timestamps

    // Throw an error if essential data is missing
    if (parsedValue == null) {
      throw FormatException('Missing or null value field in JSON: $json');
    }
    if (parsedTimestamp == null) {
      throw FormatException('Missing or null timestamp field in JSON: $json');
    }

    return WaterQualityData(
      value: parsedValue,
      timestamp: parsedTimestamp,
    );
  }
}