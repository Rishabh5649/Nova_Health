import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../models/appointment.dart';
import '../patient/patient_prescription_screen.dart';
import 'appointment_detail_screen.dart';

class AppointmentListScreen extends ConsumerStatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  ConsumerState<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends ConsumerState<AppointmentListScreen> {
  bool _loading = true;
  bool _showPast = false; // Toggle state
  List<Appointment> _upcoming = [];
  List<Appointment> _past = [];

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
          _upcoming = [];
          _past = [];
          _loading = false;
        });
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'patientId': patientId,
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final all = list.map(_mapBackendAppointment).toList();
      
      _splitAppointments(all);
      
      setState(() {
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _splitAppointments(List<Appointment> all) {
     final now = DateTime.now();
     // Upcoming: Future dates + Active statuses
     _upcoming = all.where((a) {
        final isFuture = a.end.isAfter(now);
        final isActive = a.status != AppointmentStatus.completed && a.status != AppointmentStatus.cancelled;
        return isFuture && isActive;
     }).toList();
     _upcoming.sort((a, b) => a.start.compareTo(b.start));

     // Past: Past dates OR Completed/Cancelled
     _past = all.where((a) {
        final isPast = a.end.isBefore(now);
        final isDone = a.status == AppointmentStatus.completed || a.status == AppointmentStatus.cancelled;
        return isPast || isDone;
     }).toList();
     _past.sort((a, b) => b.start.compareTo(a.start));
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
      // Check if backend returns 'review' object
      hasReview: json['reviews'] != null && (json['reviews'] as List).isNotEmpty,
    );
  }

  Future<void> _showRatingDialog(Appointment appt) async {
    // Rating implementation (kept same as before, simplified for brevity in this rewrite)
    // ... For safe update, I will keep the previous implementation logic but inline it here? 
    // Actually, to avoid losing code, I'll paste the previous implementation helper.
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
    final displayList = _showPast ? _past : _upcoming;
    final title = _showPast ? 'Past Appointments' : 'Upcoming Appointments';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                      ? Center(child: Text('No ${_showPast ? "past" : "upcoming"} appointments'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final a = displayList[index];
                            final isFreeFollowUpEligible = _checkFollowUpEligibility(a);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: a.status == AppointmentStatus.confirmed 
                                            ? Colors.green.withOpacity(0.1) 
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.event_note_rounded,
                                        color: a.status == AppointmentStatus.confirmed ? Colors.green : Colors.grey,
                                      ),
                                    ),
                                    title: Text(a.reason ?? 'General Consultation', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${DateFormat('MMM d, y').format(a.start)} • ${DateFormat('h:mm a').format(a.start)}',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(a.status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getStatusColor(a.status).withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        a.status.name.toUpperCase().replaceAll('APPOINTMENTSTATUS.', ''), 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(a.status))
                                      ),
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
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AppointmentDetailScreen(appointmentId: a.id),
                                            ),
                                          ).then((_) => _load());
                                        }
                                    },
                                  ),
                                  // Action Buttons
                                  if (_showPast && a.status == AppointmentStatus.completed)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: Row(
                                        children: [
                                          if (!a.hasReview)
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => _showRatingDialog(a),
                                                child: const Text('Rate'),
                                              ),
                                            ),
                                          if (!a.hasReview && isFreeFollowUpEligible)
                                            const SizedBox(width: 8),
                                          if (isFreeFollowUpEligible)
                                            Expanded(
                                              child: FilledButton.icon(
                                                onPressed: () {
                                                   // Navigate to book with specific params
                                                   context.push('/book-appointment/${a.doctorId}');
                                                },
                                                icon: const Icon(Icons.replay_rounded, size: 16),
                                                label: const Text('Free Follow-up'),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ),
          
          // Bottom Toggle Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showPast = !_showPast),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: Text(
                    _showPast ? 'View Upcoming Appointments' : 'View Past Appointments', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed: return Colors.green;
      case AppointmentStatus.pendingRequest: return Colors.orange;
      case AppointmentStatus.completed: return Colors.blue;
      case AppointmentStatus.cancelled: return Colors.red;
      default: return Colors.grey;
    }
  }

  bool _checkFollowUpEligibility(Appointment a) {
    if (a.status != AppointmentStatus.completed) return false;
    // Mock logic: Valid if within 7 days of completion
    final diff = DateTime.now().difference(a.end).inDays;
    return diff <= 7 && diff >= 0;
  }
}

