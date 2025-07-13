import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'models/patient.dart';
import 'models/appointment.dart';
import 'models/treatment_record.dart';
import 'models/emergency_record.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  final _searchController = TextEditingController();

  late TabController _tabController;

  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<TreatmentRecord> _treatmentRecords = [];
  List<EmergencyRecord> _emergencyRecords = [];
  Map<String, int> _dashboardStats = {};

  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final patients = await _dbService.getAllPatients();
      final appointments = await _dbService.getAppointments();
      final treatmentRecords = await _dbService.getTreatmentRecords();
      final emergencyRecords = await _dbService.getEmergencyRecords();
      final stats = await _dbService.getDashboardStats();

      setState(() {
        _patients = patients;
        _appointments = appointments;
        _treatmentRecords = treatmentRecords;
        _emergencyRecords = emergencyRecords;
        _dashboardStats = stats;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPatients(String query) async {
    setState(() => _searchQuery = query);

    if (query.isEmpty) {
      _loadData();
      return;
    }

    try {
      final searchResults = await _dbService.searchPatients(query);
      setState(() {
        _patients = searchResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Patients'),
            Tab(text: 'Appointments'),
            Tab(text: 'Treatments'),
            Tab(text: 'Emergencies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildPatientsTab(),
                _buildAppointmentsTab(),
                _buildTreatmentsTab(),
                _buildEmergenciesTab(),
              ],
            ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000074),
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Patients',
                _dashboardStats['total_patients']?.toString() ?? '0',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Scheduled Appointments',
                _dashboardStats['scheduled_appointments']?.toString() ?? '0',
                Icons.schedule,
                Colors.green,
              ),
              _buildStatCard(
                'Active Emergencies',
                _dashboardStats['active_emergencies']?.toString() ?? '0',
                Icons.emergency,
                Colors.red,
              ),
              _buildStatCard(
                "Today's Appointments",
                _dashboardStats['todays_appointments']?.toString() ?? '0',
                Icons.today,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Recent Activities
          const Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF000074),
            ),
          ),
          const SizedBox(height: 16),

          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 32),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    // Get recent patients and appointments
    final recentPatients = _patients.take(3).toList();
    final recentAppointments = _appointments.take(3).toList();

    return Column(
      children: [
        ...recentPatients.map(
          (patient) => _buildActivityCard(
            'New Patient Registered',
            patient.fullName,
            Icons.person_add,
            Colors.blue,
            patient.createdAt,
          ),
        ),
        ...recentAppointments.map(
          (appointment) => _buildActivityCard(
            'New Appointment',
            appointment.service,
            Icons.calendar_today,
            Colors.green,
            appointment.createdAt,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    DateTime time,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Text(
          _formatDateTime(time),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildPatientsTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: _searchPatients,
          ),
        ),

        // Patients List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return _buildPatientCard(patient);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF0029B2).withOpacity(0.1),
          child: Text(
            patient.firstName[0] + patient.lastName[0],
            style: const TextStyle(
              color: Color(0xFF0029B2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${patient.email}'),
            Text('Phone: ${patient.phone}'),
            if (patient.serialNumber.isNotEmpty)
              Text('Serial: ${patient.serialNumber}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientDetailRow(
                  'Classification',
                  patient.classification,
                ),
                if (patient.otherClassification.isNotEmpty)
                  _buildPatientDetailRow(
                    'Other Classification',
                    patient.otherClassification,
                  ),
                _buildPatientDetailRow(
                  'Unit Assignment',
                  patient.unitAssignment,
                ),
                _buildPatientDetailRow('Address', patient.address),
                _buildPatientDetailRow(
                  'Emergency Contact',
                  patient.emergencyContact,
                ),
                _buildPatientDetailRow(
                  'Emergency Phone',
                  patient.emergencyPhone,
                ),
                if (patient.medicalHistory.isNotEmpty)
                  _buildPatientDetailRow(
                    'Medical History',
                    patient.medicalHistory,
                  ),
                if (patient.allergies.isNotEmpty)
                  _buildPatientDetailRow('Allergies', patient.allergies),
                _buildPatientDetailRow(
                  'Registered',
                  _formatDateTime(patient.createdAt),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _viewPatientSurvey(patient),
                      icon: const Icon(Icons.assignment),
                      label: const Text('View Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0029B2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _viewPatientAppointments(patient),
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Appointments'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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

  Widget _buildPatientDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF000074),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    final pendingAppointments = _appointments
        .where((apt) => apt.status == AppointmentStatus.pending)
        .toList();
    final otherAppointments = _appointments
        .where((apt) => apt.status != AppointmentStatus.pending)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending Appointments Section
          if (pendingAppointments.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Pending Appointments (${pendingAppointments.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These appointments require review and approval',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...pendingAppointments.map(
              (appointment) => _buildPendingAppointmentCard(appointment),
            ),
            const SizedBox(height: 24),
          ],

          // Other Appointments Section
          if (otherAppointments.isNotEmpty) ...[
            const Text(
              'All Appointments',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000074),
              ),
            ),
            const SizedBox(height: 16),
            ...otherAppointments.map(
              (appointment) => _buildAppointmentCard(appointment),
            ),
          ],

          // Empty State
          if (_appointments.isEmpty) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        break;
      case AppointmentStatus.scheduled:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.red;
        break;
      case AppointmentStatus.missed:
        statusColor = Colors.orange;
        break;
      case AppointmentStatus.rescheduled:
        statusColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.service,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.displayName,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${appointment.patientId}'),
            Text('Date: ${_formatDate(appointment.date)}'),
            Text('Time: ${appointment.timeSlot}'),
            Text('Doctor: ${appointment.doctorName}'),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Text('Notes: ${appointment.notes}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAppointmentCard(Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with pending status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appointment.service,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Appointment details
              Text('Patient ID: ${appointment.patientId}'),
              Text('Date: ${_formatDate(appointment.date)}'),
              Text('Time: ${appointment.timeSlot}'),
              Text('Doctor: ${appointment.doctorName}'),

              // Survey data/notes
              if (appointment.notes != null &&
                  appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: Colors.blue.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dental Assessment:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.notes!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveAppointment(appointment),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectAppointment(appointment),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveAppointment(Appointment appointment) async {
    try {
      await _dbService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.scheduled,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(); // Reload data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAppointment(Appointment appointment) async {
    try {
      await _dbService.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelled,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rejected'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadData(); // Reload data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTreatmentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _treatmentRecords.length,
      itemBuilder: (context, index) {
        final record = _treatmentRecords[index];
        return _buildTreatmentCard(record);
      },
    );
  }

  Widget _buildTreatmentCard(TreatmentRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.treatmentType,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${record.patientId}'),
            Text('Date: ${_formatDate(record.treatmentDate)}'),
            Text('Doctor: ${record.doctorName}'),
            Text('Description: ${record.description}'),
            if (record.procedures.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Procedures:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              ...record.procedures.map(
                (procedure) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text('• $procedure'),
                ),
              ),
            ],
            if (record.prescription != null && record.prescription!.isNotEmpty)
              Text('Prescription: ${record.prescription}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergenciesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyRecords.length,
      itemBuilder: (context, index) {
        final record = _emergencyRecords[index];
        return _buildEmergencyCard(record);
      },
    );
  }

  Widget _buildEmergencyCard(EmergencyRecord record) {
    Color priorityColor;
    switch (record.priority) {
      case EmergencyPriority.immediate:
        priorityColor = Colors.red;
        break;
      case EmergencyPriority.urgent:
        priorityColor = Colors.orange;
        break;
      case EmergencyPriority.standard:
        priorityColor = Colors.blue;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.emergencyTypeDisplay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.priorityDisplay,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient ID: ${record.patientId}'),
            Text('Reported: ${_formatDateTime(record.reportedAt)}'),
            Text('Pain Level: ${record.painLevel}/10'),
            Text('Status: ${record.statusDisplay}'),
            Text('Description: ${record.description}'),
            if (record.location != null) Text('Location: ${record.location}'),
            if (record.handledBy != null)
              Text('Handled By: ${record.handledBy}'),
          ],
        ),
      ),
    );
  }

  void _viewPatientSurvey(Patient patient) async {
    try {
      final survey = await _dbService.getDentalSurvey(patient.id!);
      if (survey != null) {
        _showSurveyDialog(patient, survey);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No survey found for this patient'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading survey: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewPatientAppointments(Patient patient) async {
    try {
      final appointments = await _dbService.getAppointments(
        patientId: patient.id!,
      );
      _showAppointmentsDialog(patient, appointments);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading appointments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSurveyDialog(Patient patient, Map<String, dynamic> survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.fullName} - Survey Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Completed: ${_formatDateTime(DateTime.parse(survey['completed_at']))}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Survey Data:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(survey['survey_data'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentsDialog(
    Patient patient,
    List<Appointment> appointments,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${patient.fullName} - Appointments'),
        content: SizedBox(
          width: double.maxFinite,
          child: appointments.isEmpty
              ? const Text('No appointments found')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return ListTile(
                      title: Text(appointment.service),
                      subtitle: Text(
                        '${_formatDate(appointment.date)} - ${appointment.timeSlot}',
                      ),
                      trailing: Text(appointment.status.displayName),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
