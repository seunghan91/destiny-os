import '../../../saju/domain/entities/saju_chart.dart';
import '../entities/daily_fortune.dart';

/// 오늘의 운세 Repository 인터페이스
abstract class DailyFortuneRepository {
  /// 오늘의 운세 조회
  Future<DailyFortune> getTodayFortune({
    required SajuChart sajuChart,
    bool includePremium = false,
  });

  /// 특정 날짜의 운세 조회
  Future<DailyFortune> getFortuneByDate({
    required DateTime date,
    required SajuChart sajuChart,
    bool includePremium = false,
  });

  /// 프리미엄 상태 확인
  bool hasPremiumAccess();

  /// 프리미엄 활성화
  Future<void> activatePremium();

  /// 캐시 정리
  Future<void> clearOldCache();
}
