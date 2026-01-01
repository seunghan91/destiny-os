import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_notifier.dart';
import '../features/saju/presentation/bloc/destiny_bloc.dart';
import 'router.dart';

/// Destiny.OS 앱 루트 위젯
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
              BlocProvider<DestinyBloc>(
                create: (context) => DestinyBloc(),
              ),
            ],
            child: MaterialApp.router(
              title: 'Destiny.OS',
              debugShowCheckedModeBanner: false,

              // 한국어 로케일 설정
              locale: const Locale('ko', 'KR'),
              supportedLocales: const [
                Locale('ko', 'KR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              // 테마 - ThemeController에서 관리
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: _themeController.themeMode,

              // 라우터
              routerConfig: appRouter,

              // 빌더 (전역 설정)
              builder: (context, child) {
                return MediaQuery(
                  // 시스템 폰트 스케일 제한 (접근성)
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(
                      MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
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
