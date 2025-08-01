import 'package:flutter/material.dart';
import 'services/appointment_service.dart';
import 'services/patient_limit_service.dart';
import 'services/api_service.dart';
import 'services/survey_service.dart';
import 'services/history_service.dart';
import 'models/appointment.dart';
import 'user_state_manager.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen>
    with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  String? selectedService;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Patient information now comes from self-assessment survey

  final AppointmentService _appointmentService = AppointmentService();
  final PatientLimitService _patientLimitService = PatientLimitService();
  // Database service is now handled by ApiService static methods

  bool _isLoading = false;
  bool _isLoadingSurvey = false;
  Map<String, dynamic>? _surveyData;
  List<dynamic> _existingAppointments = [];
  bool _hasExistingAppointments = false;
  late AnimationController _warningController;
  late Animation<double> _warningAnimation;

  final List<String> services = [
    'General Checkup',
    'Teeth Cleaning',
    'Orthodontics',
    'Cosmetic Dentistry',
    'Root Canal',
    'Tooth Extraction',
    'Dental Implants',
    'Teeth Whitening',
  ];

  @override
  void initState() {
    super.initState();
    _appointmentService.initializeSampleData();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Warning animation controller
    _warningController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _warningAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _warningController, curve: Curves.elasticOut),
    );

    _loadSurveyData();
    _checkExistingAppointments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh existing appointments check when screen becomes active
    _checkExistingAppointments();
  }

  void _loadSurveyData() async {
    setState(() {
      _isLoadingSurvey = true;
    });

    try {
      // Use authenticated patient ID
      final patientId = UserStateManager().currentPatientId;

      print('Attempting to load survey data for patient ID $patientId');

      // Load survey data for authenticated patient using SurveyService
      final surveyService = SurveyService();
      final result = await surveyService.getSurveyData();

      if (result['success']) {
        final survey = result['survey'];
        // Handle both possible data structures
        final surveyData = survey['surveyData'] ?? survey['survey_data'];

        setState(() {
          _surveyData = surveyData;
        });

        print('Survey data loaded successfully: ${_surveyData?.keys}');
        final patientInfo = _surveyData?['patient_info'] ?? {};
        print('Patient name: ${patientInfo['name']}');
        // Update UserStateManager to reflect survey completion
        UserStateManager().updateSurveyStatus(true);
      } else if (result['notFound'] == true) {
        print(
          'No survey data found for patient ID $patientId - user needs to complete survey first',
        );
        // Update UserStateManager to reflect no survey
        UserStateManager().updateSurveyStatus(false);
        setState(() {
          _surveyData = null;
        });
      } else {
        print('Error loading survey data: ${result['message']}');
        // Show error message to user if it's not a "not found" case
        if (!result['notFound']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading survey: ${result['message']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _surveyData = null;
        });
      }
    } catch (e) {
      print('Error loading survey data: $e');
      print('Database may not be properly initialized or survey not saved');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load survey data. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      // Set survey data to null if there's an error
      setState(() {
        _surveyData = null;
      });
    } finally {
      setState(() {
        _isLoadingSurvey = false;
      });
    }
  }

  void _checkExistingAppointments() async {
    try {
      final patientId = UserStateManager().currentPatientId;
      if (patientId == null || patientId.isEmpty) {
        return;
      }

      // Get existing appointments for the patient
      final appointments = await ApiService.getAppointments(patientId);

      // Filter for pending, approved, or scheduled appointments
      final activeAppointments = appointments.where((apt) {
        final status = apt['status']?.toString().toLowerCase();
        print(
            'Checking appointment status: $status for appointment ${apt['id']}');
        // Check for pending, approved, or scheduled appointments
        return status == 'pending' ||
            status == 'approved' ||
            status == 'scheduled';
      }).toList();

      // Also check for completed appointments to show history
      final completedAppointments = appointments.where((apt) {
        final status = apt['status']?.toString().toLowerCase();
        return status == 'completed' || status == 'cancelled';
      }).toList();

      setState(() {
        _existingAppointments = activeAppointments;
        _hasExistingAppointments = activeAppointments.isNotEmpty;
      });

      print(
          'Found ${activeAppointments.length} active appointments for patient $patientId');
      print(
          'Found ${completedAppointments.length} completed appointments for patient $patientId');
      print('_hasExistingAppointments set to: $_hasExistingAppointments');
      print('_existingAppointments length: ${_existingAppointments.length}');

      // Trigger warning animation if appointments found
      if (activeAppointments.isNotEmpty) {
        _warningController.forward();
      }
    } catch (e) {
      print('Error checking existing appointments: $e');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _warningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0029B2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _checkExistingAppointments,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh appointment status',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0029B2).withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 16 : 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show survey status warning if needed
              if (_surveyData == null && !_isLoadingSurvey)
                _buildSurveyWarning(),

              // Show existing appointments warning if needed
              if (_hasExistingAppointments) ...[
                Builder(
                  builder: (context) {
                    print(
                        'Building existing appointments warning - has appointments: $_hasExistingAppointments');
                    return _buildExistingAppointmentsWarning();
                  },
                ),
              ],

              // Show loading indicator while survey is being loaded
              if (_isLoadingSurvey) _buildSurveyLoading(),

              _buildSectionTitle('Select Service'),
              const SizedBox(height: 15),
              _buildServiceSelection(),
              const SizedBox(height: 30),

              _buildSectionTitle('Select Date'),
              const SizedBox(height: 15),
              _buildDateSelection(),
              const SizedBox(height: 20),

              const SizedBox(height: 40),

              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyLoading() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Loading survey data...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyWarning() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber,
                  color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Survey Required',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete the dental self-assessment survey before booking an appointment. This helps us provide better care.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to survey screen
                Navigator.pushNamed(context, '/survey');
              },
              icon: const Icon(Icons.assignment, size: 18),
              label: const Text('Complete Survey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingAppointmentsWarning() {
    return AnimatedBuilder(
      animation: _warningAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _warningAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2 * _warningAnimation.value),
                  blurRadius: 10 * _warningAnimation.value,
                  offset: Offset(0, 4 * _warningAnimation.value),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.block, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Existing Appointments Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You have ${_existingAppointments.length} pending, approved, or scheduled appointment(s) that need to be completed before booking a new one.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                if (_existingAppointments.isNotEmpty) ...[
                  const Text(
                    'Your active appointments:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showExistingAppointmentsDetails,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to view details (${_existingAppointments.length} appointment(s))',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_forward_ios,
                              color: Colors.red.shade700, size: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._existingAppointments
                      .map((apt) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apt['service'] ?? 'Unknown Service',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${_formatDate(apt['appointment_date'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  'Status: ${(apt['status'] ?? 'Unknown').toString().toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: apt['status'] == 'pending'
                                        ? Colors.orange
                                        : Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF000074),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: selectedService,
        decoration: const InputDecoration(
          hintText: 'Select a service',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: services.map((service) {
          return DropdownMenuItem<String>(value: service, child: Text(service));
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedService = value;
          });
        },
      ),
    );
  }

  Widget _buildDateSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getMonthYearText(selectedDate),
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0029B2),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month - 1,
                          1,
                        );
                      });
                    },
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Color(0xFF0029B2),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month + 1,
                          1,
                        );
                      });
                    },
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF0029B2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Booking policy notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointments can be booked from today up to 5 days ahead only',
                    style: TextStyle(
                      fontSize:
                          MediaQuery.of(context).size.width < 400 ? 11 : 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Custom Calendar Grid with proper constraints
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildCustomCalendar(constraints.maxWidth);
            },
          ),
        ],
      ),
    );
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCustomCalendar([double? maxWidth]) {
    final now = DateTime.now();
    final maxBookingDate = now.add(
      const Duration(days: 5),
    ); // 5 days ahead maximum
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDayOfMonth = DateTime(
      selectedDate.year,
      selectedDate.month + 1,
      0,
    );
    final startDate = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday % 7),
    );

    // Calculate responsive cell size based on available width
    final availableWidth = (maxWidth ?? MediaQuery.of(context).size.width) -
        32; // Account for padding
    final cellSize = (availableWidth / 7) - 4; // 7 days per week, minus margins
    final fontSize =
        availableWidth < 400 ? 14.0 : 16.0; // Smaller font for small screens

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: availableWidth,
        child: Column(
          children: [
            // Weekday headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: fontSize - 2,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            // Calendar days
            ...List.generate(6, (weekIndex) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final date = startDate.add(
                    Duration(days: weekIndex * 7 + dayIndex),
                  );
                  final isCurrentMonth = date.month == selectedDate.month;
                  final isToday = date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  final isSelected = date.day == selectedDate.day &&
                      date.month == selectedDate.month &&
                      date.year == selectedDate.year;
                  final isPast = date.isBefore(now) && !isToday;
                  final isTooFar = date.isAfter(maxBookingDate);
                  final isBookable = isCurrentMonth && !isPast && !isTooFar;

                  return GestureDetector(
                    onTap: !isBookable
                        ? () {
                            // Shake animation for restricted dates
                            _shakeController.forward().then((_) {
                              _shakeController.reverse();
                            });
                          }
                        : () {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                    child: AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: !isBookable
                              ? Offset(
                                  (_shakeAnimation.value *
                                      10 *
                                      (0.5 - (_shakeAnimation.value * 0.5))),
                                  0,
                                )
                              : Offset.zero,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0029B2)
                                  : isToday
                                      ? const Color(0xFF0029B2).withOpacity(0.1)
                                      : isTooFar
                                          ? Colors.red.withOpacity(0.1)
                                          : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                8,
                              ), // Square with rounded corners
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: const Color(0xFF0029B2),
                                      width: 2,
                                    )
                                  : isTooFar && !isSelected
                                      ? Border.all(color: Colors.red, width: 1)
                                      : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0029B2,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isPast
                                          ? Colors.grey.shade400
                                          : isTooFar
                                              ? Colors.red.shade600
                                              : isCurrentMonth
                                                  ? Colors.black87
                                                  : Colors.grey.shade300,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: fontSize,
                                ),
                                child: Text(date.day.toString()),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              );
            }).where((row) {
              // Only show rows that have days from current month
              return true;
            }).take(6),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    final isFormComplete = selectedService != null;
    final dailyLimit = _patientLimitService.getDailyLimit(selectedDate);
    final canBook = isFormComplete &&
        !dailyLimit.isAtLimit &&
        !_isLoading &&
        !_hasExistingAppointments;

    print('Book button debug:');
    print('  isFormComplete: $isFormComplete');
    print('  dailyLimit.isAtLimit: ${dailyLimit.isAtLimit}');
    print('  _isLoading: $_isLoading');
    print('  _hasExistingAppointments: $_hasExistingAppointments');
    print('  canBook: $canBook');

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.width < 600 ? 48 : 55,
      child: ElevatedButton(
        onPressed: canBook ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0029B2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: const Color(0xFF0029B2).withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Text(
                _hasExistingAppointments
                    ? 'Complete Existing Appointments First'
                    : dailyLimit.isAtLimit
                        ? 'Fully Booked'
                        : 'Book Appointment',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _bookAppointment() async {
    setState(() => _isLoading = true);

    try {
      // Check if user is logged in as a patient
      if (!UserStateManager().isPatientLoggedIn) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.login, color: Colors.orange, size: 30),
                SizedBox(width: 10),
                Text('Login Required'),
              ],
            ),
            content: const Text(
              'Please log in or register as a patient to book an appointment.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Check if survey data exists
      if (_surveyData == null) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.assignment, color: Colors.orange, size: 30),
                SizedBox(width: 10),
                Text('Complete Survey'),
              ],
            ),
            content: const Text(
              'Please complete the dental self-assessment survey before booking an appointment.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Check if patient has existing appointments
      if (_hasExistingAppointments) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Existing Appointments'),
              ],
            ),
            content: const Text(
              'You have pending, approved, or scheduled appointments that need to be completed before booking a new one. Please complete your existing appointments first.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // Get patient information from authenticated user and survey data
      String patientName = UserStateManager().patientFullName;
      String patientEmail = UserStateManager().patientEmail;
      String patientPhone = '000-000-0000';
      String surveyNotes = '';

      if (_surveyData != null) {
        // Handle both possible data structures
        final surveyData = _surveyData!;
        final patientInfo = surveyData['patient_info'] ?? {};
        patientPhone = patientInfo['contact_number'] ?? '000-000-0000';

        // Create survey summary for notes
        surveyNotes = _createSurveySummary(surveyData);
      }

      final result = await _appointmentService.bookAppointmentWithSurvey(
        service: selectedService!,
        date: selectedDate,
        patientName: patientName,
        patientEmail: patientEmail,
        patientPhone: patientPhone,
        surveyData: _surveyData,
        surveyNotes: surveyNotes,
        preferredTimeSlot: null, // No time slot selected by patient
        patientId: UserStateManager().currentPatientId,
      );

      setState(() => _isLoading = false);

      if (result.success) {
        // Add the booked appointment to HistoryService for immediate display
        final bookedAppointment = Appointment(
          id: result.appointmentId ??
              'temp_${DateTime.now().millisecondsSinceEpoch}',
          patientId: UserStateManager().currentPatientId ?? '',
          service: selectedService!,

          date: selectedDate,
          timeSlot: '', // Will be assigned by admin
          status: AppointmentStatus.pending,
          notes: surveyNotes,
        );
        HistoryService().addAppointment(bookedAppointment);

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('Appointment Request Submitted!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your appointment request has been submitted for review.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pending Review',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your appointment will be reviewed by our medical staff along with your dental assessment survey. You will receive a confirmation email once approved.',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text('Booking Failed'),
              ],
            ),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF0029B2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text(
            'An unexpected error occurred. Please try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _createSurveySummary(Map<String, dynamic> surveyData) {
    List<String> conditions = [];

    // Tooth conditions
    final toothConditions = surveyData['tooth_conditions'] ?? {};
    if (toothConditions['decayed_tooth'] == true) {
      conditions.add('Decayed tooth');
    }
    if (toothConditions['worn_down_tooth'] == true) {
      conditions.add('Worn down tooth');
    }
    if (toothConditions['impacted_tooth'] == true) {
      conditions.add('Impacted wisdom tooth');
    }

    // Tartar level
    final tartarLevel = surveyData['tartar_level'];
    if (tartarLevel != null && tartarLevel != 'tartar_none') {
      conditions.add('Tartar: ${tartarLevel.replaceAll('tartar_', '')}');
    }

    // Tooth sensitivity
    if (surveyData['tooth_sensitive'] == true) {
      conditions.add('Tooth sensitivity');
    }

    // Damaged fillings
    final damagedFillings = surveyData['damaged_fillings'] ?? {};
    if (damagedFillings['broken_tooth'] == true) {
      conditions.add('Broken tooth filling');
    }
    if (damagedFillings['broken_pasta'] == true) {
      conditions.add('Broken pasta filling');
    }

    // Dentures and missing teeth
    if (surveyData['need_dentures'] == true) conditions.add('Needs dentures');
    if (surveyData['has_missing_teeth'] == true) {
      conditions.add('Has missing teeth');
    }

    return conditions.isEmpty
        ? 'No specific conditions reported'
        : conditions.join(', ');
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _showExistingAppointmentsDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.red, size: 30),
            SizedBox(width: 10),
            Text('Active Appointments'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have the following active appointments that need to be completed:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...(_existingAppointments
                .map((apt) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getStatusIcon(apt['status']),
                                color: _getStatusColor(apt['status']),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${_getStatusText(apt['status'])}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(apt['status']),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Service: ${apt['service'] ?? 'N/A'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Date: ${_formatDate(apt['date'])}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (apt['timeSlot'] != null &&
                              apt['timeSlot'].toString().isNotEmpty)
                            Text(
                              'Time: ${apt['timeSlot']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ))
                .toList()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Please complete these appointments before booking a new one. Contact the clinic if you need to reschedule.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF0029B2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.event;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'scheduled':
        return 'Scheduled';
      default:
        return 'Unknown';
    }
  }
}
