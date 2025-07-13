class DailyPatientLimit {
  final String date;
  final int currentCount;
  final int maxLimit;

  DailyPatientLimit({
    required this.date,
    required this.currentCount,
    this.maxLimit = 100,
  });

  bool get isAtLimit => currentCount >= maxLimit;
  bool get isNearLimit => currentCount >= (maxLimit * 0.9); // 90% threshold
  int get remainingSlots => maxLimit - currentCount;

  DailyPatientLimit copyWith({String? date, int? currentCount, int? maxLimit}) {
    return DailyPatientLimit(
      date: date ?? this.date,
      currentCount: currentCount ?? this.currentCount,
      maxLimit: maxLimit ?? this.maxLimit,
    );
  }
}

class PatientLimitService {
  static final PatientLimitService _instance = PatientLimitService._internal();
  factory PatientLimitService() => _instance;
  PatientLimitService._internal();

  // Map to store daily patient counts by date (YYYY-MM-DD format)
  final Map<String, DailyPatientLimit> _dailyLimits = {};

  // Maximum patients per day
  static const int maxPatientsPerDay = 100;

  // Initialize with some sample data
  void initializeSampleData() {
    // Clear all daily limits since we removed sample appointments
    _dailyLimits.clear();

    // Start fresh with no appointments - limits will be created as needed
  }

  // Get daily limit for a specific date
  DailyPatientLimit getDailyLimit(DateTime date) {
    final dateStr = _formatDate(date);
    return _dailyLimits[dateStr] ??
        DailyPatientLimit(date: dateStr, currentCount: 0);
  }

  // Get today's limit
  DailyPatientLimit getTodayLimit() {
    return getDailyLimit(DateTime.now());
  }

  // Check if can add patient for specific date
  bool canAddPatient(DateTime date) {
    final limit = getDailyLimit(date);
    return !limit.isAtLimit;
  }

  // Add a patient for specific date
  bool addPatient(DateTime date) {
    if (!canAddPatient(date)) {
      return false; // Cannot add, at limit
    }

    final dateStr = _formatDate(date);
    final currentLimit = getDailyLimit(date);
    _dailyLimits[dateStr] = currentLimit.copyWith(
      currentCount: currentLimit.currentCount + 1,
    );

    return true; // Successfully added
  }

  // Remove a patient for specific date (for cancellations)
  bool removePatient(DateTime date) {
    final dateStr = _formatDate(date);
    final currentLimit = getDailyLimit(date);

    if (currentLimit.currentCount <= 0) {
      return false; // Cannot remove, already at 0
    }

    _dailyLimits[dateStr] = currentLimit.copyWith(
      currentCount: currentLimit.currentCount - 1,
    );

    return true; // Successfully removed
  }

  // Get upcoming days with their limits (next 7 days)
  List<DailyPatientLimit> getUpcomingLimits() {
    final List<DailyPatientLimit> limits = [];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      limits.add(getDailyLimit(date));
    }

    return limits;
  }

  // Get statistics for admin dashboard
  Map<String, dynamic> getStatistics() {
    final today = getTodayLimit();
    final upcoming = getUpcomingLimits();

    int totalUpcomingPatients = 0;
    int daysAtCapacity = 0;
    int daysNearCapacity = 0;

    for (final limit in upcoming) {
      totalUpcomingPatients += limit.currentCount;
      if (limit.isAtLimit) daysAtCapacity++;
      if (limit.isNearLimit && !limit.isAtLimit) daysNearCapacity++;
    }

    return {
      'todayCount': today.currentCount,
      'todayRemaining': today.remainingSlots,
      'todayAtLimit': today.isAtLimit,
      'todayNearLimit': today.isNearLimit,
      'totalUpcomingPatients': totalUpcomingPatients,
      'daysAtCapacity': daysAtCapacity,
      'daysNearCapacity': daysNearCapacity,
      'maxPatientsPerDay': maxPatientsPerDay,
    };
  }

  // Helper method to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get formatted date for display
  String getFormattedDate(DateTime date) {
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

  // Reset daily count (for testing purposes)
  void resetDailyCount(DateTime date) {
    final dateStr = _formatDate(date);
    _dailyLimits[dateStr] = DailyPatientLimit(date: dateStr, currentCount: 0);
  }

  // Get all daily limits (for admin view)
  Map<String, DailyPatientLimit> getAllDailyLimits() {
    return Map.unmodifiable(_dailyLimits);
  }
}
