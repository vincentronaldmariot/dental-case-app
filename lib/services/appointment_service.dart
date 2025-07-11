import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import 'patient_limit_service.dart';

class AppointmentBookingResult {
  final bool success;
  final String message;
  final String? appointmentId;

  AppointmentBookingResult({
    required this.success,
    required this.message,
    this.appointmentId,
  });
}

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final PatientLimitService _patientLimitService = PatientLimitService();
  final List<Appointment> _appointments = [];
  final List<Patient> _patients = [];

  // Available time slots
  final List<String> timeSlots = [
    '08:00 AM',
    '08:30 AM',
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
  ];

  // Initialize with sample data
  void initializeSampleData() {
    _patientLimitService.initializeSampleData();

    // Create sample patients
    _patients.addAll([
      Patient(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@email.com',
        phone: '+1234567890',
        passwordHash: 'hashed_password',
        dateOfBirth: DateTime(1990, 5, 15),
        address: '123 Main St, City',
        emergencyContact: 'Jane Doe',
        emergencyPhone: '+1234567891',
        medicalHistory: 'No major issues',
        allergies: 'None',
        serialNumber: 'PTN-001',
        unitAssignment: 'Military - Army Base',
      ),
      Patient(
        id: 2,
        firstName: 'Sarah',
        lastName: 'Smith',
        email: 'sarah.smith@email.com',
        phone: '+1234567892',
        passwordHash: 'hashed_password',
        dateOfBirth: DateTime(1985, 8, 22),
        address: '456 Oak Ave, City',
        emergencyContact: 'Mike Smith',
        emergencyPhone: '+1234567893',
        medicalHistory: 'Diabetes',
        allergies: 'Penicillin',
        serialNumber: 'PTN-002',
        unitAssignment: 'AV/HR Department',
      ),
      Patient(
        id: 3,
        firstName: 'Michael',
        lastName: 'Johnson',
        email: 'michael.johnson@email.com',
        phone: '+1234567894',
        passwordHash: 'hashed_password',
        dateOfBirth: DateTime(1978, 12, 10),
        address: '789 Pine St, City',
        emergencyContact: 'Lisa Johnson',
        emergencyPhone: '+1234567895',
        medicalHistory: 'Hypertension',
        allergies: 'Latex',
        serialNumber: 'PTN-003',
        unitAssignment: 'Military - Navy Fleet',
      ),
    ]);

    // Create sample appointments for today to match the 78 count
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    // Clear existing appointments for today
    _appointments.removeWhere((apt) => _formatDate(apt.date) == todayStr);

    // Create additional patients for appointments
    final patientNames = [
      'Emily Davis',
      'James Wilson',
      'Ashley Brown',
      'Daniel Miller',
      'Jessica Garcia',
      'Ryan Martinez',
      'Amanda Rodriguez',
      'Christopher Lee',
      'Stephanie Walker',
      'Matthew Hall',
      'Nicole Allen',
      'Andrew Young',
      'Lauren King',
      'Kevin Wright',
      'Megan Lopez',
      'Brandon Scott',
      'Hannah Green',
      'Justin Adams',
      'Kayla Baker',
      'Aaron Nelson',
      'Brittany Carter',
      'Tyler Mitchell',
      'Rachel Perez',
      'Sean Roberts',
      'Alexis Turner',
      'Jordan Phillips',
      'Samantha Campbell',
      'Zachary Parker',
      'Danielle Evans',
      'Nathan Edwards',
      'Kelsey Collins',
      'Ian Stewart',
      'Jasmine Sanchez',
      'Chase Morris',
      'Courtney Rogers',
      'Devin Reed',
      'Sierra Cook',
      'Mason Bailey',
    ];

    final units = [
      'Military - Army Base',
      'Military - Navy Fleet',
      'Military - Air Force',
      'AV/HR Department',
      'Corporate Office',
      'Emergency Services',
      'Pediatric Ward',
      'Geriatric Care',
      'Special Operations',
      'Administrative Staff',
    ];

    // Add more patients for variety
    for (int i = 0; i < patientNames.length; i++) {
      final nameParts = patientNames[i].split(' ');
      _patients.add(
        Patient(
          id: i + 4,
          firstName: nameParts[0],
          lastName: nameParts[1],
          email:
              '${nameParts[0].toLowerCase()}.${nameParts[1].toLowerCase()}@email.com',
          phone: '+123456${(7900 + i).toString()}',
          passwordHash: 'hashed_password',
          dateOfBirth: DateTime(1980 + (i % 20), 1 + (i % 12), 1 + (i % 28)),
          address: '${100 + i} Street ${i % 10}, City',
          emergencyContact: 'Emergency Contact ${i + 1}',
          emergencyPhone: '+123456${(8900 + i).toString()}',
          medicalHistory: i % 3 == 0
              ? 'No issues'
              : (i % 3 == 1 ? 'Allergies' : 'Minor conditions'),
          allergies: i % 4 == 0
              ? 'None'
              : (i % 4 == 1 ? 'Penicillin' : (i % 4 == 2 ? 'Latex' : 'Dust')),
          serialNumber: 'PTN-${(i + 4).toString().padLeft(3, '0')}',
          unitAssignment: units[i % units.length],
        ),
      );
    }

    // Create appointments for multiple dates to demonstrate date filtering
    final appointmentCounts = [
      78,
      45,
      32,
      56,
      28,
      67,
      41,
      35,
      52,
      29,
    ]; // Different counts for 10 days

    for (int dayOffset = 0; dayOffset < 10; dayOffset++) {
      final appointmentDate = today.add(Duration(days: dayOffset));
      final appointmentCount = appointmentCounts[dayOffset];
      final dateStr = _formatDate(appointmentDate);

      // Clear existing appointments for this date
      _appointments.removeWhere((apt) => _formatDate(apt.date) == dateStr);

      // Create appointments for this date
      for (int i = 0; i < appointmentCount; i++) {
        final patient = _patients[i % _patients.length];
        _appointments.add(
          Appointment(
            id: 'apt_day${dayOffset}_$i',
            patientId: patient.id.toString(),
            service: _getRandomService(i),
            date: appointmentDate,
            timeSlot: timeSlots[i % timeSlots.length],
            doctorName: 'Dr. ${_getRandomDoctor(i)}',
            status: AppointmentStatus.scheduled,
            notes: dayOffset == 0
                ? 'Today\'s appointment'
                : (dayOffset == 1
                      ? 'Tomorrow\'s appointment'
                      : 'Scheduled appointment'),
          ),
        );
      }
    }
  }

  String _getRandomService(int index) {
    final services = [
      'General Checkup',
      'Teeth Cleaning',
      'Orthodontics',
      'Root Canal',
      'Tooth Extraction',
      'Dental Implants',
    ];
    return services[index % services.length];
  }

  String _getRandomDoctor(int index) {
    final doctors = ['Smith', 'Johnson', 'Williams', 'Brown', 'Davis'];
    return doctors[index % doctors.length];
  }

  // Book a new appointment
  Future<AppointmentBookingResult> bookAppointment({
    required String service,
    required DateTime date,
    required String patientName,
    required String patientEmail,
    required String patientPhone,
  }) async {
    try {
      // Check if the date has available slots
      if (!_patientLimitService.canAddPatient(date)) {
        final dailyLimit = _patientLimitService.getDailyLimit(date);
        return AppointmentBookingResult(
          success: false,
          message:
              'Sorry, we have reached the daily limit of 100 patients for ${_formatDisplayDate(date)}. Currently ${dailyLimit.currentCount}/100 slots are booked.',
          appointmentId: null,
        );
      }

      // Create or find patient
      Patient? patient = _patients.firstWhere(
        (p) => p.email == patientEmail,
        orElse: () => Patient(
          id: _patients.length + 1,
          firstName: patientName.split(' ').first,
          lastName: patientName.split(' ').length > 1
              ? patientName.split(' ').sublist(1).join(' ')
              : '',
          email: patientEmail,
          phone: patientPhone,
          passwordHash: 'temp_hash',
          dateOfBirth: DateTime(1990, 1, 1), // Default
          address: 'Not provided',
          emergencyContact: 'Not provided',
          emergencyPhone: 'Not provided',
          serialNumber:
              'PTN-${(_patients.length + 1).toString().padLeft(3, '0')}',
          unitAssignment: [
            'Military - Army Base',
            'Military - Navy Fleet',
            'Military - Air Force',
            'AV/HR Department',
            'Corporate Office',
            'Emergency Services',
            'Pediatric Ward',
            'Geriatric Care',
            'Special Operations',
            'Administrative Staff',
          ][_patients.length % 10],
        ),
      );

      // Add patient if new
      if (!_patients.any((p) => p.email == patientEmail)) {
        _patients.add(patient);
      }

      // Create appointment
      final appointmentId = 'apt_${DateTime.now().millisecondsSinceEpoch}';
      final appointment = Appointment(
        id: appointmentId,
        patientId: patient.id.toString(),
        service: service,
        date: date,
        timeSlot: _getAvailableTimeSlot(date),
        doctorName: 'Dr. ${_getRandomDoctor(DateTime.now().millisecond)}',
        status: AppointmentStatus.scheduled,
        notes: 'Booked via app',
      );

      _appointments.add(appointment);

      // Update patient limit
      _patientLimitService.addPatient(date);

      return AppointmentBookingResult(
        success: true,
        message:
            'Appointment booked successfully for ${_formatDisplayDate(date)}',
        appointmentId: appointmentId,
      );
    } catch (e) {
      return AppointmentBookingResult(
        success: false,
        message: 'Failed to book appointment: ${e.toString()}',
        appointmentId: null,
      );
    }
  }

  // Get available time slot for a date
  String _getAvailableTimeSlot(DateTime date) {
    final existingSlots = _appointments
        .where((apt) => _formatDate(apt.date) == _formatDate(date))
        .map((apt) => apt.timeSlot)
        .toSet();

    for (final slot in timeSlots) {
      if (!existingSlots.contains(slot)) {
        return slot;
      }
    }

    // If all slots are taken, return a random one (overbooking)
    return timeSlots[DateTime.now().millisecond % timeSlots.length];
  }

  // Get appointments for a specific date
  List<Appointment> getAppointmentsForDate(DateTime date) {
    final dateStr = _formatDate(date);
    return _appointments
        .where((apt) => _formatDate(apt.date) == dateStr)
        .toList()
      ..sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
  }

  // Get appointment count for a specific date
  int getAppointmentCountForDate(DateTime date) {
    return getAppointmentsForDate(date).length;
  }

  // Get patient by ID
  Patient? getPatientById(String patientId) {
    try {
      return _patients.firstWhere((p) => p.id.toString() == patientId);
    } catch (e) {
      return null;
    }
  }

  // Get appointment statistics
  Map<String, dynamic> getAppointmentStatistics() {
    final today = DateTime.now();
    final todayAppointments = getAppointmentCountForDate(today);
    final tomorrowAppointments = getAppointmentCountForDate(
      today.add(const Duration(days: 1)),
    );

    final totalScheduled = _appointments
        .where((apt) => apt.status == AppointmentStatus.scheduled)
        .length;

    final totalCompleted = _appointments
        .where((apt) => apt.status == AppointmentStatus.completed)
        .length;

    return {
      'todayAppointments': todayAppointments,
      'tomorrowAppointments': tomorrowAppointments,
      'totalPatients': _patients.length,
      'totalScheduled': totalScheduled,
      'totalCompleted': totalCompleted,
    };
  }

  // Helper methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Get all appointments
  List<Appointment> getAllAppointments() {
    return List.unmodifiable(_appointments);
  }

  // Get all patients
  List<Patient> getAllPatients() {
    return List.unmodifiable(_patients);
  }

  // Remove/Cancel an appointment
  bool removeAppointment(String appointmentId) {
    try {
      final appointmentIndex = _appointments.indexWhere(
        (apt) => apt.id == appointmentId,
      );

      if (appointmentIndex == -1) {
        return false; // Appointment not found
      }

      final appointment = _appointments[appointmentIndex];

      // Remove from appointments list
      _appointments.removeAt(appointmentIndex);

      // Update patient limit (decrease count)
      _patientLimitService.removePatient(appointment.date);

      return true; // Successfully removed
    } catch (e) {
      return false; // Error occurred
    }
  }

  // Get appointment by ID
  Appointment? getAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((apt) => apt.id == appointmentId);
    } catch (e) {
      return null;
    }
  }
}
