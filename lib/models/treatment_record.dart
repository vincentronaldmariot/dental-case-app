class TreatmentRecord {
  final String id;
  final String patientId;
  final String appointmentId;
  final String treatmentType;
  final String description;
  final String doctorName;
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
    required this.doctorName,
    required this.treatmentDate,
    required this.procedures,
    this.notes,
    this.prescription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'appointmentId': appointmentId,
      'treatmentType': treatmentType,
      'description': description,
      'doctorName': doctorName,
      'treatmentDate': treatmentDate.toIso8601String(),
      'procedures': procedures,
      'notes': notes,
      'prescription': prescription,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory TreatmentRecord.fromMap(Map<String, dynamic> map) {
    return TreatmentRecord(
      id: map['id'],
      patientId: map['patientId'],
      appointmentId: map['appointmentId'],
      treatmentType: map['treatmentType'],
      description: map['description'],
      doctorName: map['doctorName'],
      treatmentDate: DateTime.parse(map['treatmentDate']),
      procedures: List<String>.from(map['procedures'] ?? []),
      notes: map['notes'],
      prescription: map['prescription'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Copy with updated fields
  TreatmentRecord copyWith({
    String? id,
    String? patientId,
    String? appointmentId,
    String? treatmentType,
    String? description,
    String? doctorName,
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
      doctorName: doctorName ?? this.doctorName,
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
