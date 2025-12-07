import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/organization_provider.dart';
import '../core/providers.dart';

class AdminOrganizationSettingsScreen extends ConsumerStatefulWidget {
  const AdminOrganizationSettingsScreen({super.key});

  @override
  ConsumerState<AdminOrganizationSettingsScreen> createState() =>
      _AdminOrganizationSettingsScreenState();
}

class _AdminOrganizationSettingsScreenState
    extends ConsumerState<AdminOrganizationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String _success = '';

  // Settings fields
  bool _enableReceptionists = false;
  bool _allowPatientBooking = false;
  bool _requireApprovalForDoctors = false;
  bool _requireApprovalForReceptionists = false;
  bool _autoApproveFollowUps = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  String? _orgId() {
    final session = ref.read(sessionAtomProvider).value;
    final memberships = session?.user?['memberships'] as List?;
    if (memberships != null && memberships.isNotEmpty) {
      return memberships[0]['organizationId'] as String?;
    }
    return null;
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final orgId = _orgId();
      if (orgId == null) throw Exception('Organization not found');

      final service = ref.read(organizationServiceProvider);
      final data = await service.getSettings(orgId);

      setState(() {
        _enableReceptionists = data['enableReceptionists'] ?? false;
        _allowPatientBooking = data['allowPatientBooking'] ?? false;
        _requireApprovalForDoctors = data['requireApprovalForDoctors'] ?? false;
        _requireApprovalForReceptionists =
            data['requireApprovalForReceptionists'] ?? false;
        _autoApproveFollowUps = data['autoApproveFollowUps'] ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _saving = true;
      _error = '';
      _success = '';
    });
    try {
      final orgId = _orgId();
      if (orgId == null) throw Exception('Organization not found');

      final service = ref.read(organizationServiceProvider);
      await service.updateSettings(orgId, {
        'enableReceptionists': _enableReceptionists,
        'allowPatientBooking': _allowPatientBooking,
        'requireApprovalForDoctors': _requireApprovalForDoctors,
        'requireApprovalForReceptionists': _requireApprovalForReceptionists,
        'autoApproveFollowUps': _autoApproveFollowUps,
      });

      setState(() {
        _success = 'Settings saved successfully';
        _saving = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  void _toggle(String key) {
    setState(() {
      switch (key) {
        case 'enableReceptionists':
          _enableReceptionists = !_enableReceptionists;
          break;
        case 'allowPatientBooking':
          _allowPatientBooking = !_allowPatientBooking;
          break;
        case 'requireApprovalForDoctors':
          _requireApprovalForDoctors = !_requireApprovalForDoctors;
          break;
        case 'requireApprovalForReceptionists':
          _requireApprovalForReceptionists =
              !_requireApprovalForReceptionists;
          break;
        case 'autoApproveFollowUps':
          _autoApproveFollowUps = !_autoApproveFollowUps;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_success.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _success,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  // Settings toggles
                  _buildToggle(
                    'Enable Receptionists',
                    _enableReceptionists,
                    () => _toggle('enableReceptionists'),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'Allow Patient Booking',
                    _allowPatientBooking,
                    () => _toggle('allowPatientBooking'),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'Require Approval for Doctors',
                    _requireApprovalForDoctors,
                    () => _toggle('requireApprovalForDoctors'),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'Require Approval for Receptionists',
                    _requireApprovalForReceptionists,
                    () => _toggle('requireApprovalForReceptionists'),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'Auto Approve Follow‑Ups',
                    _autoApproveFollowUps,
                    () => _toggle('autoApproveFollowUps'),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _saving ? null : _loadSettings,
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _saveSettings,
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggle(String label, bool value, VoidCallback onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Switch(
          value: value,
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
