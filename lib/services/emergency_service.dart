import '../models/emergency_record.dart';
import 'api_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final List<EmergencyRecord> _emergencyRecords = [];
  bool _isInitialized = false;

  List<EmergencyRecord> get emergencyRecords =>
      List.unmodifiable(_emergencyRecords);

  // Emergency contacts and duty personnel
  final Map<String, String> emergencyContacts = {
    'AFPHSAC Emergency Hotline': '(02) 8123-4567',
    'Duty Dentist (24/7)': '(02) 8234-5678',
    'Base Medical Emergency': '911 or (02) 8345-6789',
    'Dental Clinic Main Line': '(02) 8456-7890',
    'Dental Officer of the Day': '(02) 8567-8901',
    'Command Duty Officer': '(02) 8678-9012',
  };

  final List<String> dutyDentists = [
    'Col. Maria Santos, DDS',
    'Maj. Roberto Cruz, DDS',
    'Capt. Ana Rodriguez, DDS',
    'Lt. Col. Jose Garcia, DDS',
    'Maj. Carmen Dela Cruz, DDS',
  ];

  final List<String> emergencyInstructions = [
    'Severe Tooth Pain: Take prescribed pain medication, rinse with warm salt water, apply cold compress to outside of mouth.',
    'Knocked-Out Tooth: Handle by crown only, rinse gently, try to reinsert. If not possible, keep in milk and seek immediate care.',
    'Broken/Chipped Tooth: Save fragments, rinse mouth with warm water, apply cold compress, cover sharp edges with dental wax.',
    'Lost Filling/Crown: Keep the restoration if possible, clean the area gently, use temporary dental cement, avoid sticky foods.',
    'Abscess/Swelling: Rinse with salt water, apply cold compress, take prescribed antibiotics, do NOT apply heat.',
    'Orthodontic Emergency: For broken wires, cover with wax. For loose brackets, keep them safe and contact orthodontist.',
    'Excessive Bleeding: Apply pressure with clean gauze, use cold compress, seek immediate medical attention.',
    'Facial Trauma: Control bleeding, apply ice to reduce swelling, check for jaw fractures, seek emergency care.',
  ];

  final Map<String, List<String>> emergencyKitItems = {
    'Basic Emergency Kit': [
      'Sterile gauze pads',
      'Medical tape',
      'Dental wax',
      'Temporary filling material',
      'Pain medication (Ibuprofen)',
      'Oral thermometer',
      'Instant cold pack',
      'Dental mirror',
      'Tweezers',
      'Contact card with emergency numbers',
    ],
    'Field Emergency Kit (Deployment)': [
      'All basic kit items',
      'Antibiotics (with prescription)',
      'Stronger pain medication',
      'Emergency suture kit',
      'Hemostatic agents',
      'Injectable anesthetics',
      'Emergency extraction tools',
      'Satellite communication device',
      'Medical evacuation request forms',
    ],
  };

  Future<void> initializeSampleData() async {
    if (_isInitialized) return;

    try {
      // Try to load from API first
      if (!ApiService.isOfflineMode) {
        await loadEmergencyRecordsFromAPI();
        _isInitialized = true;
        return;
      }
    } catch (e) {
      print('⚠️ Failed to load emergency records from API: $e');
    }

    // Fallback to sample data if API is not available
    if (_emergencyRecords.isNotEmpty) return;

    // Sample emergency records for demonstration
    _emergencyRecords.addAll([
      EmergencyRecord(
        id: 'emr_001',
        patientId: '8c3a807b-03ae-4cd8-9778-5bd2d6219582',
        reportedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: EmergencyType.severeToothache,
        priority: EmergencyPriority.urgent,
        status: EmergencyStatus.resolved,
        description: 'Severe pain in upper right molar during night duty',
        painLevel: 8,
        symptoms: ['Severe pain', 'Sensitivity to cold', 'Throbbing'],
        location: 'Base Command Center',
        dutyRelated: true,
        unitCommand: '1st Infantry Division',
        handledBy: 'Maj. Roberto Cruz, DDS',
        firstAidProvided: 'Ibuprofen 400mg, cold compress applied',
        resolvedAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
        resolution: 'Root canal therapy completed. Temporary crown placed.',
        followUpRequired: 'Permanent crown placement in 2 weeks',
        emergencyContact: '(02) 8234-5678',
      ),
      EmergencyRecord(
        id: 'emr_002',
        patientId: '45f784a4-ecd4-49d1-a8d0-909b25d2b03e',
        reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
        type: EmergencyType.dentalTrauma,
        priority: EmergencyPriority.immediate,
        status: EmergencyStatus.inProgress,
        description:
            'Dental trauma from training accident - fractured central incisor',
        painLevel: 7,
        symptoms: ['Fractured tooth', 'Bleeding', 'Lip laceration'],
        location: 'Training Ground Alpha',
        dutyRelated: true,
        unitCommand: 'Special Forces Group',
        handledBy: 'Col. Maria Santos, DDS',
        firstAidProvided:
            'Bleeding controlled, ice pack applied, tooth fragment saved',
        emergencyContact: '(02) 8123-4567',
        notes: 'Patient conscious and stable. X-rays show no root fracture.',
      ),
      EmergencyRecord(
        id: 'emr_003',
        patientId: '00000000-0000-0000-0000-000000000000',
        reportedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: EmergencyType.lostCrown,
        priority: EmergencyPriority.standard,
        status: EmergencyStatus.resolved,
        description: 'Crown came off while eating during mess hall dinner',
        painLevel: 3,
        symptoms: ['Exposed tooth', 'Mild sensitivity'],
        location: 'Base Mess Hall',
        dutyRelated: false,
        handledBy: 'Capt. Ana Rodriguez, DDS',
        firstAidProvided: 'Temporary cement applied to crown',
        resolvedAt: DateTime.now().subtract(const Duration(hours: 12)),
        resolution: 'Crown re-cemented successfully',
        emergencyContact: '(02) 8456-7890',
      ),
    ]);
    _isInitialized = true;
  }

  Future<void> loadEmergencyRecordsFromAPI() async {
    try {
      final records = await ApiService.getEmergencyRecords();
      _emergencyRecords.clear();
      
      for (final record in records) {
        _emergencyRecords.add(EmergencyRecord(
          id: record['id'],
          patientId: record['patientId'],
          reportedAt: DateTime.parse(record['reportedAt']),
          type: _parseEmergencyType(record['emergencyType']),
          priority: _parseEmergencyPriority(record['priority']),
          status: _parseEmergencyStatus(record['status']),
          description: record['description'],
          painLevel: record['painLevel'],
          symptoms: List<String>.from(record['symptoms']),
          location: record['location'],
          dutyRelated: record['dutyRelated'] ?? false,
          unitCommand: record['unitCommand'],
          handledBy: record['handledBy'],
          firstAidProvided: record['firstAidProvided'],
          resolvedAt: record['resolvedAt'] != null ? DateTime.parse(record['resolvedAt']) : null,
          resolution: record['resolution'],
          followUpRequired: record['followUpRequired'],
          emergencyContact: record['emergencyContact'],
          notes: record['notes'],
        ));
      }
      print('✅ Loaded ${_emergencyRecords.length} emergency records from API');
    } catch (e) {
      print('❌ Failed to load emergency records from API: $e');
      rethrow;
    }
  }

  EmergencyType _parseEmergencyType(String type) {
    switch (type) {
      case 'severeToothache': return EmergencyType.severeToothache;
      case 'knockedOutTooth': return EmergencyType.knockedOutTooth;
      case 'brokenTooth': return EmergencyType.brokenTooth;
      case 'dentalTrauma': return EmergencyType.dentalTrauma;
      case 'abscess': return EmergencyType.abscess;
      case 'excessiveBleeding': return EmergencyType.excessiveBleeding;
      case 'lostFilling': return EmergencyType.lostFilling;
      case 'lostCrown': return EmergencyType.lostCrown;
      case 'orthodonticEmergency': return EmergencyType.orthodonticEmergency;
      case 'other': return EmergencyType.other;
      default: return EmergencyType.other;
    }
  }

  EmergencyPriority _parseEmergencyPriority(String priority) {
    switch (priority) {
      case 'immediate': return EmergencyPriority.immediate;
      case 'urgent': return EmergencyPriority.urgent;
      case 'standard': return EmergencyPriority.standard;
      default: return EmergencyPriority.standard;
    }
  }

  EmergencyStatus _parseEmergencyStatus(String status) {
    switch (status) {
      case 'reported': return EmergencyStatus.reported;
      case 'triaged': return EmergencyStatus.triaged;
      case 'inProgress': return EmergencyStatus.inProgress;
      case 'resolved': return EmergencyStatus.resolved;
      case 'referred': return EmergencyStatus.referred;
      default: return EmergencyStatus.reported;
    }
  }

  Future<void> addEmergencyRecord(EmergencyRecord record) async {
    try {
      // Try to save to API first
      if (!ApiService.isOfflineMode) {
        final result = await ApiService.submitEmergencyRecord(
          emergencyType: _getEmergencyTypeString(record.type),
          priority: _getEmergencyPriorityString(record.priority),
          description: record.description,
          painLevel: record.painLevel,
          symptoms: record.symptoms,
          location: record.location,
          dutyRelated: record.dutyRelated,
          unitCommand: record.unitCommand,
        );
        
        // Update the record with the API response
        final updatedRecord = record.copyWith(
          id: result['id'],
          reportedAt: DateTime.parse(result['reportedAt']),
        );
        
        _emergencyRecords.add(updatedRecord);
        print('✅ Emergency record saved to API: ${result['id']}');
        return;
      }
    } catch (e) {
      print('⚠️ Failed to save emergency record to API: $e');
    }

    // Fallback to local storage
    _emergencyRecords.add(record);
    print('⚠️ Emergency record saved locally (offline mode)');
  }

  String _getEmergencyTypeString(EmergencyType type) {
    switch (type) {
      case EmergencyType.severeToothache: return 'severeToothache';
      case EmergencyType.knockedOutTooth: return 'knockedOutTooth';
      case EmergencyType.brokenTooth: return 'brokenTooth';
      case EmergencyType.dentalTrauma: return 'dentalTrauma';
      case EmergencyType.abscess: return 'abscess';
      case EmergencyType.excessiveBleeding: return 'excessiveBleeding';
      case EmergencyType.lostFilling: return 'lostFilling';
      case EmergencyType.lostCrown: return 'lostCrown';
      case EmergencyType.orthodonticEmergency: return 'orthodonticEmergency';
      case EmergencyType.other: return 'other';
    }
  }

  String _getEmergencyPriorityString(EmergencyPriority priority) {
    switch (priority) {
      case EmergencyPriority.immediate: return 'immediate';
      case EmergencyPriority.urgent: return 'urgent';
      case EmergencyPriority.standard: return 'standard';
    }
  }

  void updateEmergencyRecord(String id, EmergencyRecord updatedRecord) {
    final index = _emergencyRecords.indexWhere((record) => record.id == id);
    if (index != -1) {
      _emergencyRecords[index] = updatedRecord;
    }
  }

  void deleteEmergencyRecord(String id) {
    _emergencyRecords.removeWhere((record) => record.id == id);
  }

  List<EmergencyRecord> getEmergencyRecordsByPatient(String patientId) {
    return _emergencyRecords
        .where((record) => record.patientId == patientId)
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<EmergencyRecord> getEmergencyRecordsByPriority(
    EmergencyPriority priority,
  ) {
    return _emergencyRecords
        .where((record) => record.priority == priority)
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<EmergencyRecord> getEmergencyRecordsByStatus(EmergencyStatus status) {
    return _emergencyRecords.where((record) => record.status == status).toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<EmergencyRecord> getDutyRelatedEmergencies() {
    return _emergencyRecords
        .where((record) => record.dutyRelated == true)
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  List<EmergencyRecord> getActiveEmergencies() {
    return _emergencyRecords
        .where(
          (record) =>
              record.status == EmergencyStatus.reported ||
              record.status == EmergencyStatus.triaged ||
              record.status == EmergencyStatus.inProgress,
        )
        .toList()
      ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
  }

  String getCurrentDutyDentist() {
    // Rotate duty dentists based on day of year
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final index = dayOfYear % dutyDentists.length;
    return dutyDentists[index];
  }

  Map<String, int> getEmergencyStatistics() {
    return {
      'total': _emergencyRecords.length,
      'active': getActiveEmergencies().length,
      'immediate': getEmergencyRecordsByPriority(
        EmergencyPriority.immediate,
      ).length,
      'urgent': getEmergencyRecordsByPriority(EmergencyPriority.urgent).length,
      'dutyRelated': getDutyRelatedEmergencies().length,
      'resolved': getEmergencyRecordsByStatus(EmergencyStatus.resolved).length,
    };
  }

  EmergencyPriority assessPriority({
    required EmergencyType type,
    required int painLevel,
    required List<String> symptoms,
    bool hasSwelling = false,
    bool hasBleeding = false,
    bool difficultySwallowing = false,
  }) {
    // Immediate priority conditions
    if (difficultySwallowing ||
        hasBleeding ||
        symptoms.contains('difficulty breathing') ||
        symptoms.contains('facial swelling') ||
        type == EmergencyType.dentalTrauma) {
      return EmergencyPriority.immediate;
    }

    // Urgent priority conditions
    if (painLevel >= 7 ||
        type == EmergencyType.severeToothache ||
        type == EmergencyType.knockedOutTooth ||
        type == EmergencyType.abscess ||
        hasSwelling) {
      return EmergencyPriority.urgent;
    }

    // Standard priority for everything else
    return EmergencyPriority.standard;
  }

  List<String> getEmergencyInstructionsFor(EmergencyType type) {
    switch (type) {
      case EmergencyType.severeToothache:
        return [
          '1. Take prescribed pain medication (Ibuprofen 400-600mg)',
          '2. Rinse mouth with warm salt water',
          '3. Apply cold compress to outside of mouth',
          '4. Avoid hot or cold foods/drinks',
          '5. Do not place aspirin directly on tooth',
          '6. Contact duty dentist if pain persists',
        ];
      case EmergencyType.knockedOutTooth:
        return [
          '1. Handle tooth by crown only (white part)',
          '2. Rinse gently if dirty - do not scrub',
          '3. Try to reinsert tooth immediately',
          '4. If cannot reinsert, place in milk or saline',
          '5. Seek emergency care within 30 minutes',
          '6. Time is critical for tooth survival',
        ];
      case EmergencyType.brokenTooth:
        return [
          '1. Save any tooth fragments',
          '2. Rinse mouth with warm water',
          '3. Apply cold compress to reduce swelling',
          '4. Cover sharp edges with dental wax',
          '5. Avoid chewing on affected side',
          '6. Schedule emergency appointment',
        ];
      case EmergencyType.dentalTrauma:
        return [
          '1. Control bleeding with clean gauze',
          '2. Apply ice to reduce swelling',
          '3. Check for loose or displaced teeth',
          '4. Look for signs of jaw fracture',
          '5. Seek immediate emergency care',
          '6. Call base medical emergency line',
        ];
      case EmergencyType.abscess:
        return [
          '1. Rinse with warm salt water multiple times daily',
          '2. Apply cold compress to outside of face',
          '3. Take prescribed antibiotics if available',
          '4. DO NOT apply heat to the area',
          '5. Seek immediate treatment - can be serious',
          '6. Report high fever or difficulty swallowing',
        ];
      default:
        return [
          '1. Apply basic first aid as appropriate',
          '2. Contact duty dentist for guidance',
          '3. Document the emergency details',
          '4. Seek professional dental care',
        ];
    }
  }
}
