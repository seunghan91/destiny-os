import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../domain/usecases/get_daily_fortune.dart';
import 'daily_fortune_event.dart';
import 'daily_fortune_state.dart';

/// 오늘의 운세 BLoC
class DailyFortuneBloc extends Bloc<DailyFortuneEvent, DailyFortuneState> {
  DailyFortuneBloc({
    required GetDailyFortune getDailyFortune,
    required DestinyBloc destinyBloc,
  })  : _getDailyFortune = getDailyFortune,
        _destinyBloc = destinyBloc,
        super(const DailyFortuneInitial()) {
    on<LoadDailyFortune>(_onLoadDailyFortune);
    on<ActivatePremiumFeatures>(_onActivatePremiumFeatures);
    on<RefreshDailyFortune>(_onRefreshDailyFortune);
  }

  final GetDailyFortune _getDailyFortune;
  final DestinyBloc _destinyBloc;

  Future<void> _onLoadDailyFortune(
    LoadDailyFortune event,
    Emitter<DailyFortuneState> emit,
  ) async {
    try {
      emit(const DailyFortuneLoading());

      // 사주 정보 확인
      final destinyState = _destinyBloc.state;
      if (destinyState is! DestinySuccess || destinyState.sajuChart == null) {
        emit(const DailyFortuneError('사주 정보가 없습니다. 먼저 사주를 입력해주세요.'));
        return;
      }

      final sajuChart = destinyState.sajuChart!;
      final hasPremium = _getDailyFortune.hasPremiumAccess();

      final fortune = event.date != null
          ? await _getDailyFortune.getByDate(
              date: event.date!,
              sajuChart: sajuChart,
              includePremium: hasPremium,
            )
          : await _getDailyFortune(
              sajuChart: sajuChart,
              includePremium: hasPremium,
            );

      emit(DailyFortuneLoaded(
        fortune: fortune,
        hasPremium: hasPremium,
      ));
    } catch (e) {
      emit(DailyFortuneError('운세를 불러오는데 실패했습니다: ${e.toString()}'));
    }
  }

  Future<void> _onActivatePremiumFeatures(
    ActivatePremiumFeatures event,
    Emitter<DailyFortuneState> emit,
  ) async {
    try {
      await _getDailyFortune.activatePremium();
      emit(const DailyFortunePremiumActivated());

      // 운세 다시 로드
      add(const LoadDailyFortune());
    } catch (e) {
      emit(DailyFortuneError('프리미엄 활성화 실패: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshDailyFortune(
    RefreshDailyFortune event,
    Emitter<DailyFortuneState> emit,
  ) async {
    // 현재 날짜로 다시 로드
    add(const LoadDailyFortune());
  }
}
