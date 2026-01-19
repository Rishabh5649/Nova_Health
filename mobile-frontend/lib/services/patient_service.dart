import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers.dart';
import '../models/patient.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return PatientService(dio);
});

class PatientService {
  final Dio _dio;

  PatientService(this._dio);

  Future<Patient> getMe() async {
    final res = await _dio.get('/patients/profile'); // Assuming /patients/profile or /patients/me
    return Patient.fromJson(res.data);
  }

  Future<Patient> updateMe(Map<String, dynamic> data) async {
    final res = await _dio.patch('/patients/profile', data: data);
    return Patient.fromJson(res.data);
  }
}
