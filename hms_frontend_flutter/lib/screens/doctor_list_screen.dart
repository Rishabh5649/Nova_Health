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

class _DoctorListScreenState extends ConsumerState<DoctorListScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = false;
  List<DoctorPublic> _all = [];
  List<DoctorPublic> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final svc = DoctorsPublicService(dio);
      final docs = await svc.list(take: 100);
      if (!mounted) return;
      setState(() {
        _all = docs;
        _filtered = docs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find doctors'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search by name or specialty',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilter(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Chip(label: Text('Specialty filter (coming soon)')),
                    SizedBox(width: 8),
                    Chip(label: Text('Rating filter (coming soon)')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(child: Text('No doctors found.')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final d = _filtered[index];
                              final specs = (d.specialties ?? []).join(', ');
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(child: Icon(Icons.person)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              d.name,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              specs.isEmpty
                                                  ? 'No specialties listed'
                                                  : specs,
                                            ),
                                            const SizedBox(height: 4),
                                            Text('Base fee: [20b[20b${d.baseFee ?? 0}'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        children: [
                                          FilledButton(
                                            onPressed: () {
                                              context.push('/patient/doctor/${d.doctorId}');
                                            },
                                            child: const Text('View'),
                                          ),
                                          const SizedBox(height: 8),
                                          OutlinedButton(
                                            onPressed: () {
                                              context.push('/patient/book-details?doctorId=${d.doctorId}');
                                            },
                                            child: const Text('Book'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
