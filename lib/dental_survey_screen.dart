import 'package:flutter/material.dart';
import 'user_state_manager.dart';

class DentalSurveyScreen extends StatefulWidget {
  const DentalSurveyScreen({super.key});

  @override
  State<DentalSurveyScreen> createState() => _DentalSurveyScreenState();
}

class _DentalSurveyScreenState extends State<DentalSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _unitAssignmentController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _lastVisitController = TextEditingController();

  String _selectedClassification = '';

  // Survey answers
  Map<String, bool?> _toothConditions = {
    'decayed_tooth': null,
    'worn_down_tooth': null,
    'impacted_tooth': null,
  };

  String? _tartarLevel;
  bool? _toothPain;
  bool? _toothSensitive;

  Map<String, bool?> _damagedFillings = {
    'broken_tooth': null,
    'broken_pasta': null,
  };

  bool? _needDentures;
  bool? _missingTeeth;
  bool? _hasMissingTeeth;

  Map<String, bool?> _missingToothConditions = {
    'missing_broken_tooth': null,
    'missing_broken_pasta': null,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _unitAssignmentController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _lastVisitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with DSC logo and title
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

            // Survey Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Serial number is required'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      _buildInputField(
                        controller: _unitAssignmentController,
                        labelText: 'UNIT ASSIGNMENT:',
                        validator: (value) => value?.isEmpty ?? true
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

                      // Classification Selection
                      _buildSectionTitle('PLEASE SELECT YOUR CLASSIFICATION'),
                      const SizedBox(height: 15),

                      _buildClassificationDropdown(),

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

                      // Questions 3-4: Pain and Sensitivity
                      _buildSimpleYesNoQuestion(
                        '3. Do you experience tooth pain?',
                        _toothPain,
                        (value) {
                          setState(() => _toothPain = value);
                        },
                      ),

                      const SizedBox(height: 15),

                      _buildSimpleYesNoQuestion(
                        '4. Do your teeth feel sensitive?',
                        _toothSensitive,
                        (value) {
                          setState(() => _toothSensitive = value);
                        },
                      ),

                      const SizedBox(height: 25),

                      // Question 5: Damaged Fillings
                      _buildQuestionTitle(
                        '5. Do you have damaged or broken fillings like those shown in the pictures?',
                      ),
                      const SizedBox(height: 15),

                      _buildDamagedFillingsSection(),

                      const SizedBox(height: 25),

                      // Questions 6-7: Dentures and Missing Teeth
                      _buildSimpleYesNoQuestion(
                        '6. Do you need to get dentures (false teeth)?',
                        _needDentures,
                        (value) {
                          setState(() => _needDentures = value);
                        },
                      ),

                      const SizedBox(height: 15),

                      _buildSimpleYesNoQuestion(
                        '7. Do you have missing or extracted teeth?',
                        _hasMissingTeeth,
                        (value) {
                          setState(() => _hasMissingTeeth = value);
                        },
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Sample pictures of missing teeth types:',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildMissingTeethSamplesSection(),

                      const SizedBox(height: 25),

                      // Question 8: Last Visit
                      _buildQuestionTitle(
                        '8. When was your last dental visit at a Dental Treatment Facility?',
                      ),
                      const SizedBox(height: 15),

                      _buildInputField(
                        controller: _lastVisitController,
                        labelText: 'Write your answer here',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 40),

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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
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
          });
        },
        validator: (value) =>
            value == null ? 'Please select classification' : null,
      ),
    );
  }

  Widget _buildToothConditionsSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToothConditionCard('Decayed tooth', 'decayed_tooth'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToothConditionCard(
                'Worn-down tooth',
                'worn_down_tooth',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildToothConditionCard(
                'Impacted third molar/\nwisdom tooth that\nhasn\'t erupted',
                'impacted_tooth',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToothConditionCard(String title, String key) {
    // Map keys to image file names
    final imageMap = {
      'decayed_tooth': 'decayed_tooth.png',
      'worn_down_tooth': 'worn_down_tooth.png',
      'impacted_tooth': 'impacted_wisdom_tooth.png',
    };

    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/${imageMap[key]}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF0029B2).withOpacity(0.1),
                    child: const Icon(
                      Icons.medical_services,
                      color: Color(0xFF0029B2),
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_buildYesNoButtons(key, _toothConditions[key])],
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoButtons(String key, bool? value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (_toothConditions.containsKey(key)) {
                _toothConditions[key] = true;
              } else if (_damagedFillings.containsKey(key)) {
                _damagedFillings[key] = true;
              } else if (_missingToothConditions.containsKey(key)) {
                _missingToothConditions[key] = true;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: value == true
                  ? const Color(0xFF0029B2)
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'YES',
              style: TextStyle(
                color: value == true ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_toothConditions.containsKey(key)) {
                _toothConditions[key] = false;
              } else if (_damagedFillings.containsKey(key)) {
                _damagedFillings[key] = false;
              } else if (_missingToothConditions.containsKey(key)) {
                _missingToothConditions[key] = false;
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: value == false ? Colors.red : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'NO',
              style: TextStyle(
                color: value == false ? Colors.white : Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTartarSection() {
    final levels = ['NONE', 'MILD', 'MODERATE', 'HEAVY'];
    final imageMap = {
      'NONE': 'tartar_none.png',
      'MILD': 'tartar_mild.png',
      'MODERATE': 'tartar_moderate.png',
      'HEAVY': 'tartar_heavy.png',
    };

    return Row(
      children: levels.map((level) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tartarLevel = level;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _tartarLevel == level
                    ? const Color(0xFF005800)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _tartarLevel == level
                      ? const Color(0xFF005800)
                      : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/image/${imageMap[level]}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.medical_information,
                              color: Colors.grey,
                              size: 30,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    level,
                    style: TextStyle(
                      color: _tartarLevel == level
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSimpleYesNoQuestion(
    String question,
    bool? value,
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: value == true
                        ? const Color(0xFF0029B2)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: value == true ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: value == false ? Colors.red : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: value == false ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDamagedFillingsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDamagedFillingCard('Broken tooth', 'broken_tooth'),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildDamagedFillingCard('Broken pasta', 'broken_pasta'),
        ),
      ],
    );
  }

  Widget _buildDamagedFillingCard(String title, String key) {
    // Map keys to image file names for damaged fillings
    final imageMap = {
      'broken_tooth': 'broken_tooth_filling.png',
      'broken_pasta': 'broken_pasta_filling.png',
    };

    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/${imageMap[key]}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.red.withOpacity(0.1),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildYesNoButtons(key, _damagedFillings[key]),
        ],
      ),
    );
  }

  Widget _buildMissingTeethSamplesSection() {
    return Row(
      children: [
        Expanded(
          child: _buildSampleToothCard('Missing teeth', 'missing_teeth.png'),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSampleToothCard(
            'Extracted teeth',
            'extracted_teeth.png',
          ),
        ),
      ],
    );
  }

  Widget _buildMissingTeethSection() {
    return Column(
      children: [
        const Text(
          'Type of missing teeth:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMissingToothCard(
                'Broken tooth',
                'missing_broken_tooth',
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildMissingToothCard(
                'Broken pasta',
                'missing_broken_pasta',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSampleToothCard(String title, String imageName) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/$imageName',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.blue.withOpacity(0.1),
                    child: const Icon(
                      Icons.image,
                      color: Colors.blue,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '(Sample)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingToothCard(String title, String key) {
    // Map keys to image file names for missing teeth
    final imageMap = {
      'missing_broken_tooth': 'broken_tooth_filling.png',
      'missing_broken_pasta': 'broken_pasta_filling.png',
    };

    return Container(
      padding: const EdgeInsets.all(12),
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
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image/${imageMap[key]}',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.orange.withOpacity(0.1),
                    child: const Icon(
                      Icons.healing,
                      color: Colors.orange,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildYesNoButtons(key, _missingToothConditions[key]),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _submitSurvey,
          child: const Center(
            child: Text(
              'NEXT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitSurvey() {
    if (_formKey.currentState!.validate()) {
      // Mark survey as completed
      UserStateManager().completeSurvey();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Health assessment completed! You can now book appointments.',
          ),
          backgroundColor: Color(0xFF005800),
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back or to next screen
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
