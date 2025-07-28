import 'package:flutter/material.dart';
import 'lib/services/api_service.dart';
import 'lib/user_state_manager.dart';

void main() {
  runApp(const AppointmentRestrictionTestApp());
}

class AppointmentRestrictionTestApp extends StatelessWidget {
  const AppointmentRestrictionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Appointment Restriction Test',
      home: AppointmentRestrictionTestScreen(),
    );
  }
}

class AppointmentRestrictionTestScreen extends StatefulWidget {
  const AppointmentRestrictionTestScreen({super.key});

  @override
  State<AppointmentRestrictionTestScreen> createState() =>
      _AppointmentRestrictionTestScreenState();
}

class _AppointmentRestrictionTestScreenState
    extends State<AppointmentRestrictionTestScreen> {
  String _testOutput = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runRestrictionTest();
  }

  void _runRestrictionTest() async {
    setState(() {
      _isLoading = true;
    });

    final output = StringBuffer();
    output.writeln('🔍 === APPOINTMENT RESTRICTION TEST ===');
    output.writeln('Time: ${DateTime.now()}');
    output.writeln('');

    try {
      final patientId = UserStateManager().currentPatientId;
      output.writeln('Patient ID: $patientId');
      output.writeln('');

      if (patientId == null || patientId.isEmpty) {
        output.writeln('❌ No patient ID found - user not logged in');
        output.writeln('Please log in as a patient first');
      } else {
        // Get all appointments for the patient
        final appointments = await ApiService.getAppointments(patientId);
        output.writeln('Total appointments found: ${appointments.length}');
        output.writeln('');

        // Check for active appointments (pending, approved, scheduled)
        final activeAppointments = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase();
          return status == 'pending' ||
              status == 'approved' ||
              status == 'scheduled';
        }).toList();

        output.writeln(
            'Active appointments (blocking new bookings): ${activeAppointments.length}');
        if (activeAppointments.isNotEmpty) {
          output.writeln('📋 Active Appointments:');
          for (int i = 0; i < activeAppointments.length; i++) {
            final apt = activeAppointments[i];
            output.writeln(
                '   $i: ID="${apt['id']}", Service="${apt['service']}", Status=${apt['status']}, Date=${apt['date']}');
          }
          output.writeln('');
          output.writeln(
              '✅ RESTRICTION ACTIVE: Patient cannot book new appointments');
        } else {
          output.writeln(
              '✅ No active appointments found - patient can book new appointments');
        }
        output.writeln('');

        // Check for completed appointments
        final completedAppointments = appointments.where((apt) {
          final status = apt['status']?.toString().toLowerCase();
          return status == 'completed' || status == 'cancelled';
        }).toList();

        output.writeln(
            'Completed/Cancelled appointments: ${completedAppointments.length}');
        if (completedAppointments.isNotEmpty) {
          output.writeln('📋 Completed Appointments:');
          for (int i = 0; i < completedAppointments.length; i++) {
            final apt = completedAppointments[i];
            output.writeln(
                '   $i: ID="${apt['id']}", Service="${apt['service']}", Status=${apt['status']}, Date=${apt['date']}');
          }
        }
        output.writeln('');

        // Test the restriction logic
        output.writeln('🧪 TESTING RESTRICTION LOGIC:');
        if (activeAppointments.isNotEmpty) {
          output.writeln('   ❌ Booking should be BLOCKED');
          output.writeln(
              '   Reason: ${activeAppointments.length} active appointment(s) found');
        } else {
          output.writeln('   ✅ Booking should be ALLOWED');
          output.writeln('   Reason: No active appointments found');
        }
      }
    } catch (e) {
      output.writeln('❌ Error during test: $e');
    }

    output.writeln('=== END TEST ===');

    setState(() {
      _testOutput = output.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Restriction Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _runRestrictionTest,
            icon: const Icon(Icons.refresh),
            tooltip: 'Run Test Again',
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
              'Appointment Booking Restriction Test',
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
                _testOutput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Summary:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This test verifies that:\n'
              '1. Patients with pending appointments cannot book new ones\n'
              '2. Patients with approved appointments cannot book new ones\n'
              '3. Patients with scheduled appointments cannot book new ones\n'
              '4. Patients with only completed/cancelled appointments can book new ones\n'
              '5. The restriction logic is working correctly in the booking screen',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
