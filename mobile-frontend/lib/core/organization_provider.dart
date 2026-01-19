import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/organization_service.dart';
import 'providers.dart';

/// Provider for Organization Service
final organizationServiceProvider = Provider<OrganizationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrganizationService(apiClient);
});
