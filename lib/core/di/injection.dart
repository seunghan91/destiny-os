import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/saju/data/services/saju_calculator.dart';
import '../../features/saju/presentation/bloc/destiny_bloc.dart';

/// 전역 서비스 로케이터
final GetIt getIt = GetIt.instance;

/// 의존성 주입 초기화
Future<void> configureDependencies() async {
  // ============================================
  // External Services
  // ============================================

  // SharedPreferences (비동기 초기화)
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Supabase Client (초기화된 경우에만 등록)
  try {
    final supabaseClient = Supabase.instance.client;
    getIt.registerLazySingleton<SupabaseClient>(() => supabaseClient);
  } catch (e) {
    // Supabase가 초기화되지 않았을 경우 - 오프라인 모드
    // 에러를 던지지 않고 건너뜀 (선택적 의존성)
  }

  // ============================================
  // Services
  // ============================================

  // 사주 계산 서비스 (싱글톤 인스턴스 참조)
  getIt.registerLazySingleton<SajuCalculator>(() => SajuCalculator.instance);

  // CreditService는 static 메서드만 사용하므로 별도 등록 불필요

  // ============================================
  // BLoCs
  // ============================================

  // DestinyBloc (팩토리 - 매번 새 인스턴스)
  getIt.registerFactory<DestinyBloc>(() => DestinyBloc());
}

/// 의존성 리셋 (테스트용)
Future<void> resetDependencies() async {
  await getIt.reset();
}

/// DI 헬퍼 확장
extension GetItExtension on GetIt {
  /// 안전하게 의존성 가져오기 (없으면 null 반환)
  T? tryGet<T extends Object>() {
    try {
      return get<T>();
    } catch (_) {
      return null;
    }
  }

  /// 의존성 등록 여부 확인
  bool isRegistered<T extends Object>() {
    return GetIt.I.isRegistered<T>();
  }
}
