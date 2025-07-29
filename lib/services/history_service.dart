import '../models/appointment.dart';
import '../models/treatment_record.dart';
import '../user_state_manager.dart'; // Fixed import path

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
      final patientAppointments =
          _appointments.where((apt) => apt.patientId == patientId).toList();
      return patientAppointments;
    }
    return List.from(_appointments);
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(AppointmentStatus status,
      {String? patientId}) {
    final appointments = getAppointments(patientId: patientId);
    final filteredAppointments =
        appointments.where((apt) => apt.status == status).toList();

    return filteredAppointments;
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
    // Check if appointment with same ID already exists
    final existingIndex =
        _appointments.indexWhere((apt) => apt.id == appointment.id);
    if (existingIndex != -1) {
      _appointments[existingIndex] = appointment;
    } else {
      _appointments.add(appointment);
    }
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

  Future<void> loadAppointmentsFromBackend(List<dynamic> backendAppointments,
      {String? patientId}) async {
    try {
      final targetPatientId = patientId ?? UserStateManager().currentPatientId;

      // Clear existing appointments for this patient
      _appointments.removeWhere((apt) => apt.patientId == targetPatientId);

      // Convert backend data to Appointment objects
      for (final aptData in backendAppointments) {
        try {
          final appointment = Appointment(
            id: aptData['id']?.toString() ?? '',
            patientId: aptData['patient_id']?.toString() ?? targetPatientId,
            service: aptData['service']?.toString() ?? '',
            date: DateTime.parse(aptData['date']),
            timeSlot: aptData['time_slot']?.toString() ?? '',
            status: _parseStatus(aptData['status']),
            notes: aptData['notes']?.toString() ?? '',
          );
          _appointments.add(appointment);
        } catch (e) {
          // Skip invalid appointment data
          continue;
        }
      }
    } catch (e) {
      // Handle any errors during loading
    }
  }

  // Clear appointments for a specific patient
  void clearAppointmentsForPatient(String patientId) {
    final beforeCount = _appointments.length;
    _appointments.removeWhere((apt) => apt.patientId == patientId);
    final afterCount = _appointments.length;
  }

  // Clear all appointments (for debugging)
  void clearAllAppointments() {
    final count = _appointments.length;
    _appointments.clear();
  }

  // Clear all data (appointments and treatment records)
  void clearAllData() {
    final appointmentCount = _appointments.length;
    final treatmentCount = _treatmentRecords.length;
    _appointments.clear();
    _treatmentRecords.clear();
  }

  // Clear all pending appointments (for debugging the pending tab issue)
  void clearAllPendingAppointments() {
    final beforeCount = _appointments.length;
    final pendingCount = _appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .length;
    _appointments.removeWhere((apt) => apt.status == AppointmentStatus.pending);
    final afterCount = _appointments.length;
  }

  // Parse status string to AppointmentStatus enum
  AppointmentStatus _parseStatus(String status) {
    final lowerStatus = status.toLowerCase();
    switch (lowerStatus) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'approved':
        return AppointmentStatus.scheduled; // Map 'approved' to 'scheduled'
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'missed':
        return AppointmentStatus.missed;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      default:
        return AppointmentStatus
            .scheduled; // Default to scheduled instead of pending
    }
  }

  // Debug method to show all appointments
  void debugShowAllAppointments() {
    print(
        '🔍 DEBUG: All appointments in HistoryService (${_appointments.length} total)');
    for (int i = 0; i < _appointments.length; i++) {
      final apt = _appointments[i];
      print(
          '   $i: ID=${apt.id}, PatientID=${apt.patientId}, Service=${apt.service}, Status=${apt.status}');
    }
  }
}
