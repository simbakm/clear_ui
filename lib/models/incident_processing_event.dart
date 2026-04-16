import 'dart:convert';

class IncidentProcessingEvent {
  final int incidentId;
  final int step;
  final String message;
  final dynamic data;
  final String status;
  final DateTime timestamp;

  IncidentProcessingEvent({
    required this.incidentId,
    required this.step,
    required this.message,
    this.data,
    required this.status,
    required this.timestamp,
  });

  factory IncidentProcessingEvent.fromJson(Map<String, dynamic> json) {
    return IncidentProcessingEvent(
      incidentId: json['incidentId'] ?? 0,
      step: json['step'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'],
      status: json['status'] ?? '',
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : DateTime.now(),
    );
  }

  factory IncidentProcessingEvent.fromString(String jsonString) {
    return IncidentProcessingEvent.fromJson(json.decode(jsonString));
  }
}
