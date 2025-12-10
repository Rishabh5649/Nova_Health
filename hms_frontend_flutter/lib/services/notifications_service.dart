import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService(ref.read(apiClientProvider).dio);
});

class NotificationsService {
  final Dio _dio;
  NotificationsService(this._dio);

  Future<List<Map<String, dynamic>>> getAll() async {
    try {
      final res = await _dio.get('/notifications');
      if (res.data is List) {
        return List<Map<String, dynamic>>.from(res.data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (_) {}
  }
  
  // Method to simulate triggering a notification (for testing/demo)
  Future<void> sendTest({required String title, required String message, required String type}) async {
    // In real app, this endpoint wouldn't be public or client-callable usually,
    // but for demo we might want to trigger it. 
    // However, the backend controller currently only has findAll/create.
    // 'create' expects a DTO. We need userId.
    // Ideally the backend 'create' should infer userId or be admin only.
    // For now we'll assume we can post to it if we send userId (backend checks auth?).
    // Actually the backend controller expects DTO with userId.
  }
}
