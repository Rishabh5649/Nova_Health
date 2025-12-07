import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers.dart';

/// Screen shown when user has a PENDING membership status
/// Polls the backend every 30 seconds to check if they've been approved
class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _pollTimer;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    // Start polling every 30 seconds
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkApprovalStatus();
    });
  }

  Future<void> _checkApprovalStatus() async {
    if (_isCheckingStatus) return;

    setState(() => _isCheckingStatus = true);

    try {
      // Try to re-login to get updated user info
      final authController = ref.read(authControllerProvider);
      await authController.hydrate();

      // Check if user is now approved
      final session = ref.read(sessionAtomProvider).value;
      if (session != null) {
        final memberships = session.user?['memberships'] as List?;
        if (memberships != null && memberships.isNotEmpty) {
          final status = memberships[0]['status'];
          if (status == 'APPROVED') {
            // Approved! Navigate to app
            if (mounted) {
              context.go('/app');
            }
          } else if (status == 'REJECTED') {
            // Rejected - show error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your account has been rejected by the admin.'),
                  backgroundColor: Colors.red,
                ),
              );
              // Log out
              authController.logout();
              context.go('/login');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[PendingApproval] Error checking status: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionAtomProvider).value;
    final organizationName =
        session?.user?['memberships']?[0]?['organization']?['name'] ?? 'the organization';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approval'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider).logout();
              context.go('/login');
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkApprovalStatus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              
              // Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  size: 80,
                  color: Colors.orange.shade700,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Pending Approval',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                'Your account is awaiting approval from $organizationName admin.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Text(
                            'What happens next?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoPoint('1', 'Admin will review your account'),
                      const SizedBox(height: 12),
                      _buildInfoPoint('2', 'You\'ll receive approval or feedback'),
                      const SizedBox(height: 12),
                      _buildInfoPoint('3', 'Once approved, you can access the system'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status indicator
              if (_isCheckingStatus)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Checking status...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                )
              else
                Text(
                  'Auto-checking every 30 seconds',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Manual check button
              FilledButton.icon(
                onPressed: _isCheckingStatus ? null : _checkApprovalStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Status Now'),
              ),
              
              const SizedBox(height: 16),
              
              // Sign out button
              OutlinedButton(
                onPressed: () {
                  ref.read(authControllerProvider).logout();
                  context.go('/login');
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPoint(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
