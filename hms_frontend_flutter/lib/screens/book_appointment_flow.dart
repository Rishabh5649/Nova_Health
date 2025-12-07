import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/public/doctors_public_service.dart';
import '../features/public/models/doctor_public.dart';

class BookAppointmentFlow extends ConsumerStatefulWidget {
  const BookAppointmentFlow({super.key});

  @override
  ConsumerState<BookAppointmentFlow> createState() => _BookAppointmentFlowState();
}

class _BookAppointmentFlowState extends ConsumerState<BookAppointmentFlow> {
  final _searchCtrl = TextEditingController();
  List<DoctorPublic> _all = [];
  List<DoctorPublic> _filtered = [];
  bool _loading = false;

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
        title: const Text('Book appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select doctor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search doctors',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _applyFilter(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(child: Text('No doctors found.'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final d = _filtered[index];
                            final specs = (d.specialties ?? []).join(', ');
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading:
                                    const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(d.name),
                                subtitle: Text(
                                  specs.isEmpty
                                      ? 'No specialties listed'
                                      : specs,
                                ),
                                trailing: FilledButton(
                                  onPressed: () {
                                    // For now just navigate to same route as public booking
                                    context.push(
                                      '/appointments/book?doctorId=${d.doctorId}',
                                    );
                                  },
                                  child: const Text('Book'),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
