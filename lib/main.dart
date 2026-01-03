import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/env_config.dart';
import 'core/di/injection.dart';
import 'core/services/apps_in_toss/apps_in_toss_service.dart';
import 'core/services/notifications/firebase_notification_service.dart';
import 'core/services/pwa/pwa_service.dart';
import 'core/services/pwa/web_notification_service.dart';
import 'core/services/auth/auth_manager.dart';
import 'core/services/auth/auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 웹에서 해시(#) 없는 URL 사용
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // 초기 렌더를 최대한 빠르게 보여주기 위해 runApp을 먼저 실행하고,
  // 무거운 초기화(Firebase/Supabase/DI 등)는 부트스트랩 화면 뒤에서 진행한다.
  final initFuture = _initializeApp();
  runApp(DestinyBootstrap(initFuture: initFuture));
}

/// 앱 초기화 (부트스트랩 화면이 떠 있는 동안 실행)
Future<void> _initializeApp() async {
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
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    // Firebase Cloud Messaging 초기화
    await FirebaseNotificationService().initialize();

    // 웹: Redirect 로그인 결과 확인 (팝업 차단 시 리다이렉트로 fallback한 경우)
    if (kIsWeb) {
      try {
        final authService = AuthService();
        final redirectResult = await authService.checkRedirectResult();
        if (redirectResult != null) {
          if (redirectResult.success) {
            debugPrint(
              '✅ Redirect 로그인 성공: ${redirectResult.user?.email}',
            );
          } else {
            debugPrint('❌ Redirect 로그인 실패: ${redirectResult.errorMessage}');
          }
        }
      } catch (e) {
        debugPrint('⚠️  Redirect result check failed: $e');
      }
    }
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
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

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

  // AuthManager 초기화 (Firebase Auth + Supabase 연동)
  try {
    await getIt<AuthManager>().initialize();
    debugPrint('✅ AuthManager initialized successfully');
  } catch (e) {
    debugPrint('⚠️  AuthManager initialization failed: $e');
  }

  // 웹 플랫폼 서비스 초기화
  if (kIsWeb) {
    try {
      // PWA 서비스
      final pwaService = PwaService();
      await pwaService.initialize();

      final webNotificationService = WebNotificationService();
      await webNotificationService.initialize();

      debugPrint('✅ PWA services initialized');
    } catch (e) {
      debugPrint('⚠️  PWA services initialization failed: $e');
    }

    // Apps in Toss SDK 초기화
    try {
      final appsInTossBridge = AppsInTossBridge();
      await appsInTossBridge.initialize();

      debugPrint('✅ Apps in Toss SDK initialized');
      debugPrint('🏪 환경: ${appsInTossBridge.isAppsInToss ? "Apps in Toss" : "Mock"}');
    } catch (e) {
      debugPrint('⚠️  Apps in Toss SDK initialization failed: $e');
    }
  }

}

/// 초기 로딩 중 사용자에게 "접속됨"을 명확히 보여주는 부트스트랩 UI
class DestinyBootstrap extends StatelessWidget {
  const DestinyBootstrap({super.key, required this.initFuture});

  final Future<void> initFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapLoadingView();
        }
        if (snapshot.hasError) {
          return _BootstrapErrorView(error: snapshot.error);
        }
        return const DestinyApp();
      },
    );
  }
}

class _BootstrapLoadingView extends StatelessWidget {
  const _BootstrapLoadingView();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0B0F1A),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF9B7BFF),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '불러오는 중…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapErrorView extends StatelessWidget {
  const _BootstrapErrorView({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '앱을 불러오는 중 문제가 발생했어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB7B7C2),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // 웹/모바일 모두에서 동작하는 가장 단순한 재시도 UX
                      runApp(
                        DestinyBootstrap(initFuture: _initializeApp()),
                      );
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
