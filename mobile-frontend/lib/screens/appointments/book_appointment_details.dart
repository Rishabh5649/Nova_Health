// Booking flow step 2: capture details
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/providers.dart';

class BookAppointmentDetailsScreen extends ConsumerStatefulWidget {
  const BookAppointmentDetailsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  ConsumerState<BookAppointmentDetailsScreen> createState() => _BookAppointmentDetailsScreenState();
}

class _BookAppointmentDetailsScreenState extends ConsumerState<BookAppointmentDetailsScreen> {
  final _symptomsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController(); // Used for notes/reason
  bool _loadingDoctor = true;
  bool _submitting = false;
  Map<String, dynamic>? _doctor;
  bool _checkingEligibility = true;
  Map<String, dynamic>? _eligibility;
  
  late Razorpay _razorpay;
  String? _pendingOrgId; 
  bool _simulatePayment = false;
  String? _precreatedOrderId;
  bool _creatingOrder = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadDoctorAndCheckEligibility();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _symptomsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }
  
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment Done. Verify and Book.
    try {
      final dio = ref.read(apiClientProvider).dio;
      
      // Verify first
      await dio.post('/payments/verify', data: {
        'orderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature
      });
      
      // If verify success, Proceed to Book
      await _finalizeBooking(paymentData: {
        'razorpayOrderId': response.orderId,
        'razorpayPaymentId': response.paymentId,
        'paymentStatus': 'PAID'
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Verification Failed: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
    setState(() => _submitting = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
    // Usually means success or pending? Razorpay docs say handle separately.
    // For now treated as info.
  }

  // ... (rest of load logic identical) ...
  Future<void> _loadDoctorAndCheckEligibility() async {
     // ... (Keep existing implementation) ...
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
      
      // Check eligibility
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

      // Prefetch order if needed
      final chargedFee = _eligibility?['chargedFee'] ?? _doctor?['baseFee'] ?? _doctor?['fees'] ?? 0;
      if (chargedFee is num && chargedFee > 0) {
        _prefetchRazorpayOrder(chargedFee.toInt());
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _loadingDoctor = false;
        _checkingEligibility = false;
      });
    }
  }
  
  Future<void> _prefetchRazorpayOrder(int amount) async {
    if (_creatingOrder) return;
    setState(() => _creatingOrder = true);
    try {
       final dio = ref.read(apiClientProvider).dio;
       final orderRes = await dio.post('/payments/create-order', data: {'amount': amount});
       if (mounted) {
         setState(() => _precreatedOrderId = orderRes.data['id'].toString());
       }
    } catch (e) {
      debugPrint('Error pre-creating order: $e');
    } finally {
      if (mounted) setState(() => _creatingOrder = false);
    }
  }

  Future<void> _submit() async {
    if (_symptomsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your symptoms')),
      );
      return;
    }

    // Organization Selection
    List<dynamic>? memberships;
    try {
      memberships = _doctor?['user']?['memberships'] as List?;
    } catch (e) { }

    String? organizationId;
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
      if (selectedOrg == null) return;
      organizationId = selectedOrg['id']?.toString();
    } else if (memberships != null && memberships.isNotEmpty) {
      organizationId = memberships[0]['organizationId']?.toString();
    }
    
    _pendingOrgId = organizationId;
    
    // Fee Calculation
    final doc = _doctor;
    final chargedFee = _eligibility?['chargedFee'] ?? doc?['baseFee'] ?? doc?['fees'] ?? 0;
    
    setState(() => _submitting = true);

    if (chargedFee > 0) {
      // Dev Mode Bypass
      if (_simulatePayment) {
        // Wait a bit to simulate network
        await Future.delayed(const Duration(seconds: 1));
        _handlePaymentSuccess(PaymentSuccessResponse(
           'pay_simulated_${DateTime.now().millisecondsSinceEpoch}',
           'order_simulated_${DateTime.now().millisecondsSinceEpoch}',
           'simulated_signature',
           null
        ));
        return;
      }

      // Initiate Razorpay Flow
      try {
        final dio = ref.read(apiClientProvider).dio;
        
        String orderId;
        if (_precreatedOrderId != null) {
           orderId = _precreatedOrderId!;
        } else {
           // Fallback if prefetch failed
           final orderRes = await dio.post('/payments/create-order', data: {'amount': chargedFee});
           orderId = orderRes.data['id'].toString();
        }

        var options = {
          'key': 'rzp_test_1DP5mmOlF5G5ag',
          'amount': chargedFee * 100,
          'name': 'Nova Health',
          'description': 'Appointment with Dr. ${_doctor?['name']}',
          if (!orderId.contains('simulated')) 'order_id': orderId,
          'prefill': {
            'contact': '9123456789',
            'email': 'test@example.com'
          },
          'theme': {'color': '#0F766E'}
        };
        
        debugPrint('Attempting to open Razorpay: $options');
        try {
           _razorpay.open(options);
        } catch (e) {
           debugPrint('Razorpay.open() failed: $e');
           throw e;
        }
        
        // Stop loading immediately. 
        // If the sheet opens, the user interacts with it.
        // If it fails to open, the user isn't stuck.
        setState(() => _submitting = false);

      } catch (e) {
        debugPrint('Error initiating payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Init Failed: $e')));
        setState(() => _submitting = false);
      }
    } else {
      // Free or Follow-up
      await _finalizeBooking();
    }
  }

  Future<void> _finalizeBooking({Map<String, dynamic>? paymentData}) async {
     try {
      final dio = ref.read(apiClientProvider).dio;
      
      final requestData = {
        'doctorUserId': widget.doctorId,
        'scheduledAt': DateTime.now().toUtc().toIso8601String(),
        'reason': _symptomsCtrl.text.trim(),
        if (_pendingOrgId != null) 'organizationId': _pendingOrgId,
        'notes': _notesCtrl.text.trim(),
        if (paymentData != null) ...paymentData
      };
      
      await dio.post('/appointments/request', data: requestData);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment confirmed successfully!')),
      );
      context.pop();
    } catch (e) {
      debugPrint('Error submitting appointment: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                if (!isFollowUp) ...[
                   CheckboxListTile(
                     title: const Text('Dev Mode: Simulate Payment'),
                     subtitle: const Text('Skip actual gateway (for testing)'),
                     value: _simulatePayment,
                     onChanged: (val) => setState(() => _simulatePayment = val ?? false),
                     contentPadding: EdgeInsets.zero,
                     dense: true,
                     controlAffinity: ListTileControlAffinity.leading,
                   ),
                   const Text(
                    'Base fees for this doctor must be paid now. Anything extra will be charged after the appointment.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                   const SizedBox(height: 16),
                ],
                if (isFollowUp)
                  const SizedBox(height: 24),
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

