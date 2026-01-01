import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/di/injection.dart';
import 'core/services/notifications/firebase_notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드 (존재하지 않을 경우 무시)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('⚠️  .env file not found - using --dart-define or defaults');
  }

  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // 백그라운드 메시지 핸들러 등록 (앱 종료 상태)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Firebase Cloud Messaging 초기화
    await FirebaseNotificationService().initialize();
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('   Run: flutterfire configure');
    // Firebase 없이도 앱 실행 가능 (알림 기능만 비활성화)
  }

  // 상태바 스타일은 테마에서 동적으로 처리
  // (AppTheme.light/dark의 appBarTheme.systemOverlayStyle에서 정의)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
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
