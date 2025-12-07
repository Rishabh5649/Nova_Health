import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_logo_leading.dart';
import '../../core/providers.dart';
import '../public/doctors_public_service.dart';
import '../public/models/doctor_public.dart';
import '../../models/appointment.dart';
import '../../widgets/skeleton_list.dart';

class HomePatient extends ConsumerStatefulWidget {
  const HomePatient({super.key});

  @override
  ConsumerState<HomePatient> createState() => _HomePatientState();
}

class _HomePatientState extends ConsumerState<HomePatient> {
  final _searchCtrl = TextEditingController();
  List<DoctorPublic> _all = [];
  List<DoctorPublic> _filtered = [];
  bool _loadingDoctors = false;
  bool _loadingAppts = false;
  List<Appointment> _upcoming = const [];

  int _unreadMessages = 0; // placeholder until wired to real notifications API
  bool _loadingRx = false;
  List<Map<String, dynamic>> _recentRx = const [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadAppointments();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final svc = DoctorsPublicService(dio);
      final docs = await svc.list(take: 100);
      if (!mounted) return;
      setState(() {
        _all = docs;
        _filtered = docs;
        _loadingDoctors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
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

  Future<void> _loadAppointments() async {
    setState(() => _loadingAppts = true);
    try {
      final session = ref.read(authControllerProvider).session;
      final patientId = (session?.user['id']?.toString().isNotEmpty ?? false)
          ? session!.user['id'].toString()
          : null;

      if (patientId == null) {
        setState(() {
          _upcoming = const [];
          _loadingAppts = false;
        });
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'patientId': patientId,
        'status': 'CONFIRMED',
      });
      final list = (res.data as List).cast<Map<String, dynamic>>();
      final appts = list.map(_mapBackendAppointment).toList();
      if (!mounted) return;
      setState(() {
        _upcoming = appts.take(3).toList(growable: false);
        _loadingAppts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAppts = false);
    }
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _loadingRx = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/patients/me/prescriptions');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _recentRx = list.take(3).toList(growable: false);
        _loadingRx = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRx = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((d) {
        final name = d.name.toLowerCase();
        final spec = (d.specialties ?? []).join(' ').toLowerCase();
        return name.contains(q) || spec.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final name = session?.user['name']?.toString() ?? 'Patient';

    return Scaffold(
      appBar: AppBar(
        leading: const AppLogoLeading(),
        title: const Text('Patient Dashboard'),
        actions: [
          // Notifications bell with simple badge placeholder
          IconButton(
            onPressed: () {
              context.push('/patient/notifications');
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (_unreadMessages > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          _unreadMessages > 9
                              ? '9+'
                              : _unreadMessages.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/patient/profile');
                  break;
                case 'signout':
                  // Placeholder sign-out: delegate to auth controller when ready
                  ref.read(authControllerProvider).logout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Text('View profile'),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/mvp-book');
        },
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Book appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),

              // Search bar placeholder for doctors
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  labelText: 'Search doctors by name or specialty',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => _applyFilter(),
              ),

              const SizedBox(height: 16),

              // Quick stats (Next appointment, Messages, Prescriptions)
              Row(
                children: [
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          context.push('/mvp-appointments');
                        },
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
                                    : _upcoming.first.start
                                        .toLocal()
                                        .toString(),
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          context.push('/patient/notifications');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Messages'),
                              const SizedBox(height: 4),
                              Text('$_unreadMessages unread'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Card(
                      clipBehavior: Clip.hardEdge,
                      child: InkWell(
                        onTap: () {
                          context.push('/patient/medical-history');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prescriptions'),
                              const SizedBox(height: 4),
                              if (_loadingRx)
                                const Text('Loading...')
                              else if (_recentRx.isEmpty)
                                const Text('None yet')
                              else
                                Text('${_recentRx.length} recent'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming appointments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      context.push('/mvp-appointments');
                    },
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: _loadingAppts
                    ? const SkeletonList()
                    : _upcoming.isEmpty
                        ? const Center(
                            child: Text('No upcoming appointments'),
                          )
                        : ListView.separated(
                            itemCount: _upcoming.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final a = _upcoming[index];
                              return Card(
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to appointment details if needed
                                    context.push('/mvp-appointments');
                                  },
                                  child: ListTile(
                                    leading:
                                        const Icon(Icons.event_note_outlined),
                                    title: Text(
                                      a.reason?.isNotEmpty == true
                                          ? a.reason!
                                          : 'Appointment',
                                    ),
                                    subtitle: Text(
                                      '${a.start.toLocal()} - ${a.end.toLocal()}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 24),
              Text(
                'Prescriptions & Medical History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingRx)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        )
                      else if (_recentRx.isEmpty)
                        const Text('No prescriptions yet.')
                      else
                        Column(
                          children: _recentRx
                              .map(
                                (rx) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(rx['diagnosis']?.toString() ?? 'Prescription'),
                                  subtitle: Text(
                                    (rx['appointment']?['scheduledAt'] ?? rx['createdAt'] ?? '')
                                        .toString(),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            context.push('/patient/medical-history');
                          },
                          child: const Text('View full medical history'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Browse doctors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: _loadingDoctors
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? const Center(child: Text('No doctors found.'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final d = _filtered[i];
                              final specs = (d.specialties ?? []).join(', ');
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                clipBehavior: Clip.hardEdge,
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to doctor's public profile
                                    context.push('/doctor-profile/${d.doctorId}');
                                  },
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    title: Text(d.name),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          specs.isEmpty
                                              ? 'No specialties listed'
                                              : specs,
                                        ),
                                        if (d.organizationName != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (d.organizationId != null) {
                                                      context.push('/organizations/${d.organizationId}');
                                                    }
                                                  },
                                                  child: Text(
                                                    d.organizationName!,
                                                    style: TextStyle(
                                                      color: Colors.blue[300], // Lighter blue for dark theme visibility
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                InkWell(
                                                  onTap: () async {
                                                    Uri? url;
                                                    if (d.organizationLat != null && d.organizationLng != null) {
                                                      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${d.organizationLat},${d.organizationLng}');
                                                    } else if (d.organizationName != null) {
                                                      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(d.organizationName!)}');
                                                    }
                                                    
                                                    if (url != null && await canLaunchUrl(url)) {
                                                      await launchUrl(url, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                                  child: const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: FilledButton(
                                      onPressed: () {
                                        context.push(
                                            '/appointments/book?doctorId=${d.doctorId}');
                                      },
                                      child: const Text('Book'),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
//import 'package:flutter/material.dart';
//import '../../widgets/app_logo_leading.dart'; // adjust relative path

//AppBar(
  //leading: const AppLogoLeading(),   // <-- add this line
  //title: const Text('Screen Title'),
  //actions: [ /* ... */ ],
//)
