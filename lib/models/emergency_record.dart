enum EmergencyType {
  severeToothache,
  knockedOutTooth,
  brokenTooth,
  dentalTrauma,
  abscess,
  excessiveBleeding,
  lostFilling,
  lostCrown,
  orthodonticEmergency,
  other,
}

enum EmergencyPriority {
  immediate, // Life-threatening, needs attention within minutes
  urgent, // Severe pain/damage, needs attention within 2-4 hours
  standard, // Moderate concern, can wait until next business day
}

enum EmergencyStatus { reported, triaged, inProgress, resolved, referred }

class EmergencyRecord {
  final String id;
  final String patientId;
  final DateTime reportedAt;
  final EmergencyType type;
  final EmergencyPriority priority;
  final EmergencyStatus status;
  final String description;
  final String? location; // Where the emergency occurred
  final String? firstAidProvided; // What first aid was given
  final String? handledBy; // Duty dentist or medical personnel
  final DateTime? resolvedAt;
  final String? resolution; // How it was resolved
  final String? followUpRequired;
  final int painLevel; // 1-10 scale
  final bool dutyRelated; // If emergency occurred during duty
  final String? unitCommand; // Military unit for reporting
  final List<String> symptoms;
  final String? emergencyContact;
  final String? notes;

  EmergencyRecord({
    required this.id,
    required this.patientId,
    required this.reportedAt,
    required this.type,
    required this.priority,
    required this.status,
    required this.description,
    required this.painLevel,
    required this.symptoms,
    this.location,
    this.firstAidProvided,
    this.handledBy,
    this.resolvedAt,
    this.resolution,
    this.followUpRequired,
    this.dutyRelated = false,
    this.unitCommand,
    this.emergencyContact,
    this.notes,
  });

  String get emergencyTypeDisplay {
    switch (type) {
      case EmergencyType.severeToothache:
        return 'Severe Toothache';
      case EmergencyType.knockedOutTooth:
        return 'Knocked-Out Tooth';
      case EmergencyType.brokenTooth:
        return 'Broken/Chipped Tooth';
      case EmergencyType.dentalTrauma:
        return 'Dental Trauma';
      case EmergencyType.abscess:
        return 'Dental Abscess';
      case EmergencyType.excessiveBleeding:
        return 'Excessive Bleeding';
      case EmergencyType.lostFilling:
        return 'Lost Filling';
      case EmergencyType.lostCrown:
        return 'Lost Crown';
      case EmergencyType.orthodonticEmergency:
        return 'Orthodontic Emergency';
      case EmergencyType.other:
        return 'Other Emergency';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case EmergencyPriority.immediate:
        return 'IMMEDIATE';
      case EmergencyPriority.urgent:
        return 'URGENT';
      case EmergencyPriority.standard:
        return 'STANDARD';
    }
  }

  String get statusDisplay {
    switch (status) {
      case EmergencyStatus.reported:
        return 'Reported';
      case EmergencyStatus.triaged:
        return 'Triaged';
      case EmergencyStatus.inProgress:
        return 'In Progress';
      case EmergencyStatus.resolved:
        return 'Resolved';
      case EmergencyStatus.referred:
        return 'Referred';
    }
  }

  EmergencyRecord copyWith({
    String? id,
    String? patientId,
    DateTime? reportedAt,
    EmergencyType? type,
    EmergencyPriority? priority,
    EmergencyStatus? status,
    String? description,
    String? location,
    String? firstAidProvided,
    String? handledBy,
    DateTime? resolvedAt,
    String? resolution,
    String? followUpRequired,
    int? painLevel,
    bool? dutyRelated,
    String? unitCommand,
    List<String>? symptoms,
    String? emergencyContact,
    String? notes,
  }) {
    return EmergencyRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      reportedAt: reportedAt ?? this.reportedAt,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
      location: location ?? this.location,
      firstAidProvided: firstAidProvided ?? this.firstAidProvided,
      handledBy: handledBy ?? this.handledBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
      followUpRequired: followUpRequired ?? this.followUpRequired,
      painLevel: painLevel ?? this.painLevel,
      dutyRelated: dutyRelated ?? this.dutyRelated,
      unitCommand: unitCommand ?? this.unitCommand,
      symptoms: symptoms ?? this.symptoms,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notes: notes ?? this.notes,
    );
  }
}
