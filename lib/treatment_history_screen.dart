import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/treatment_record.dart';
import 'services/history_service.dart';
import 'user_state_manager.dart';

class TreatmentHistoryScreen extends StatefulWidget {
  const TreatmentHistoryScreen({super.key});

  @override
  State<TreatmentHistoryScreen> createState() => _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState extends State<TreatmentHistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<TreatmentRecord> _treatmentRecords = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'All',
    'General Checkup',
    'Teeth Cleaning',
    'Root Canal',
    'Orthodontics',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    _loadTreatmentRecords();
  }

  void _loadTreatmentRecords() {
    setState(() => _isLoading = true);

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _treatmentRecords = _historyService.getTreatmentRecords(
          patientId: 'patient_1',
        );
        _isLoading = false;
      });
    });
  }

  void _filterTreatmentRecords(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _treatmentRecords = _historyService.getTreatmentRecords(
          patientId: 'patient_1',
        );
      } else {
        _treatmentRecords = _historyService.getTreatmentRecordsByType(
          filter,
          patientId: 'patient_1',
        );
      }
    });
  }

  Widget _buildUserStatusBanner(BuildContext context) {
    final userState = UserStateManager();

    if (userState.isGuestUser) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFE74C3C)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            const Text(
              'GUEST MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    } else if (userState.isClientLoggedIn) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, color: Colors.white, size: 12),
            const SizedBox(width: 6),
            const Text(
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
                  'Treatment History',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF0029B2),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    onPressed: _loadTreatmentRecords,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0029B2), Color(0xFF000074)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by Treatment Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final filter = _filterOptions[index];
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF0029B2),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) =>
                              _filterTreatmentRecords(filter),
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF005800),
                          checkmarkColor: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Treatment Records List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0029B2),
                      ),
                    ),
                  )
                : _treatmentRecords.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _treatmentRecords.length,
                    itemBuilder: (context, index) {
                      final record = _treatmentRecords[index];
                      return _buildTreatmentRecordCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Treatment Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your treatment history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentRecordCard(TreatmentRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF0029B2).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForTreatmentType(record.treatmentType),
            color: const Color(0xFF0029B2),
            size: 24,
          ),
        ),
        title: Text(
          record.treatmentType,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              record.description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(record.treatmentDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  record.doctorName,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        children: [
          const Divider(),
          _buildDetailSection('Procedures Performed', record.procedures),
          if (record.notes != null) ...[
            const SizedBox(height: 12),
            _buildDetailSection('Notes', [record.notes!]),
          ],
          if (record.prescription != null) ...[
            const SizedBox(height: 12),
            _buildDetailSection('Prescription', [record.prescription!]),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF0029B2))),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForTreatmentType(String treatmentType) {
    switch (treatmentType.toLowerCase()) {
      case 'general checkup':
        return Icons.medical_services;
      case 'teeth cleaning':
        return Icons.cleaning_services;
      case 'root canal':
        return Icons.healing;
      case 'orthodontics':
        return Icons.straighten;
      case 'emergency':
        return Icons.local_hospital;
      case 'preventive care':
        return Icons.shield;
      default:
        return Icons.medical_information;
    }
  }
}
