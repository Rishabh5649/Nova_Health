import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/appointment.dart';
import '../../services/appointment_api.dart';
import '../../core/providers.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  ConsumerState<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends ConsumerState<PendingRequestsScreen> {
  bool _loading = true;
  List<Appointment> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = ref.read(authControllerProvider).session;
      final doctorId = session?.user['id']?.toString();
      
      if (doctorId == null || doctorId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _requests = [];
          _loading = false;
        });
        return;
      }
      
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/appointments', queryParameters: {
        'doctorId': doctorId,
        'status': 'PENDING',
      });
      
      if (!mounted) return;
      
      final list = (res.data as List?)?.cast<Map<String, dynamic>>() ?? [];
      final appointments = list.map((json) => Appointment.fromJson(json)).toList();
      
      setState(() {
        _requests = appointments;
        _loading = false;
      });
    } catch (e) {
      print('Error loading pending requests: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(Appointment a) async {
    // 1. Pick Date
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    // 2. Pick Time
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1))),
    );
    if (time == null) return;

    // Combine to a single scheduledAt that we send to backend
    final start = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    try {
      // Notify backend that doctor confirmed and picked a slot
      final dio = ref.read(apiClientProvider).dio;
      await dio.patch('/appointments/${a.id}/confirm', data: {
        'scheduledAt': start.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment accepted for ${start.toLocal()}')),
      );
      _load(); // reload list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Requests')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No pending requests'),
                      SizedBox(height: 8),
                      Text(
                        'Requests are accepted by admin/receptionist',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final a = _requests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.schedule, color: Colors.orange),
                        title: Text(a.reason ?? 'Appointment Request'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested: ${a.start.toLocal()}'),
                            const SizedBox(height: 4),
                            const Text(
                              'Waiting for admin approval',
                              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}

