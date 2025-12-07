import 'package:dio/dio.dart';
import 'models/doctor_public.dart';

class DoctorsPublicService {
  final Dio _dio;
  DoctorsPublicService(this._dio);

  /// Calls GET /doctors with QueryDoctorsDto params:
  /// q, specialty, skip, take
  Future<List<DoctorPublic>> list({String? q, String? specialty, int? skip, int? take}) async {
    try {
      final res = await _dio.get('/doctors', queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        if (skip != null) 'skip': skip,
        if (take != null) 'take': take,
      });

      // Controller returns { total, skip, take, items: [...] }
      final data = res.data;
      if (data == null) return [];
      
      final items = (data is Map && data['items'] is List) 
          ? (data['items'] as List) 
          : (data is List ? data : []);
      
      return items
          .whereType<Map<String, dynamic>>()
          .map((e) {
            try {
              return DoctorPublic.fromJson(e);
            } catch (e) {
              // Skip invalid doctor entries
              return null;
            }
          })
          .whereType<DoctorPublic>()
          .toList();
    } catch (e) {
      // Return empty list on error instead of throwing
      return [];
    }
  }

  /// Optional: GET /doctors/:userId (profile)
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final res = await _dio.get('/doctors/$userId');
      if (res.data is Map) {
        return Map<String, dynamic>.from(res.data as Map);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
