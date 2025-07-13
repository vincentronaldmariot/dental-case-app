import 'package:flutter/material.dart';
import 'user_state_manager.dart';
import 'services/api_service.dart';

class DentalSurveyScreen extends StatefulWidget {
  const DentalSurveyScreen({super.key});

  @override
  State<DentalSurveyScreen> createState() => _DentalSurveyScreenState();
}

class _DentalSurveyScreenState extends State<DentalSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  // Using static ApiService methods instead of instance
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _unitAssignmentController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _lastVisitController = TextEditingController();
  final _otherClassificationController = TextEditingController();

  String _selectedClassification = '';
  bool _hasExistingSurveyData = false;
  bool _isLoadingExistingData = true;
  Map<String, dynamic>? _existingSurveyData;

  // Survey answers
  Map<String, bool?> _toothConditions = {
    'decayed_tooth': null,
    'worn_down_tooth': null,
    'impacted_tooth': null,
  };

  String? _tartarLevel;
  bool? _toothSensitive;

  Map<String, bool?> _damagedFillings = {
    'broken_tooth': null,
    'broken_pasta': null,
  };

  bool? _needDentures;
  bool? _missingTeeth;
  bool? _hasMissingTeeth;

  Map<String, bool?> _missingToothConditions = {
    'extracted_teeth': null,
    'missing_teeth': null,
  };

  @override
  void initState() {
    super.initState();
    _checkForExistingSurveyData();
  }

  Future<void> _checkForExistingSurveyData() async {
    try {
      final surveyData = await ApiService.getDentalSurvey(
        UserStateManager().currentPatientId,
      ); // Use authenticated patient ID

      setState(() {
        _hasExistingSurveyData = surveyData != null;
        _existingSurveyData = surveyData;
        _isLoadingExistingData = false;
      });

      // If existing data found, populate the form
      if (surveyData != null) {
        _populateFormWithExistingData(surveyData);
      }
    } catch (e) {
      print('Error checking for existing survey data: $e');
      setState(() {
        _hasExistingSurveyData = false;
        _isLoadingExistingData = false;
      });
    }
  }

  void _populateFormWithExistingData(Map<String, dynamic> surveyData) {
    final data = surveyData['survey_data'];
    final patientInfo = data['patient_info'] ?? {};

    // Populate patient info fields
    _nameController.text = patientInfo['name'] ?? '';
    _serialNumberController.text = patientInfo['serial_number'] ?? '';
    _unitAssignmentController.text = patientInfo['unit_assignment'] ?? '';
    _contactNumberController.text = patientInfo['contact_number'] ?? '';
    _emailController.text = patientInfo['email'] ?? '';
    _emergencyContactController.text = patientInfo['emergency_contact'] ?? '';
    _emergencyPhoneController.text = patientInfo['emergency_phone'] ?? '';
    _lastVisitController.text = patientInfo['last_visit'] ?? '';
    _selectedClassification = patientInfo['classification'] ?? '';
    _otherClassificationController.text =
        patientInfo['other_classification'] ?? '';

    // Populate survey answers
    final toothConditions = data['tooth_conditions'] ?? {};
    _toothConditions['decayed_tooth'] = toothConditions['decayed_tooth'];
    _toothConditions['worn_down_tooth'] = toothConditions['worn_down_tooth'];
    _toothConditions['impacted_tooth'] = toothConditions['impacted_tooth'];

    _tartarLevel = data['tartar_level'];
    _toothSensitive = data['tooth_sensitive'];

    final damagedFillings = data['damaged_fillings'] ?? {};
    _damagedFillings['broken_tooth'] = damagedFillings['broken_tooth'];
    _damagedFillings['broken_pasta'] = damagedFillings['broken_pasta'];

    _needDentures = data['need_dentures'];
    _hasMissingTeeth = data['has_missing_teeth'];

    final missingToothConditions = data['missing_tooth_conditions'] ?? {};
    _missingToothConditions['extracted_teeth'] =
        missingToothConditions['extracted_teeth'];
    _missingToothConditions['missing_teeth'] =
        missingToothConditions['missing_teeth'];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0029B2), Color(0xFF000074)],
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/image/main_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'DENTAL SERVICE CENTER\nAFPHSC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Existing Survey Data Notification
            if (_hasExistingSurveyData && !_isLoadingExistingData)
              _buildExistingSurveyNotification(),

            // Survey Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Classification Selection - Moved to top
                      _buildSectionTitle('PLEASE SELECT YOUR CLASSIFICATION'),
                      const SizedBox(height: 15),

                      _buildClassificationDropdown(),

                      // Show "Other" specification field when "Others" is selected
                      if (_selectedClassification == 'Others') ...[
                        const SizedBox(height: 15),
                        _buildOtherSpecificationField(),
                      ],

                      const SizedBox(height: 25),

                      // Patient Information Section
                      _buildSectionTitle('Patient Information'),
                      const SizedBox(height: 15),

                      _buildInputField(
                        controller: _nameController,
                        labelText: 'NAME:',
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _serialNumberController,
                        labelText: 'SERIAL NUMBER:',
                        enabled: _selectedClassification != 'Others',
                        validator: (value) =>
                            _selectedClassification != 'Others' &&
                                    (value?.isEmpty ?? true)
                                ? 'Serial number is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _unitAssignmentController,
                        labelText: 'UNIT ASSIGNMENT:',
                        enabled: _selectedClassification != 'Others',
                        validator: (value) =>
                            _selectedClassification != 'Others' &&
                                    (value?.isEmpty ?? true)
                                ? 'Unit assignment is required'
                                : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _contactNumberController,
                        labelText: 'CONTACT NUMBER:',
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Contact number is required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _emailController,
                        labelText: 'EMAIL:',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!value!.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _emergencyContactController,
                        labelText: 'EMERGENCY CONTACT:',
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Emergency contact is required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _emergencyPhoneController,
                        labelText: 'EMERGENCY PHONE:',
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Emergency phone is required'
                            : null,
                      ),

                      const SizedBox(height: 25),

                      // Self-Assessment Dental Survey
                      _buildSectionTitle('Self-Assessment Dental Survey'),
                      const SizedBox(height: 20),

                      // Question 1: Tooth Conditions
                      _buildQuestionTitle(
                        '1. Do you have any of the ones shown in the pictures?',
                      ),
                      const SizedBox(height: 15),

                      _buildToothConditionsSection(),

                      const SizedBox(height: 25),

                      // Question 2: Tartar/Calculus
                      _buildQuestionTitle(
                        '2. Do you have tartar/calculus deposits or rough feeling teeth like in the images?',
                      ),
                      const SizedBox(height: 15),

                      _buildTartarSection(),

                      const SizedBox(height: 25),

                      // Question 3: Tooth Sensitivity
                      _buildSimpleYesNoQuestion(
                        '3. Do your teeth feel sensitive to hot, cold, or sweet foods?',
                        _toothSensitive,
                        (value) => setState(() => _toothSensitive = value),
                      ),

                      const SizedBox(height: 25),

                      // Question 4: Damaged Fillings
                      _buildQuestionTitle(
                        '4. Do you have damaged or broken fillings like those shown in the pictures?',
                      ),
                      const SizedBox(height: 15),

                      _buildDamagedFillingsSection(),

                      const SizedBox(height: 25),

                      // Questions 5-6: Dentures and Missing Teeth
                      _buildSimpleYesNoQuestion(
                        '5. Do you need dentures?',
                        _needDentures,
                        (value) => setState(() => _needDentures = value),
                      ),

                      const SizedBox(height: 15),

                      _buildSimpleYesNoQuestion(
                        '6. Do you have missing teeth?',
                        _hasMissingTeeth,
                        (value) => setState(() => _hasMissingTeeth = value),
                      ),

                      // Show missing teeth conditions if user has missing teeth
                      if (_hasMissingTeeth == true) ...[
                        const SizedBox(height: 15),
                        _buildQuestionTitle(
                          'What type of missing teeth conditions do you have?',
                        ),
                        const SizedBox(height: 10),
                        _buildMissingTeethSection(),
                      ],

                      const SizedBox(height: 25),

                      // Last Visit
                      _buildQuestionTitle(
                        '7. When was your last dental visit?',
                      ),
                      const SizedBox(height: 10),

                      _buildInputField(
                        controller: _lastVisitController,
                        labelText:
                            'Last dental visit (e.g., 6 months ago, 1 year ago)',
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please specify your last dental visit'
                            : null,
                      ),

                      const SizedBox(height: 30),

                      // Submit Button
                      _buildSubmitButton(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000074),
      ),
    );
  }

  Widget _buildQuestionTitle(String question) {
    return Text(
      question,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        validator: enabled ? validator : null,
        maxLines: maxLines,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: enabled ? Colors.grey : Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          suffixIcon: !enabled
              ? Icon(Icons.lock, color: Colors.grey.shade400, size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildClassificationDropdown() {
    final classifications = ['Military', 'AD/HR', 'Department', 'Others'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedClassification.isEmpty ? null : _selectedClassification,
        decoration: InputDecoration(
          labelText: 'Select',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: classifications.map((classification) {
          return DropdownMenuItem<String>(
            value: classification,
            child: Text(classification),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedClassification = value ?? '';

            // If "Others" is selected, clear and disable military-specific fields
            if (_selectedClassification == 'Others') {
              _serialNumberController.clear();
              _unitAssignmentController.clear();
            } else {
              // If not "Others", clear the other specification field
              _otherClassificationController.clear();
            }
          });
        },
        validator: (value) =>
            value == null ? 'Please select classification' : null,
      ),
    );
  }

  Widget _buildOtherSpecificationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Please specify your classification:',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Text field
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: _otherClassificationController,
              decoration: InputDecoration(
                hintText: 'e.g., Family member, Visitor, Student, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Colors.blue.shade600,
                ),
              ),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Please specify your classification'
                  : null,
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToothConditionsSection() {
    return Column(
      children: [
        _buildToothConditionCard(
          'Decayed Tooth',
          'assets/image/decayed_tooth.png',
          'decayed_tooth',
        ),
        const SizedBox(height: 12),
        _buildToothConditionCard(
          'Worn Down Tooth',
          'assets/image/worn_down_tooth.png',
          'worn_down_tooth',
        ),
        const SizedBox(height: 12),
        _buildToothConditionCard(
          'Impacted Wisdom Tooth',
          'assets/image/impacted_wisdom_tooth.png',
          'impacted_tooth',
        ),
      ],
    );
  }

  Widget _buildToothConditionCard(String title, String imagePath, String key) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          // Title and Yes/No buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildYesNoButton(
                        'Yes',
                        _toothConditions[key] == true,
                        () => setState(() => _toothConditions[key] = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildYesNoButton(
                        'No',
                        _toothConditions[key] == false,
                        () => setState(() => _toothConditions[key] = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTartarSection() {
    final tartarLevels = [
      {
        'key': 'tartar_none',
        'title': 'None',
        'image': 'assets/image/tartar_none.png',
      },
      {
        'key': 'tartar_mild',
        'title': 'Mild',
        'image': 'assets/image/tartar_mild.png',
      },
      {
        'key': 'tartar_moderate',
        'title': 'Moderate',
        'image': 'assets/image/tartar_moderate.png',
      },
      {
        'key': 'tartar_heavy',
        'title': 'Heavy',
        'image': 'assets/image/tartar_heavy.png',
      },
    ];

    return Column(
      children: tartarLevels.map((level) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _tartarLevel == level['key']
                  ? const Color(0xFF0029B2)
                  : Colors.grey.shade300,
              width: _tartarLevel == level['key'] ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => setState(() => _tartarLevel = level['key']),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        level['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and radio
                  Expanded(
                    child: Text(
                      level['title']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _tartarLevel == level['key']
                            ? const Color(0xFF0029B2)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Radio<String>(
                    value: level['key']!,
                    groupValue: _tartarLevel,
                    onChanged: (value) => setState(() => _tartarLevel = value),
                    activeColor: const Color(0xFF0029B2),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDamagedFillingsSection() {
    return Column(
      children: [
        _buildToothConditionCard(
          'Broken Tooth Filling',
          'assets/image/broken_tooth_filling.png',
          'broken_tooth',
        ),
        const SizedBox(height: 12),
        _buildToothConditionCard(
          'Broken Pasta Filling',
          'assets/image/broken_pasta_filling.png',
          'broken_pasta',
        ),
      ],
    );
  }

  Widget _buildMissingTeethSection() {
    return Column(
      children: [
        _buildMissingToothConditionCard(
          'Extracted Teeth',
          'assets/image/extracted_teeth.png',
          'extracted_teeth',
        ),
        const SizedBox(height: 12),
        _buildMissingToothConditionCard(
          'Missing Teeth',
          'assets/image/missing_teeth.png',
          'missing_teeth',
        ),
      ],
    );
  }

  Widget _buildMissingToothConditionCard(
    String title,
    String imagePath,
    String key,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          // Title and Yes/No buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildYesNoButton(
                        'Yes',
                        _missingToothConditions[key] == true,
                        () =>
                            setState(() => _missingToothConditions[key] = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildYesNoButton(
                        'No',
                        _missingToothConditions[key] == false,
                        () => setState(
                          () => _missingToothConditions[key] = false,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleYesNoQuestion(
    String question,
    bool? currentValue,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildYesNoButton(
                  'Yes',
                  currentValue == true,
                  () => onChanged(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildYesNoButton(
                  'No',
                  currentValue == false,
                  () => onChanged(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoButton(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0029B2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0029B2) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0029B2), Color(0xFF000074)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _submitSurvey,
          child: Center(
            child: Text(
              _hasExistingSurveyData ? 'Update Survey' : 'Submit Survey',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitSurvey() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Check if all required survey questions are answered
      bool allToothConditionsAnswered = _toothConditions.values.every(
        (value) => value != null,
      );
      bool allDamagedFillingsAnswered = _damagedFillings.values.every(
        (value) => value != null,
      );

      if (!allToothConditionsAnswered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer all tooth condition questions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_tartarLevel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your tartar level'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_toothSensitive == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer the tooth sensitivity question'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!allDamagedFillingsAnswered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer all damaged filling questions'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_needDentures == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer if you need dentures'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_hasMissingTeeth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please answer if you have missing teeth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If user has missing teeth, check that missing teeth questions are answered
      if (_hasMissingTeeth == true) {
        bool allMissingToothConditionsAnswered =
            _missingToothConditions.values.every((value) => value != null);

        if (!allMissingToothConditionsAnswered) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please answer all missing teeth condition questions',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Save survey data to database
      try {
        await _saveSurveyData();

        // Mark survey as completed only if save was successful
        UserStateManager().completeSurvey();

        // Update the notification state to show it was completed
        await _checkForExistingSurveyData();

        // All validations passed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hasExistingSurveyData
                  ? 'Survey updated successfully!'
                  : 'Survey submitted successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or to next screen
        Navigator.pop(context);
      } catch (e) {
        // Error already handled in _saveSurveyData
        print('Survey submission failed: $e');
        return; // Don't proceed if save failed
      }
    }
  }

  Future<void> _saveSurveyData() async {
    try {
      // Use authenticated patient ID
      final patientId = UserStateManager().currentPatientId;

      // Compile all survey data
      final surveyData = {
        'patient_info': {
          'name': _nameController.text,
          'serial_number': _serialNumberController.text,
          'unit_assignment': _unitAssignmentController.text,
          'contact_number': _contactNumberController.text,
          'email': _emailController.text,
          'emergency_contact': _emergencyContactController.text,
          'emergency_phone': _emergencyPhoneController.text,
          'classification': _selectedClassification,
          'other_classification': _otherClassificationController.text,
          'last_visit': _lastVisitController.text,
        },
        'tooth_conditions': _toothConditions,
        'tartar_level': _tartarLevel,
        'tooth_sensitive': _toothSensitive,
        'damaged_fillings': _damagedFillings,
        'need_dentures': _needDentures,
        'has_missing_teeth': _hasMissingTeeth,
        'missing_tooth_conditions': _missingToothConditions,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      print('Attempting to save survey data for patient $patientId');
      print('Survey data: ${surveyData.toString()}');

      // Save to database
      await ApiService.saveDentalSurvey(patientId, surveyData);
      print('Survey data saved successfully to database');

      // Verify the data was saved by trying to retrieve it
      final savedData = await ApiService.getDentalSurvey(patientId);
      if (savedData != null) {
        print('Survey data verified in database');
        print('Retrieved survey data: ${savedData.toString()}');
      } else {
        print('Warning: Survey data not found after saving');
      }
    } catch (e) {
      print('Error saving survey data: $e');
      print('Error stack trace: ${e.toString()}');

      // Show error to user since this is critical for the workflow
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save survey data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow; // Re-throw to prevent successful completion message
    }
  }

  Widget _buildExistingSurveyNotification() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Survey Already Completed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _existingSurveyData != null
                          ? 'Last updated: ${_formatDate(_existingSurveyData!['completed_at'])}'
                          : 'You have already completed this assessment.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your previous answers have been loaded below. You can review and update them if needed, then submit to save any changes.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.edit, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                'Make changes below and submit to update',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        final months = [
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
    } catch (e) {
      return 'Previously completed';
    }
  }
}
