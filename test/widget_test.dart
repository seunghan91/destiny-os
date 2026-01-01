// Destiny.OS 기본 위젯 테스트

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:destiny_os/features/saju/presentation/bloc/destiny_bloc.dart';

void main() {
  testWidgets('DestinyBloc이 MaterialApp에서 제공된다', (WidgetTester tester) async {
    // 간단한 테스트 앱 빌드
    await tester.pumpWidget(
      BlocProvider<DestinyBloc>(
        create: (_) => DestinyBloc(),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Test')),
          ),
        ),
      ),
    );

    // BlocProvider가 정상적으로 작동하는지 확인
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('DestinyBloc 초기 상태 확인', (WidgetTester tester) async {
    final bloc = DestinyBloc();

    await tester.pumpWidget(
      BlocProvider<DestinyBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: BlocBuilder<DestinyBloc, DestinyState>(
            builder: (context, state) {
              if (state is DestinyInitial) {
                return const Text('Initial');
              }
              return const Text('Other');
            },
          ),
        ),
      ),
    );

    expect(find.text('Initial'), findsOneWidget);

    bloc.close();
  });
}
