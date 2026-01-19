import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';

final remindersServiceProvider = Provider((ref) => RemindersService(ref.read(apiClientProvider).dio));

class RemindersService {
  final Dio _dio;

  RemindersService(this._dio);

  Future<List<Map<String, dynamic>>> getMyReminders() async {
    final response = await _dio.get('/reminders/me');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createReminder({
    required String medicineName,
    required int frequency,
    required List<String> timeSlots,
    required int duration,
  }) async {
    await _dio.post('/reminders', data: {
      'medicineName': medicineName,
      'frequency': frequency,
      'timeSlots': timeSlots,
      'duration': duration,
    });
  }

  Future<void> updateReminder(String id, bool isEnabled) async {
    await _dio.patch('/reminders/$id', data: {
      'isEnabled': isEnabled,
    });
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete('/reminders/$id');
  }
}
