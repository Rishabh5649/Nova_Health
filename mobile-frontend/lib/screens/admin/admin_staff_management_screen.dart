import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/organization_provider.dart';
import '../../core/providers.dart';

class AdminStaffManagementScreen extends ConsumerStatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  ConsumerState<AdminStaffManagementScreen> createState() =>
      _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState
    extends ConsumerState<AdminStaffManagementScreen> {
  List<dynamic> _staff = [];
  int _pendingCount = 0;
  bool _loading = true;
  String _error = '';
  String _statusFilter = ''; // '', 'PENDING', 'APPROVED', 'REJECTED'
  String? _processingId;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  String? _getOrgId() {
    final session = ref.read(sessionAtomProvider).value;
    final memberships = session?.user?['memberships'] as List?;
    if (memberships != null && memberships.isNotEmpty) {
      return memberships[0]['organizationId'] as String?;
    }
    return null;
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final orgId = _getOrgId();
      if (orgId == null) {
        setState(() {
          _error = 'No organization found';
          _loading = false;
        });
        return;
      }

      final orgService = ref.read(organizationServiceProvider);

      // Load all staff
      final staff = await orgService.getAllStaff(
        orgId,
        status: _statusFilter.isEmpty ? null : _statusFilter,
      );

      // Load pending count
      final pending = await orgService.getPendingStaff(orgId);

      setState(() {
        _staff = staff;
        _pendingCount = pending.length;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approveStaff(String membershipId) async {
    setState(() => _processingId = membershipId);

    try {
      final orgId = _getOrgId();
      if (orgId == null) return;

      final orgService = ref.read(organizationServiceProvider);
      await orgService.updateStaffStatus(orgId, membershipId, 'APPROVED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processingId = null);
    }
  }

  Future<void> _rejectStaff(String membershipId, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Staff Member'),
        content: Text('Are you sure you want to reject $staffName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingId = membershipId);

    try {
      final orgId = _getOrgId();
      if (orgId == null) return;

      final orgService = ref.read(organizationServiceProvider);
      await orgService.updateStaffStatus(orgId, membershipId, 'REJECTED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      await _loadStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processingId = null);
    }
  }

  Future<void> _removeStaff(String membershipId, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff Member'),
        content: Text(
            'Are you sure you want to remove $staffName from the organization?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingId = membershipId);

    try {
      final orgId = _getOrgId();
      if (orgId == null) return;

      final orgService = ref.read(organizationServiceProvider);
      await orgService.removeStaff(orgId, membershipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member removed'),
          ),
        );
      }

      await _loadStaff();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadStaff,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStaff,
                  child: CustomScrollView(
                    slivers: [
                      // Stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Staff',
                                  _staff.length.toString(),
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Pending',
                                  _pendingCount.toString(),
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Approved',
                                  _staff
                                      .where((s) => s['status'] == 'APPROVED')
                                      .length
                                      .toString(),
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Filter Buttons
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All'),
                                selected: _statusFilter == '',
                                onSelected: (_) {
                                  setState(() => _statusFilter = '');
                                  _loadStaff();
                                },
                              ),
                              FilterChip(
                                label: Text('Pending ($_pendingCount)'),
                                selected: _statusFilter == 'PENDING',
                                onSelected: (_) {
                                  setState(() => _statusFilter = 'PENDING');
                                  _loadStaff();
                                },
                              ),
                              FilterChip(
                                label: const Text('Approved'),
                                selected: _statusFilter == 'APPROVED',
                                onSelected: (_) {
                                  setState(() => _statusFilter = 'APPROVED');
                                  _loadStaff();
                                },
                              ),
                              FilterChip(
                                label: const Text('Rejected'),
                                selected: _statusFilter == 'REJECTED',
                                onSelected: (_) {
                                  setState(() => _statusFilter = 'REJECTED');
                                  _loadStaff();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Staff List
                      _staff.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text('No staff members found'),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final member = _staff[index];
                                  return _buildStaffCard(member);
                                },
                                childCount: _staff.length,
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> member) {
    final user = member['user'] as Map<String, dynamic>;
    final status = member['status'] as String;
    final role = member['role'] as String;
    final membershipId = member['id'] as String;
    final approver = member['approver'] as Map<String, dynamic>?;

    final isProcessing = _processingId == membershipId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (approver != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Approved by: ${approver['name']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildRoleBadge(role),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (user['phone'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user['phone'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            if (status == 'PENDING' || (status == 'APPROVED' && role != 'ORG_ADMIN')) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'PENDING') ...[
                    OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _rejectStaff(membershipId, user['name'] ?? 'this user'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed:
                          isProcessing ? null : () => _approveStaff(membershipId),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ] else if (status == 'APPROVED' && role != 'ORG_ADMIN') ...[
                    OutlinedButton.icon(
                      onPressed: isProcessing
                          ? null
                          : () => _removeStaff(membershipId, user['name'] ?? 'this user'),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final displayRole = role.replaceAll('ORG_ADMIN', 'ADMIN');
    Color color;

    switch (role) {
      case 'ORG_ADMIN':
        color = Colors.red;
        break;
      case 'DOCTOR':
        color = Colors.blue;
        break;
      case 'RECEPTIONIST':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayRole,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

