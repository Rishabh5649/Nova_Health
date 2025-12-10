// Doctor search/browse screen MVP
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/public/doctors_public_service.dart';
import '../features/public/models/doctor_public.dart';

class DoctorListScreen extends ConsumerStatefulWidget {
  const DoctorListScreen({super.key});

  @override
  ConsumerState<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabController;
  
  bool _loading = false;
  List<DoctorPublic> _allDoctors = [];
  List<DoctorPublic> _filteredDoctors = [];
  List<Map<String, dynamic>> _allOrgs = [];
  List<Map<String, dynamic>> _filteredOrgs = [];

  // Filters
  double? _minRating;
  double _maxFee = 1000;
  String? _selectedSpecialty;
  double _maxDistance = 50; // Mock distance

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
    _searchCtrl.addListener(_applyFilter); // Real-time filtering
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final svc = DoctorsPublicService(dio);
      
      final docs = await svc.list(take: 100);
      final orgs = await svc.listOrganizations();
      
      final state = GoRouterState.of(context);
      final category = state.uri.queryParameters['category'];

      if (!mounted) return;
      
      _allDoctors = docs;
      _allOrgs = orgs;

      // Initial filter if category passed
      if (category != null && category.isNotEmpty) {
         _searchCtrl.text = category;
         if (_searchCtrl.text.isNotEmpty) {
           _applyFilter(); // Will use the text
         }
      } else {
         _filteredDoctors = List.from(docs);
         _filteredOrgs = List.from(orgs);
      }
      
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    
    setState(() {
      // Filter Doctors
      _filteredDoctors = _allDoctors.where((d) {
        final matchesName = d.name.toLowerCase().contains(q);
        final matchesSpec = (d.specialties ?? []).join(' ').toLowerCase().contains(q);
        final matchesSearch = matchesName || matchesSpec;
        
        final matchesRating = _minRating == null || (d.ratingAvg ?? 0) >= _minRating!;
        final matchesFee = (d.baseFee ?? 0) <= _maxFee;
        final matchesSpecialtyFilter = _selectedSpecialty == null || 
            (d.specialties ?? []).any((s) => s.toLowerCase() == _selectedSpecialty!.toLowerCase());
            
        return matchesSearch && matchesRating && matchesFee && matchesSpecialtyFilter;
      }).toList();

      // Filter Orgs
      _filteredOrgs = _allOrgs.where((o) {
        final name = (o['name'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(q);
        // Add more org filters if available
        return matchesSearch;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  
                  // Rating
                  Text('Minimum Rating: ${_minRating ?? "Any"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: (_minRating ?? 0).toString(),
                    onChanged: (val) {
                      setSheetState(() => _minRating = val == 0 ? null : val);
                    },
                  ),

                  // Fee
                  Text('Max Base Fee: \$${_maxFee.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxFee,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    label: _maxFee.toInt().toString(),
                    onChanged: (val) {
                      setSheetState(() => _maxFee = val);
                    },
                  ),

                  // Distance (Mock)
                  Text('Distance: < ${_maxDistance.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 100,
                    label: '${_maxDistance.toInt()} km',
                    onChanged: (val) {
                      setSheetState(() => _maxDistance = val);
                    },
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilter();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _minRating = null;
                      _maxFee = 1000;
                      _maxDistance = 50;
                      // _selectedSpecialty = null;
                      Navigator.pop(context);
                      _applyFilter();
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Doctors'),
            Tab(text: 'Organizations'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: _showFilterSheet,
                  icon: const Icon(Icons.tune_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Doctors List
                      _filteredDoctors.isEmpty
                          ? const Center(child: Text('No doctors found'))
                          : ListView.builder(
                              itemCount: _filteredDoctors.length,
                              itemBuilder: (context, index) {
                                final d = _filteredDoctors[index];
                                final specs = (d.specialties ?? []).join(', ');
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${d.userId}'),
                                      onBackgroundImageError: (_,__) => const Icon(Icons.person),
                                    ),
                                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('$specs\n\$${d.baseFee} • ⭐ ${(d.ratingAvg ?? 0).toStringAsFixed(1)}'),
                                    isThreeLine: true,
                                    trailing: FilledButton(
                                      onPressed: () => context.push('/book-appointment/${d.doctorId}'),
                                      child: const Text('Book'),
                                    ),
                                    onTap: () => context.push('/doctor-profile/${d.doctorId}'),
                                  ),
                                );
                              },
                            ),

                      // Organizations List
                      _filteredOrgs.isEmpty
                          ? const Center(child: Text('No organizations found'))
                          : ListView.builder(
                              itemCount: _filteredOrgs.length,
                              itemBuilder: (context, index) {
                                final o = _filteredOrgs[index];
                                final name = o['name'] ?? 'Unknown';
                                final type = o['type'] ?? 'Organization';
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.business, color: Colors.blue),
                                    ),
                                    title: Text(name.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(type.toString()),
                                    onTap: () {
                                      if (o['id'] != null) {
                                         context.push('/organizations/${o['id']}');
                                      }
                                    },
                                    trailing: const Icon(Icons.chevron_right),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
