import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/appointment.dart';
import '../../core/providers.dart'; // for apiClientProvider

class AppointmentsService {
  final Dio _dio;
  AppointmentsService(this._dio);

  Future<List<Appointment>> getMyAppointments() async {
    try {
      final res = await _dio.get('/appointments/my');
      final data = res.data;
      if (data is List) {
        return data.map((e) => Appointment.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // Return empty on error
      return [];
    }
  }
}

final appointmentsServiceProvider = Provider<AppointmentsService>((ref) {
  return AppointmentsService(ref.read(apiClientProvider).dio);
});
