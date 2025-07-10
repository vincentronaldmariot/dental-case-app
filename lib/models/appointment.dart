class Appointment {
  final String id;
  final String patientId;
  final String service;
  final DateTime date;
  final String timeSlot;
  final String doctorName;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.service,
    required this.date,
    required this.timeSlot,
    required this.doctorName,
    required this.status,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'service': service,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'doctorName': doctorName,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'],
      service: map['service'],
      date: DateTime.parse(map['date']),
      timeSlot: map['timeSlot'],
      doctorName: map['doctorName'],
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Copy with updated fields
  Appointment copyWith({
    String? id,
    String? patientId,
    String? service,
    DateTime? date,
    String? timeSlot,
    String? doctorName,
    AppointmentStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      service: service ?? this.service,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      doctorName: doctorName ?? this.doctorName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Appointment{id: $id, service: $service, date: $date, status: $status}';
  }
}

enum AppointmentStatus { scheduled, completed, cancelled, missed, rescheduled }

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.missed:
        return 'Missed';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  String get color {
    switch (this) {
      case AppointmentStatus.scheduled:
        return '#0029B2';
      case AppointmentStatus.completed:
        return '#005800';
      case AppointmentStatus.cancelled:
        return '#E74C3C';
      case AppointmentStatus.missed:
        return '#FF6B35';
      case AppointmentStatus.rescheduled:
        return '#7B1FA2';
    }
  }
}
