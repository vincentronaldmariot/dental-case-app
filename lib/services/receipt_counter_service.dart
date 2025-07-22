import 'package:shared_preferences/shared_preferences.dart';

class ReceiptCounterService {
  static final ReceiptCounterService _instance =
      ReceiptCounterService._internal();
  factory ReceiptCounterService() => _instance;
  ReceiptCounterService._internal();

  static const String _counterKey = 'daily_receipt_counter';
  static const String _lastDateKey = 'last_receipt_date';

  /// Get the next receipt number for today
  /// Returns a formatted string like "001", "002", etc.
  Future<String> getNextReceiptNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Check if it's a new day
    final lastDate = prefs.getString(_lastDateKey);
    if (lastDate != todayString) {
      // Reset counter for new day
      await prefs.setString(_lastDateKey, todayString);
      await prefs.setInt(_counterKey, 0);
    }

    // Get current counter and increment
    final currentCounter = prefs.getInt(_counterKey) ?? 0;
    final nextCounter = currentCounter + 1;

    // Save the new counter
    await prefs.setInt(_counterKey, nextCounter);

    // Return formatted receipt number (3 digits with leading zeros)
    return nextCounter.toString().padLeft(3, '0');
  }

  /// Get today's receipt count
  Future<int> getTodayReceiptCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final lastDate = prefs.getString(_lastDateKey);
    if (lastDate != todayString) {
      return 0; // New day, no receipts yet
    }

    return prefs.getInt(_counterKey) ?? 0;
  }

  /// Get the last receipt number used today
  Future<String> getLastReceiptNumber() async {
    final count = await getTodayReceiptCount();
    return count.toString().padLeft(3, '0');
  }

  /// Reset the counter (useful for testing or manual reset)
  Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_counterKey);
    await prefs.remove(_lastDateKey);
  }

  /// Get counter statistics
  Future<Map<String, dynamic>> getCounterStats() async {
    final count = await getTodayReceiptCount();
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return {
      'today_date': todayString,
      'receipt_count': count,
      'next_receipt_number': (count + 1).toString().padLeft(3, '0'),
    };
  }
}
