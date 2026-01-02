import '../../../saju/domain/entities/saju_chart.dart';
import '../../domain/entities/daily_fortune.dart';
import '../../domain/repositories/daily_fortune_repository.dart';
import '../datasources/daily_fortune_local_datasource.dart';
import '../models/daily_fortune_model.dart';
import '../services/daily_fortune_generator.dart';

/// 오늘의 운세 Repository 구현
class DailyFortuneRepositoryImpl implements DailyFortuneRepository {
  const DailyFortuneRepositoryImpl({
    required DailyFortuneLocalDatasource localDatasource,
    required DailyFortuneGenerator generator,
  })  : _localDatasource = localDatasource,
        _generator = generator;

  final DailyFortuneLocalDatasource _localDatasource;
  final DailyFortuneGenerator _generator;

  @override
  Future<DailyFortune> getTodayFortune({
    required SajuChart sajuChart,
    bool includePremium = false,
  }) async {
    final today = DateTime.now();
    return getFortuneByDate(
      date: today,
      sajuChart: sajuChart,
      includePremium: includePremium,
    );
  }

  @override
  Future<DailyFortune> getFortuneByDate({
    required DateTime date,
    required SajuChart sajuChart,
    bool includePremium = false,
  }) async {
    // 날짜 정규화 (시간 제거)
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // 캐시 확인
    final cached = _localDatasource.getCachedFortune(normalizedDate);

    // 프리미엄 포함 여부 확인
    final shouldIncludePremium =
        includePremium && _localDatasource.hasPremium;

    // 캐시가 있고, 프리미엄 요청이 없거나 캐시에 프리미엄 데이터가 있는 경우
    if (cached != null) {
      final hasPremiumData = cached.morningFortune != null;

      // 프리미엄이 필요 없거나, 캐시에 프리미엄 데이터가 있으면 캐시 반환
      if (!shouldIncludePremium || hasPremiumData) {
        return cached;
      }
    }

    // 새로 생성
    final fortune = _generator.generate(
      date: normalizedDate,
      sajuChart: sajuChart,
      includePremium: shouldIncludePremium,
    ) as DailyFortuneModel;

    // 캐시 저장
    await _localDatasource.cacheFortune(fortune);

    return fortune;
  }

  @override
  bool hasPremiumAccess() {
    return _localDatasource.hasPremium;
  }

  @override
  Future<void> activatePremium() async {
    await _localDatasource.setPremiumStatus(true);
  }

  @override
  Future<void> clearOldCache() async {
    await _localDatasource.clearOldCache();
  }
}
