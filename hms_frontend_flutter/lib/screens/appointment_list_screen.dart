import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../models/appointment.dart';
import 'patient_prescription_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
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
      final patientId = session?.user['id']?.toString();
      if (patientId == null || patientId.isEmpty) {
        setState(() {
          _items = const [];
          _loading = false;
        });
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'patientId': patientId,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final appts = list.map(_mapBackendAppointment).toList();
      setState(() {
        _items = appts;
        _loading = false;
      });
    } catch (_) {
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

  Future<void> _showRatingDialog(Appointment appt) async {
    double rating = 5;
    double orgRating = 5;
    final commentCtrl = TextEditingController();
    final orgCommentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate your experience'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Doctor Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
              StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => rating = index + 1.0);
                        },
                      );
                    }),
                  );
                },
              ),
              TextField(
                controller: commentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Doctor Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Organization Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
               StatefulBuilder(
                builder: (context, setState) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < orgRating ? Icons.star : Icons.star_border,
                          color: Colors.blueAccent,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() => orgRating = index + 1.0);
                        },
                      );
                    }),
                  );
                },
              ),
              TextField(
                controller: orgCommentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Organization Comment (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final dio = ref.read(apiClientProvider).dio;
                await dio.post('/reviews', data: {
                  'appointmentId': appt.id,
                  'rating': rating.toInt(),
                  'comment': commentCtrl.text,
                  'organizationRating': orgRating.toInt(),
                  'organizationComment': orgCommentCtrl.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you for your feedback!')),
                );
                _load(); // Reload to update UI
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My appointments'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('No appointments'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final a = _items[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text(a.reason ?? 'Appointment'),
                          subtitle: Text(
                            '${a.start.toLocal()} - ${a.end.toLocal()}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (a.status == AppointmentStatus.completed && !a.hasReview)
                                TextButton(
                                  onPressed: () => _showRatingDialog(a),
                                  child: const Text('Rate'),
                                ),
                              Text(a.status.name.toUpperCase()),
                            ],
                          ),
                          onTap: () {
                            if (a.status == AppointmentStatus.completed) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientPrescriptionScreen(appointmentId: a.id),
                                ),
                              );
                            } else {
                              // Navigate to detail screen for reschedule/cancel options
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailScreen(appointmentId: a.id),
                                ),
                              ).then((_) => _load()); // Reload after returning
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
