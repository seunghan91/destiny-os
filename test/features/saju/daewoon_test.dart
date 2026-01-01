import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/features/saju/domain/entities/saju_chart.dart';
import 'package:destiny_os/features/saju/domain/entities/daewoon.dart';

void main() {
  group('Daewoon', () {
    test('isCurrentDaewoon은 현재 나이가 범위 내일 때 true를 반환한다', () {
      final daewoon = Daewoon(
        startAge: 25,
        endAge: 35,
        pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
        theme: '재물 축적의 시기',
        description: '경제적 기회가 많아지는 시기입니다.',
        fortuneScore: 80.0,
      );

      expect(daewoon.isCurrentDaewoon(25), true);
      expect(daewoon.isCurrentDaewoon(30), true);
      expect(daewoon.isCurrentDaewoon(34), true);
      expect(daewoon.isCurrentDaewoon(35), false); // endAge는 포함되지 않음
      expect(daewoon.isCurrentDaewoon(24), false);
    });

    test('periodString은 올바른 기간 문자열을 반환한다', () {
      final daewoon = Daewoon(
        startAge: 25,
        endAge: 35,
        pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
        theme: '재물 축적의 시기',
        description: '',
        fortuneScore: 80.0,
      );

      expect(daewoon.periodString, '25세 ~ 34세');
    });

    test('themeEmoji는 테마에 맞는 이모지를 반환한다', () {
      final testCases = [
        ('재물 축적기', '💰'),
        ('명예 추구기', '🏆'),
        ('학업 성취기', '📚'),
        ('사업 확장기', '🚀'),
        ('안정 유지기', '🏠'),
        ('도전 모험기', '⚔️'),
        ('인간관계 확장기', '🤝'),
        ('자아 성찰기', '🧘'),
        ('알 수 없는 테마', '✨'),
      ];

      for (final (theme, expectedEmoji) in testCases) {
        final daewoon = Daewoon(
          startAge: 25,
          endAge: 35,
          pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
          theme: theme,
          description: '',
          fortuneScore: 80.0,
        );
        expect(daewoon.themeEmoji, expectedEmoji, reason: 'Theme: $theme');
      }
    });

    test('props는 모든 필드를 포함한다', () {
      final daewoon1 = Daewoon(
        startAge: 25,
        endAge: 35,
        pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
        theme: '재물 축적의 시기',
        description: '테스트',
        fortuneScore: 80.0,
      );
      final daewoon2 = Daewoon(
        startAge: 25,
        endAge: 35,
        pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '자'),
        theme: '재물 축적의 시기',
        description: '테스트',
        fortuneScore: 80.0,
      );

      expect(daewoon1, equals(daewoon2));
    });
  });

  group('DaewoonChart', () {
    late List<Daewoon> testDaewoons;

    setUp(() {
      testDaewoons = [
        Daewoon(
          startAge: 5,
          endAge: 15,
          pillar: const Pillar(heavenlyStem: '기', earthlyBranch: '묘'),
          theme: '학습과 성장의 시기',
          description: '',
          fortuneScore: 68.0,
        ),
        Daewoon(
          startAge: 15,
          endAge: 25,
          pillar: const Pillar(heavenlyStem: '경', earthlyBranch: '진'),
          theme: '도전과 발전의 시기',
          description: '',
          fortuneScore: 72.0,
        ),
        Daewoon(
          startAge: 25,
          endAge: 35,
          pillar: const Pillar(heavenlyStem: '신', earthlyBranch: '사'),
          theme: '재물 축적의 시기',
          description: '',
          fortuneScore: 80.0,
        ),
        Daewoon(
          startAge: 35,
          endAge: 45,
          pillar: const Pillar(heavenlyStem: '임', earthlyBranch: '오'),
          theme: '표현과 성취의 시기',
          description: '',
          fortuneScore: 85.0,
        ),
        Daewoon(
          startAge: 45,
          endAge: 55,
          pillar: const Pillar(heavenlyStem: '계', earthlyBranch: '미'),
          theme: '자아 확립의 시기',
          description: '',
          fortuneScore: 70.0,
        ),
      ];
    });

    test('currentDaewoon은 현재 나이에 해당하는 대운을 반환한다', () {
      final chart = DaewoonChart(
        daewoons: testDaewoons,
        currentAge: 30,
      );

      final current = chart.currentDaewoon;
      expect(current, isNotNull);
      expect(current!.theme, '재물 축적의 시기');
    });

    test('currentDaewoon은 해당 대운이 없으면 null을 반환한다', () {
      final chart = DaewoonChart(
        daewoons: testDaewoons,
        currentAge: 100,
      );

      expect(chart.currentDaewoon, isNull);
    });

    test('nextDaewoon은 다음 대운을 반환한다', () {
      final chart = DaewoonChart(
        daewoons: testDaewoons,
        currentAge: 30,
      );

      final next = chart.nextDaewoon;
      expect(next, isNotNull);
      expect(next!.theme, '표현과 성취의 시기');
    });

    test('nextDaewoon은 마지막 대운일 때 null을 반환한다', () {
      final chart = DaewoonChart(
        daewoons: testDaewoons,
        currentAge: 50,
      );

      expect(chart.nextDaewoon, isNull);
    });

    test('yearsUntilNextDaewoon은 다음 대운까지 남은 기간을 반환한다', () {
      final chart = DaewoonChart(
        daewoons: testDaewoons,
        currentAge: 30,
      );

      expect(chart.yearsUntilNextDaewoon, 5); // 35 - 30
    });
  });
}
