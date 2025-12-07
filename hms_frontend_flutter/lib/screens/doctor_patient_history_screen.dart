import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

class DoctorPatientHistoryScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const DoctorPatientHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<DoctorPatientHistoryScreen> createState() => _DoctorPatientHistoryScreenState();
}

class _DoctorPatientHistoryScreenState extends ConsumerState<DoctorPatientHistoryScreen> {
  bool _loading = true;
  List<dynamic> _appointments = [];
  List<dynamic> _medicalHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final session = ref.read(authControllerProvider).session;
      final doctorId = session?.user['id']?.toString();
      
      // Fetch all appointments with this patient
      final apptsRes = await dio.get('/appointments', queryParameters: {
        'doctorId': doctorId,
        'patientId': widget.patientId,
      });
      
      // Fetch patient's complete medical history
      final historyRes = await dio.get('/patients/${widget.patientId}/records');
      
      if (mounted) {
        setState(() {
          _appointments = apptsRes.data as List<dynamic>;
          _medicalHistory = historyRes.data as List<dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showMedicalHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Complete Medical History',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _medicalHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'No medical history found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _medicalHistory.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final item = _medicalHistory[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.medical_information, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['diagnosis'] ?? 'Unknown Diagnosis',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item['details'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item['details'],
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    item['recordedAt'] != null
                                        ? DateTime.parse(item['recordedAt']).toLocal().toString().split('.')[0]
                                        : '',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.patientName}\'s Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            onPressed: _showMedicalHistory,
            tooltip: 'View Complete Medical History',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_appointments.length} Appointments',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete appointment history with prescriptions',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showMedicalHistory,
                        icon: const Icon(Icons.medical_information, size: 18),
                        label: const Text('Full History'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Appointments list
                Expanded(
                  child: _appointments.isEmpty
                      ? const Center(child: Text('No appointments found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appt = _appointments[index];
                            final scheduledAt = DateTime.parse(appt['scheduledAt']);
                            final status = appt['status'];
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: status == 'COMPLETED' ? Colors.green : Colors.blue,
                                  child: Icon(
                                    status == 'COMPLETED' ? Icons.check : Icons.schedule,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  appt['reason'] ?? 'Consultation',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year} • ${status}',
                                ),
                                children: [
                                  const Divider(height: 1),
                                  _AppointmentDetails(appointmentId: appt['id']),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AppointmentDetails extends ConsumerStatefulWidget {
  final String appointmentId;
  
  const _AppointmentDetails({required this.appointmentId});
  
  @override
  ConsumerState<_AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends ConsumerState<_AppointmentDetails> {
  bool _loading = true;
  Map<String, dynamic>? _prescription;
  
  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }
  
  Future<void> _loadPrescription() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/prescriptions/appointment/${widget.appointmentId}');
      if (mounted) {
        setState(() {
          _prescription = res.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_prescription == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No prescription available', style: TextStyle(color: Colors.grey)),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Prescription',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Diagnosis', _prescription!['diagnosis'] ?? 'N/A'),
          const SizedBox(height: 8),
          _buildInfoRow('Notes', _prescription!['notes'] ?? 'No notes'),
          if (_prescription!['medications'] != null && (_prescription!['medications'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Medications:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(_prescription!['medications'] as List).map((med) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text('${med['dosage']} • ${med['frequency']} • ${med['duration']}'),
                  if (med['instruction'] != null && med['instruction'].toString().isNotEmpty)
                    Text(
                      med['instruction'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
