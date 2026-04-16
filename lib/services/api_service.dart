import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/incident.dart';
import '../models/camera.dart';
import '../models/dispute.dart';
import '../models/offender.dart';

class ApiService {
  static Future<Camera?> registerCamera({
    required String cameraName,
    required String location,
    required String ipAddress,
    String status = 'ONLINE',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.camerasUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cameraName': cameraName,
          'location': location,
          'ipAddress': ipAddress,
          'status': status,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Camera.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error registering camera: $e');
    }
    return null;
  }

  static Future<Map<String, List<Camera>>> discoverCamerasByLocation() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.camerasUrl));
      if (response.statusCode != 200) {
        return {};
      }

      final Map<String, dynamic> discovered = json.decode(response.body);
      final ids =
          discovered.keys
              .map((k) => int.tryParse(k))
              .whereType<int>()
              .toList();

      if (ids.isEmpty) return {};

      final cameras = await Future.wait(ids.map(getCamera));
      final Map<String, List<Camera>> byLocation = {};
      for (final cam in cameras) {
        if (cam == null) continue;
        byLocation.putIfAbsent(cam.location, () => []).add(cam);
      }
      return byLocation;
    } catch (e) {
      print('Error discovering cameras: $e');
      return {};
    }
  }

  static Future<bool> stopAllCameras() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.camerasUrl}/stop_all'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error stopping cameras: $e');
      return false;
    }
  }
  
  static Future<List<Incident>> getIncidents() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.incidentsUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => Incident.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error fetching incidents: $e');
    }
    return [];
  }

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

  static Future<bool> submitDispute({
    required int incidentId,
    required String reason,
    required String description,
    String status = 'PENDING',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/disputes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'incidentId': incidentId,
          'reason': reason,
          'description': description,
          'status': status,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error submitting dispute: $e');
      return false;
    }
  }

  static Future<List<Dispute>> getDisputes(int incidentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/disputes?incidentId=$incidentId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .whereType<Map<String, dynamic>>()
            .map((item) => Dispute.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error fetching disputes: $e');
    }
    return [];
  }

  static Future<Offender?> getOffender(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/offenders/$id'),
      );
      if (response.statusCode == 200) {
        return Offender.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching offender: $e');
    }
    return null;
  }
}

