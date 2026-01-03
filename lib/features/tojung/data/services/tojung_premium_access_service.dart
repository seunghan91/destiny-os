import 'package:shared_preferences/shared_preferences.dart';

class TojungPremiumAccessService {
  static const String _initializedKey = 'tojung_premium_initialized';
  static const String _creditsKey = 'tojung_premium_credits';

  static const int initialFreeCredits = 0;

  static Future<void> resetToInitialCredits() async {
    await setCredits(initialFreeCredits);
  }

  static Future<void> setCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditsKey, credits);
    await prefs.setBool(_initializedKey, true);
  }

  static Future<void> initializeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;
    if (initialized) return;

    await prefs.setInt(_creditsKey, initialFreeCredits);
    await prefs.setBool(_initializedKey, true);
  }

  static Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await initializeIfNeeded();
    return prefs.getInt(_creditsKey) ?? 0;
  }

  static Future<bool> consumeOne() async {
    final prefs = await SharedPreferences.getInstance();
    await initializeIfNeeded();

    final current = prefs.getInt(_creditsKey) ?? 0;
    if (current <= 0) return false;

    await prefs.setInt(_creditsKey, current - 1);
    return true;
  }

  static Future<int> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    await initializeIfNeeded();

    final current = prefs.getInt(_creditsKey) ?? 0;
    final next = current + amount;
    await prefs.setInt(_creditsKey, next);
    return next;
  }
}
