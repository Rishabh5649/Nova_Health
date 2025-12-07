// Booking flow step 2: capture details
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';

class BookAppointmentDetailsScreen extends ConsumerStatefulWidget {
  const BookAppointmentDetailsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookAppointmentDetailsScreen> createState() => _BookAppointmentDetailsScreenState();
}

class _BookAppointmentDetailsScreenState extends ConsumerState<BookAppointmentDetailsScreen> {
  final _symptomsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loadingDoctor = true;
  bool _submitting = false;
  Map<String, dynamic>? _doctor;
  bool _checkingEligibility = true;
  Map<String, dynamic>? _eligibility;

  @override
  void initState() {
    super.initState();
    _loadDoctorAndCheckEligibility();
  }

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorAndCheckEligibility() async {
    setState(() {
      _loadingDoctor = true;
      _checkingEligibility = true;
    });

    try {
      final dio = ref.read(apiClientProvider).dio;
      final session = ref.read(authControllerProvider).session;
      final patientId = session?.user['id']?.toString();

      // Load doctor
      final docRes = await dio.get('/doctors/${widget.doctorId}');
      
      // Check eligibility if patient is logged in
      Map<String, dynamic>? eligibilityData;
      if (patientId != null) {
        try {
          final eligRes = await dio.get('/appointments/check-eligibility', queryParameters: {
            'patientId': patientId,
            'doctorId': widget.doctorId,
          });
          eligibilityData = eligRes.data as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Error checking eligibility: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _doctor = docRes.data as Map<String, dynamic>;
        _eligibility = eligibilityData;
        _loadingDoctor = false;
        _checkingEligibility = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _loadingDoctor = false;
        _checkingEligibility = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading details: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_symptomsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your symptoms')),
      );
      return;
    }

    // Extract organization memberships
    List<dynamic>? memberships;
    try {
      memberships = _doctor?['user']?['memberships'] as List?;
    } catch (e) {
      debugPrint('Could not extract memberships: $e');
    }

    String? organizationId;

    // If doctor has multiple organizations, let patient choose
    if (memberships != null && memberships.length > 1) {
      final selectedOrg = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Organization'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: memberships!.map((membership) {
              final org = membership['organization'];
              return ListTile(
                title: Text(org['name'] ?? 'Unknown'),
                subtitle: Text('${org['type'] ?? ''} • ${org['address'] ?? ''}'),
                onTap: () => Navigator.pop(context, org),
              );
            }).toList(),
          ),
        ),
      );

      if (selectedOrg == null) return; // User cancelled
      organizationId = selectedOrg['id']?.toString();
    } else if (memberships != null && memberships.isNotEmpty) {
      // Single organization - use it directly
      organizationId = memberships[0]['organizationId']?.toString();
    }

    setState(() => _submitting = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      
      // For MVP we send a request and let the doctor choose the exact slot.
      // Backend expects: { doctorUserId, scheduledAt, reason, organizationId }
      final requestData = {
        'doctorUserId': widget.doctorId,
        'scheduledAt': DateTime.now().toUtc().toIso8601String(),
        'reason': _symptomsCtrl.text.trim(),
      };
      
      if (organizationId != null) {
        requestData['organizationId'] = organizationId;
      }
      
      await dio.post('/appointments/request', data: requestData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment request sent to doctor'),
        ),
      );
      context.pop();
    } catch (e) {
      debugPrint('Error submitting appointment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doctor;
    final memberships = doc?['user']?['memberships'] as List?;
    final isFollowUp = _eligibility?['isFollowUp'] == true;
    final chargedFee = _eligibility?['chargedFee'] ?? doc?['baseFee'] ?? doc?['fees'] ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment details'),
      ),
      body: _loadingDoctor
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Doctor'),
                  subtitle: Text((doc?['name'] ?? 'Doctor').toString()),
                ),
                if (memberships != null && memberships.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(memberships.length > 1 ? 'Works at ${memberships.length} organizations' : 'Organization'),
                    subtitle: Text(
                      memberships.length > 1
                          ? 'You will select one when booking'
                          : (memberships[0]['organization']?['name'] ?? 'Unknown'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                
                // Fee Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFollowUp ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFollowUp ? Colors.green : Colors.blue,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFollowUp ? 'Follow-up Appointment' : 'Consultation Fee',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFollowUp ? Colors.green[800] : Colors.blue[800],
                            ),
                          ),
                          Text(
                            '₹$chargedFee',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isFollowUp ? Colors.green[800] : Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                      if (isFollowUp) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Original Fee: ₹${_eligibility?['originalFee'] ?? 0}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'This is a valid follow-up appointment.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                TextField(
                  controller: _symptomsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Disease / symptoms',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isFollowUp)
                  const Text(
                    'Base fees for this doctor must be paid now. Anything extra will be charged after the appointment.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isFollowUp ? 'Confirm Follow-up' : 'Confirm and book'),
                ),
              ],
            ),
    );
  }
}
