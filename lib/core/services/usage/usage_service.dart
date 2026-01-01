import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용량 체크 결과
class UsageCheckResult {
  final bool allowed;
  final String? reason;
  final String? message;
  final int currentCount;
  final int limit;
  final int remaining;

  UsageCheckResult({
    required this.allowed,
    this.reason,
    this.message,
    required this.currentCount,
    required this.limit,
    required this.remaining,
  });

  factory UsageCheckResult.fromJson(Map<String, dynamic> json) {
    return UsageCheckResult(
      allowed: json['allowed'] as bool? ?? true,
      reason: json['reason'] as String?,
      message: json['message'] as String?,
      currentCount: json['current_count'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10000,
      remaining: json['remaining'] as int? ?? 10000,
    );
  }

  factory UsageCheckResult.error(String message) {
    return UsageCheckResult(
      allowed: true, // 에러 시에는 허용 (사용자 경험 우선)
      message: message,
      currentCount: 0,
      limit: 10000,
      remaining: 10000,
    );
  }
}

/// 사용량 상태 (관리자용)
class UsageStatus {
  final DateTime date;
  final int totalCount;
  final int sajuCount;
  final int mbtiCount;
  final int compatibilityCount;
  final int consultationCount;
  final int dailyLimit;
  final int warningThreshold;
  final bool isPaused;
  final List<UsageAlert> alerts;

  UsageStatus({
    required this.date,
    required this.totalCount,
    required this.sajuCount,
    required this.mbtiCount,
    required this.compatibilityCount,
    required this.consultationCount,
    required this.dailyLimit,
    required this.warningThreshold,
    required this.isPaused,
    required this.alerts,
  });

  factory UsageStatus.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    final alertsList = json['alerts'] as List? ?? [];

    return UsageStatus(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      totalCount: json['total_count'] as int? ?? 0,
      sajuCount: json['saju_count'] as int? ?? 0,
      mbtiCount: json['mbti_count'] as int? ?? 0,
      compatibilityCount: json['compatibility_count'] as int? ?? 0,
      consultationCount: json['consultation_count'] as int? ?? 0,
      dailyLimit: settings['daily_limit'] as int? ?? 10000,
      warningThreshold: settings['warning_threshold'] as int? ?? 8000,
      isPaused: settings['is_paused'] as bool? ?? false,
      alerts: alertsList
          .map((a) => UsageAlert.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  double get usagePercentage => (totalCount / dailyLimit * 100).clamp(0, 100);
}

/// 사용량 알림
class UsageAlert {
  final String id;
  final String type;
  final String message;
  final DateTime createdAt;

  UsageAlert({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  factory UsageAlert.fromJson(Map<String, dynamic> json) {
    return UsageAlert(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// 사용량 타입
enum UsageType {
  general,
  saju,
  mbti,
  compatibility,
  consultation,
}

/// 사용량 관리 서비스
class UsageService {
  final SupabaseClient _client;

  UsageService({required SupabaseClient client}) : _client = client;

  /// 사용량 증가 및 한도 체크
  ///
  /// [usageType]: 사용 유형 (saju, mbti, compatibility, consultation, general)
  ///
  /// Returns: 사용 가능 여부와 현재 상태
  Future<UsageCheckResult> incrementAndCheck({
    UsageType usageType = UsageType.general,
  }) async {
    try {
      final response = await _client.rpc(
        'increment_usage',
        params: {'usage_type': usageType.name},
      );

      if (response == null) {
        return UsageCheckResult.error('사용량 체크 실패');
      }

      return UsageCheckResult.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      // 에러 시에는 사용 허용 (사용자 경험 우선)
      return UsageCheckResult.error('사용량 체크 오류: $e');
    }
  }

  /// 현재 사용량 상태 조회 (관리자용)
  Future<UsageStatus?> getUsageStatus() async {
    try {
      final response = await _client.rpc('get_usage_status');

      if (response == null) {
        return null;
      }

      return UsageStatus.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// 서비스 일시 중단/재개
  Future<bool> toggleServicePause(bool isPaused) async {
    try {
      await _client.from('app_settings').update({
        'value': {
          'daily_limit': 10000,
          'warning_threshold': 8000,
          'is_paused': isPaused,
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('key', 'usage_limit');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 알림 읽음 처리
  Future<bool> markAlertAsRead(String alertId) async {
    try {
      await _client.from('usage_alerts').update({
        'is_read': true,
      }).eq('id', alertId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 모든 알림 읽음 처리
  Future<bool> markAllAlertsAsRead() async {
    try {
      await _client.from('usage_alerts').update({
        'is_read': true,
      }).eq('is_read', false);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 일일 사용량 초기화 (자정에 호출)
  Future<bool> resetDailyUsage() async {
    try {
      await _client.rpc('reset_daily_usage');
      return true;
    } catch (e) {
      return false;
    }
  }
}
