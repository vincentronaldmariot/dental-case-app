class TreatmentRecord {
  final String id;
  final String patientId;
  final String appointmentId;
  final String treatmentType;
  final String description;
  final DateTime treatmentDate;
  final List<String> procedures;
  final String? notes;
  final String? prescription;
  final DateTime createdAt;
  final DateTime updatedAt;

  TreatmentRecord({
    required this.id,
    required this.patientId,
    required this.appointmentId,
    required this.treatmentType,
    required this.description,
    required this.treatmentDate,
    required this.procedures,
    this.notes,
    this.prescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'appointment_id': appointmentId,
      'treatment_type': treatmentType,
      'description': description,
      'treatment_date': treatmentDate.toIso8601String(),
      'procedures': procedures,
      'notes': notes,
      'prescription': prescription,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory TreatmentRecord.fromMap(Map<String, dynamic> map) {
    return TreatmentRecord(
      id: map['id'],
      patientId: map['patient_id'].toString(),
      appointmentId: map['appointment_id'],
      treatmentType: map['treatment_type'],
      description: map['description'],
      treatmentDate: DateTime.parse(map['treatment_date']),
      procedures: List<String>.from(map['procedures'] ?? []),
      notes: map['notes'],
      prescription: map['prescription'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Copy with updated fields
  TreatmentRecord copyWith({
    String? id,
    String? patientId,
    String? appointmentId,
    String? treatmentType,
    String? description,
    DateTime? treatmentDate,
    List<String>? procedures,
    String? notes,
    String? prescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TreatmentRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      appointmentId: appointmentId ?? this.appointmentId,
      treatmentType: treatmentType ?? this.treatmentType,
      description: description ?? this.description,
      treatmentDate: treatmentDate ?? this.treatmentDate,
      procedures: procedures ?? this.procedures,
      notes: notes ?? this.notes,
      prescription: prescription ?? this.prescription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TreatmentRecord{id: $id, treatmentType: $treatmentType, date: $treatmentDate}';
  }
}

enum TreatmentType {
  generalCheckup,
  teethCleaning,
  orthodontics,
  cosmeticDentistry,
  rootCanal,
  toothExtraction,
  dentalImplants,
  teethWhitening,
  emergency,
  consultation,
}

extension TreatmentTypeExtension on TreatmentType {
  String get displayName {
    switch (this) {
      case TreatmentType.generalCheckup:
        return 'General Checkup';
      case TreatmentType.teethCleaning:
        return 'Teeth Cleaning';
      case TreatmentType.orthodontics:
        return 'Orthodontics';
      case TreatmentType.cosmeticDentistry:
        return 'Cosmetic Dentistry';
      case TreatmentType.rootCanal:
        return 'Root Canal';
      case TreatmentType.toothExtraction:
        return 'Tooth Extraction';
      case TreatmentType.dentalImplants:
        return 'Dental Implants';
      case TreatmentType.teethWhitening:
        return 'Teeth Whitening';
      case TreatmentType.emergency:
        return 'Emergency Treatment';
      case TreatmentType.consultation:
        return 'Consultation';
    }
  }
}
