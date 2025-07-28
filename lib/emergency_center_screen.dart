import 'package:flutter/material.dart';
import './user_state_manager.dart';
import './models/appointment.dart';
import './models/emergency_record.dart';
import './services/history_service.dart';
import './services/emergency_service.dart';
import './emergency_pain_assessment_screen.dart';
import './admin_dashboard_screen.dart';

class EmergencyCenterScreen extends StatefulWidget {
  const EmergencyCenterScreen({super.key});

  @override
  State<EmergencyCenterScreen> createState() => _EmergencyCenterScreenState();
}

class _EmergencyCenterScreenState extends State<EmergencyCenterScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize emergency service with sample data
    EmergencyService().initializeSampleData();
  }

  Widget _buildUserStatusBanner(BuildContext context) {
    final userState = UserStateManager();

    if (userState.isClientLoggedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005800), Color(0xFF004400)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: Colors.white, size: 12),
            SizedBox(width: 6),
            Text(
              'AUTHENTICATED USER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Column(
          children: [
            _buildUserStatusBanner(context),
            Expanded(
              child: AppBar(
                title: const Text(
                  'Emergency Dental Center',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFFE74C3C),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Color(0xFFE74C3C),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AFPHSAC Emergency',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Immediate dental emergency assistance',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Emergency Actions Grid
            const Text(
              'Emergency Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildEmergencyCard(
                    'Emergency Booking',
                    Icons.calendar_today,
                    const Color(0xFFFF6B35),
                    'Schedule urgent care',
                    () => _showEmergencyBooking(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEmergencyCard(
                    'Pain Assessment',
                    Icons.assignment_outlined,
                    const Color(0xFF9B59B6),
                    'Evaluate emergency level',
                    () => _showPainAssessment(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEmergencyCard(
                    'First Aid Guide',
                    Icons.medical_services,
                    const Color(0xFF3498DB),
                    'Emergency instructions',
                    () => _showFirstAidGuide(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Emergency Instructions
            const Text(
              'Quick Emergency Instructions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            _buildInstructionCard(
              'Severe Tooth Pain',
              'Take prescribed pain medication, rinse with warm salt water, apply cold compress to outside of mouth.',
              Icons.sentiment_very_dissatisfied,
              const Color(0xFFE74C3C),
            ),
            _buildInstructionCard(
              'Knocked-Out Tooth',
              'Handle by crown only, rinse gently, try to reinsert. If not possible, keep in milk and seek immediate care.',
              Icons.warning,
              const Color(0xFFFF6B35),
            ),
            _buildInstructionCard(
              'Broken/Chipped Tooth',
              'Save fragments, rinse mouth with warm water, apply cold compress, cover sharp edges with dental wax.',
              Icons.broken_image,
              const Color(0xFF9B59B6),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard(
    String title,
    String instruction,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  instruction,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyBooking(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Text('Emergency Appointment'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency appointments are prioritized and scheduled within 2-4 hours.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Required Information:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('• Nature of emergency'),
            Text('• Pain level (1-10)'),
            Text('• Service member ID'),
            Text('• Contact number'),
            Text('• Current location'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bookEmergencyAppointment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Book Emergency'),
          ),
        ],
      ),
    );
  }

  void _showPainAssessment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: Colors.purple[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Pain Assessment'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Level Guide:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              '🔴 IMMEDIATE (Call now):',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
            ),
            Text('• Severe facial swelling'),
            Text('• Difficulty swallowing/breathing'),
            Text('• Trauma with bleeding'),
            SizedBox(height: 8),
            Text(
              '🟡 URGENT (Within 2-4 hours):',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            Text('• Severe tooth pain'),
            Text('• Lost filling/crown'),
            Text('• Broken tooth'),
            SizedBox(height: 8),
            Text(
              '🟢 NON-URGENT (Next day):',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            Text('• Mild discomfort'),
            Text('• Food stuck in teeth'),
            Text('• Minor sensitivity'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startPainAssessment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Assessment'),
          ),
        ],
      ),
    );
  }

  void _showFirstAidGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Colors.blue[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dental First Aid Guide',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildFirstAidItem(
                      'Toothache',
                      '1. Rinse with warm salt water\n2. Use dental floss to remove debris\n3. Apply cold compress outside mouth\n4. Take pain medication as directed\n5. Avoid hot/cold foods',
                    ),
                    _buildFirstAidItem(
                      'Knocked-Out Tooth',
                      '1. Handle by crown only (not root)\n2. Rinse gently if dirty\n3. Try to reinsert immediately\n4. If not possible, store in milk\n5. Seek emergency care within 30 min',
                    ),
                    _buildFirstAidItem(
                      'Broken/Cracked Tooth',
                      '1. Save any pieces\n2. Rinse mouth with warm water\n3. Apply cold compress\n4. Cover sharp edges with wax\n5. Avoid chewing on that side',
                    ),
                    _buildFirstAidItem(
                      'Lost Filling/Crown',
                      '1. Keep the crown/filling if possible\n2. Clean the area gently\n3. Use temporary dental cement\n4. Avoid sticky/hard foods\n5. Schedule appointment ASAP',
                    ),
                    _buildFirstAidItem(
                      'Abscess/Swelling',
                      '1. Rinse with salt water\n2. Apply cold compress\n3. Take prescribed antibiotics\n4. Do NOT apply heat\n5. Seek immediate care if severe',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Close Guide'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstAidItem(String title, String instructions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(instructions, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _bookEmergencyAppointment() async {
    try {
      final now = DateTime.now();

      // Create emergency record with current timestamp (when reported)
      final emergencyRecord = EmergencyRecord(
        id: 'emr_${now.millisecondsSinceEpoch}',
        patientId: UserStateManager().currentPatientId,
        reportedAt: now, // When the emergency was reported
        type: EmergencyType
            .severeToothache, // Default type, can be enhanced later
        priority: EmergencyPriority.urgent,
        status: EmergencyStatus.reported,
        description: 'Emergency booking requested by patient',
        painLevel: 7, // Default pain level
        symptoms: ['Emergency booking'],
        location: 'Mobile App',
        dutyRelated: false,
        emergencyContact: UserStateManager().currentPatient?.phone ?? 'N/A',
        notes: 'Emergency appointment requested through mobile app',
      );

      // Add emergency record to service (now uses API)
      await EmergencyService().addEmergencyRecord(emergencyRecord);

      // Create emergency appointment scheduled for 2-4 hours later
      final emergency = Appointment(
        id: 'emergency_${now.millisecondsSinceEpoch}',
        patientId: UserStateManager().currentPatientId,
        service: 'Emergency Treatment',
        date: now.add(const Duration(hours: 2)), // Schedule for 2 hours later
        timeSlot: 'Emergency Slot',
        status: AppointmentStatus.scheduled,
        notes: 'Emergency appointment - Priority scheduling',
      );

      HistoryService().addAppointment(emergency);

      // Check if current user is an admin
      final userState = UserStateManager();
      final isAdmin = userState.isAdminLoggedIn;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAdmin
                ? 'Emergency booking submitted! Redirecting to admin dashboard...'
                : 'Emergency booking submitted successfully! We will contact you shortly.',
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
        ),
      );

      // Only navigate to admin dashboard if user is an admin
      if (isAdmin) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(
                  initialTabIndex: 4), // Emergencies tab
            ),
            (Route<dynamic> route) => false,
          );
        });
      }
    } catch (error) {
      // Show error message if emergency booking fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emergency booking failed: ${error.toString()}'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _startPainAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyPainAssessmentScreen(),
      ),
    );
  }
}
