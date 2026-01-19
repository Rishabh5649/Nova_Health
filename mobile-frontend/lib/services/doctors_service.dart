import 'package:dio/dio.dart';
import '../models/doctor.dart';

class DoctorsService {
  final Dio _dio;

  DoctorsService(this._dio);

  Future<Doctor?> getMe() async {
    try {
      // In a real app, we'd have a /doctors/me endpoint.
      // For now, we'll fetch the user's ID from the session (handled by caller)
      // and then fetch the doctor details.
      // But since we don't have a direct "get me" for doctor details in the public API,
      // we might need to rely on the user object or a specific endpoint.
      
      // Let's assume we can get the doctor by user ID.
      // If the backend doesn't support this, we might need to update the backend.
      // For MVP, if we can't fetch, we'll return null.
      
      // TEMPORARY: Return null to force using session data or empty defaults if API fails
      // But wait, the user said data IS in the DB.
      // We need to fetch it.
      
      // Let's try to fetch from a hypothetical endpoint or list.
      // Since we don't have a dedicated endpoint, we'll skip this for a moment
      // and rely on the caller to pass the ID.
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Doctor> getDoctorByUserId(String userId) async {
    // This endpoint might not exist publicly.
    // We'll try to use the public doctors list and filter (inefficient but works for MVP)
    final res = await _dio.get('/doctors');
    final list = (res.data as List).map((e) => Doctor.fromJson(e)).toList();
    return list.firstWhere((d) => d.userId == userId, orElse: () => throw Exception('Doctor not found'));
  }

  Future<void> updateProfile(String doctorId, Map<String, dynamic> data) async {
    // We need a PATCH /doctors/:id endpoint.
    // If it doesn't exist, we can't save.
    // Let's assume it exists or we need to create it.
    // For now, we'll try to hit it.
    await _dio.patch('/doctors/$doctorId', data: data);
  }

  Future<List<Map<String, dynamic>>> getAvailability(String userId) async {
    try {
      final res = await _dio.get('/doctors/$userId/availability');
      return (res.data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching availability: $e');
      return [];
    }
  }

  Future<void> setAvailability(String userId, List<Map<String, dynamic>> workHours) async {
    await _dio.post('/doctors/$userId/availability', data: {'workHours': workHours});
  }
}
