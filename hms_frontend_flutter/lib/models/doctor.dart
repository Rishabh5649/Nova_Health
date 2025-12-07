import 'organization.dart';

class Doctor {
  final String id;
  final String userId;
  final String name;
  final int? age;
  final List<String> qualifications;
  final List<String> specialties;
  final int yearsExperience;
  final String? bio;
  final String verificationStatus;
  final int baseFee;
  final double ratingAvg;
  final int ratingCount;
  final List<String> degrees;
  final int fees;
  final Organization? organization;

  const Doctor({
    required this.id,
    required this.userId,
    required this.name,
    this.age,
    this.qualifications = const [],
    this.specialties = const [],
    this.yearsExperience = 0,
    this.bio,
    this.verificationStatus = 'PENDING',
    this.baseFee = 0,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.degrees = const [],
    this.fees = 500,
    this.organization,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    Organization? org;
    if (json['user'] != null && 
        json['user']['memberships'] != null && 
        (json['user']['memberships'] as List).isNotEmpty &&
        json['user']['memberships'][0]['organization'] != null) {
      org = Organization.fromJson(json['user']['memberships'][0]['organization']);
    }

    return Doctor(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      age: json['age'],
      qualifications: (json['qualifications'] as List?)?.cast<String>() ?? [],
      specialties: (json['specialties'] as List?)?.cast<String>() ?? [],
      yearsExperience: json['yearsExperience'] ?? 0,
      bio: json['bio'],
      verificationStatus: json['verificationStatus'] ?? 'PENDING',
      baseFee: json['baseFee'] ?? 0,
      ratingAvg: (json['ratingAvg'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      degrees: (json['degrees'] as List?)?.cast<String>() ?? [],
      fees: json['fees'] ?? 500,
      organization: org,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'age': age,
      'qualifications': qualifications,
      'specialties': specialties,
      'yearsExperience': yearsExperience,
      'bio': bio,
      'verificationStatus': verificationStatus,
      'baseFee': baseFee,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'degrees': degrees,
      'fees': fees,
      // organization toJson not typically needed for sending back to server via Doctor model update
      // but if needed we can add it. omitting for now.
    };
  }
}
