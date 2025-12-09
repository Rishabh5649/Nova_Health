import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';

final organizationsServiceProvider = Provider<OrganizationsService>((ref) {
  return OrganizationsService(ref.read(apiClientProvider).dio);
});

class OrganizationsService {
  final Dio _dio;
  OrganizationsService(this._dio);

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _dio.get('/organizations');
    // Assuming API returns array of organizations directly or { data: [] }
    // Based on typical NestJS default, it returns the array or object. 
    // organizationsController.findAll returns the result of service.findAll().
    // If Prisma returns array, it's array.
    if (response.data is List) {
      return (response.data as List).cast<Map<String, dynamic>>();
    } else if (response.data is Map && response.data['data'] != null) {
       return (response.data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
