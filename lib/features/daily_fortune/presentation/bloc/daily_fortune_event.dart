import 'package:equatable/equatable.dart';

/// 오늘의 운세 이벤트
sealed class DailyFortuneEvent extends Equatable {
  const DailyFortuneEvent();

  @override
  List<Object?> get props => [];
}

/// 운세 로드 이벤트
class LoadDailyFortune extends DailyFortuneEvent {
  const LoadDailyFortune({this.date});

  final DateTime? date;

  @override
  List<Object?> get props => [date];
}

/// 프리미엄 기능 활성화
class ActivatePremiumFeatures extends DailyFortuneEvent {
  const ActivatePremiumFeatures();
}

/// 운세 새로고침
class RefreshDailyFortune extends DailyFortuneEvent {
  const RefreshDailyFortune();
}
