import 'package:shared_preferences/shared_preferences.dart';

/// AI 상담 크레딧 관리 서비스
class CreditService {
  static const String _creditsKey = 'freeAiCredits';
  static const String _usedCreditsKey = 'usedAiCredits';
  static const String _lastResetKey = 'lastCreditReset';

  /// 초기 무료 크레딧 수
  static const int initialCredits = 3;

  /// 일일 무료 크레딧 (매일 리셋)
  static const int dailyFreeCredits = 1;

  /// 현재 크레딧 조회
  static Future<int> getCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);
    return prefs.getInt(_creditsKey) ?? 0;
  }

  /// 크레딧 차감
  /// 성공하면 남은 크레딧 수 반환, 실패하면 -1 반환
  static Future<int> useCredit() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);

    final currentCredits = prefs.getInt(_creditsKey) ?? 0;

    if (currentCredits <= 0) {
      return -1; // 크레딧 부족
    }

    final newCredits = currentCredits - 1;
    await prefs.setInt(_creditsKey, newCredits);

    // 사용한 총 크레딧 수 기록
    final usedCredits = prefs.getInt(_usedCreditsKey) ?? 0;
    await prefs.setInt(_usedCreditsKey, usedCredits + 1);

    return newCredits;
  }

  /// 크레딧 추가 (프로모션 등)
  static Future<int> addCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCredits = prefs.getInt(_creditsKey) ?? 0;
    final newCredits = currentCredits + amount;
    await prefs.setInt(_creditsKey, newCredits);
    return newCredits;
  }

  /// 크레딧 충분 여부 확인
  static Future<bool> hasCredits() async {
    final credits = await getCredits();
    return credits > 0;
  }

  /// 일일 무료 크레딧 리셋 체크
  static Future<void> _checkDailyReset(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastReset != today) {
      // 오늘 처음 접속 - 일일 무료 크레딧 지급
      final currentCredits = prefs.getInt(_creditsKey) ?? 0;
      // 일일 크레딧만 추가 (누적되도록)
      await prefs.setInt(_creditsKey, currentCredits + dailyFreeCredits);
      await prefs.setString(_lastResetKey, today);
    }
  }

  /// 크레딧 초기화 (온보딩 완료 시 호출)
  static Future<void> initializeCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInitialized = prefs.getBool('creditsInitialized') ?? false;

    if (!hasInitialized) {
      await prefs.setInt(_creditsKey, initialCredits);
      await prefs.setBool('creditsInitialized', true);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_lastResetKey, today);
    }
  }

  /// 사용 통계 조회
  static Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'remaining': prefs.getInt(_creditsKey) ?? 0,
      'used': prefs.getInt(_usedCreditsKey) ?? 0,
    };
  }
}
