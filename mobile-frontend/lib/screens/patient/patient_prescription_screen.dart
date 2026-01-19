import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/providers.dart';

class PatientPrescriptionScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  const PatientPrescriptionScreen({super.key, required this.appointmentId});

  @override
  ConsumerState<PatientPrescriptionScreen> createState() => _PatientPrescriptionScreenState();
}

class _PatientPrescriptionScreenState extends ConsumerState<PatientPrescriptionScreen> {
  bool _loading = true;
  Map<String, dynamic>? _prescription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/prescriptions/appointment/${widget.appointmentId}');
      
      if (!mounted) return;
      setState(() {
        _prescription = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is DioException && e.response?.statusCode == 404) {
          _error = 'No prescription found for this appointment.';
        } else {
          _error = 'Error loading prescription: $e';
        }
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _prescription == null
                  ? const Center(child: Text('No prescription data'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dr. ${_prescription!['doctor']?['name'] ?? 'Unknown'}',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    _prescription!['createdAt'] != null
                                        ? DateTime.parse(_prescription!['createdAt']).toLocal().toString().split(' ')[0]
                                        : '',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Text(
                                'Diagnosis',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(_prescription!['diagnosis'] ?? 'None'),
                              const SizedBox(height: 16),
                              Text(
                                'Notes / Instructions',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(_prescription!['notes'] ?? 'None'),
                              
                              // Medications would go here if we had them
                              if (_prescription!['medications'] != null && (_prescription!['medications'] as List).isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'Medications',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ...(_prescription!['medications'] as List).map((m) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(m['name']),
                                  subtitle: Text('${m['dosage']} - ${m['frequency']} (${m['duration']})'),
                                )),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}

