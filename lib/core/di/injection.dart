import 'package:get_it/get_it.dart';

/// 전역 서비스 로케이터
final GetIt getIt = GetIt.instance;

/// 의존성 주입 초기화
Future<void> configureDependencies() async {
  // ============================================
  // External Services
  // ============================================
  
  // TODO: Supabase Client 등록
  // getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ============================================
  // Data Sources
  // ============================================

  // TODO: Local Data Sources
  // getIt.registerLazySingleton<LocalStorageDataSource>(
  //   () => LocalStorageDataSourceImpl(),
  // );

  // TODO: Remote Data Sources (Supabase)
  // getIt.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(getIt()),
  // );

  // ============================================
  // Repositories
  // ============================================

  // TODO: Saju Repository
  // getIt.registerLazySingleton<SajuRepository>(
  //   () => SajuRepositoryImpl(getIt()),
  // );

  // ============================================
  // Use Cases
  // ============================================

  // TODO: Calculate Four Pillars
  // getIt.registerLazySingleton(() => CalculateFourPillarsUseCase(getIt()));

  // ============================================
  // BLoCs
  // ============================================

  // TODO: Saju BLoC
  // getIt.registerFactory(() => SajuBloc(
  //   calculateFourPillars: getIt(),
  //   analyzeTenGods: getIt(),
  // ));
}

/// 의존성 리셋 (테스트용)
Future<void> resetDependencies() async {
  await getIt.reset();
}
