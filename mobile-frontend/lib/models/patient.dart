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
  final bool isMedicalHistoryShared;

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
    this.isMedicalHistoryShared = false,
    required this.timezone,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    // Handling nested user object if present (api usually returns flattened or nested)
    // Adjust based on your actual API response structure for 'getMe'
    final user = json['user'] ?? {};
    
    return Patient(
      id: json['userId'] ?? '',
      name: user['name'] ?? '', // Fallback or from user join
      email: user['email'] ?? '',
      phone: user['phone'] ?? '',
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      bloodGroup: json['bloodGroup'],
      gender: json['gender'],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chronicConditions: (json['chronicConditions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isMedicalHistoryShared: json['isMedicalHistoryShared'] ?? false,
      timezone: 'UTC', // Default
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dob': dob?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'gender': gender,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
    };
  }
}
