import '../models/appointment.dart';
import '../models/treatment_record.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  // Sample data cleared - will be populated when users book appointments
  final List<Appointment> _appointments = [];

  final List<TreatmentRecord> _treatmentRecords = [
    TreatmentRecord(
      id: 'tr_1',
      patientId: '1',
      appointmentId: '1',
      treatmentType: 'General Checkup',
      description: 'Comprehensive oral examination and assessment',
      doctorName: 'Dr. Smith',
      treatmentDate: DateTime.now().subtract(const Duration(days: 30)),
      procedures: [
        'Visual examination',
        'X-ray imaging',
        'Gum health assessment',
      ],
      notes: 'Overall dental health is good. Minor plaque buildup noted.',
      prescription: 'Fluoride toothpaste, regular flossing recommended',
    ),
    TreatmentRecord(
      id: 'tr_2',
      patientId: '1',
      appointmentId: '2',
      treatmentType: 'Teeth Cleaning',
      description: 'Professional dental cleaning and tartar removal',
      doctorName: 'Dr. Johnson',
      treatmentDate: DateTime.now().subtract(const Duration(days: 60)),
      procedures: ['Scaling', 'Polishing', 'Fluoride treatment'],
      notes:
          'Significant tartar buildup removed. Patient advised on proper brushing technique.',
      prescription: 'Antibacterial mouthwash for 2 weeks',
    ),
    TreatmentRecord(
      id: 'tr_3',
      patientId: '1',
      appointmentId: '3',
      treatmentType: 'Root Canal',
      description: 'Root canal therapy on posterior molar',
      doctorName: 'Dr. Davis',
      treatmentDate: DateTime.now().subtract(const Duration(days: 90)),
      procedures: [
        'Local anesthesia',
        'Pulp removal',
        'Canal cleaning',
        'Temporary filling',
      ],
      notes:
          'Root canal treatment completed successfully. Crown placement scheduled.',
      prescription:
          'Antibiotics (Amoxicillin 500mg) for 7 days, pain medication as needed',
    ),
    TreatmentRecord(
      id: 'tr_4',
      patientId: '1',
      appointmentId: '1',
      treatmentType: 'Preventive Care',
      description: 'Dental sealant application',
      doctorName: 'Dr. Smith',
      treatmentDate: DateTime.now().subtract(const Duration(days: 30)),
      procedures: ['Tooth preparation', 'Sealant application', 'Curing'],
      notes: 'Sealants applied to molars for cavity prevention.',
    ),
  ];

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
