// lib/features/public/public_dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/require_auth.dart';
import '../../core/providers.dart';
import '../../core/session_store.dart'; // Import Session class
import 'doctors_public_service.dart';
import 'models/doctor_public.dart';
import 'organizations_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme_provider.dart'; // if you put theme provider there

class PublicDashboardScreen extends ConsumerStatefulWidget {
  const PublicDashboardScreen({super.key});
  @override
  ConsumerState<PublicDashboardScreen> createState() => _PublicDashboardScreenState();
}

class _PublicDashboardScreenState extends ConsumerState<PublicDashboardScreen> {
  List<DoctorPublic> _docs = [];
  List<DoctorPublic> _allDocs = []; // all doctors from API
  List<DoctorPublic> _filteredDocs = []; // filtered list for "All doctors" section
  List<Map<String, dynamic>> _orgs = []; // featured organizations
  bool _loading = true;
  String _q = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      setState(() => _loading = true);
    } catch (e) {
      return;
    }
    
    try {
      final dio = ref.read(apiClientProvider).dio;
      final svc = DoctorsPublicService(dio);
      final orgSvc = ref.read(organizationsServiceProvider);

      // Load all doctors once (no search query) for client-side filtering
      final allRes = await svc.list(take: 100);
      // Load featured doctors (first 5) for carousel once
      final featuredRes = await svc.list(take: 5);
      // Load featured organizations
      final orgsRes = await orgSvc.list();
      
      if (mounted) {
        try {
          setState(() {
            _allDocs = allRes; // All doctors
            _docs = featuredRes; // Featured doctors
            _orgs = orgsRes.take(5).toList();
            _loading = false;
          });
          _applyFilter();
        } catch (e) {
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          setState(() => _loading = false);
        } catch (e) {
        }
      }
    }
  }

  void _applyFilter() {
    if (!mounted) return;
    final query = _q.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredDocs = List<DoctorPublic>.from(_allDocs);
      });
      return;
    }

    setState(() {
      _filteredDocs = _allDocs.where((d) {
        final name = d.name.toLowerCase();
        final specialties = (d.specialties ?? []).join(' ').toLowerCase();
        return name.contains(query) || specialties.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = false;
    try {
      final session = ref.watch(sessionAtomProvider).value;
      isLoggedIn = session != null;
    } catch (e) {
      // Handle provider errors gracefully
      isLoggedIn = false;
    }

    return Scaffold(
      // Hero header + AppBar combined using Stack so header can be large
      body: RefreshIndicator(
        onRefresh: () => _load(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 320,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _HeaderArea(
                  searchController: _searchController,
                  onSearch: (q) {
                    // Cancel any pending search
                    _searchDebounce?.cancel();
                    // Debounce the search
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      _q = q;
                      _applyFilter();
                    });
                  },
                  isLoggedIn: isLoggedIn,
                  onSignInPressed: () {
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  onSignUpPressed: () {
                    if (context.mounted) {
                      context.go('/signup');
                    }
                  },
                ),
              ),
              actions: [
                if (isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PopupMenuButton(
                    icon: const Icon(Icons.account_circle_outlined),
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'dashboard', child: Text('My Dashboard')),
                      PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                    onSelected: (v) async {
                      try {
                        if (v == 'dashboard') {
                          if (context.mounted) {
                            try {
                              context.go('/app');
                            } catch (e) {
                              // Handle navigation errors
                            }
                          }
                        } else if (v == 'logout') {
                          try {
                            await ref.read(authControllerProvider).logout();
                          } catch (e) {
                            // Handle logout errors silently
                          }
                        }
                      } catch (e) {
                        // Handle any unexpected errors
                      }
                    },
                  ),
                )
              ],
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _QuickActionsRow(onAction: (route) async {
                    try {
                      requireAuth(ref, context, () async {
                        if (context.mounted) {
                          try {
                            context.go(route);
                          } catch (e) {
                            // Handle navigation errors
                          }
                        }
                      });
                    } catch (e) {
                      // Handle requireAuth errors
                    }
                  }),
                ),
              ),
            ),

            // Featured carousel title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Featured doctors', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),

            // Featured doctors horizontally
            SliverToBoxAdapter(
              child: SizedBox(
                height: 205,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final d = _docs[i];
                    return _FeaturedDoctorCard(
                      doctor: d,
                      onBook: () {
                        try {
                          requireAuth(ref, context, () async {
                            if (context.mounted) {
                              try {
                                context.push('/appointments/book?doctorId=${d.doctorId}');
                              } catch (e) {
                                // Handle navigation errors
                              }
                            }
                          });
                        } catch (e) {
                          // Handle requireAuth errors
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // Organizations title
            if (_orgs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Trusted Organizations', style: Theme.of(context).textTheme.titleLarge),
                ),
              ),
              
              // Organizations horizontally
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 190,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _orgs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) {
                      final org = _orgs[i];
                      return _FeaturedOrganizationCard(
                        org: org,
                        onTap: () {
                           context.push('/organizations/${org['id']}');
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // List title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('All doctors', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),

            // Search bar for All doctors section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doctors, specialties...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      _q = value;
                      _applyFilter();
                    });
                  },
                  onSubmitted: (value) {
                    _searchDebounce?.cancel();
                    if (!mounted) return;
                    _q = value;
                    _applyFilter();
                  },
                ),
              ),
            ),

            // Doctor list - show all doctors
            SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                if (i >= _filteredDocs.length) {
                  return const SizedBox.shrink();
                }
                final d = _filteredDocs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _DoctorListCard(doctor: d, onBook: () {
                    try {
                      requireAuth(ref, context, () async {
                        if (context.mounted) {
                          try {
                            context.push('/appointments/book?doctorId=${d.doctorId}');
                          } catch (e) {
                            // Handle navigation errors
                          }
                        }
                      });
                    } catch (e) {
                      // Handle requireAuth errors
                    }
                  }),
                );
              }, childCount: _allDocs.length),
            ),

            SliverToBoxAdapter(child: const SizedBox(height: 40)),
            
            // About Us Section
            const SliverToBoxAdapter(
              child: _AboutUsSection(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          try {
            requireAuth(ref, context, () async {
              if (context.mounted) {
                try {
                  context.go('/appointments/book');
                } catch (e) {
                  // Handle navigation errors
                }
              }
            });
          } catch (e) {
            // Handle requireAuth errors
          }
        },
        label: const Text('Quick Book'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

/// Header area with gradient, logo, greeting and search
class _HeaderArea extends ConsumerWidget {
  final TextEditingController searchController;
  final void Function(String q) onSearch;
  final bool isLoggedIn;
  final VoidCallback onSignInPressed;
  final VoidCallback onSignUpPressed;

  const _HeaderArea({
    required this.searchController,
    required this.onSearch,
    required this.isLoggedIn,
    required this.onSignInPressed,
     required this.onSignUpPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;
    
    ThemeMode tm = ThemeMode.system;
    Session? session;
    try {
      tm = ref.watch(themeProvider);
    } catch (e) {
      tm = ThemeMode.system;
    }
    
    try {
      session = ref.watch(sessionAtomProvider).value;
    } catch (e) {
      session = null;
    }
    
    String userName = 'Guest';
    try {
      userName = session?.user?['name']?.toString() ?? 
                 session?.user?['email']?.toString() ?? 
                 'Guest';
    } catch (e) {
      userName = 'Guest';
    }
    
    // Calculate logo size - bigger as requested
    double screenWidth = 800.0;
    try {
      screenWidth = size.width;
    } catch (e) {}
    final logoSize = (screenWidth * 0.22).clamp(100.0, 180.0);
    
    return Container(
      padding: EdgeInsets.only(top: top + 12, left: 16, right: 16, bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tm == ThemeMode.dark
              ? [Color(0xFF0B2447), Color(0xFF2563EB)]
              : [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with For Doctors (left) and Sign In + Theme (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Link to Doctor Home
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/doctor-home'),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'For Doctors',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),

              // Right side items
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Theme toggle
                  IconButton(
                    tooltip: 'Toggle Theme',
                    onPressed: () {
                      try {
                        ref.read(themeProvider.notifier).toggleTheme();
                      } catch (e) {}
                    },
                    icon: Icon(tm == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 28),
                    color: Colors.white,
                  ),
                  
                  // Auth buttons when logged out
                  if (!isLoggedIn) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: onSignInPressed,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Logo and title row
          Row(
            children: [
              // Logo on the left side
              Image.asset(
                'assets/images/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) {
                    return child;
                  }
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medical_services, size: logoSize * 0.6, color: Colors.white),
                  );
                },
              ),
              const SizedBox(width: 16),
              // App name and catchy text in the center
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nova Health',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32, // slightly larger
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLoggedIn 
                          ? 'Welcome back, $userName! 👋' 
                          : 'Your Health, Our Priority 💙',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find trusted doctors, book instantly & store medical history',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Search bar placeholder
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
/// Quick actions row with small animated cards
class _QuickActionsRow extends StatelessWidget {
  final void Function(String route) onAction;
  const _QuickActionsRow({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Book Appointment', 'icon': Icons.add_circle_outline, 'route': '/appointments/book'},
      {'label': 'Prescriptions', 'icon': Icons.medication_outlined, 'route': '/prescriptions'},
      {'label': 'Medical History', 'icon': Icons.history_edu_outlined, 'route': '/medical-history'},
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (ctx, i) {
        final it = items[i];
        return _ActionCard(label: it['label']! as String, icon: it['icon']! as IconData, onTap: () => onAction(it['route']! as String));
      },
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.label, required this.icon, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(widget.icon, size: 28),
            const Spacer(),
            Text(widget.label, style: Theme.of(context).textTheme.titleMedium),
          ]),
        ),
      ),
    );
  }
}

/// Big featured doctor card used in the carousel
class _FeaturedDoctorCard extends StatelessWidget {
  final DoctorPublic doctor;
  final VoidCallback onBook;
  const _FeaturedDoctorCard({required this.doctor, required this.onBook, super.key});

  @override
  Widget build(BuildContext context) {
    // give the card a fixed height so it can't overflow the carousel
    return SizedBox(
      width: 280,
      height: 195,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(children: [
                _AvatarForDoctor(doctor: doctor, size: 56),
                const SizedBox(width: 12),
                Expanded(child: Text(doctor.name, style: Theme.of(context).textTheme.titleMedium)),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('⭐ ${doctor.ratingAvg?.toStringAsFixed(1) ?? '5.0'}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text('₹${doctor.baseFee ?? '—'}', style: Theme.of(context).textTheme.titleSmall),
                ]),
              ]),

              const SizedBox(height: 4),

              // limit the chip area height and allow horizontal scrolling for many chips
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (doctor.specialties ?? []).map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(label: Text(s)),
                  )).toList(),
                ),
              ),

              const Spacer(),

              // book button aligned to bottom right without expanding card height
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(onPressed: onBook, child: const Text('Book')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact list card for doctors
class _DoctorListCard extends StatelessWidget {
  final DoctorPublic doctor;
  final VoidCallback onBook;
  const _DoctorListCard({required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          try {
            context.push('/doctor-profile/${doctor.userId}');
          } catch (e) {
            // navigate safely
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              _AvatarForDoctor(doctor: doctor, size: 56),
              const SizedBox(width: 12),
              // Doctor info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      doctor.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // Organization & Location
                    if (doctor.organizationName != null)
                      Row(
                        children: [
                          const Icon(Icons.business_rounded, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${doctor.organizationName} ${doctor.organizationAddress != null ? "• ${doctor.organizationAddress}" : ""}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    // Rating & Experience
                    Row(
                      children: [
                        if (doctor.ratingAvg != null) ...[
                          Icon(Icons.star_rounded, size: 16, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            doctor.ratingAvg!.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (doctor.yearsExperience != null) ...[
                          Icon(Icons.work_history_rounded, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor.yearsExperience} yrs',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Specialties wrapped
                    if (doctor.specialties != null && doctor.specialties!.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: doctor.specialties!.take(3).map((s) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(s, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                        )).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Price and Book button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${doctor.baseFee ?? '—'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onBook,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Book'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar helper: shows image if available or initials in a circle
class _AvatarForDoctor extends StatelessWidget {
  final DoctorPublic doctor;
  final double size;
  const _AvatarForDoctor({required this.doctor, this.size = 48});

  @override
  Widget build(BuildContext context) {
    // If doctor model had image URL, use FadeInImage.network; otherwise use initials
    final initials = doctor.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join();
    return CircleAvatar(
      radius: size / 2,
      child: Text(initials, style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _FeaturedOrganizationCard extends StatelessWidget {
  final Map<String, dynamic> org;
  final VoidCallback onTap;
  
  const _FeaturedOrganizationCard({required this.org, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    // Random color generation for placeholder or use logo
    final name = org['name'] as String? ?? 'Organization';
    final initial = name.isNotEmpty ? name[0] : 'O';
    
    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blueAccent)),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        org['type'] as String? ?? 'General Hospital',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Text('View Details', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutUsSection extends StatelessWidget {
  const _AboutUsSection();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[100],
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism_rounded, size: 48, color: Colors.blueAccent),
          const SizedBox(height: 16),
          Text(
            'About Nova Health',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Our mission is to make quality healthcare accessible to everyone. '
            'We connect patients with trusted medical professionals and organizations, '
            'streamlining the process of booking appointments, managing records, '
            'and receiving care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FeatureIcon(Icons.verified_user_rounded, 'Trusted'),
              const SizedBox(width: 24),
              _FeatureIcon(Icons.speed_rounded, 'Fast'),
              const SizedBox(width: 24),
              _FeatureIcon(Icons.security_rounded, 'Secure'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureIcon(this.icon, this.label);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
