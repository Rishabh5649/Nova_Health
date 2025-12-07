import 'dart:async';
import '../models/appointment.dart';

class AppointmentApi {
  // In Sprint 1 this is a placeholder using in-memory mock data.
  // Replace with real HTTP calls in later sprints.

  Future<List<Appointment>> getAppointments({
    String? patientId,
    String? doctorId,
    AppointmentStatus? status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    var all = _mockAppointments;

    if (patientId != null) {
      all = all.where((a) => a.patientId == patientId).toList(growable: false);
    }

    if (doctorId != null) {
      all = all.where((a) => a.doctorId == doctorId).toList(growable: false);
    }

    if (status == null) return all;
    return all.where((a) => a.status == status).toList(growable: false);
  }

  Future<Appointment> postAppointment({
    required String patientId,
    required String doctorId,
    required DateTime start,
    required DateTime end,
    String? reason,
    double fee = 0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final appt = Appointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: patientId,
      doctorId: doctorId,
      start: start,
      end: end,
      status: AppointmentStatus.pending,
      reason: reason,
      fee: fee,
      paymentStatus: PaymentStatus.unpaid,
    );

    _mockAppointments.add(appt);
    return appt;
  }

  Future<Appointment> updateStatus(String appointmentId, AppointmentStatus status) async {
    return updateAppointment(appointmentId, status: status);
  }

  Future<Appointment> updateAppointment(String id, {AppointmentStatus? status, DateTime? start, DateTime? end}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final index = _mockAppointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      final old = _mockAppointments[index];
      final updated = Appointment(
        id: old.id,
        patientId: old.patientId,
        doctorId: old.doctorId,
        start: start ?? old.start,
        end: end ?? old.end,
        status: status ?? old.status,
        reason: old.reason,
        fee: old.fee,
        paymentStatus: old.paymentStatus,
      );
      _mockAppointments[index] = updated;
      return updated;
    }
    throw Exception('Appointment not found');
  }

  Future<void> createPrescription(String appointmentId, Map<String, dynamic> data) async {
     await Future<void>.delayed(const Duration(milliseconds: 400));
     // Mock implementation
  }
}

final List<Appointment> _mockAppointments = <Appointment>[
  Appointment(
    id: 'a1',
    patientId: 'p1',
    doctorId: 'd1',
    start: DateTime.now().add(const Duration(hours: 3)),
    end: DateTime.now().add(const Duration(hours: 4)),
    status: AppointmentStatus.confirmed,
    reason: 'General check-up',
    fee: 500,
    paymentStatus: PaymentStatus.paid,
  ),
  Appointment(
    id: 'a2',
    patientId: 'p1',
    doctorId: 'd1', // Changed to d1 to match default doctor
    start: DateTime.now().add(const Duration(days: 1, hours: 2)),
    end: DateTime.now().add(const Duration(days: 1, hours: 3)),
    status: AppointmentStatus.pendingRequest, // Changed to pendingRequest
    reason: 'Follow-up',
    fee: 700,
    paymentStatus: PaymentStatus.unpaid,
  ),
];
