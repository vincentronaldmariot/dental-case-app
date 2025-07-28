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
      final patientAppointments =
          _appointments.where((apt) => apt.patientId == patientId).toList();
      print(
          '🔍 getAppointments called for patient $patientId: ${patientAppointments.length} appointments');
      return patientAppointments;
    }
    print(
        '🔍 getAppointments called for all patients: ${_appointments.length} appointments');
    return List.from(_appointments);
  }

  // Get appointments by status
  List<Appointment> getAppointmentsByStatus(
    AppointmentStatus status, {
    String? patientId,
  }) {
    var appointments = getAppointments(patientId: patientId);
    final filteredAppointments =
        appointments.where((apt) => apt.status == status).toList();
    print('🔍 getAppointmentsByStatus called:');
    print('   Status: $status');
    print('   Patient ID: $patientId');
    print('   Total appointments for patient: ${appointments.length}');
    print('   Filtered appointments: ${filteredAppointments.length}');
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
      print(
          '⚠️ Appointment with ID ${appointment.id} already exists, updating instead of adding');
      _appointments[existingIndex] = appointment;
    } else {
      _appointments.add(appointment);
      print(
          '➕ Added new appointment: ${appointment.id} for patient ${appointment.patientId}');
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

  // Load appointments from backend data
  void loadAppointmentsFromBackend(
      List<Map<String, dynamic>> backendAppointments,
      {String? patientId}) {
    print('🔄 Loading appointments from backend...');
    print('📊 Total backend appointments: ${backendAppointments.length}');
    print('👤 Target patient ID: $patientId');
    print(
        '📈 Total appointments in HistoryService before loading: ${_appointments.length}');

    // Always clear existing appointments for this patient to ensure fresh data
    if (patientId != null) {
      final beforeCount = _appointments.length;
      final patientAppointmentsBefore =
          _appointments.where((apt) => apt.patientId == patientId).toList();
      print(
          '👤 Patient appointments before clearing: ${patientAppointmentsBefore.length}');
      for (final apt in patientAppointmentsBefore) {
        print('   - ${apt.id}: ${apt.service} (${apt.status})');
      }

      _appointments.removeWhere((apt) => apt.patientId == patientId);
      final afterCount = _appointments.length;
      print(
          '🗑️ Cleared ${beforeCount - afterCount} existing appointments for patient $patientId');
    } else {
      // If no patientId specified, clear all appointments to ensure fresh data
      final beforeCount = _appointments.length;
      _appointments.clear();
      print(
          '🗑️ Cleared all $beforeCount appointments (no patientId specified)');
    }

    // Convert backend data to Appointment objects and add them
    for (final aptData in backendAppointments) {
      try {
        final appointment = Appointment(
          id: aptData['id'] ?? '',
          patientId: aptData['patient_id'] ?? aptData['patientId'] ?? '',
          service: aptData['service'] ?? '',
          date: DateTime.parse(aptData['appointment_date'] ??
              aptData['appointmentDate'] ??
              DateTime.now().toIso8601String()),
          timeSlot: aptData['time_slot'] ?? aptData['timeSlot'] ?? '',
          status: _parseStatus(aptData['status'] ?? 'pending'),
          notes: aptData['notes'],
        );
        addAppointment(appointment);
        print(
            '✅ Added appointment: ${appointment.id} for patient ${appointment.patientId} with status ${appointment.status}');
      } catch (e) {
        print('❌ Error converting backend appointment data: $e');
        print('Problematic data: $aptData');
      }
    }

    print(
        '📈 Total appointments in HistoryService after loading: ${_appointments.length}');
    if (patientId != null) {
      final patientAppointments =
          _appointments.where((apt) => apt.patientId == patientId).toList();
      print(
          '👤 Appointments for patient $patientId: ${patientAppointments.length}');
      final pendingAppointments = patientAppointments
          .where((apt) => apt.status == AppointmentStatus.pending)
          .toList();
      print(
          '⏳ Pending appointments for patient $patientId: ${pendingAppointments.length}');

      // Show all appointments for this patient
      for (final apt in patientAppointments) {
        print('   📋 ${apt.id}: ${apt.service} (${apt.status}) - ${apt.date}');
      }
    }
  }

  // Clear appointments for a specific patient
  void clearAppointmentsForPatient(String patientId) {
    final beforeCount = _appointments.length;
    _appointments.removeWhere((apt) => apt.patientId == patientId);
    final afterCount = _appointments.length;
    print(
        '🗑️ Cleared ${beforeCount - afterCount} appointments for patient $patientId');
  }

  // Clear all appointments (for debugging)
  void clearAllAppointments() {
    final count = _appointments.length;
    _appointments.clear();
    print('🗑️ Cleared all $count appointments from HistoryService');
  }

  // Clear all data (appointments and treatment records)
  void clearAllData() {
    final appointmentCount = _appointments.length;
    final treatmentCount = _treatmentRecords.length;
    _appointments.clear();
    _treatmentRecords.clear();
    print('🗑️ Cleared all data from HistoryService:');
    print('   - $appointmentCount appointments');
    print('   - $treatmentCount treatment records');
  }

  // Clear all pending appointments (for debugging the pending tab issue)
  void clearAllPendingAppointments() {
    final beforeCount = _appointments.length;
    final pendingCount = _appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .length;
    _appointments.removeWhere((apt) => apt.status == AppointmentStatus.pending);
    final afterCount = _appointments.length;
    print('🗑️ Cleared all pending appointments:');
    print('   - Removed $pendingCount pending appointments');
    print('   - Total appointments: $beforeCount → $afterCount');
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
        print(
            '⚠️ Unknown appointment status: "$status", defaulting to scheduled');
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
