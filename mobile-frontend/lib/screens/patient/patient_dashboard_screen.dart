import 'package:flutter/material.dart';

import '../../models/appointment.dart';
import '../../services/appointment_api.dart';
import '../../widgets/skeleton_list.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _api = AppointmentApi();
  final String _patientId = 'p1'; // placeholder until wired to real auth

  bool _loading = true;
  List<Appointment> _upcoming = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final appts = await _api.getAppointments(
      patientId: _patientId,
      status: AppointmentStatus.confirmed,
    );
    setState(() {
      _upcoming = appts.take(3).toList(growable: false);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Home'),
        actions: const [
          // Notifications bell placeholder
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to booking flow in later sprint
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Book appointment'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning,', style: theme.textTheme.titleMedium),
              Text('Patient Name', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),

              // Search bar placeholder (no function yet)
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: 'Search doctors',
                  border: const OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () {
                  // Wire to search in later sprint
                },
              ),

              const SizedBox(height: 16),

              // Quick stats row
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Next appointment'),
                            const SizedBox(height: 4),
                            Text(
                              _upcoming.isEmpty
                                  ? 'None scheduled'
                                  : _upcoming.first.start.toLocal().toString(),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Messages'),
                            SizedBox(height: 4),
                            Text('0 unread'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Prescriptions'),
                            SizedBox(height: 4),
                            Text('Coming soon'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text('Upcoming appointments', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),

              SizedBox(
                height: 220,
                child: _loading
                    ? const SkeletonList()
                    : _upcoming.isEmpty
                        ? const Center(child: Text('No upcoming appointments'))
                        : ListView.separated(
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              final a = _upcoming[index];
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.event_note),
                                  title: Text(
                                    a.reason?.isNotEmpty == true
                                        ? a.reason!
                                        : 'Appointment',
                                  ),
                                  subtitle: Text(
                                    '${a.start.toLocal()} - ${a.end.toLocal()}',
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemCount: _upcoming.length,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

