// Destiny.OS 기본 위젯 테스트

import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/app/app.dart';

void main() {
  testWidgets('Destiny.OS 앱 스모크 테스트', (WidgetTester tester) async {
    // 앱 빌드 및 프레임 트리거
    await tester.pumpWidget(const DestinyApp());
    await tester.pumpAndSettle();

    // 스플래시 화면이 로드되는지 확인
    // 앱이 정상적으로 시작되면 테스트 통과
    expect(find.byType(DestinyApp), findsOneWidget);
  });
}
