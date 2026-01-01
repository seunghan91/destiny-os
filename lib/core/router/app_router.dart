import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/saju/presentation/pages/input_page.dart';
import '../../features/saju/presentation/pages/result_page.dart';
import '../../features/fortune_2026/presentation/pages/fortune_2026_page.dart';
import '../../features/daewoon/presentation/pages/daewoon_page.dart';
import '../../features/compatibility/presentation/pages/compatibility_page.dart';

/// 앱 라우터 설정
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: Routes.splash,
        name: Routes.splashName,
        builder: (context, state) => const SplashPage(),
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: Routes.onboardingName,
        builder: (context, state) => const OnboardingPage(),
      ),

      // Input (생년월일, MBTI 입력)
      GoRoute(
        path: Routes.input,
        name: Routes.inputName,
        builder: (context, state) => const InputPage(),
      ),

      // Result (운세 결과)
      GoRoute(
        path: Routes.result,
        name: Routes.resultName,
        builder: (context, state) => const ResultPage(),
      ),

      // 2026 운세 상세
      GoRoute(
        path: Routes.fortune2026,
        name: Routes.fortune2026Name,
        builder: (context, state) => const Fortune2026Page(),
      ),

      // 대운 타임라인
      GoRoute(
        path: Routes.daewoon,
        name: Routes.daewoonName,
        builder: (context, state) => const DaewoonPage(),
      ),

      // 궁합 분석
      GoRoute(
        path: Routes.compatibility,
        name: Routes.compatibilityName,
        builder: (context, state) => const CompatibilityPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
      ),
    ),
  );
}

/// 라우트 상수
class Routes {
  Routes._();

  static const String splash = '/';
  static const String splashName = 'splash';

  static const String onboarding = '/onboarding';
  static const String onboardingName = 'onboarding';

  static const String input = '/input';
  static const String inputName = 'input';

  static const String result = '/result';
  static const String resultName = 'result';

  static const String fortune2026 = '/fortune-2026';
  static const String fortune2026Name = 'fortune2026';

  static const String daewoon = '/daewoon';
  static const String daewoonName = 'daewoon';

  static const String compatibility = '/compatibility';
  static const String compatibilityName = 'compatibility';
}
