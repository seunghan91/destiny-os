import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_notifier.dart';
import '../features/daily_fortune/presentation/bloc/daily_fortune_bloc.dart';
import '../features/saju/presentation/bloc/destiny_bloc.dart';
import 'router_deferred.dart';

/// 2026 신년운세 (MBTI 운세) 앱 루트 위젯
class DestinyApp extends StatefulWidget {
  const DestinyApp({super.key});

  @override
  State<DestinyApp> createState() => _DestinyAppState();
}

class _DestinyAppState extends State<DestinyApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeNotifier(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, _) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<DestinyBloc>(create: (context) => getIt<DestinyBloc>()),
              BlocProvider<DailyFortuneBloc>(create: (context) => getIt<DailyFortuneBloc>()),
            ],
            child: MaterialApp.router(
              title: '2026 신년운세 (MBTI 운세)',
              debugShowCheckedModeBanner: false,

              // 한국어 로케일 설정
              locale: const Locale('ko', 'KR'),
              supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // 테마 - ThemeController에서 관리
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _themeController.themeMode,

              // 라우터 (Deferred Loading 최적화)
              routerConfig: appRouterDeferred,

              // 빌더 (전역 설정)
              builder: (context, child) {
                // 다크모드에 맞춰 상태바 스타일 동적 설정
                final isDark = _themeController.isDarkMode(context);
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                    statusBarBrightness: isDark
                        ? Brightness.dark
                        : Brightness.light,
                    systemNavigationBarColor: isDark
                        ? const Color(0xFF0D1117) // AppColors.backgroundDark
                        : const Color(0xFFF9FAFB), // AppColors.background
                    systemNavigationBarIconBrightness: isDark
                        ? Brightness.light
                        : Brightness.dark,
                  ),
                );

                return MediaQuery(
                  // 시스템 폰트 스케일 제한 (접근성)
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.of(
                        context,
                      ).textScaler.scale(1.0).clamp(0.8, 1.2),
                    ),
                  ),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
