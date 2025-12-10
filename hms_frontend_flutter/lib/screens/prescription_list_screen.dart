import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../core/providers.dart';
import '../models/appointment.dart';
import 'patient_prescription_screen.dart';

/// Shows the latest 5 prescriptions, then a button to see full medical history.
class PrescriptionListScreen extends ConsumerStatefulWidget {
  const PrescriptionListScreen({super.key});

  @override
  ConsumerState<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends ConsumerState<PrescriptionListScreen> {
  bool _loading = true;
  List<Appointment> _prescriptions = [];

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
      if (patientId == null) {
        setState(() => _loading = false);
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      // Fetch COMPLETED appointments to find prescriptions
      final res = await dio.get('/appointments', queryParameters: {
        'patientId': patientId,
        // Since we don't have a dedicated /prescriptions endpoint for list yet, 
        // we filter appointments. Ideally backend should support status filtering in query
      });

      final list = (res.data as List).cast<Map<String, dynamic>>();
      final all = list.map((json) => Appointment.fromJson(json)).toList();

      // Filter for completed items (assuming they have prescriptions/notes)
      // Sort by date DESC
      final completed = all
          .where((a) => a.status == AppointmentStatus.completed)
          .toList()
        ..sort((a, b) => b.start.compareTo(a.start));

      // Take latest 5
      _prescriptions = completed.take(5).toList();

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _prescriptions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No prescriptions found',
                                style: GoogleFonts.poppins(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _prescriptions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final appt = _prescriptions[index];
                            return _PrescriptionCard(
                              appointment: appt,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PatientPrescriptionScreen(appointmentId: appt.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.push('/patient/medical-history');
                        },
                        icon: const Icon(Icons.history_edu_rounded),
                        label: const Text('View Full Medical History'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;

  const _PrescriptionCard({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y').format(appointment.start);
    final timeStr = DateFormat('h:mm a').format(appointment.start);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. ${appointment.reason ?? "Doctor"}', // Ideally fetch doctor name properly or store it
                      style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • $timeStr',
                      style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
