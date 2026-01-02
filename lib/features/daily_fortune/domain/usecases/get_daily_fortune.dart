import '../../../saju/domain/entities/saju_chart.dart';
import '../entities/daily_fortune.dart';
import '../repositories/daily_fortune_repository.dart';

/// 오늘의 운세 조회 Usecase
class GetDailyFortune {
  const GetDailyFortune(this._repository);

  final DailyFortuneRepository _repository;

  /// 오늘의 운세 조회
  Future<DailyFortune> call({
    required SajuChart sajuChart,
    bool includePremium = false,
  }) async {
    return _repository.getTodayFortune(
      sajuChart: sajuChart,
      includePremium: includePremium,
    );
  }

  /// 특정 날짜 운세 조회
  Future<DailyFortune> getByDate({
    required DateTime date,
    required SajuChart sajuChart,
    bool includePremium = false,
  }) async {
    return _repository.getFortuneByDate(
      date: date,
      sajuChart: sajuChart,
      includePremium: includePremium,
    );
  }

  /// 프리미엄 상태 확인
  bool hasPremiumAccess() {
    return _repository.hasPremiumAccess();
  }

  /// 프리미엄 활성화
  Future<void> activatePremium() async {
    await _repository.activatePremium();
  }
}
