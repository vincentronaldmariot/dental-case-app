import 'package:flutter/material.dart';
import 'models/patient.dart';
import 'services/appointment_service.dart';

class AppointmentSchedulingScreen extends StatefulWidget {
  final Patient patient;
  final List<String> treatmentPlan;

  const AppointmentSchedulingScreen({
    super.key,
    required this.patient,
    required this.treatmentPlan,
  });

  @override
  State<AppointmentSchedulingScreen> createState() =>
      _AppointmentSchedulingScreenState();
}

class _AppointmentSchedulingScreenState
    extends State<AppointmentSchedulingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '';
  String _selectedService = 'General Checkup';
  bool _isLoading = false;

  final List<String> _services = [
    'General Checkup',
    'Dental Cleaning',
    'Cavity Treatment',
    'Root Canal',
    'Tooth Extraction',
    'Orthodontics',
    'Dental Implants',
    'Follow-up Examination',
  ];

  @override
  void initState() {
    super.initState();
    _loadAvailableTimeSlots();
  }

  void _loadAvailableTimeSlots() {
    final appointments = _appointmentService.getAppointmentsForDate(
      _selectedDate,
    );
    final bookedSlots = appointments.map((apt) => apt.timeSlot).toSet();

    // Find first available slot
    String? firstAvailable;
    for (final slot in _appointmentService.timeSlots) {
      if (!bookedSlots.contains(slot)) {
        firstAvailable = slot;
        break;
      }
    }

    // Update selected time slot only if we found an available slot
    if (mounted) {
      setState(() {
        _selectedTimeSlot = firstAvailable ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Schedule Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Information Card
            _buildPatientInfoCard(),
            const SizedBox(height: 20),

            // Treatment Plan Card
            _buildTreatmentPlanCard(),
            const SizedBox(height: 20),

            // Appointment Details Card
            _buildAppointmentDetailsCard(),
            const SizedBox(height: 30),

            // Schedule Button
            _buildScheduleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard() {
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
              CircleAvatar(
                backgroundColor: const Color(0xFF0029B2).withOpacity(0.1),
                child: Text(
                  widget.patient.firstName[0] + widget.patient.lastName[0],
                  style: const TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patient.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.patient.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInfoRow('Serial Number:', widget.patient.serialNumber),
          _buildInfoRow('Unit Assignment:', widget.patient.unitAssignment),
          _buildInfoRow('Phone:', widget.patient.phone),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlanCard() {
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
              Icon(Icons.medical_services, color: Colors.green[600]),
              const SizedBox(width: 10),
              const Text(
                'Recommended Treatment Plan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...widget.treatmentPlan.map(
            (treatment) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(treatment)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetailsCard() {
    final appointments = _appointmentService.getAppointmentsForDate(
      _selectedDate,
    );
    final availableSlots = _appointmentService.timeSlots
        .where((slot) => !appointments.any((apt) => apt.timeSlot == slot))
        .toList();

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
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0029B2),
            ),
          ),
          const SizedBox(height: 20),

          // Service Selection
          _buildDropdownField(
            label: 'Service Type',
            value: _selectedService,
            items: _services,
            onChanged: (value) {
              setState(() {
                _selectedService = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Date Selection
          _buildDateSelector(appointments.length),
          const SizedBox(height: 20),

          // Time Slot Selection
          if (availableSlots.isNotEmpty)
            _buildTimeSlotSelector(availableSlots)
          else
            _buildNoSlotsAvailable(),
        ],
      ),
    );
  }

  Widget _buildDateSelector(int appointmentCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointment Date',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600]),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDisplayDate(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$appointmentCount/100 slots booked',
                      style: TextStyle(
                        fontSize: 12,
                        color: appointmentCount >= 90
                            ? Colors.red
                            : appointmentCount >= 80
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _selectDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0029B2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelector(List<String> availableSlots) {
    final appointments = _appointmentService.getAppointmentsForDate(
      _selectedDate,
    );
    final bookedSlots = appointments.map((apt) => apt.timeSlot).toSet();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Time Slot Management',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCustomTimeDialog,
                icon: const Icon(Icons.add_alarm, size: 18),
                label: const Text('Custom Time'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Time slot status info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _buildTimeStatusIndicator(
                  'Available',
                  Colors.green,
                  availableSlots.length,
                ),
                const SizedBox(width: 20),
                _buildTimeStatusIndicator(
                  'Booked',
                  Colors.red,
                  bookedSlots.length,
                ),
                const SizedBox(width: 20),
                _buildTimeStatusIndicator(
                  'Total',
                  Colors.blue,
                  _appointmentService.timeSlots.length,
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          const Text(
            'Select Appointment Time:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),

          // Current time selection display
          if (_selectedTimeSlot.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'Selected Time: $_selectedTimeSlot',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedTimeSlot = '';
                      });
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedTimeSlot.isEmpty) ...[
            // Available time slots grid - Mobile responsive
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio:
                    MediaQuery.of(context).size.width > 600 ? 2.5 : 2.2,
              ),
              itemCount: _appointmentService.timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _appointmentService.timeSlots[index];
                final isBooked = bookedSlots.contains(slot);
                final isAvailable = !isBooked;

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedTimeSlot = slot;
                          });
                        }
                      : () {
                          _showBookedSlotDialog(slot);
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isBooked
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 11
                                : 10,
                            fontWeight: FontWeight.bold,
                            color: isBooked
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isBooked ? Icons.block : Icons.check_circle,
                          size: 14,
                          color: isBooked
                              ? Colors.red.shade600
                              : Colors.green.shade600,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            // Legend - Mobile responsive
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildTimeLegend(Colors.green, 'Available - Click to select'),
                _buildTimeLegend(Colors.red, 'Booked - Click for details'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeStatusIndicator(
    String label,
    MaterialColor color,
    int count,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color[700],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLegend(MaterialColor color, String description) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color[100],
            border: Border.all(color: color[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            color == Colors.green ? Icons.check_circle : Icons.block,
            size: 12,
            color: color[600],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          description,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNoSlotsAvailable() {
    return Column(
      children: [
        // No slots available info
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.event_busy, color: Colors.red.shade600, size: 48),
              const SizedBox(height: 10),
              Text(
                'No Standard Slots Available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'All standard time slots for this date are fully booked.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade600),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Choose Different Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Manual time scheduling option
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200, width: 2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orange.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Admin Override Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0029B2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Current selected time display
              if (_selectedTimeSlot.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Text(
                        'Selected Time: $_selectedTimeSlot',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTimeSlot = '';
                          });
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Change'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedTimeSlot.isEmpty) ...[
                // Manual time input options
                Text(
                  'As an admin, you can schedule appointments at custom times:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Manual time selection buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCustomTimeDialog,
                        icon: const Icon(Icons.access_time, size: 20),
                        label: const Text('Set Custom Time'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showQuickTimeOptions,
                        icon: const Icon(Icons.schedule, size: 20),
                        label: const Text('Quick Times'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Emergency scheduling option
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Emergency Override',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For urgent cases, you can override existing appointments or schedule outside normal hours.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _showEmergencyTimeOptions,
                        icon: const Icon(Icons.emergency, size: 18),
                        label: const Text('Emergency Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildScheduleButton() {
    final canSchedule = _selectedTimeSlot.isNotEmpty && !_isLoading;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: canSchedule
              ? [const Color(0xFF0029B2), const Color(0xFF000074)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canSchedule ? _scheduleAppointment : null,
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Schedule Appointment',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF0029B2)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = '';
      });
      _loadAvailableTimeSlots();
    }
  }

  Future<void> _scheduleAppointment() async {
    if (_selectedTimeSlot.isEmpty) {
      _showErrorDialog('Please select a time slot before scheduling.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _appointmentService.bookAppointment(
        service: _selectedService,
        date: _selectedDate,
        patientName: widget.patient.fullName,
        patientEmail: widget.patient.email,
        patientPhone: widget.patient.phone,
        preferredTimeSlot: _selectedTimeSlot,
      );

      if (mounted) {
        if (result.success) {
          _showSuccessDialog();
        } else {
          _showErrorDialog(result.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to schedule appointment: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 64),
              const SizedBox(height: 16),
              const Text(
                'Appointment Scheduled!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Appointment for ${widget.patient.fullName} has been successfully scheduled for ${_formatDisplayDate(_selectedDate)} at $_selectedTimeSlot.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0029B2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red[600]),
              const SizedBox(width: 10),
              const Text('Scheduling Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
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

  void _showCustomTimeDialog() {
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.add_alarm, color: Colors.orange[600]),
              const SizedBox(width: 10),
              const Text('Custom Time Slot'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a custom time for this appointment:'),
              const SizedBox(height: 15),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g., 02:45 PM)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    final formattedTime = pickedTime.format(context);
                    timeController.text = formattedTime;
                  }
                },
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (timeController.text.isNotEmpty) {
                  setState(() {
                    _selectedTimeSlot = timeController.text;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Custom time "${timeController.text}" selected',
                      ),
                      backgroundColor: Colors.orange[600],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Set Time'),
            ),
          ],
        );
      },
    );
  }

  void _showBookedSlotDialog(String timeSlot) {
    final appointments = _appointmentService.getAppointmentsForDate(
      _selectedDate,
    );
    final appointment = appointments.firstWhere(
      (apt) => apt.timeSlot == timeSlot,
      orElse: () => appointments.first,
    );
    final patient = _appointmentService.getPatientById(
      appointment.patientId.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.red[600]),
              const SizedBox(width: 10),
              Text('Time Slot: $timeSlot'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This time slot is already booked:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (patient != null) ...[
                Text('Patient: ${patient.fullName}'),
                Text('Service: ${appointment.service}'),
                Text('Doctor: ${appointment.doctorName}'),
              ] else ...[
                const Text('Patient information not available'),
              ],
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Text(
                  'Admin Override: You can still schedule at this time if needed for emergency cases.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedTimeSlot = timeSlot;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Override: Selected booked time slot $timeSlot',
                    ),
                    backgroundColor: Colors.orange[600],
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Override & Use'),
            ),
          ],
        );
      },
    );
  }

  void _showQuickTimeOptions() {
    final quickTimes = [
      '07:00 AM', '07:30 AM', // Early morning
      '12:00 PM', '12:30 PM', // Lunch time
      '06:00 PM', '06:30 PM', '07:00 PM', // Evening
      '08:00 PM', '08:30 PM', // Extended hours
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange[600]),
              const SizedBox(width: 10),
              const Text('Quick Time Options'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select from commonly used appointment times:'),
              const SizedBox(height: 15),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: quickTimes.length,
                  itemBuilder: (context, index) {
                    final time = quickTimes[index];
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTimeSlot = time;
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Quick time "$time" selected'),
                            backgroundColor: Colors.orange[600],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[100],
                        foregroundColor: Colors.orange[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyTimeOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red[600]),
              const SizedBox(width: 10),
              const Text('Emergency Scheduling'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Emergency scheduling options for urgent dental care:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Emergency time options
              SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: [
                    _buildEmergencyTimeButton('ASAP - Next Available', 'ASAP'),
                    const SizedBox(height: 10),
                    _buildEmergencyTimeButton(
                      'Early Morning (6:00 AM)',
                      '06:00 AM',
                    ),
                    const SizedBox(height: 10),
                    _buildEmergencyTimeButton(
                      'Late Evening (9:00 PM)',
                      '09:00 PM',
                    ),
                    const SizedBox(height: 10),
                    _buildEmergencyTimeButton(
                      'Override Existing (Admin Only)',
                      'OVERRIDE',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Text(
                  'Warning: Emergency scheduling should only be used for urgent dental emergencies.',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyTimeButton(String label, String timeValue) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          String selectedTime = timeValue;
          if (timeValue == 'ASAP') {
            selectedTime =
                'ASAP - ${DateTime.now().add(Duration(minutes: 30)).hour.toString().padLeft(2, '0')}:${DateTime.now().add(Duration(minutes: 30)).minute.toString().padLeft(2, '0')}';
          } else if (timeValue == 'OVERRIDE') {
            selectedTime =
                'ADMIN OVERRIDE - ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
          }

          setState(() {
            _selectedTimeSlot = selectedTime;
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Emergency time "$selectedTime" scheduled'),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 3),
            ),
          );
        },
        icon: Icon(
          timeValue == 'ASAP'
              ? Icons.flash_on
              : timeValue == 'OVERRIDE'
                  ? Icons.admin_panel_settings
                  : Icons.schedule,
          size: 18,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
