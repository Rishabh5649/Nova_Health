import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import 'doctor_patient_history_screen.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  bool _loading = true;
  List<dynamic> _patients = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/doctors/me/patients');
      if (mounted) {
        setState(() {
          _patients = res.data as List<dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patients: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? const Center(child: Text('No patients found'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = _patients[index];
                    final name = p['name'] ?? 'Unknown';
                    final email = p['email'] ?? '';
                    final id = p['id'];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(name[0].toUpperCase())),
                        title: Text(name),
                        subtitle: Text(email),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DoctorPatientHistoryScreen(patientId: id, patientName: name),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

