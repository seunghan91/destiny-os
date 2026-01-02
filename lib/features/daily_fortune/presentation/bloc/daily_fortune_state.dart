import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_fortune.dart';

/// 오늘의 운세 상태
sealed class DailyFortuneState extends Equatable {
  const DailyFortuneState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class DailyFortuneInitial extends DailyFortuneState {
  const DailyFortuneInitial();
}

/// 로딩 중
class DailyFortuneLoading extends DailyFortuneState {
  const DailyFortuneLoading();
}

/// 로드 성공
class DailyFortuneLoaded extends DailyFortuneState {
  const DailyFortuneLoaded({
    required this.fortune,
    required this.hasPremium,
  });

  final DailyFortune fortune;
  final bool hasPremium;

  @override
  List<Object?> get props => [fortune, hasPremium];
}

/// 로드 실패
class DailyFortuneError extends DailyFortuneState {
  const DailyFortuneError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// 프리미엄 활성화 완료
class DailyFortunePremiumActivated extends DailyFortuneState {
  const DailyFortunePremiumActivated();
}
