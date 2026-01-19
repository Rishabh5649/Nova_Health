import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../models/appointment.dart';
import 'doctor_upcoming_appointments_screen.dart';

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
      
      final now = DateTime.now();
      final todayAppointments = appointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return appointmentDate.year == now.year &&
               appointmentDate.month == now.month &&
               appointmentDate.day == now.day &&
               a.status == AppointmentStatus.confirmed; // Only confirmed
      }).toList();
      
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
        title: Text('Today\'s Appointments', style: GoogleFonts.poppins()),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                    ? Center(child: Text('No confirmed appointments today', style: GoogleFonts.poppins()))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final a = _appointments[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                              ),
                              title: Text(a.reason ?? 'Consultation', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${_formatTime(a.start)} - ${_formatTime(a.end)}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                              onTap: () {
                                context.push('/doctor/appointment/${a.id}');
                              },
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DoctorUpcomingAppointmentsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6), // Teal
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('View All Upcoming Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
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

