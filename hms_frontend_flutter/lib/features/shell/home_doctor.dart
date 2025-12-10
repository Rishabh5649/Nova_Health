import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/app_logo_leading.dart';
import '../../core/providers.dart';
import '../../core/theme_provider.dart';
import '../../models/appointment.dart';
import '../../widgets/skeleton_list.dart';
import '../../screens/doctor_patients_screen.dart';
import '../../screens/doctor_work_hours_screen.dart';
import '../../screens/doctor_today_full_screen.dart';
import '../../screens/doctor_past_appointments_screen.dart';
import '../../screens/doctor_upcoming_appointments_screen.dart';
import '../../screens/doctor_completed_today_screen.dart';
import '../../screens/notifications_center_screen.dart';

class HomeDoctor extends ConsumerStatefulWidget {
  const HomeDoctor({super.key});

  @override
  ConsumerState<HomeDoctor> createState() => _HomeDoctorState();
}

class _HomeDoctorState extends ConsumerState<HomeDoctor> {
  bool _loadingAppts = false;
  List<Appointment> _upcoming = const [];
  int _todayTotal = 0;
  int _todayConfirmed = 0; // Added for specific count
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
      
      // Count today's appointments matches
      final todayAppointments = allAppointments.where((a) {
        final appointmentDate = a.start.toLocal();
        return appointmentDate.year == now.year &&
               appointmentDate.month == now.month &&
               appointmentDate.day == now.day;
      }).toList();
      
      final todayConfirmed = todayAppointments.where((a) => a.status == AppointmentStatus.confirmed).length;
      
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
        _todayConfirmed = todayConfirmed;
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
    ref.listen(authControllerProvider, (previous, next) {
      final prevId = previous?.session?.user['id'];
      final nextId = next.session?.user['id'];
      if (nextId != null && nextId != prevId) {
        _loadAppointments();
      }
    });

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final session = ref.watch(authControllerProvider).session;
    final user = session?.user;
    var name = user?['name']?.toString() ?? 'Doctor';
    final userEmail = user?['email']?.toString() ?? 'doctor@nova.com';
    final userInitial = name.isNotEmpty ? name[0].toUpperCase() : 'D';
    
    // Clean name for greeting
    if (name.length > 4 && name.startsWith('Dr. ')) {
      name = name.substring(4);
    }

    // Determine greeting
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning,';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon,';
    if (hour >= 17) greeting = 'Good Evening,';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF2563EB)], 
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                child: Text(
                  userInitial,
                  style: GoogleFonts.poppins(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: const Color(0xFF1E3A8A)
                  ),
                ),
              ),
              accountName: Text('Dr. $name', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              accountEmail: Text(userEmail, style: GoogleFonts.poppins(color: Colors.white70)),
            ),
             ListTile(
              leading: const Icon(Icons.new_releases_rounded, color: Colors.blueAccent),
              title: Text("What's New", style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("What's New", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUpdateItem('📅', 'Enhanced Scheduling', 'Manage your availability with our new work hours interface.'),
                        const SizedBox(height: 12),
                        _buildUpdateItem('🩺', 'Patient History', 'Access complete patient history directly from the dashboard.'),
                        const SizedBox(height: 12),
                        _buildUpdateItem('📊', 'Analytics', 'Track your daily performance with new stats cards.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Got it", style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: Colors.purple),
              title: Text("Dark Mode", style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              trailing: Switch(
                value: isDark,
                onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                activeColor: Colors.purple,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_rounded, color: Colors.teal),
              title: Text('Manage Profile', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(context);
                context.push('/doctor/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.domain_disabled_rounded, color: Colors.orange),
              title: Text('Leave Organization', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                 Navigator.pop(context);
                 showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Leave Organization', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    content: Text(
                      'Are you sure you want to leave your current organization? This action cannot be undone by you.',
                      style: GoogleFonts.poppins(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                      TextButton(
                        onPressed: () {
                          // Logic to leave organization would go here
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request to leave organization sent to Admin.')),
                          );
                        },
                        child: Text('Leave', style: GoogleFonts.poppins(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Log Out', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    content: Text('Are you sure you want to log out?', style: GoogleFonts.poppins()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                      TextButton(
                        onPressed: () async {
                           Navigator.pop(context); // Close dialog
                           await ref.read(authControllerProvider).logout();
                           if (context.mounted) context.go('/');
                        },
                        child: Text('Log Out', style: GoogleFonts.poppins(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Nova Health Doctor\nv2.1.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.menu_rounded),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          'Nova Health',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF14B8A6), // Teal
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_rounded),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const NotificationsCenterScreen()),
                            ),
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Greeting
                    Text(
                      'Hello, Dr. $name',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                     const SizedBox(height: 24),
                     
                     // Horizontal Stats Cards (Today & Completed)
                     SingleChildScrollView(
                       scrollDirection: Axis.horizontal,
                       clipBehavior: Clip.none,
                       child: Row(
                         children: [
                           // Appointments Today Card
                           GestureDetector(
                             onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DoctorTodayAppointmentsFullScreen()),
                              ),
                             child: Container(
                               width: 250,
                               padding: const EdgeInsets.all(20),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFFFF9EA), // Cream
                                 borderRadius: BorderRadius.circular(24),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Container(
                                         padding: const EdgeInsets.all(10),
                                         decoration: const BoxDecoration(
                                           color: Colors.orangeAccent,
                                           shape: BoxShape.circle,
                                         ),
                                         child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   Text(
                                     'Appointments Today',
                                     style: GoogleFonts.poppins(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: const Color(0xFF1E293B),
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         '$_todayConfirmed',
                                         style: GoogleFonts.poppins(
                                           fontSize: 32,
                                           fontWeight: FontWeight.bold,
                                           color: const Color(0xFF1E293B),
                                         ),
                                       ),
                                       const Icon(Icons.arrow_forward_rounded, color: Colors.orange),
                                     ],
                                   ),
                                   Text(
                                     'Confirmed',
                                     style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                   )
                                 ],
                               ),
                             ),
                           ),
                           const SizedBox(width: 16),
                           // Completed Today Card
                           GestureDetector(
                             // Navigating to history or filtered view. Using Past Appointments for now.
                             onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DoctorCompletedTodayScreen()),
                              ),
                             child: Container(
                               width: 250,
                               padding: const EdgeInsets.all(20),
                               decoration: BoxDecoration(
                                 color: const Color(0xFFEBF3FF), // Light Blue
                                 borderRadius: BorderRadius.circular(24),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Container(
                                         padding: const EdgeInsets.all(10),
                                         decoration: const BoxDecoration(
                                           color: Colors.blueAccent,
                                           shape: BoxShape.circle,
                                         ),
                                         child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 16),
                                   Text(
                                     'Completed Today',
                                     style: GoogleFonts.poppins(
                                       fontSize: 16,
                                       fontWeight: FontWeight.w600,
                                       color: const Color(0xFF1E293B),
                                     ),
                                   ),
                                   const SizedBox(height: 8),
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Text(
                                         '$_completedToday',
                                         style: GoogleFonts.poppins(
                                           fontSize: 32,
                                           fontWeight: FontWeight.bold,
                                           color: const Color(0xFF1E293B),
                                         ),
                                       ),
                                       const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
                                     ],
                                   ),
                                    Text(
                                     'Patients',
                                     style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                   )
                                 ],
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                     
                     const SizedBox(height: 32),
                     
                     // My Space
                     Text(
                        'My Space',
                        style: GoogleFonts.poppins(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B)
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1, // Adjusted for square-ish look like patient dash
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ActionCard(
                            title: 'Work Hours',
                            icon: Icons.access_time_rounded,
                            color: Colors.teal,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DoctorWorkHoursScreen()),
                            ),
                          ),
                          _ActionCard(
                            title: 'My Patients',
                            icon: Icons.people_outline_rounded,
                            color: Colors.purple,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DoctorPatientsScreen()),
                            ),
                          ),
                          _ActionCard(
                            title: 'History',
                            icon: Icons.history_rounded,
                            color: Colors.orange,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DoctorPastAppointmentsScreen()),
                            ),
                          ),
                          _ActionCard(
                            title: 'Requests', 
                            icon: Icons.notifications_active_outlined,
                            color: Colors.indigo,
                            onTap: () => context.push('/doctor/requests'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
          // End of new Header content
          // Continuing with upcoming schedule list...


                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Schedule',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DoctorUpcomingAppointmentsScreen()),
                          );
                        },
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_loadingAppts)
                    const SkeletonList()
                  else if (_upcoming.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.event_available, size: 48, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('No upcoming appointments', style: TextStyle(color: Colors.grey.withOpacity(0.7))),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _upcoming.length,
                      itemBuilder: (context, index) {
                        return _buildAppointmentCard(context, _upcoming[index]);
                      },
                    ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => context.push('/doctor/appointment/${a.id}'),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
             color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
             shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          'Patient ${a.patientId}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(a.reason ?? 'No reason provided', style: GoogleFonts.poppins(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_formatTime(a.start)} - ${_formatTime(a.end)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildUpdateItem(String icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : color.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
