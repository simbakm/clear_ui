class Dispute {
  final int id;
  final int incidentId;
  final int? offenderId;
  final String reason;
  final String description;
  final String status;
  final DateTime submittedAt;

  Dispute({
    required this.id,
    required this.incidentId,
    this.offenderId,
    required this.reason,
    required this.description,
    required this.status,
    required this.submittedAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    final submittedAtRaw = json['submittedAt'] ?? json['createdAt'];
    return Dispute(
      id: json['id'] ?? 0,
      incidentId: json['incidentId'] ?? 0,
      offenderId: json['offenderId'],
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      submittedAt:
          submittedAtRaw != null
              ? DateTime.parse(submittedAtRaw)
              : DateTime.now(),
    );
  }
}
