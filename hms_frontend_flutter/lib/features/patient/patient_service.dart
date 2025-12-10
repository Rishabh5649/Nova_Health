import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/patient.dart';

final patientServiceProvider = Provider<PatientService>((ref) {
  return PatientService(ref.read(apiClientProvider));
});

class PatientService {
  final ApiClient _api;

  PatientService(this._api);

  Future<Patient> getMe() async {
    final response = await _api.dio.get('/patients/me');
    return Patient.fromJson(response.data);
  }

  Future<Patient> updateMe(Map<String, dynamic> data) async {
    final response = await _api.dio.patch('/patients/me', data: data);
    return Patient.fromJson(response.data);
  }
}
