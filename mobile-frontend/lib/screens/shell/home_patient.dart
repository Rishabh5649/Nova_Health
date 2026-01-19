import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/theme_provider.dart';
import '../../services/appointments_service.dart';
import '../../services/doctors_public_service.dart';
import '../../models/doctor_public.dart';
import '../../models/appointment.dart';
import '../../screens/patient/patient_profile_screen.dart';
import '../../screens/doctor/doctor_list_screen.dart';
import '../../widgets/chatbot_widget.dart';

import '../../screens/patient/medical_history_screen.dart';

// Note: Using dynamic for prescriptions for now to avoid import errors.


class HomePatient extends ConsumerStatefulWidget {
  const HomePatient({super.key});

  @override
  ConsumerState<HomePatient> createState() => _HomePatientState();
}

class _HomePatientState extends ConsumerState<HomePatient> {
  // --- STATE ---
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  List<DoctorPublic> _allDoctors = [];
  List<DoctorPublic> _filteredDoctors = [];
  List<Appointment> _upcoming = [];
  List<dynamic> _recentPrescriptions = []; // Use dynamic for safety
  bool _loadingDoctors = true;
  bool _loadingAppts = true;
  bool _loadingPrescriptions = true;

  // --- INIT ---
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final docs = await ref.read(doctorsPublicServiceProvider).list();
      if (mounted) {
        setState(() {
          _allDoctors = docs;
          _filteredDoctors = docs;
          _loadingDoctors = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
      if (mounted) setState(() => _loadingDoctors = false);
    }

    // Load Appointments
    try {
      final appts = await ref.read(appointmentsServiceProvider).getMyAppointments();
      final now = DateTime.now();
      final upcoming = appts
          .where((a) => a.start.isAfter(now))
          .toList();
      upcoming.sort((a, b) => a.start.compareTo(b.start));

      if (mounted) {
        setState(() {
          _upcoming = upcoming;
          _loadingAppts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) setState(() => _loadingAppts = false);
    }
    // Load Prescriptions
    try {
      // Trying to find the provider. If this fails to compile, I will fix.
      // Assuming 'prescriptionsServiceProvider' or similar.
      // For now, I'll leave it empty to avoid compilation error until verified.
      // TODO: Connect to real service
      _recentPrescriptions = []; 
      _loadingPrescriptions = false;
    } catch (e) {
      debugPrint('Error loading prescriptions: $e');
      if (mounted) setState(() => _loadingPrescriptions = false);
    }
  }

  @override
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final session = ref.watch(authControllerProvider).session;
    final userName = session?.user['name']?.toString() ?? 'User';
    final userEmail = session?.user['email']?.toString() ?? 'user@nova.com';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    final tabs = [
      const _HomeTab(),
      const DoctorListScreen(),
      MedicalHistoryScreen(),
      PatientProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          tabs[_currentIndex],
          if (_currentIndex == 0) // Only on Home tab
            const Positioned(
              bottom: 90,
              right: 24,
              child: ChatbotWidget(),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: const Color(0xFF6366F1).withOpacity(0.1),
            labelTextStyle: MaterialStateProperty.all(
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          child: NavigationBar(
            height: 65,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF6366F1)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history_rounded, color: Color(0xFF6366F1)),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF6366F1)),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF0F172A), const Color(0xFF6366F1)]
                      : [const Color(0xFF6366F1).withOpacity(0.8), const Color(0xFF6366F1)], 
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
                    color: const Color(0xFF6366F1)
                  ),
                ),
              ),
              accountName: Text(userName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              accountEmail: Text(userEmail, style: GoogleFonts.poppins(color: Colors.white70)),
            ),
            ListTile(
              leading: const Icon(Icons.star_rounded, color: Colors.amber),
              title: Text('Buy Premium', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(context);
                context.push('/patient/premium');
              },
            ),
            ListTile(
              leading: const Icon(Icons.new_releases_rounded, color: Colors.blueAccent),
              title: Text("What's New", style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(context);
                context.push('/patient/whats-new');
              },
            ),
            Divider(color: isDark ? Colors.white24 : Colors.grey[300]),
            ListTile(
              leading: Icon(Icons.settings_rounded, color: isDark ? Colors.white60 : Colors.grey),
              title: Text('Settings & Privacy', style: GoogleFonts.poppins(color: isDark ? Colors.white : const Color(0xFF1E293B))),
              onTap: () {
                Navigator.pop(context);
                context.push('/patient/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text('Log Out', style: GoogleFonts.poppins(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider).logout();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0\nHelp: support@novahealth.com',
                style: GoogleFonts.poppins(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  // Logic from original HomePatient
  List<DoctorPublic> _allDoctors = [];
  List<DoctorPublic> _filteredDoctors = [];
  bool _loadingDoctors = true;
  String? _selectedCategory;
  List<dynamic> _recentPrescriptions = []; // Added for Recent Prescriptions UI

  void _toggleCategory(String category) {
     if (_selectedCategory == category) {
       _filterDoctors(null);
     } else {
       _filterDoctors(category);
     }
  }

  void _filterDoctors(String? category) {
    setState(() {
      _selectedCategory = category;
      if (category == null) {
        _filteredDoctors = List.from(_allDoctors);
      } else {
        _filteredDoctors = _allDoctors.where((d) {
          return d.specialties?.any((s) => s.toLowerCase().contains(category.toLowerCase())) ?? false;
        }).toList();
      }
    });
  }
  
  // Auto-scrolling
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _startAutoScroll();
    // Placeholder recent prescriptions
    _recentPrescriptions = [
      {
        'doctorName': 'Dr. Sarah Smith',
        'dateFormatted': 'Dec 12, 2023',
        'medicationCount': 3
      },
      {
         'doctorName': 'Dr. John Doe',
         'dateFormatted': 'Nov 28, 2023',
         'medicationCount': 1
      },
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double currentScroll = _scrollController.position.pixels;
        // Card width ~260 + spacing 16 = 276
        const double delta = 276.0; 
        
        double target = currentScroll + delta;
        if (target > maxScroll) {
          // If we reach the end, scroll back to start smoothly or jump? 
          // Let's scroll back to 0
          target = 0;
        }
        
        _scrollController.animateTo(
          target,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchDoctors() async {
    try {
      final service = ref.read(doctorsPublicServiceProvider);
      final docs = await service.list();
      if (mounted) {
        setState(() {
          _allDoctors = docs;
          _filteredDoctors = docs;
          _loadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  String _getGreeting() {
    return 'Hello';
  }

  void _showPremiumDetails({
    required BuildContext context,
    required String title,
    required String description,
    required String details,
    required String price,
    required List<String> features,
    required Color color,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(description, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Key Benefits', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                   Icon(Icons.check_circle_rounded, color: color, size: 20),
                   const SizedBox(width: 12),
                   Text(f, style: GoogleFonts.poppins(fontSize: 14)),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Text(details, style: GoogleFonts.poppins(color: Colors.grey[600], height: 1.5, fontSize: 13)),
            const SizedBox(height: 32),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                    Text(price, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Purchased $title!')));
                        context.push('/coming-soon?title=$title');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Purchase Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final fullName = session?.user['name']?.toString() ?? 'Guest';
    final name = fullName.split(' ').first;
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final gradientColors = isDark 
        ? [const Color(0xFF0F172A), const Color(0xFF000000)]
        : [const Color(0xFFF8F9FA), const Color(0xFFE2E8F0)];
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final iconBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);
    final iconColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gradientColors)),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false, // Custom leading
                  title: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF4ADE80), Color(0xFF06B6D4)], // Green to Ocean Blue (Cyan)
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Text(
                      'Nova Health',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Buttons Row (moved up)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                                child: InkWell(
                                  onTap: () => Scaffold.of(context).openDrawer(),
                                  child: Icon(Icons.menu_rounded, color: iconColor),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                                child: InkWell(
                                  onTap: () => context.push('/patient/notifications'),
                                  child: Icon(Icons.notifications_rounded, color: iconColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                         const SizedBox(height: 8),
                        // Greeting (moved down)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Text(
                            '${_getGreeting()}, $name',
                             style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                 // Premium Features Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      'Premium Features',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                // Premium Features Carousel
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _WellnessCard(
                          title: 'Gold\nMembership',
                          buttonText: 'View Details',
                          colorStart: const Color(0xFFFFF8E1), // Light Amber
                          colorEnd: Colors.white,
                          icon: Icons.workspace_premium_rounded,
                          iconColor: Colors.amber[800]!,
                          onTap: () => _showPremiumDetails(
                            context: context,
                            title: 'Gold Membership',
                            description: 'Priority booking & \$0 fees',
                            details: 'Ideal for frequent visits. Enjoy priority booking slots during peak hours, zero platform fees on all appointments, and priority 24/7 support.',
                            price: '\$19.99/mo',
                            features: ['Priority Booking', 'Zero Platform Fees', 'Priority Support'],
                            color: Colors.amber,
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _WellnessCard(
                          title: 'Family\nHealth Plan',
                          buttonText: 'See Coverage',
                          colorStart: const Color(0xFFE8EAF6), // Light Indigo
                          colorEnd: Colors.white,
                          icon: Icons.family_restroom_rounded,
                          iconColor: Colors.indigo,
                          onTap: () => _showPremiumDetails(
                            context: context,
                            title: 'Family Health Plan',
                            description: 'Coverage for 4 members',
                            details: 'Complete peace of mind for your family. Add up to 3 dependents, access shared health records, and get flat 20% off on all pediatric consultations.',
                            price: '\$29.99/mo',
                            features: ['Up to 4 Members', 'Shared Records', '20% Off Pediatrics'],
                            color: Colors.indigo,
                            icon: Icons.family_restroom_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _WellnessCard(
                          title: 'Telemed\nPlus',
                          buttonText: 'Start Now',
                          colorStart: const Color(0xFFE0F2F1), // Light Teal
                          colorEnd: Colors.white,
                          icon: Icons.video_camera_front_rounded,
                          iconColor: Colors.teal,
                          onTap: () => _showPremiumDetails(
                            context: context,
                            title: 'Telemed Plus',
                            description: 'Unlimited Video Consults',
                            details: 'Skip the travel. Get unlimited video consultations with General Physicians, inclusive of free 7-day follow-up chats and instant digital prescriptions.',
                            price: '\$14.99/mo',
                            features: ['Unlimited Video Calls', 'Free Follow-ups', 'Digital Rx'],
                            color: Colors.teal,
                            icon: Icons.video_camera_front_rounded,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _WellnessCard(
                          title: 'Health\nInsurance',
                          buttonText: 'Get Quote',
                          colorStart: const Color(0xFFF3E5F5), // Light Purple
                          colorEnd: Colors.white,
                          icon: Icons.shield_rounded,
                          iconColor: Colors.purple,
                          onTap: () => context.push('/patient/insurance'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // My Space Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Text(
                      'My Space',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),

                // My Space Cards (Appointments, Reminders, History)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Appointments Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/patient/appointments'),
                            child: Container(
                               height: 135,
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFEEF2FF),
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Icon(Icons.calendar_today_rounded, color: const Color(0xFF6366F1), size: 28),
                                   FittedBox(fit: BoxFit.scaleDown, child: Text('Appointments', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor))),
                                 ],
                               ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Reminders Card
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/patient/reminders'),
                            child: Container(
                               height: 135,
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFFF7ED), // Light Orange
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: Colors.orange.withOpacity(0.2)),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Icon(Icons.alarm_rounded, color: Colors.orange, size: 28),
                                   FittedBox(fit: BoxFit.scaleDown, child: Text('Reminders', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor))),
                                 ],
                               ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Prescriptions Card (Restored)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/patient/prescriptions'),
                            child: Container(
                               height: 135,
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE0F2F1), // Teal 50
                                 borderRadius: BorderRadius.circular(20),
                                 border: Border.all(color: Colors.teal.withOpacity(0.2)),
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Icon(Icons.description_rounded, color: Colors.teal, size: 28),
                                   FittedBox(fit: BoxFit.scaleDown, child: Text('Prescriptions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor))),
                                 ],
                               ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Medical History & Recent Prescriptions Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View Complete History Button
                         Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/patient/medical-history'),
                            icon: const Icon(Icons.history_edu_rounded),
                            label: const Text('View Complete Medical History'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              foregroundColor: const Color(0xFF6366F1),
                              side: const BorderSide(color: Color(0xFF6366F1)),
                            ),
                          ),
                        ),

                        Text('Recent Prescriptions', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                        const SizedBox(height: 12),
                        // List of last 5 prescriptions
                        // Note: Data fetching to be implemented/connected
                        _recentPrescriptions.isEmpty 
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
                                ),
                                child: Center(child: Text('No recent prescriptions found.', style: GoogleFonts.poppins(color: Colors.grey))),
                              )
                            : Column(
                                children: _recentPrescriptions.map((p) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.description_outlined, color: Colors.teal),
                                    ),
                                    title: Text(p['doctorName'] ?? 'Unknown Doctor', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: textColor)),
                                    subtitle: Text(p['dateFormatted'] ?? '', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    onTap: () => context.push('/patient/prescriptions'), // Or specific detail
                                  ),
                                )).toList(),
                              ),
                      ],
                    ),
                  ),
                ),

                // Categories
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Text('Categories', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _CategoryChip(
                          label: 'Cardiology', 
                          icon: Icons.favorite_rounded, 
                          onTap: () => _toggleCategory('Cardiology'),
                          bgColor: _selectedCategory == 'Cardiology' ? const Color(0xFF6366F1) : iconBgColor,
                          borderColor: isDark ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          iconColor: _selectedCategory == 'Cardiology' ? Colors.white : iconColor,
                          textColor: _selectedCategory == 'Cardiology' ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        _CategoryChip(
                          label: 'Dental', 
                          icon: Icons.sentiment_very_satisfied_rounded, 
                          onTap: () => _toggleCategory('Dental'),
                          bgColor: _selectedCategory == 'Dental' ? const Color(0xFF6366F1) : iconBgColor,
                          borderColor: isDark ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          iconColor: _selectedCategory == 'Dental' ? Colors.white : iconColor,
                          textColor: _selectedCategory == 'Dental' ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        _CategoryChip(
                          label: 'General', 
                          icon: Icons.medical_services_rounded, 
                          onTap: () => _toggleCategory('General'),
                          bgColor: _selectedCategory == 'General' ? const Color(0xFF6366F1) : iconBgColor,
                          borderColor: isDark ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          iconColor: _selectedCategory == 'General' ? Colors.white : iconColor,
                          textColor: _selectedCategory == 'General' ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        _CategoryChip(
                          label: 'Neurology', 
                          icon: Icons.psychology_rounded, 
                          onTap: () => _toggleCategory('Neurology'),
                          bgColor: _selectedCategory == 'Neurology' ? const Color(0xFF6366F1) : iconBgColor,
                          borderColor: isDark ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          iconColor: _selectedCategory == 'Neurology' ? Colors.white : iconColor,
                          textColor: _selectedCategory == 'Neurology' ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        _CategoryChip(
                          label: 'Ortho', 
                          icon: Icons.accessibility_new_rounded, 
                          onTap: () => _toggleCategory('Ortho'),
                          bgColor: _selectedCategory == 'Ortho' ? const Color(0xFF6366F1) : iconBgColor,
                          borderColor: isDark ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          iconColor: _selectedCategory == 'Ortho' ? Colors.white : iconColor,
                          textColor: _selectedCategory == 'Ortho' ? Colors.white : subTextColor,
                        ),
                        const SizedBox(width: 12),
                        _CategoryChip(
                          label: 'See All', 
                          icon: Icons.grid_view_rounded, 
                          onTap: () => _filterDoctors(null), // Clear filter
                          bgColor: const Color(0xFF6366F1).withOpacity(0.1),
                          borderColor: const Color(0xFF6366F1).withOpacity(0.3),
                          iconColor: const Color(0xFF6366F1),
                          textColor: const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Top Doctors
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Top Doctors', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                        TextButton(
                          onPressed: () {
                            // If a category is selected, pass it as a query parameter
                            if (_selectedCategory != null) {
                              context.push('/patient/doctors?category=${Uri.encodeComponent(_selectedCategory!)}');
                            } else {
                              context.push('/patient/doctors');
                            }
                          },
                          child: Text('See All', style: GoogleFonts.poppins(color: subTextColor)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_loadingDoctors)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator(color: isDark ? Colors.white : const Color(0xFF6366F1))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (_filteredDoctors.isEmpty) { 
                             return _DoctorCard(
                               doctor: DoctorPublic(
                                  doctorId: 'dummy', userId: 'u', name: 'Dr. John Doe', 
                                  specialties: ['Specialist'], baseFee: 100, ratingAvg: 4.8, ratingCount: 100
                               ),
                               onTap: () {},
                               isDark: isDark,
                             );
                          }
                          final doc = _filteredDoctors[index];
                          return _DoctorCard(
                            doctor: doc,
                            onTap: () => context.push('/doctor-profile/${doc.doctorId}'),
                            onBook: () => context.push('/book-appointment/${doc.doctorId}'), // Direct navigation
                            isDark: isDark,
                          );
                        },
                        childCount: _filteredDoctors.isEmpty ? 1 : _filteredDoctors.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Featured Organizations
                 SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                     child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Featured Organizations', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                        TextButton(
                          onPressed: () => context.push('/organizations'), // Check if this route exists, otherwise create or use placeholder
                          child: Text('See All', style: GoogleFonts.poppins(color: subTextColor)),
                        ),
                      ],
                    ),
                  ),
                ),
                 SliverToBoxAdapter(
                  child: SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _OrgCard(
                          name: 'City Hospital',
                           rating: 4.8,
                           location: 'New York, USA',
                           doctorCount: 45,
                           onTap: () => context.push('/organizations/org-1'),
                           onLocationTap: () async {
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("City Hospital New York")}');
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                           },
                           isDark: isDark,
                           iconBgColor: iconBgColor,
                           textColor: textColor,
                           subTextColor: subTextColor,
                        ),
                        const SizedBox(width: 16),
                         _OrgCard(
                          name: 'Grand Medical',
                           rating: 4.5,
                           location: 'London, UK',
                           doctorCount: 32,
                           onTap: () => context.push('/organizations/org-2'),
                           onLocationTap: () async {
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("Grand Medical London")}');
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                           },
                           isDark: isDark,
                           iconBgColor: iconBgColor,
                           textColor: textColor,
                           subTextColor: subTextColor,
                        ),
                        const SizedBox(width: 16),
                         _OrgCard(
                          name: 'Sunrise Clinic',
                           rating: 4.9,
                           location: 'California, USA',
                           doctorCount: 18,
                           onTap: () => context.push('/organizations/org-3'),
                           onLocationTap: () async {
                              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("Sunrise Clinic California")}');
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                           },
                           isDark: isDark,
                           iconBgColor: iconBgColor,
                           textColor: textColor,
                           subTextColor: subTextColor,
                        ),
                      ],
                    ),
                  ),
                ),


             const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
         onPressed: () => context.push('/patient/doctors'),
         label: Text('Book', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
         icon: const Icon(Icons.add_rounded),
         backgroundColor: const Color(0xFF6366F1),
         foregroundColor: Colors.white,
      ),
    );
  }
}


class _SearchTab extends StatelessWidget {
  const _SearchTab();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Search Screen Coming Soon"));
  }
}

class _PrescriptionsPlaceholder extends StatelessWidget {
  const _PrescriptionsPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Prescriptions Coming Soon"));
  }
}


// --- WIDGETS ---

class _WellnessCard extends StatelessWidget {
  final String title;
  final String buttonText;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _WellnessCard({
    required this.title, 
    required this.buttonText, 
    required this.colorStart, 
    required this.colorEnd,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorStart, colorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 140,
                  color: iconColor.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: iconColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _CategoryChip({
    required this.label, 
    required this.icon, 
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: bgColor, 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Center(
                child: Icon(icon, color: iconColor, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorPublic doctor;
  final VoidCallback onTap;
  final VoidCallback? onBook; // New callback
  final bool isDark;

  const _DoctorCard({required this.doctor, required this.onTap, this.onBook, required this.isDark});

  @override
  Widget build(BuildContext context) {
    var specs = 'Specialist';
    if ((doctor.specialties ?? []).isNotEmpty) {
      specs = doctor.specialties!.first;
    }
    
    final cardColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final avatarBgColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100];
    final avatarTextColor = isDark ? Colors.white70 : Colors.grey[400];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: avatarBgColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://i.pravatar.cc/300?u=${doctor.doctorId}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            doctor.name.isNotEmpty ? doctor.name[0] : 'D',
                            style: GoogleFonts.poppins(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold, 
                              color: avatarTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        specs,
                        style: GoogleFonts.poppins(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (doctor.organizationName != null) ...[
                        Row(
                          children: [
                            // Location Icon -> Maps
                            GestureDetector(
                              onTap: () async {
                                final lat = doctor.organizationLat;
                                final lng = doctor.organizationLng;
                                final name = doctor.organizationName!;
                                Uri url;
                                if (lat != null && lng != null) {
                                   url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                } else {
                                   url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}');
                                }
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Icon(Icons.location_on_rounded, size: 16, color: Colors.redAccent),
                              ),
                            ),
                            
                            // Org Name -> Org Profile
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (doctor.organizationId != null) {
                                    context.push('/organizations/${doctor.organizationId}');
                                  }
                                },
                                child: Text(
                                  doctor.organizationName!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, 
                                    color: subTextColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                (doctor.ratingAvg ?? 0).toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${doctor.ratingCount ?? 0})',
                                style: GoogleFonts.poppins(
                                  color: subTextColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: onBook, // Use the dedicated callback
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'Book', 
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, 
                                  fontSize: 12
                                )
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  final String name;
  final double rating;
  final String location;
  final int doctorCount;
  final VoidCallback onTap;
  final VoidCallback? onLocationTap;
  final bool isDark;
  final Color iconBgColor;
  final Color textColor;
  final Color subTextColor;

  const _OrgCard({
    required this.name,
    required this.rating,
    required this.location,
    required this.doctorCount,
    required this.onTap,
    this.onLocationTap,
    required this.isDark,
    required this.iconBgColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_rounded, color: Color(0xFF6366F1), size: 20),
                    ),
                    const Spacer(),
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(Icons.location_on_rounded, size: 14, color: Colors.redAccent),
                      ),
                      Expanded(
                        child: Text(
                          location,
                           maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: subTextColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people_alt_rounded, size: 14, color: const Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    Text(
                      '$doctorCount Doctors',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

