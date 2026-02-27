class Camera {
  final int id;
  final String cameraName;
  final String location;
  final String ipAddress;
  final String streamUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Camera({
    required this.id,
    required this.cameraName,
    required this.location,
    required this.ipAddress,
    required this.streamUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'],
      cameraName: json['cameraName'],
      location: json['location'],
      ipAddress: json['ipAddress'],
      streamUrl: json['streamUrl'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
