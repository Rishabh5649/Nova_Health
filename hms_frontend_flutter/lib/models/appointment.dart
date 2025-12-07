enum AppointmentStatus { pending, pendingRequest, confirmed, completed, cancelled }

enum PaymentStatus { unpaid, paid, refunded }

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime start;
  final DateTime end;
  final AppointmentStatus status;
  final String? reason;
  final double fee;
  final PaymentStatus paymentStatus;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.start,
    required this.end,
    required this.status,
    this.reason,
    required this.fee,
    required this.paymentStatus,
    this.hasReview = false,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Parse status from backend (PENDING, CONFIRMED, etc.)
    AppointmentStatus parseStatus(String? statusStr) {
      switch (statusStr?.toUpperCase()) {
        case 'PENDING':
          return AppointmentStatus.pending;
        case 'PENDING_REQUEST':
          return AppointmentStatus.pendingRequest;
        case 'CONFIRMED':
          return AppointmentStatus.confirmed;
        case 'COMPLETED':
          return AppointmentStatus.completed;
        case 'CANCELLED':
          return AppointmentStatus.cancelled;
        default:
          return AppointmentStatus.pending;
      }
    }

    // Backend uses scheduledAt, we use start/end
    final scheduledAt = json['scheduledAt'] != null 
        ? DateTime.parse(json['scheduledAt'] as String)
        : DateTime.now();
    
    // For MVP, assume 1 hour appointments
    final endTime = scheduledAt.add(const Duration(hours: 1));

    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      start: scheduledAt,
      end: endTime,
      status: parseStatus(json['status']?.toString()),
      reason: json['reason']?.toString(),
      fee: (json['fee'] ?? 0).toDouble(),
      paymentStatus: PaymentStatus.unpaid,
      hasReview: json['review'] != null,
    );
  }

  final bool hasReview;

  Map<String, dynamic> toJson() {
    String statusToString(AppointmentStatus status) {
      switch (status) {
        case AppointmentStatus.pending:
          return 'PENDING';
        case AppointmentStatus.pendingRequest:
          return 'PENDING_REQUEST';
        case AppointmentStatus.confirmed:
          return 'CONFIRMED';
        case AppointmentStatus.completed:
          return 'COMPLETED';
        case AppointmentStatus.cancelled:
          return 'CANCELLED';
      }
    }

    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'scheduledAt': start.toIso8601String(),
      'status': statusToString(status),
      'reason': reason,
      'fee': fee,
    };
  }
}
