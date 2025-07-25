import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  final dynamic patient;

  const AppointmentHistoryScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  State<AppointmentHistoryScreen> createState() =>
      _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  late List<dynamic> completedAppointments;
  late List<bool> expanded;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final allAppointments = (widget.patient['appointments'] as List?) ?? [];
    completedAppointments =
        allAppointments.where((a) => a['status'] == 'completed').toList();
    expanded = List.generate(completedAppointments.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: _buildHistoryScreen(context),
    );
  }

  Widget _buildHistoryScreen(BuildContext context) {
    final filteredAppointments = completedAppointments.where((appt) {
      final query = _searchQuery.toLowerCase();
      return (appt['service']?.toLowerCase().contains(query) == true) ||
          (_formatDate(appt['appointmentDate'] ?? appt['appointment_date'])
              .toLowerCase()
              .contains(query)) ||
          (appt['notes']?.toLowerCase().contains(query) == true);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Appointment History - ${widget.patient['fullName'] ?? 'Patient'}'),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
      ),
      body: completedAppointments.isEmpty
          ? Center(
              child: Text(
                'No completed appointments found.',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by service, date, or note',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredAppointments.isEmpty
                      ? Center(
                          child: Text(
                            'No completed appointments found.',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) {
                            final appt = filteredAppointments[index];
                            final expandedIndex =
                                completedAppointments.indexOf(appt);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    title: Text(
                                        appt['service'] ?? 'Unknown Service'),
                                    subtitle: Text(
                                      'Date: ' +
                                          _formatDate(appt['appointmentDate'] ??
                                              appt['appointment_date']) +
                                          '\nStatus: ${appt['status'] ?? 'N/A'}',
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(expanded[expandedIndex]
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                      onPressed: () {
                                        setState(() {
                                          expanded[expandedIndex] =
                                              !expanded[expandedIndex];
                                        });
                                      },
                                    ),
                                  ),
                                  if (expanded[expandedIndex])
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Note: ' +
                                                  (appt['notes']?.toString() ??
                                                      'No note'),
                                              style: TextStyle(
                                                  color: Colors.grey[800]),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit,
                                                size: 18),
                                            tooltip: 'Edit Note',
                                            onPressed: () {
                                              _showEditNoteDialog(
                                                  context, appt, expandedIndex);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showEditNoteDialog(BuildContext context, dynamic appt, int index) {
    final TextEditingController controller =
        TextEditingController(text: appt['notes'] ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Note'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Enter note...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newNote = controller.text.trim();
                Navigator.of(context).pop();
                try {
                  await ApiService.updateAppointmentNotesAsAdmin(
                      appt['id'].toString(), newNote);
                  setState(() {
                    completedAppointments[index]['notes'] = newNote;
                  });
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note updated successfully.')),
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Failed to update note: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
      if (dt == null) return date.toString();
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (e) {
      return date.toString();
    }
  }
}
