import 'package:flutter/material.dart';
import 'lib/services/history_service.dart';
import 'lib/models/appointment.dart';
import 'lib/user_state_manager.dart';
import 'lib/services/api_service.dart';

void main() {
  runApp(const AppointmentTestApp());
}

class AppointmentTestApp extends StatelessWidget {
  const AppointmentTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Appointment Test',
      home: AppointmentTestScreen(),
    );
  }
}

class AppointmentTestScreen extends StatefulWidget {
  const AppointmentTestScreen({super.key});

  @override
  State<AppointmentTestScreen> createState() => _AppointmentTestScreenState();
}

class _AppointmentTestScreenState extends State<AppointmentTestScreen> {
  final HistoryService _historyService = HistoryService();
  String _debugOutput = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDebugAnalysis();
  }

  void _runDebugAnalysis() {
    setState(() {
      _isLoading = true;
    });

    final output = StringBuffer();
    output.writeln('🔍 === APPOINTMENT DEBUG ANALYSIS ===');
    output.writeln('Time: ${DateTime.now()}');
    output.writeln('');

    final patientId = UserStateManager().currentPatientId;
    output.writeln('Patient ID: $patientId');
    output.writeln('');

    final allAppointments =
        _historyService.getAppointments(patientId: patientId);
    output.writeln(
        'Total appointments in HistoryService: ${allAppointments.length}');
    output.writeln('');

    if (allAppointments.isNotEmpty) {
      output.writeln('📋 All Appointments:');
      for (int i = 0; i < allAppointments.length; i++) {
        final apt = allAppointments[i];
        output.writeln(
            '   $i: ID="${apt.id}", PatientID="${apt.patientId}", Service="${apt.service}", Status=${apt.status}');
      }
      output.writeln('');
    }

    final pendingAppointments = _historyService.getAppointmentsByStatus(
      AppointmentStatus.pending,
      patientId: patientId,
    );
    output.writeln('Pending appointments: ${pendingAppointments.length}');
    output.writeln(
        'pendingAppointments.isNotEmpty: ${pendingAppointments.isNotEmpty}');
    output.writeln('');

    if (pendingAppointments.isNotEmpty) {
      output.writeln('⏳ Pending Appointments Details:');
      for (int i = 0; i < pendingAppointments.length; i++) {
        final apt = pendingAppointments[i];
        output.writeln(
            '   $i: ID="${apt.id}", PatientID="${apt.patientId}", Service="${apt.service}", Status=${apt.status}');
      }
      output.writeln('');
    }

    // Check for problematic appointments
    final problematicAppointments = allAppointments.where((apt) {
      return apt.id.isEmpty || apt.service.isEmpty || apt.patientId.isEmpty;
    }).toList();

    if (problematicAppointments.isNotEmpty) {
      output.writeln('⚠️ Problematic Appointments:');
      for (final apt in problematicAppointments) {
        output.writeln(
            '   - ID: "${apt.id}", PatientID: "${apt.patientId}", Service: "${apt.service}", Status: ${apt.status}');
      }
      output.writeln('');
    }

    // Check for wrong patient appointments
    final wrongPatientAppointments = allAppointments.where((apt) {
      return apt.patientId != patientId;
    }).toList();

    if (wrongPatientAppointments.isNotEmpty) {
      output.writeln('⚠️ Wrong Patient Appointments:');
      for (final apt in wrongPatientAppointments) {
        output.writeln(
            '   - ID: "${apt.id}", PatientID: "${apt.patientId}", Service: "${apt.service}", Status: ${apt.status}');
      }
      output.writeln('');
    }

    output.writeln('=== END DEBUG ANALYSIS ===');

    setState(() {
      _debugOutput = output.toString();
      _isLoading = false;
    });
  }

  Future<void> _loadFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    final output = StringBuffer();
    output.writeln('🔄 === LOADING FROM BACKEND ===');
    output.writeln('Time: ${DateTime.now()}');
    output.writeln('');

    try {
      final patientId = UserStateManager().currentPatientId;
      final backendAppointments = await ApiService.getAppointments(patientId);
      output.writeln(
          'Backend returned ${backendAppointments.length} appointments');
      output.writeln('');

      if (backendAppointments.isNotEmpty) {
        output.writeln('📋 Backend Appointments:');
        for (int i = 0; i < backendAppointments.length; i++) {
          final apt = backendAppointments[i];
          output.writeln(
              '   $i: ID="${apt['id']}", PatientID="${apt['patient_id']}", Service="${apt['service']}", Status=${apt['status']}');
        }
        output.writeln('');

        // Load into HistoryService
        _historyService.loadAppointmentsFromBackend(backendAppointments);
        output.writeln('✅ Loaded appointments into HistoryService');
      } else {
        output.writeln('⚠️ Backend returned empty list');
        // Clear local data if backend is empty
        _historyService.clearAppointmentsForPatient(patientId);
        output.writeln('✅ Cleared local appointments for patient $patientId');
      }
    } catch (e) {
      output.writeln('❌ Error loading from backend: $e');
    }

    output.writeln('=== END BACKEND LOAD ===');
    output.writeln('');

    // Run debug analysis after loading
    _runDebugAnalysis();

    setState(() {
      _debugOutput = output.toString() + _debugOutput;
      _isLoading = false;
    });
  }

  void _clearAllData() {
    _historyService.clearAllData();
    _runDebugAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Debug Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDebugAnalysis,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analysis',
          ),
          IconButton(
            onPressed: _loadFromBackend,
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Load from Backend',
          ),
          IconButton(
            onPressed: _clearAllData,
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear All Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            const Text(
              'Appointment Data Analysis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _debugOutput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Use the refresh button to re-analyze current data\n'
              '2. Use the cloud download button to load fresh data from backend\n'
              '3. Use the delete button to clear all data\n'
              '4. Check if there are any pending appointments that shouldn\'t be there\n'
              '5. Look for problematic appointments with empty values\n'
              '6. Check if there are appointments for the wrong patient',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
