// Patient profile screen MVP
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _editMode = false;

  Map<String, dynamic>? _data;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/patients/me');
      final json = res.data as Map<String, dynamic>;
      _data = json;
      _nameCtrl.text = json['name']?.toString() ?? '';
      _phoneCtrl.text = json['user']?['phone']?.toString() ?? '';
      _addressCtrl.text = json['address']?.toString() ?? '';
    } catch (_) {
      // ignore errors for now
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.patch('/patients/me', data: {
        'name': _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      });
      await _load();
      if (mounted) {
        setState(() => _editMode = false);
      }
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close : Icons.edit_outlined),
            onPressed: _loading
                ? null
                : () {
                    setState(() => _editMode = !_editMode);
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Basic details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _editMode
                      ? TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Full name'),
                          subtitle: Text(_data?['name']?.toString() ?? '-'),
                        ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Email'),
                    subtitle: Text(_data?['user']?['email']?.toString() ?? '-'),
                  ),
                  const SizedBox(height: 12),
                  _editMode
                      ? TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Phone'),
                          subtitle: Text(_data?['user']?['phone']?.toString() ?? '-'),
                        ),
                  const SizedBox(height: 24),
                  Text('Additional info', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _editMode
                      ? TextField(
                          controller: _addressCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Address'),
                          subtitle: Text(_data?['address']?.toString() ?? '-'),
                        ),
                  const SizedBox(height: 24),
                  Text('Insurance (coming soon)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('You will be able to manage insurance details here in a future update.'),
                  const SizedBox(height: 24),
                  Text('Payment methods (coming soon)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('You will be able to manage saved cards and UPI handles here later.'),
                  const SizedBox(height: 24),
                  if (_editMode)
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    ),
                ],
              ),
            ),
    );
  }
}
