import 'package:shared_preferences/shared_preferences.dart';

class UsageManager {
  static const String _batchUsageKey = 'batch_usage_count';
  static const String _lastUsageDateKey = 'last_usage_date';
  static const int maxDailyBatchUsage = 3;

  static Future<bool> canUseBatchConversion() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD format
    final lastUsageDate = prefs.getString(_lastUsageDateKey) ?? '';
    final usageCount = prefs.getInt(_batchUsageKey) ?? 0;

    // If it's a new day, reset the counter
    if (lastUsageDate != today) {
      await prefs.setString(_lastUsageDateKey, today);
      await prefs.setInt(_batchUsageKey, 0);
      return true;
    }

    // Check if user has reached daily limit
    return usageCount < maxDailyBatchUsage;
  }

  static Future<int> getRemainingBatchUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastUsageDate = prefs.getString(_lastUsageDateKey) ?? '';
    final usageCount = prefs.getInt(_batchUsageKey) ?? 0;

    // If it's a new day, reset the counter
    if (lastUsageDate != today) {
      await prefs.setString(_lastUsageDateKey, today);
      await prefs.setInt(_batchUsageKey, 0);
      return maxDailyBatchUsage;
    }

    return maxDailyBatchUsage - usageCount;
  }

  static Future<void> incrementBatchUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastUsageDate = prefs.getString(_lastUsageDateKey) ?? '';
    final usageCount = prefs.getInt(_batchUsageKey) ?? 0;

    // If it's a new day, reset the counter
    if (lastUsageDate != today) {
      await prefs.setString(_lastUsageDateKey, today);
      await prefs.setInt(_batchUsageKey, 1);
    } else {
      await prefs.setInt(_batchUsageKey, usageCount + 1);
    }
  }

  static Future<void> resetDailyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_batchUsageKey, 0);
  }
}

