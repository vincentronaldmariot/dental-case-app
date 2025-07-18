class Patient {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String passwordHash;
  final DateTime dateOfBirth;
  final String address;
  final String emergencyContact;
  final String emergencyPhone;
  final String medicalHistory;
  final String allergies;
  final String serialNumber;
  final String unitAssignment;
  final String classification;
  final String otherClassification;
  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.dateOfBirth,
    required this.address,
    required this.emergencyContact,
    required this.emergencyPhone,
    this.medicalHistory = '',
    this.allergies = '',
    this.serialNumber = '',
    this.unitAssignment = '',
    this.classification = '',
    this.otherClassification = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert Patient to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'password_hash': passwordHash,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'address': address,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'medical_history': medicalHistory,
      'allergies': allergies,
      'serial_number': serialNumber,
      'unit_assignment': unitAssignment,
      'classification': classification,
      'other_classification': otherClassification,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create Patient from Map (database retrieval)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      firstName: map['firstName'] ?? map['first_name'] ?? '',
      lastName: map['lastName'] ?? map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      passwordHash: map['passwordHash'] ?? map['password_hash'] ?? '',
      dateOfBirth: DateTime.parse(map['dateOfBirth'] ?? map['date_of_birth']),
      address: map['address'] ?? '',
      emergencyContact:
          map['emergencyContact'] ?? map['emergency_contact'] ?? '',
      emergencyPhone: map['emergencyPhone'] ?? map['emergency_phone'] ?? '',
      medicalHistory: map['medicalHistory'] ?? map['medical_history'] ?? '',
      allergies: map['allergies'] ?? '',
      serialNumber: map['serialNumber'] ?? map['serial_number'] ?? '',
      unitAssignment: map['unitAssignment'] ?? map['unit_assignment'] ?? '',
      classification: map['classification'] ?? '',
      otherClassification:
          map['otherClassification'] ?? map['other_classification'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ??
          map['created_at'] ??
          DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ??
          map['updated_at'] ??
          DateTime.now().toIso8601String()),
    );
  }

  // Get full name
  String get fullName => '$firstName $lastName';

  // Copy with updated fields
  Patient copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? passwordHash,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    String? medicalHistory,
    String? allergies,
    String? serialNumber,
    String? unitAssignment,
    String? classification,
    String? otherClassification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      allergies: allergies ?? this.allergies,
      serialNumber: serialNumber ?? this.serialNumber,
      unitAssignment: unitAssignment ?? this.unitAssignment,
      classification: classification ?? this.classification,
      otherClassification: otherClassification ?? this.otherClassification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Patient{id: $id, name: $fullName, email: $email, phone: $phone, serial: $serialNumber, unit: $unitAssignment}';
  }
}
