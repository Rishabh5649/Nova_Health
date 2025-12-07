import 'package:dio/dio.dart';
import '../core/api_client.dart';

class OrganizationService {
  final ApiClient apiClient;

  OrganizationService(this.apiClient);

  /// Get organization settings
  Future<Map<String, dynamic>> getSettings(String orgId) async {
    final resp = await apiClient.dio.get('/organizations/$orgId/settings');
    return resp.data as Map<String, dynamic>;
  }

  /// Update organization settings
  Future<Map<String, dynamic>> updateSettings(
    String orgId,
    Map<String, dynamic> settings,
  ) async {
    final resp = await apiClient.dio.patch(
      '/organizations/$orgId/settings',
      data: settings,
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Get all staff members (with optional status filter)
  Future<List<dynamic>> getAllStaff(String orgId, {String? status}) async {
    final params = status != null ? {'status': status} : null;
    final resp = await apiClient.dio.get(
      '/organizations/$orgId/staff',
      queryParameters: params,
    );
    return resp.data as List<dynamic>;
  }

  /// Get pending staff members
  Future<List<dynamic>> getPendingStaff(String orgId) async {
    final resp = await apiClient.dio.get('/organizations/$orgId/staff/pending');
    return resp.data as List<dynamic>;
  }

  /// Approve or reject a staff member
  Future<Map<String, dynamic>> updateStaffStatus(
    String orgId,
    String membershipId,
    String status, // 'APPROVED' or 'REJECTED'
  ) async {
    final resp = await apiClient.dio.patch(
      '/organizations/$orgId/staff/$membershipId',
      data: {'status': status},
    );
    return resp.data as Map<String, dynamic>;
  }

  /// Remove a staff member
  Future<void> removeStaff(String orgId, String membershipId) async {
    await apiClient.dio.delete('/organizations/$orgId/staff/$membershipId');
  }
}
