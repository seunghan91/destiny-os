import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Supabase 초기화 (환경 변수 사용)
  if (EnvConfig.hasSupabaseKey) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // 보안 강화
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3, // 재시도 옵션
        ),
      );
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Supabase initialization failed: $e');
      // Supabase 없이도 앱 실행 가능 (로컬 기능만 사용)
    }
  } else {
    debugPrint('⚠️  Supabase key not found - running in offline mode');
  }

  // 의존성 주입 초기화
  await configureDependencies();

  runApp(const DestinyApp());
}
