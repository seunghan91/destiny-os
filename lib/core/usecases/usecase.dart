// Clean Architecture UseCase 베이스 클래스

/// Result 타입 (Either 대신 간단한 구현)
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}

/// 파라미터가 있는 UseCase
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// 파라미터가 없는 UseCase
abstract class NoParamsUseCase<T> {
  Future<Result<T>> call();
}

/// 파라미터 없음을 나타내는 클래스
class NoParams {
  const NoParams();
}
