import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/presentation/pages/splash_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/saju/presentation/pages/input_page.dart';
import '../features/saju/presentation/pages/result_page.dart';
import '../features/fortune_2026/presentation/pages/fortune_2026_page.dart';
import '../features/daewoon/presentation/pages/daewoon_page.dart';
import '../features/compatibility/presentation/pages/compatibility_page.dart';
import '../features/ai_consultation/presentation/pages/consultation_page.dart';
import '../features/share/presentation/pages/share_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/tojung/presentation/pages/tojung_premium_page.dart';

/// 앱 라우터 설정
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
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

    // 사주 입력
    GoRoute(
      path: '/input',
      name: 'input',
      builder: (context, state) => const InputPage(),
    ),

    // 사주 결과
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultPage(),
    ),

    // 2026년 운세
    GoRoute(
      path: '/fortune',
      name: 'fortune',
      builder: (context, state) => const Fortune2026Page(),
    ),

    // 대운 타임라인
    GoRoute(
      path: '/daewoon',
      name: 'daewoon',
      builder: (context, state) => const DaewoonPage(),
    ),

    GoRoute(
      path: '/tojung-premium',
      name: 'tojungPremium',
      builder: (context, state) => const TojungPremiumPage(),
    ),

    // 궁합 분석
    GoRoute(
      path: '/compatibility',
      name: 'compatibility',
      builder: (context, state) => const CompatibilityPage(),
    ),

    // AI 상담
    GoRoute(
      path: '/consultation',
      name: 'consultation',
      builder: (context, state) => const ConsultationPage(),
    ),

    // 공유
    GoRoute(
      path: '/share',
      name: 'share',
      builder: (context, state) => const SharePage(),
    ),

    // 설정
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
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
}
