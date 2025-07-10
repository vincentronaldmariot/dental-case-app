import 'package:flutter/material.dart';

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
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Select Service'),
              const SizedBox(height: 15),
              _buildServiceSelection(),
              const SizedBox(height: 30),

              _buildSectionTitle('Select Date'),
              const SizedBox(height: 15),
              _buildDateSelection(),
              const SizedBox(height: 40),

              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000074),
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
              Text(
                _getMonthYearText(selectedDate),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0029B2),
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
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointments can be booked from today up to 5 days ahead only',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          // Custom Calendar Grid
          _buildCustomCalendar(),
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

  Widget _buildCustomCalendar() {
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

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 14,
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
                  final isToday =
                      date.day == now.day &&
                      date.month == now.month &&
                      date.year == now.year;
                  final isSelected =
                      date.day == selectedDate.day &&
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
                            width: 40,
                            height: 40,
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
                                  fontSize: 16,
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
            })
            .where((row) {
              // Only show rows that have days from current month
              return true;
            })
            .take(6),
      ],
    );
  }

  Widget _buildBookButton() {
    final isFormComplete = selectedService != null;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isFormComplete ? _bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0029B2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          shadowColor: const Color(0xFF0029B2).withOpacity(0.3),
        ),
        child: const Text(
          'Book Appointment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _bookAppointment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('Appointment Booked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: $selectedService'),
            const SizedBox(height: 5),
            Text(
              'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
            ),
            const SizedBox(height: 15),
            const Text(
              'You will receive a confirmation email shortly.',
              style: TextStyle(color: Colors.grey),
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
  }
}
