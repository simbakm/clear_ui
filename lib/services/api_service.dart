import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/incident.dart';
import '../models/camera.dart';

class ApiService {
  static Future<Incident?> getIncident(int id) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getIncidentUrl(id)));
      if (response.statusCode == 200) {
        return Incident.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching incident: $e');
    }
    return null;
  }

  static Future<Camera?> getCamera(int id) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getCameraUrl(id)));
      if (response.statusCode == 200) {
        return Camera.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching camera: $e');
    }
    return null;
  }
}
