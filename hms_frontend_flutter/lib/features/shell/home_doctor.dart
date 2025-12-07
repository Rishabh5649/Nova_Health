import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_logo_leading.dart';
import '../../core/providers.dart';
import '../../models/appointment.dart';
import '../../widgets/skeleton_list.dart';
import '../../screens/doctor_patients_screen.dart';
import '../../screens/doctor_today_full_screen.dart';
import '../../screens/doctor_past_appointments_screen.dart';
import '../../screens/doctor_upcoming_appointments_screen.dart';
import '../../screens/doctor_work_hours_screen.dart';

class HomeDoctor extends ConsumerStatefulWidget {
  const HomeDoctor({super.key});

  @override
  ConsumerState<HomeDoctor> createState() => _HomeDoctorState();
}

class _HomeDoctorState extends ConsumerState<HomeDoctor> {
  bool _loadingAppts = false;
  List<Appointment> _upcoming = const [];
  int _todayTotal = 0;
  int _completedToday = 0;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loadingAppts = true;
      _errorMessage = null;
    });
    
    try {
      final session = ref.read(authControllerProvider).session;
      final doctorId = session?.user['id']?.toString();
      
      if (doctorId == null || doctorId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loadingAppts = false;
          // Don't set error message yet, wait for session update via listener
        });
        return;
      }

      final dio = ref.read(apiClientProvider).dio;
      
      // Fetch all appointments
      final allRes = await dio.get('/appointments', queryParameters: {
        'doctorId': doctorId,
      });
      
      if (!mounted) return;
      
      final allList = (allRes.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final allAppointments = allList.map((json) => Appointment.fromJson(json)).toList();
      
      final now = DateTime.now();
      
      // Count today's appointments (all statuses)
      final todayAppointments = allAppointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return appointmentDate.year == now.year &&
               appointmentDate.month == now.month &&
               appointmentDate.day == now.day;
      }).toList();
      
      // Count completed today
      final completedToday = todayAppointments.where((a) => 
        a.status == AppointmentStatus.completed
      ).length;
      
      // Get upcoming appointments (confirmed, today or future)
      final upcomingConfirmed = allAppointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return a.status == AppointmentStatus.confirmed &&
               (appointmentDate.year > now.year ||
                (appointmentDate.year == now.year && appointmentDate.month > now.month) ||
                (appointmentDate.year == now.year && appointmentDate.month == now.month && appointmentDate.day >= now.day));
      }).toList();
      
      // Sort by date
      upcomingConfirmed.sort((a, b) => a.start.compareTo(b.start));
      
      setState(() {
        _upcoming = upcomingConfirmed.take(5).toList(growable: false);
        _todayTotal = todayAppointments.length;
        _completedToday = completedToday;
        _loadingAppts = false;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (!mounted) return;
      setState(() {
        _loadingAppts = false;
        _errorMessage = 'Failed to load appointments: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for session changes to reload data if user ID changes/populates
    ref.listen(authControllerProvider, (previous, next) {
      final prevId = previous?.session?.user['id'];
      final nextId = next.session?.user['id'];
      if (nextId != null && nextId != prevId) {
        _loadAppointments();
      }
    });

    final session = ref.watch(authControllerProvider).session;
    var name = session?.user['name']?.toString() ?? 'Doctor';
    if (name.length > 4 && name.startsWith('Dr. ')) {
      name = name.substring(4);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppLogoLeading(),
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
          PopupMenuButton<String>(
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.push('/doctor/profile');
                  break;
                case 'signout':
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

      body: RefreshIndicator(
        onRefresh: _loadAppointments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, Dr. $name',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[900]),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadAppointments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),

              // Stats Row - 4 Buttons
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Appointments Today',
                      value: _todayTotal.toString(),
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DoctorTodayAppointmentsFullScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Completed Today',
                      value: _completedToday.toString(),
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Past Appointments',
                      value: '',
                      icon: Icons.history,
                      color: Colors.orange,
                      isAction: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DoctorPastAppointmentsScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'My Patients',
                      value: '',
                      icon: Icons.people,
                      color: Colors.purple,
                      isAction: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Work Hours',
                      value: '',
                      icon: Icons.access_time,
                      color: Colors.teal,
                      isAction: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DoctorWorkHoursScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'My Profile',
                      value: '',
                      icon: Icons.person,
                      color: Colors.indigo,
                      isAction: true,
                      onTap: () {
                        context.push('/doctor/profile');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DoctorUpcomingAppointmentsScreen()),
                      );
                    },
                    child: const Text('View all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _loadingAppts
                  ? const SkeletonList()
                  : _upcoming.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(_errorMessage == null ? 'No upcoming appointments' : ''),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _upcoming.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final a = _upcoming[index];
                            return Card(
                              clipBehavior: Clip.hardEdge,
                              child: InkWell(
                                onTap: () {
                                  context.push('/doctor/appointment/${a.id}');
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(
                                      'P${a.patientId.replaceAll(RegExp(r'[^0-9]'), '')}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
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
                                ),
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isAction;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: isAction 
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ],
        ),
    );

    return Card(
      elevation: 2,
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: color.withOpacity(0.1),
                highlightColor: color.withOpacity(0.05),
                child: content,
              ),
            )
          : content,
    );
  }
}