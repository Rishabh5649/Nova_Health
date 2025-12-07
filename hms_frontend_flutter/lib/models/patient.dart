class Patient {
  /// User core
  final String id;
  final String name;
  final String email;
  final String phone;

  /// Patient profile (from Prisma Patient model)
  final DateTime? dob;
  final String? bloodGroup;
  final String? gender;
  final List<String> allergies;
  final List<String> chronicConditions;

  /// Display / preferences only (no direct Prisma field)
  final String timezone;

  const Patient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.dob,
    this.bloodGroup,
    this.gender,
    this.allergies = const [],
    this.chronicConditions = const [],
    required this.timezone,
  });
}
