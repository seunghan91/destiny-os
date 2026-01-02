import 'package:shared_preferences/shared_preferences.dart';

class FortuneViewAccessService {
  static const String _initializedKey = 'fortune2026_view_initialized';
  static const String _creditsKey = 'fortune2026_view_credits';
  static const String _shareBonusClaimedKey = 'fortune2026_share_bonus_claimed';

  static const int initialFreeCredits = 1;

  static Future<void> resetToInitialCredits() async {
    await setCredits(initialFreeCredits);
  }

  static Future<void> setCredits(int credits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_creditsKey, credits);
    await prefs.setBool(_initializedKey, true);
    await prefs.setBool(_shareBonusClaimedKey, false);
  }

  static Future<void> initializeIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final initialized = prefs.getBool(_initializedKey) ?? false;
    if (initialized) return;

    await prefs.setInt(_creditsKey, initialFreeCredits);
    await prefs.setBool(_initializedKey, true);
    await prefs.setBool(_shareBonusClaimedKey, false);
  }

  static Future<bool> canClaimShareBonus() async {
    final prefs = await SharedPreferences.getInstance();
    await initializeIfNeeded();
    final already = prefs.getBool(_shareBonusClaimedKey) ?? false;
    final credits = prefs.getInt(_creditsKey) ?? 0;
    return !already && credits <= 0;
  }

  static Future<bool> claimShareBonus() async {
    final prefs = await SharedPreferences.getInstance();
    await initializeIfNeeded();

    final already = prefs.getBool(_shareBonusClaimedKey) ?? false;
    if (already) return false;

    final credits = prefs.getInt(_creditsKey) ?? 0;
    if (credits > 0) return false;

    await prefs.setBool(_shareBonusClaimedKey, true);
    await addCredits(1);
    return true;
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
