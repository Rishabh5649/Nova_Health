import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../models/appointment.dart';

class DoctorPastAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorPastAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorPastAppointmentsScreen> createState() => _DoctorPastAppointmentsScreenState();
}

class _DoctorPastAppointmentsScreenState extends ConsumerState<DoctorPastAppointmentsScreen> {
  bool _loading = true;
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = ref.read(authControllerProvider).session;
      final doctorId = session?.user['id']?.toString();
      
      if (doctorId == null || doctorId.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'doctorId': doctorId,
        'status': 'COMPLETED',
      });
      
      if (!mounted) return;
      
      final list = (res.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final appointments = list.map((json) => Appointment.fromJson(json)).toList();
      
      // Sort by date descending (most recent first)
      appointments.sort((a, b) => b.start.compareTo(a.start));
      
      setState(() {
        _appointments = appointments;
        _loading = false;
      });
    } catch (e) {
      print('Error loading appointments: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Appointments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No past appointments'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final a = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(a.reason ?? 'Consultation'),
                        subtitle: Text(
                          '${_formatDate(a.start)} • ${_formatTime(a.start)} - ${_formatTime(a.end)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/doctor/appointment/${a.id}');
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

