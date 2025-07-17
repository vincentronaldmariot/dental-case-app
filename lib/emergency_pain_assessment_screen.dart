import 'package:flutter/material.dart';
import 'models/emergency_record.dart';
import 'services/emergency_service.dart';
import 'user_state_manager.dart';

class EmergencyPainAssessmentScreen extends StatefulWidget {
  const EmergencyPainAssessmentScreen({super.key});

  @override
  State<EmergencyPainAssessmentScreen> createState() =>
      _EmergencyPainAssessmentScreenState();
}

class _EmergencyPainAssessmentScreenState
    extends State<EmergencyPainAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final EmergencyService _emergencyService = EmergencyService();

  // Assessment variables
  int _painLevel = 0;
  EmergencyType _selectedType = EmergencyType.severeToothache;
  List<String> _symptoms = [];
  bool _hasFacialSwelling = false;
  bool _hasDifficultySwallowing = false;
  bool _hasBleeding = false;
  String _location = '';
  String _description = '';
  bool _isDutyRelated = false;
  String _unitCommand = '';

  // Calculated priority
  EmergencyPriority? _assessedPriority;
  Color _priorityColor = Colors.grey;
  String _priorityMessage = '';
  List<String> _emergencyInstructions = [];

  @override
  void initState() {
    super.initState();
    _emergencyService.initializeSampleData();
  }

  void _assessPriority() {
    setState(() {
      _assessedPriority = _emergencyService.assessPriority(
        type: _selectedType,
        painLevel: _painLevel,
        symptoms: _symptoms,
        hasSwelling: _hasFacialSwelling,
        hasBleeding: _hasBleeding,
        difficultySwallowing: _hasDifficultySwallowing,
      );

      // Set priority color and message
      switch (_assessedPriority!) {
        case EmergencyPriority.immediate:
          _priorityColor = Colors.red;
          _priorityMessage =
              'IMMEDIATE ATTENTION REQUIRED - Call Emergency Hotline Now!';
          break;
        case EmergencyPriority.urgent:
          _priorityColor = Colors.orange;
          _priorityMessage = 'URGENT - Seek care within 2-4 hours';
          break;
        case EmergencyPriority.standard:
          _priorityColor = Colors.green;
          _priorityMessage =
              'NON-URGENT - Schedule appointment next business day';
          break;
      }

      _emergencyInstructions = _emergencyService.getEmergencyInstructionsFor(
        _selectedType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Emergency Pain Assessment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE74C3C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'If experiencing severe facial swelling, difficulty breathing, or uncontrolled bleeding, call emergency services immediately.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Pain Level Assessment
              _buildPainLevelSection(),

              const SizedBox(height: 25),

              // Emergency Type Selection
              _buildEmergencyTypeSection(),

              const SizedBox(height: 25),

              // Critical Symptoms
              _buildCriticalSymptomsSection(),

              const SizedBox(height: 25),

              // Additional Symptoms
              _buildAdditionalSymptomsSection(),

              const SizedBox(height: 25),

              // Location and Context
              _buildLocationContextSection(),

              const SizedBox(height: 30),

              // Assess Button
              _buildAssessButton(),

              // Assessment Results
              if (_assessedPriority != null) ...[
                const SizedBox(height: 30),
                _buildAssessmentResults(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPainLevelSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Pain Level Assessment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Rate your pain from 0 (no pain) to 10 (worst pain):'),
          const SizedBox(height: 15),

          // Pain scale
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (index) {
              final isSelected = _painLevel == index;
              Color getColorForPain(int level) {
                if (level == 0) return Colors.green;
                if (level <= 3) return Colors.yellow.shade700;
                if (level <= 6) return Colors.orange;
                return Colors.red;
              }

              return GestureDetector(
                onTap: () => setState(() => _painLevel = index),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? getColorForPain(index)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? getColorForPain(index)
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          if (_painLevel > 0)
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Pain Level: $_painLevel/10 - ${_getPainDescription(_painLevel)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_services,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Type of Emergency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<EmergencyType>(
            value: _selectedType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
            ),
            items: EmergencyType.values.map((type) {
              return DropdownMenuItem<EmergencyType>(
                value: type,
                child: Text(_getEmergencyTypeDisplay(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Describe the emergency in detail',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            onChanged: (value) => _description = value,
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalSymptomsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: Colors.red.shade700, size: 24),
              const SizedBox(width: 10),
              Text(
                'Critical Symptoms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            'Check any that apply (these indicate immediate emergency):',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 10),
          CheckboxListTile(
            title: const Text('Facial swelling affecting eyes or breathing'),
            value: _hasFacialSwelling,
            onChanged: (value) => setState(() => _hasFacialSwelling = value!),
            activeColor: Colors.red.shade600,
          ),
          CheckboxListTile(
            title: const Text('Difficulty swallowing or breathing'),
            value: _hasDifficultySwallowing,
            onChanged: (value) =>
                setState(() => _hasDifficultySwallowing = value!),
            activeColor: Colors.red.shade600,
          ),
          CheckboxListTile(
            title: const Text('Uncontrolled bleeding'),
            value: _hasBleeding,
            onChanged: (value) => setState(() => _hasBleeding = value!),
            activeColor: Colors.red.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalSymptomsSection() {
    final additionalSymptoms = [
      'Severe throbbing pain',
      'Sensitivity to temperature',
      'Swelling around tooth/gum',
      'Loose or displaced tooth',
      'Bad taste in mouth',
      'Fever or chills',
      'Jaw stiffness',
      'Visible pus or discharge',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Additional Symptoms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text('Select all symptoms you are experiencing:'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: additionalSymptoms.map((symptom) {
              final isSelected = _symptoms.contains(symptom);
              return FilterChip(
                label: Text(symptom),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _symptoms.add(symptom);
                    } else {
                      _symptoms.remove(symptom);
                    }
                  });
                },
                selectedColor: Colors.orange.shade100,
                checkmarkColor: Colors.orange.shade700,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationContextSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 10),
              const Text(
                'Location & Context',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Current location',
              hintText: 'e.g., Base quarters, Training field, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.all(15),
            ),
            onChanged: (value) => _location = value,
          ),
          const SizedBox(height: 15),
          CheckboxListTile(
            title: const Text('Is this duty-related?'),
            subtitle: const Text(
              'Did this occur during duty hours or military activities?',
            ),
            value: _isDutyRelated,
            onChanged: (value) => setState(() => _isDutyRelated = value!),
          ),
          if (_isDutyRelated) ...[
            const SizedBox(height: 15),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Unit/Command',
                hintText: 'e.g., 1st Infantry Division',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(15),
              ),
              onChanged: (value) => _unitCommand = value,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _assessPriority,
          child: const Center(
            child: Text(
              'Assess Emergency Level',
              style: TextStyle(
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

  Widget _buildAssessmentResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority Result
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: _priorityColor, width: 2),
          ),
          child: Column(
            children: [
              Icon(_getPriorityIcon(), color: _priorityColor, size: 48),
              const SizedBox(height: 12),
              Text(
                _assessedPriority!.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _priorityColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _priorityMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _priorityColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Emergency Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_information,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Emergency Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ...(_emergencyInstructions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            if (_assessedPriority == EmergencyPriority.immediate) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callEmergencyHotline(),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call Emergency'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _bookEmergencyAppointment(),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Book Emergency Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _priorityColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _saveAssessment(),
                icon: const Icon(Icons.save),
                label: const Text('Save Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPainDescription(int level) {
    if (level == 0) return 'No pain';
    if (level <= 2) return 'Mild discomfort';
    if (level <= 4) return 'Moderate pain';
    if (level <= 6) return 'Significant pain';
    if (level <= 8) return 'Severe pain';
    return 'Extreme/Unbearable pain';
  }

  String _getEmergencyTypeDisplay(EmergencyType type) {
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

  IconData _getPriorityIcon() {
    switch (_assessedPriority!) {
      case EmergencyPriority.immediate:
        return Icons.warning;
      case EmergencyPriority.urgent:
        return Icons.access_time;
      case EmergencyPriority.standard:
        return Icons.schedule;
    }
  }

  void _callEmergencyHotline() {
    // In real implementation, this would initiate a call
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Hotline'),
        content: const Text(
          'Calling AFPHSAC Emergency Hotline:\n(02) 8123-4567',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _bookEmergencyAppointment() {
    // Navigate to emergency booking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to emergency appointment booking...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _saveAssessment() {
    // Create emergency record
    final record = EmergencyRecord(
      id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
      patientId:
          UserStateManager().currentPatientId, // Use authenticated patient ID
      reportedAt: DateTime.now(),
      type: _selectedType,
      priority: _assessedPriority!,
      status: EmergencyStatus.reported,
      description: _description,
      painLevel: _painLevel,
      symptoms: _symptoms,
      location: _location,
      dutyRelated: _isDutyRelated,
      unitCommand: _isDutyRelated ? _unitCommand : null,
    );

    // Save to service (in real app, this would save to database)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency assessment saved successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate back with results
    Navigator.pop(context);
  }
}
