import '../models/appointment.dart';
import '../models/treatment_record.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  // Sample data cleared - will be populated when users book appointments
  final List<Appointment> _appointments = [];

  final List<TreatmentRecord> _treatmentRecords = [];

  // Get all appointments for a patient
  List<Appointment> getAppointments({String? patientId}) {
    if (patientId != null) {
      return _appointments.where((apt) => apt.patientId == patientId).toList();
    }
    return List.from(_appointments);
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(
    AppointmentStatus status, {
    String? patientId,
  }) {
    var appointments = getAppointments(patientId: patientId);
    return appointments.where((apt) => apt.status == status).toList();
  }

  // Get upcoming appointments
  List<Appointment> getUpcomingAppointments({String? patientId}) {
    var appointments = getAppointments(patientId: patientId);
    return appointments
        .where(
          (apt) =>
              apt.date.isAfter(DateTime.now()) &&
              apt.status == AppointmentStatus.scheduled,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Get recent appointments (last 6 months)
  List<Appointment> getRecentAppointments({String? patientId}) {
    var appointments = getAppointments(patientId: patientId);
    var sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return appointments.where((apt) => apt.date.isAfter(sixMonthsAgo)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Get treatment records for a patient
  List<TreatmentRecord> getTreatmentRecords({String? patientId}) {
    if (patientId != null) {
      return _treatmentRecords.where((tr) => tr.patientId == patientId).toList()
        ..sort((a, b) => b.treatmentDate.compareTo(a.treatmentDate));
    }
    return List.from(_treatmentRecords)
      ..sort((a, b) => b.treatmentDate.compareTo(a.treatmentDate));
  }

  // Get treatment records by type
  List<TreatmentRecord> getTreatmentRecordsByType(
    String treatmentType, {
    String? patientId,
  }) {
    var records = getTreatmentRecords(patientId: patientId);
    return records.where((tr) => tr.treatmentType == treatmentType).toList();
  }

  // Get recent treatment records (last 12 months)
  List<TreatmentRecord> getRecentTreatmentRecords({String? patientId}) {
    var records = getTreatmentRecords(patientId: patientId);
    var twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365));
    return records
        .where((tr) => tr.treatmentDate.isAfter(twelveMonthsAgo))
        .toList();
  }

  // Add new appointment
  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
  }

  // Add new treatment record
  void addTreatmentRecord(TreatmentRecord record) {
    _treatmentRecords.add(record);
  }

  // Update appointment status
  void updateAppointmentStatus(String appointmentId, AppointmentStatus status) {
    final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: status);
    }
  }

  // Get last appointment
  Appointment? getLastAppointment({String? patientId}) {
    var appointments = getAppointments(patientId: patientId);
    var pastAppointments = appointments
        .where(
          (apt) =>
              apt.date.isBefore(DateTime.now()) &&
              apt.status == AppointmentStatus.completed,
        )
        .toList();

    if (pastAppointments.isEmpty) return null;
    pastAppointments.sort((a, b) => b.date.compareTo(a.date));
    return pastAppointments.first;
  }

  // Get next appointment
  Appointment? getNextAppointment({String? patientId}) {
    var upcoming = getUpcomingAppointments(patientId: patientId);
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
