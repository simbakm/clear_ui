class ApiConfig {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String pythonServiceUrl = 'http://localhost:8000';
  static const String incidentsUrl = '$baseUrl/incidents';
  static const String camerasUrl = '$baseUrl/cameras';

  static String getIncidentUrl(int id) => '$incidentsUrl/$id';
  static String getCameraUrl(int id) => '$camerasUrl/$id';
  static String getCameraStreamUrl(int id) => '$camerasUrl/stream/$id';
  static String getVideoUrl(String filename) => '$baseUrl/../uploads/videos/$filename';
}
