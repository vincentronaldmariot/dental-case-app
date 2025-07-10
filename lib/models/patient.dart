class Patient {
  final int? id;
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert Patient to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'passwordHash': passwordHash,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'address': address,
      'emergencyContact': emergencyContact,
      'emergencyPhone': emergencyPhone,
      'medicalHistory': medicalHistory,
      'allergies': allergies,
      'serialNumber': serialNumber,
      'unitAssignment': unitAssignment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Patient from Map (database retrieval)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      passwordHash: map['passwordHash'],
      dateOfBirth: DateTime.parse(map['dateOfBirth']),
      address: map['address'],
      emergencyContact: map['emergencyContact'],
      emergencyPhone: map['emergencyPhone'],
      medicalHistory: map['medicalHistory'] ?? '',
      allergies: map['allergies'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      unitAssignment: map['unitAssignment'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Get full name
  String get fullName => '$firstName $lastName';

  // Copy with updated fields
  Patient copyWith({
    int? id,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Patient{id: $id, name: $fullName, email: $email, phone: $phone, serial: $serialNumber, unit: $unitAssignment}';
  }
}
