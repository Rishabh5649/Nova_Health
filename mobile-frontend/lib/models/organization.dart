class Organization {
  final String id;
  final String name;
  final String? type;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double ratingAvg;
  final int ratingCount;

  const Organization({
    required this.id,
    required this.name,
    this.type,
    this.address,
    this.latitude,
    this.longitude,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Organization',
      type: json['type'],
      address: json['address'],
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      ratingAvg: (json['ratingAvg'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
    );
  }
}
