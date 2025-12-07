import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../models/appointment.dart';

class DoctorUpcomingAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorUpcomingAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorUpcomingAppointmentsScreen> createState() => _DoctorUpcomingAppointmentsScreenState();
}

class _DoctorUpcomingAppointmentsScreenState extends ConsumerState<DoctorUpcomingAppointmentsScreen> {
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
        'status': 'CONFIRMED',
      });
      
      if (!mounted) return;
      
      final list = (res.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final appointments = list.map((json) => Appointment.fromJson(json)).toList();
      
      // Filter for upcoming appointments (today or future, not completed)
      final now = DateTime.now();
      final upcomingAppointments = appointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return appointmentDate.year > now.year ||
               (appointmentDate.year == now.year && appointmentDate.month > now.month) ||
               (appointmentDate.year == now.year && appointmentDate.month == now.month && appointmentDate.day >= now.day);
      }).toList();
      
      // Sort by date ascending (soonest first)
      upcomingAppointments.sort((a, b) => a.start.compareTo(b.start));
      
      setState(() {
        _appointments = upcomingAppointments;
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
        title: const Text('Upcoming Appointments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? const Center(child: Text('No upcoming appointments'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final a = _appointments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            'P${a.patientId.replaceAll(RegExp(r'[^0-9]'), '')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          a.reason?.isNotEmpty == true ? a.reason! : 'Consultation',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
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
