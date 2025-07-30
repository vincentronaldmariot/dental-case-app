class Appointment {
  final String id;
  final String patientId;
  final String service;
  final DateTime date;
  final String timeSlot;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.service,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'service': service,
      'date': date.toIso8601String(),
      'time_slot': timeSlot,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id']?.toString() ?? '',
      patientId: map['patient_id']?.toString() ?? '',
      service: map['service']?.toString() ?? '',
      date: _parseDateSafely(map['date']),
      timeSlot: map['time_slot']?.toString() ?? '',
      status: map['status'] != null
          ? _parseStatusFromString(map['status'].toString())
          : AppointmentStatus.scheduled,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Helper method to parse date safely without timezone issues
  static DateTime _parseDateSafely(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();

    final dateString = dateValue.toString();

    // Handle ISO date strings with timezone (e.g., "2025-01-15T00:00:00.000Z")
    if (dateString.contains('T')) {
      final datePart = dateString.split('T')[0];
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    }

    // Handle regular date strings (e.g., "2025-01-15")
    if (dateString.contains('-')) {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    }

    // Fallback to DateTime.tryParse
    return DateTime.tryParse(dateString) ?? DateTime.now();
  }

  // Helper method to parse status string to AppointmentStatus enum
  static AppointmentStatus _parseStatusFromString(String status) {
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
      case 'done':
        return AppointmentStatus.completed; // Map 'done' to 'completed'
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

  // Copy with updated fields
  Appointment copyWith({
    String? id,
    String? patientId,
    String? service,
    DateTime? date,
    String? timeSlot,
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

enum AppointmentStatus {
  pending,
  scheduled,
  completed,
  cancelled,
  missed,
  rescheduled,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending Review';
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
      case AppointmentStatus.pending:
        return '#FF9800';
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
