import 'package:flutter/material.dart';
import 'lib/services/history_service.dart';
import 'lib/models/appointment.dart';
import 'lib/user_state_manager.dart';

void main() {
  runApp(const AppointmentDebugApp());
}

class AppointmentDebugApp extends StatelessWidget {
  const AppointmentDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appointment Debug',
      home: const AppointmentDebugScreen(),
    );
  }
}

class AppointmentDebugScreen extends StatefulWidget {
  const AppointmentDebugScreen({super.key});

  @override
  State<AppointmentDebugScreen> createState() => _AppointmentDebugScreenState();
}

class _AppointmentDebugScreenState extends State<AppointmentDebugScreen> {
  final HistoryService _historyService = HistoryService();
  String _debugOutput = '';

  @override
  void initState() {
    super.initState();
    _runDebugAnalysis();
  }

  void _runDebugAnalysis() {
    final patientId = UserStateManager().currentPatientId;
    final output = StringBuffer();

    output.writeln('🔍 === APPOINTMENT DEBUG ANALYSIS ===');
    output.writeln('Patient ID: $patientId');
    output.writeln('Time: ${DateTime.now()}');
    output.writeln('');

    final allAppointments =
        _historyService.getAppointments(patientId: patientId);
    output.writeln('Total appointments: ${allAppointments.length}');
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runDebugAnalysis,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analysis',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              '1. Run this debug app to see the current appointment data\n'
              '2. Check if there are any pending appointments that shouldn\'t be there\n'
              '3. Look for problematic appointments with empty values\n'
              '4. Check if there are appointments for the wrong patient\n'
              '5. Use the refresh button to re-run the analysis',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
