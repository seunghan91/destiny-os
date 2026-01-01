import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/saju/presentation/bloc/destiny_bloc.dart';
import 'router.dart';

/// Destiny.OS 앱 루트 위젯
class DestinyApp extends StatelessWidget {
  const DestinyApp({super.key});

  @override
  Widget build(BuildContext context) {
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

        // 테마
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,

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
  }
}
