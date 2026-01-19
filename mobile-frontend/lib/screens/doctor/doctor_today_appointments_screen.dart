import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/appointment.dart';

class DoctorTodayAppointmentsScreen extends ConsumerStatefulWidget {
  const DoctorTodayAppointmentsScreen({super.key});

  @override
  ConsumerState<DoctorTodayAppointmentsScreen> createState() => _DoctorTodayAppointmentsScreenState();
}

class _DoctorTodayAppointmentsScreenState extends ConsumerState<DoctorTodayAppointmentsScreen> {
  bool _loading = true;
  List<Appointment> _items = const [];

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
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'doctorId': doctorId,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final all = list.map(_mapBackendAppointment).toList();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final filtered = all.where((a) {
        final d = a.start.toLocal();
        final day = DateTime(d.year, d.month, d.day);
        return day == today;
      }).toList();
      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Appointment _mapBackendAppointment(Map<String, dynamic> json) {
    final scheduledAt = DateTime.parse(json['scheduledAt'] as String);
    final statusStr = json['status']?.toString();

    AppointmentStatus status;
    switch (statusStr) {
      case 'CONFIRMED':
        status = AppointmentStatus.confirmed;
        break;
      case 'COMPLETED':
        status = AppointmentStatus.completed;
        break;
      case 'CANCELLED':
        status = AppointmentStatus.cancelled;
        break;
      case 'PENDING':
      default:
        status = AppointmentStatus.pendingRequest;
        break;
    }

    return Appointment(
      id: json['id'].toString(),
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      start: scheduledAt,
      end: scheduledAt.add(const Duration(minutes: 30)),
      status: status,
      reason: json['reason']?.toString(),
      fee: (json['fee'] is num) ? (json['fee'] as num).toDouble() : 0,
      paymentStatus: PaymentStatus.unpaid,
    );
  }

  Future<void> _markComplete(Appointment a) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.patch('/appointments/${a.id}/complete');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment marked as completed')),
      );
      _load(); // Reload list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Appointments")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No appointments today')),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final a = _items[index];
                        final isConfirmed = a.status == AppointmentStatus.confirmed;
                        final isCompleted = a.status == AppointmentStatus.completed;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(a.reason ?? 'Consultation'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${a.start.toLocal()}'),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(
                                    a.status.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: isCompleted 
                                      ? Colors.green.withOpacity(0.2)
                                      : isConfirmed
                                          ? Colors.blue.withOpacity(0.2)
                                          : Colors.orange.withOpacity(0.2),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isConfirmed
                                ? FilledButton(
                                    onPressed: () => _markComplete(a),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('Complete'),
                                  )
                                : isCompleted
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

