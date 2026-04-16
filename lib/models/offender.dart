class Offender {
  final int id;
  final String name;
  final String email;

  Offender({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Offender.fromJson(Map<String, dynamic> json) {
    return Offender(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
