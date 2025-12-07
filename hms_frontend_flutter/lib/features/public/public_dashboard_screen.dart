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
      // Handle setState errors
      return;
    }
    
    try {
      final dio = ref.read(apiClientProvider).dio;
      final svc = DoctorsPublicService(dio);
      // Load all doctors once (no search query) for client-side filtering
      final allRes = await svc.list(take: 100);
      // Load featured doctors (first 5) for carousel once, not affected by search
      final featuredRes = await svc.list(take: 5);
      
      if (mounted) {
        try {
          setState(() {
            _allDocs = allRes; // All doctors for the "All doctors" section
            _docs = featuredRes; // Featured doctors (first 5) for carousel
            _loading = false;
          });
          _applyFilter();
        } catch (e) {
          // Handle setState errors silently
        }
      }
    } catch (e) {
      // Silently handle errors - don't show snackbar to reduce noise
      // Just set loading to false
      if (mounted) {
        try {
          setState(() => _loading = false);
        } catch (e) {
          // Handle setState errors silently
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
                height: 180,
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
    
    ThemeMode tm = ThemeMode.dark;
    Session? session;
    try {
      tm = ref.watch(themeModeProvider);
    } catch (e) {
      // Use default theme mode on error
      tm = ThemeMode.dark;
    }
    
    try {
      session = ref.watch(sessionAtomProvider).value;
    } catch (e) {
      // Handle provider errors
      session = null;
    }
    
    String userName = 'Guest';
    try {
      userName = session?.user?['name']?.toString() ?? 
                 session?.user?['email']?.toString() ?? 
                 'Guest';
    } catch (e) {
      // Use default if there's any error accessing user data
      userName = 'Guest';
    }
    
    // Calculate logo size - smaller since it's on the side now
    double screenWidth = 800.0; // Default fallback
    try {
      screenWidth = size.width;
    } catch (e) {
      // Use default width on error
    }
    final logoSize = (screenWidth * 0.15).clamp(80.0, 150.0);
    
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
          // Top row with theme toggle and sign in
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Theme toggle
              IconButton(
                tooltip: tm == ThemeMode.dark ? 'Switch to light' : 'Switch to dark',
                onPressed: () {
                  try {
                    ref.read(themeModeProvider.notifier).toggle();
                  } catch (e) {
                    // Handle theme toggle errors
                  }
                },
                icon: Icon(tm == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                color: Colors.white,
              ),
              // Auth buttons when logged out
              if (!isLoggedIn) ...[
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onSignInPressed,
                  child: const Text('Sign in'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onSignUpPressed,
                  child: const Text('Sign up'),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Logo and title row - logo on left, title in center
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
                            fontSize: 28,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLoggedIn 
                          ? 'Welcome back, $userName! 👋' 
                          : 'Your Health, Our Priority 💙',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find trusted doctors & book instantly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search bar
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
      height: 170,
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

              const SizedBox(height: 8),

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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _AvatarForDoctor(doctor: doctor, size: 46),
            const SizedBox(width: 12),
            // Doctor info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doctor.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  // Specialties wrapped
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (doctor.specialties ?? [])
                        .map((s) => Chip(
                              label: Text(s, style: const TextStyle(fontSize: 12)),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ))
                        .toList(),
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
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Book'),
                ),
              ],
            ),
          ],
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
