import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../models/appointment.dart';

class DoctorTodayAppointmentsFullScreen extends ConsumerStatefulWidget {
  const DoctorTodayAppointmentsFullScreen({super.key});

  @override
  ConsumerState<DoctorTodayAppointmentsFullScreen> createState() => _DoctorTodayAppointmentsFullScreenState();
}

class _DoctorTodayAppointmentsFullScreenState extends ConsumerState<DoctorTodayAppointmentsFullScreen> {
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
      });
      
      if (!mounted) return;
      
      final list = (res.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final appointments = list.map((json) => Appointment.fromJson(json)).toList();
      
      // Filter for today's appointments only (both completed and pending)
      final now = DateTime.now();
      final todayAppointments = appointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return appointmentDate.year == now.year &&
               appointmentDate.month == now.month &&
               appointmentDate.day == now.day;
      }).toList();
      
      // Sort by time
      todayAppointments.sort((a, b) => a.start.compareTo(b.start));
      
      setState(() {
        _appointments = todayAppointments;
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
        title: const Text('Today\'s Appointments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No appointments today'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final a = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: a.status == AppointmentStatus.completed
                              ? Colors.green
                              : Colors.blue,
                          child: Icon(
                            a.status == AppointmentStatus.completed
                                ? Icons.check
                                : Icons.schedule,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(a.reason ?? 'Consultation'),
                        subtitle: Text(
                          '${_formatTime(a.start)} - ${_formatTime(a.end)} • ${a.status.name.toUpperCase()}',
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

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
