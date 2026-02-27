class Incident {
  final int id;
  final int cameraId;
  final int? offenderId;
  final DateTime? detectedAt;
  final double confidenceScore;
  final String videoPath;
  final String incidentType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Incident({
    required this.id,
    required this.cameraId,
    this.offenderId,
    this.detectedAt,
    required this.confidenceScore,
    required this.videoPath,
    required this.incidentType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      cameraId: json['cameraId'],
      offenderId: json['offenderId'],
      detectedAt:
          json['detectedAt'] != null
              ? DateTime.parse(json['detectedAt'])
              : null,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      videoPath: json['videoPath'],
      incidentType: json['incidentType'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  DateTime get effectiveDate => detectedAt ?? createdAt;
}
