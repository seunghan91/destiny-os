import 'package:equatable/equatable.dart';

/// 앱 전역 실패(Failure) 클래스
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// 서버 에러
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = '서버 오류가 발생했습니다.',
    super.code,
  });
}

/// 네트워크 에러
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = '네트워크 연결을 확인해주세요.',
    super.code,
  });
}

/// 캐시 에러
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = '로컬 데이터를 불러올 수 없습니다.',
    super.code,
  });
}

/// 인증 에러
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = '인증에 실패했습니다.',
    super.code,
  });
}

/// 입력 유효성 에러
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

/// 사주 계산 에러
class SajuCalculationFailure extends Failure {
  const SajuCalculationFailure({
    super.message = '사주 계산 중 오류가 발생했습니다.',
    super.code,
  });
}

/// AI 상담 에러
class ConsultationFailure extends Failure {
  const ConsultationFailure({
    super.message = 'AI 상담 중 오류가 발생했습니다.',
    super.code,
  });
}

/// AI 상담 횟수 초과
class ConsultationLimitExceeded extends Failure {
  const ConsultationLimitExceeded({
    super.message = '무료 AI 상담 횟수를 모두 사용했습니다.',
    super.code = 'CONSULTATION_LIMIT_EXCEEDED',
  });
}
