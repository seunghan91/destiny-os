import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_manager.dart';
import '../auth/credit_service.dart';

/// 통합 크레딧 서비스
/// 로그인 사용자: Supabase 크레딧 사용
/// 비로그인 사용자: 로컬 SharedPreferences 크레딧 사용
class UnifiedCreditService {
  static const String _localCreditsKey = 'freeAiCredits';
  static const String _localUsedCreditsKey = 'usedAiCredits';
  static const String _lastResetKey = 'lastCreditReset';

  /// 초기 무료 크레딧 수
  static const int initialCredits = 3;

  /// 일일 무료 크레딧 (매일 리셋)
  static const int dailyFreeCredits = 1;

  /// 현재 크레딧 조회
  static Future<int> getCredits() async {
    final authManager = AuthManager();

    if (authManager.isAuthenticated && authManager.userProfile != null) {
      // 로그인 사용자: Supabase 크레딧
      return authManager.creditBalance;
    } else {
      // 비로그인 사용자: 로컬 크레딧
      return _getLocalCredits();
    }
  }

  /// 로컬 크레딧 조회 (비로그인 사용자용)
  static Future<int> _getLocalCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);
    return prefs.getInt(_localCreditsKey) ?? 0;
  }

  /// 크레딧 사용
  /// 성공하면 남은 크레딧 수 반환, 실패하면 -1 반환
  static Future<int> useCredit({
    FeatureType feature = FeatureType.aiConsultation,
    String? description,
  }) async {
    final authManager = AuthManager();

    if (authManager.isAuthenticated && authManager.userProfile != null) {
      // 로그인 사용자: Supabase 크레딧 사용
      final result = await authManager.useCredit(
        feature: feature,
        amount: 1,
        description: description,
      );

      if (result.success) {
        return result.newBalance ?? 0;
      } else {
        return -1; // 크레딧 부족 또는 오류
      }
    } else {
      // 비로그인 사용자: 로컬 크레딧 사용
      return _useLocalCredit();
    }
  }

  /// 로컬 크레딧 사용 (비로그인 사용자용)
  static Future<int> _useLocalCredit() async {
    final prefs = await SharedPreferences.getInstance();
    await _checkDailyReset(prefs);

    final currentCredits = prefs.getInt(_localCreditsKey) ?? 0;

    if (currentCredits <= 0) {
      return -1; // 크레딧 부족
    }

    final newCredits = currentCredits - 1;
    await prefs.setInt(_localCreditsKey, newCredits);

    // 사용한 총 크레딧 수 기록
    final usedCredits = prefs.getInt(_localUsedCreditsKey) ?? 0;
    await prefs.setInt(_localUsedCreditsKey, usedCredits + 1);

    return newCredits;
  }

  /// 크레딧 추가
  static Future<int> addCredits(
    int amount, {
    CreditTransactionType type = CreditTransactionType.bonus,
    String? description,
    String? paymentId,
  }) async {
    final authManager = AuthManager();

    if (authManager.isAuthenticated && authManager.userProfile != null) {
      // 로그인 사용자: Supabase 크레딧 추가
      final result = await authManager.addCredit(
        amount: amount,
        type: type,
        description: description,
        paymentId: paymentId,
      );

      if (result.success) {
        return result.newBalance ?? 0;
      } else {
        // 실패 시 현재 잔액 반환
        return authManager.creditBalance;
      }
    } else {
      // 비로그인 사용자: 로컬 크레딧 추가
      return _addLocalCredits(amount);
    }
  }

  /// 로컬 크레딧 추가 (비로그인 사용자용)
  static Future<int> _addLocalCredits(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCredits = prefs.getInt(_localCreditsKey) ?? 0;
    final newCredits = currentCredits + amount;
    await prefs.setInt(_localCreditsKey, newCredits);
    return newCredits;
  }

  /// 크레딧 충분 여부 확인
  static Future<bool> hasCredits({int required = 1}) async {
    final credits = await getCredits();
    return credits >= required;
  }

  /// 사용자가 로그인 상태인지 확인
  static bool get isLoggedIn => AuthManager().isAuthenticated;

  /// 일일 무료 크레딧 리셋 체크 (로컬 크레딧용)
  static Future<void> _checkDailyReset(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastReset != today) {
      // 오늘 처음 접속 - 일일 무료 크레딧 지급
      final currentCredits = prefs.getInt(_localCreditsKey) ?? 0;
      await prefs.setInt(_localCreditsKey, currentCredits + dailyFreeCredits);
      await prefs.setString(_lastResetKey, today);
    }
  }

  /// 크레딧 초기화 (온보딩 완료 시 호출)
  static Future<void> initializeCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInitialized = prefs.getBool('creditsInitialized') ?? false;

    if (!hasInitialized) {
      await prefs.setInt(_localCreditsKey, initialCredits);
      await prefs.setBool('creditsInitialized', true);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await prefs.setString(_lastResetKey, today);
    }
  }

  /// 사용 통계 조회
  static Future<Map<String, dynamic>> getStats() async {
    final authManager = AuthManager();
    final prefs = await SharedPreferences.getInstance();

    return {
      'isLoggedIn': authManager.isAuthenticated,
      'remaining': await getCredits(),
      'localUsed': prefs.getInt(_localUsedCreditsKey) ?? 0,
      'source': authManager.isAuthenticated ? 'supabase' : 'local',
    };
  }

  /// 크레딧 새로고침 (로그인 사용자용)
  static Future<void> refresh() async {
    final authManager = AuthManager();
    if (authManager.isAuthenticated) {
      await authManager.refreshCreditBalance();
    }
  }

  /// 로그인 시 로컬 크레딧을 Supabase로 마이그레이션
  /// 주의: 호출 전 사용자가 로그인 상태인지 확인 필요
  static Future<void> migrateLocalCreditsToSupabase() async {
    final authManager = AuthManager();
    if (!authManager.isAuthenticated || authManager.userProfile == null) {
      debugPrint('⚠️ 마이그레이션 실패: 로그인 필요');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final localCredits = prefs.getInt(_localCreditsKey) ?? 0;

    if (localCredits > 0) {
      // 로컬 크레딧을 Supabase로 이전
      final result = await authManager.addCredit(
        amount: localCredits,
        type: CreditTransactionType.bonus,
        description: '로컬 크레딧 마이그레이션',
      );

      if (result.success) {
        // 로컬 크레딧 초기화
        await prefs.setInt(_localCreditsKey, 0);
        debugPrint('✅ 로컬 크레딧 $localCredits회 마이그레이션 완료');
      }
    }
  }
}
