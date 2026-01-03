import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// 초기 로딩 페이지 (즉시 로드)
// ============================================================================
// Splash와 Onboarding, Input은 초기 로딩에 필수이므로 직접 import
import '../features/onboarding/presentation/pages/splash_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/saju/presentation/pages/input_page.dart';

// ============================================================================
// Deferred Loading: 사용자 진입 시에만 로드
// ============================================================================
// 각 feature를 별도 번들로 분할하여 초기 로딩 속도 개선

// Saju Feature (사주 결과 페이지)
import '../features/saju/presentation/pages/result_page.dart' deferred as saju;

// Fortune Features (운세 관련 페이지들)
import '../features/fortune_2026/presentation/pages/fortune_2026_page.dart'
    deferred as fortune;
import '../features/daewoon/presentation/pages/daewoon_page.dart'
    deferred as daewoon;

// Social Features (궁합, 공유)
import '../features/compatibility/presentation/pages/compatibility_page.dart'
    deferred as compatibility;
import '../features/share/presentation/pages/share_page.dart' deferred as share;

// Advanced Features (AI 상담)
import '../features/ai_consultation/presentation/pages/consultation_page.dart'
    deferred as consultation;

// Settings
import '../features/settings/presentation/pages/settings_page.dart'
    deferred as settings;

// Admin Feature (관리자 페이지)
import '../features/admin/presentation/pages/admin_page.dart' deferred as admin;

/// 앱 라우터 설정 (Deferred Loading 최적화)
///
/// 번들 분할 전략:
/// - 초기 번들 (~1.2MB): splash, onboarding, input
/// - Saju 번들 (~500KB): result
/// - Fortune 번들 (~600KB): fortune_2026, daewoon
/// - Social 번들 (~400KB): compatibility, share
/// - Advanced 번들 (~800KB): consultation (AI)
/// - Settings 번들 (~200KB): settings
///
/// 예상 효과:
/// - 초기 로딩: 4.1MB → 1.2MB (71% 감소)
/// - FCP: 1.69s → 0.9s (47% 개선)
final GoRouter appRouterDeferred = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // ========================================================================
    // 초기 로딩 페이지 (Eager Loading)
    // ========================================================================

    // 스플래시
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),

    // 온보딩
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),

    // 사주 입력 (핵심 기능 - 초기 로딩)
    GoRoute(
      path: '/input',
      name: 'input',
      builder: (context, state) => const InputPage(),
    ),

    // ========================================================================
    // Deferred Loading 페이지
    // ========================================================================

    // 사주 결과 (Deferred - 사용자가 입력 완료 후 진입)
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) {
        return FutureBuilder(
          future: saju.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return saju.ResultPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 2026년 운세 (Deferred)
    GoRoute(
      path: '/fortune',
      name: 'fortune',
      builder: (context, state) {
        return FutureBuilder(
          future: fortune.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return fortune.Fortune2026Page();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 대운 타임라인 (Deferred)
    GoRoute(
      path: '/daewoon',
      name: 'daewoon',
      builder: (context, state) {
        return FutureBuilder(
          future: daewoon.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return daewoon.DaewoonPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 궁합 분석 (Deferred)
    GoRoute(
      path: '/compatibility',
      name: 'compatibility',
      builder: (context, state) {
        return FutureBuilder(
          future: compatibility.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return compatibility.CompatibilityPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // AI 상담 (Deferred - 가장 큰 번들)
    GoRoute(
      path: '/consultation',
      name: 'consultation',
      builder: (context, state) {
        return FutureBuilder(
          future: consultation.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return consultation.ConsultationPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 공유 (Deferred)
    GoRoute(
      path: '/share',
      name: 'share',
      builder: (context, state) {
        return FutureBuilder(
          future: share.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return share.SharePage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 설정 (Deferred)
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) {
        return FutureBuilder(
          future: settings.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return settings.SettingsPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),

    // 어드민 (Deferred - 숨겨진 관리자 페이지)
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (context, state) {
        return FutureBuilder(
          future: admin.loadLibrary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return admin.AdminPage();
            }
            return const DeferredLoadingIndicator();
          },
        );
      },
    ),
  ],

  // 에러 페이지
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('페이지를 찾을 수 없습니다'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('홈으로'),
          ),
        ],
      ),
    ),
  ),
);

/// 라우트 이름 상수
class AppRoutes {
  AppRoutes._();

  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String input = 'input';
  static const String result = 'result';
  static const String fortune = 'fortune';
  static const String daewoon = 'daewoon';
  static const String compatibility = 'compatibility';
  static const String consultation = 'consultation';
  static const String share = 'share';
  static const String settings = 'settings';
  static const String admin = 'admin';
}

/// Deferred Loading 진행 상태 표시 위젯
class DeferredLoadingIndicator extends StatelessWidget {
  const DeferredLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('로딩 중...'),
          ],
        ),
      ),
    );
  }
}
