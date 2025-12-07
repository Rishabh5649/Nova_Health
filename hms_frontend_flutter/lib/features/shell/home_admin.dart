import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_logo_leading.dart';
import '../../core/providers.dart';
import '../../core/organization_provider.dart';

class HomeAdmin extends ConsumerWidget {
  const HomeAdmin({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionAtomProvider).value;
    final orgId = session?.user?['memberships']?[0]?['organizationId'] as String?;
    final orgService = ref.read(organizationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const AppLogoLeading(),
        title: const Text('Admin Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pending staff card
            FutureBuilder<List<dynamic>>(
              future: orgId != null ? orgService.getPendingStaff(orgId) : Future.value([]),
              builder: (context, snapshot) {
                final pending = snapshot.data?.length ?? 0;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.people_outline, color: Colors.orange),
                    title: const Text('Pending Staff Approvals'),
                    subtitle: Text('$pending pending'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/dashboard/staff'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Staff Management button
            FilledButton.icon(
              icon: const Icon(Icons.group),
              label: const Text('Staff Management'),
              onPressed: () => context.go('/dashboard/staff'),
            ),
            const SizedBox(height: 12),
            // Organization Settings button
            FilledButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Organization Settings'),
              onPressed: () => context.go('/dashboard/settings/organization'),
            ),
          ],
        ),
      ),
    );
  }
}