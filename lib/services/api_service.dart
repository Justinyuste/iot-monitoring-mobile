
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL Laravel API untuk pengujian melalui Chrome
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Mengambil data telemetry
  static Future<List<dynamic>> getTelemetry() async {
    final response = await http.get(
      Uri.parse('$baseUrl/telemetry'),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['data'];
    } else {
      throw Exception('Gagal mengambil data telemetry');
    }
  }

  // Mengambil status ESP32
  static Future<Map<String, dynamic>> getDeviceStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/device-status'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal mengambil status ESP32');
    }
  }
}
