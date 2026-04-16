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
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final createdAt =
        createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now();
    final updatedAt =
        updatedAtRaw != null ? DateTime.parse(updatedAtRaw) : createdAt;

    return Incident(
      id: json['id'] ?? 0,
      cameraId: json['cameraId'] ?? 0,
      offenderId: json['offenderId'],
      detectedAt:
          json['detectedAt'] != null
              ? DateTime.parse(json['detectedAt'])
              : null,
      confidenceScore:
          json['confidenceScore'] != null
              ? (json['confidenceScore'] as num).toDouble()
              : 0.0,
      videoPath: json['videoPath'] ?? '',
      incidentType: json['incidentType'] ?? 'UNKNOWN',
      status: json['status'] ?? 'UNKNOWN',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DateTime get effectiveDate => detectedAt ?? createdAt;
  bool get hasConfidence => confidenceScore > 0;
}
