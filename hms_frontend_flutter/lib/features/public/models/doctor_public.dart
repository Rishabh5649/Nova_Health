// lib/features/public/models/doctor_public.dart
class DoctorPublic {
  final String doctorId; // doctor table id (preferred for appointments)
  final String userId; // user id (for profile routes)
  final String name;
  final List<String>? specialties;
  final List<String>? qualifications;
  final int? yearsExperience;
  final int? baseFee;
  final double? ratingAvg;
  final int? ratingCount;

  DoctorPublic({
    required this.doctorId,
    required this.userId,
    required this.name,
    this.specialties,
    this.qualifications,
    this.yearsExperience,
    this.baseFee,
    this.ratingAvg,
    this.ratingCount,
    this.organizationName,
    this.organizationId,
    this.organizationLat,
    this.organizationLng,
  });

  /// Accepts several possible shapes returned by your backend:
  /// - { doctorId, userId, name, specialties: [...], baseFee: 100 }
  /// - or older shapes like { id, user: { id, name }, specialty, hospital, ... }
  factory DoctorPublic.fromJson(Map<String, dynamic> j) {
    // helper to parse list-of-strings safely
    List<String>? parseStringList(dynamic v) {
      if (v == null) return null;
      if (v is List) {
        return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).cast<String>().toList();
      }
      // sometimes backend returns a comma-separated string
      if (v is String && v.trim().isNotEmpty) {
        return v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
      return null;
    }

    // attempt various locations for id/name
    final doctorId = (j['doctorId'] ?? j['id'] ?? j['doctor_id'] ?? '').toString();
    final userId = (j['userId'] ??
            (j['user'] != null ? (j['user']['id'] ?? j['user']['userId']) : null) ??
            '')
        .toString();

    String name = '';
    if (j['name'] != null) name = j['name'].toString();
    else if (j['user'] != null && j['user']['name'] != null) name = j['user']['name'].toString();
    else if (j['userName'] != null) name = j['userName'].toString();
    else if (j['doctorName'] != null) name = j['doctorName'].toString();
    if (name.isEmpty) name = 'Doctor';

    final specialties = parseStringList(j['specialties'] ?? j['specialty'] ?? j['speciality']);
    final qualifications = parseStringList(j['qualifications'] ?? j['qualification']);
    int? yearsExp;
    try {
      if (j['yearsExperience'] != null) yearsExp = int.tryParse(j['yearsExperience'].toString());
      else if (j['experience'] != null) yearsExp = int.tryParse(j['experience'].toString());
    } catch (_) {}
    int? baseFee;
    try {
      if (j['baseFee'] != null) baseFee = int.tryParse(j['baseFee'].toString());
      else if (j['fee'] != null) baseFee = int.tryParse(j['fee'].toString());
    } catch (_) {}
    double? ratingAvg;
    try {
      if (j['ratingAvg'] != null) ratingAvg = double.tryParse(j['ratingAvg'].toString());
      else if (j['rating'] != null) ratingAvg = double.tryParse(j['rating'].toString());
    } catch (_) {}
    int? ratingCount;
    try {
      if (j['ratingCount'] != null) ratingCount = int.tryParse(j['ratingCount'].toString());
    } catch (_) {}

    String? orgName;
    String? orgId;
    double? orgLat;
    double? orgLng;

    if (j['user'] != null && j['user']['memberships'] != null && (j['user']['memberships'] as List).isNotEmpty) {
      final m = j['user']['memberships'][0];
      if (m['organization'] != null) {
        final org = m['organization'];
        orgName = org['name']?.toString();
        orgId = org['id']?.toString();
        if (org['latitude'] != null) orgLat = double.tryParse(org['latitude'].toString());
        if (org['longitude'] != null) orgLng = double.tryParse(org['longitude'].toString());
      }
    }

    return DoctorPublic(
      doctorId: doctorId.isEmpty ? userId : doctorId,
      userId: userId.isEmpty ? doctorId : userId,
      name: name,
      specialties: specialties,
      qualifications: qualifications,
      yearsExperience: yearsExp,
      baseFee: baseFee,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      organizationName: orgName,
      organizationId: orgId,
      organizationLat: orgLat,
      organizationLng: orgLng,
    );
  }

  final String? organizationName;
  final String? organizationId;
  final double? organizationLat;
  final double? organizationLng;
}
