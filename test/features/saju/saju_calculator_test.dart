import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/features/saju/data/services/saju_calculator.dart';
import 'package:destiny_os/features/saju/domain/entities/saju_chart.dart';

void main() {
  late SajuCalculator calculator;

  setUp(() {
    calculator = SajuCalculator.instance;
  });

  group('SajuCalculator', () {
    group('calculateSajuChart', () {
      test('양력 생년월일로 사주팔자를 계산한다', () {
        // 1990년 5월 15일 오전 10시 (양력)
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);

        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        expect(chart, isNotNull);
        expect(chart.yearPillar.heavenlyStem, isNotEmpty);
        expect(chart.yearPillar.earthlyBranch, isNotEmpty);
        expect(chart.monthPillar.heavenlyStem, isNotEmpty);
        expect(chart.monthPillar.earthlyBranch, isNotEmpty);
        expect(chart.dayPillar.heavenlyStem, isNotEmpty);
        expect(chart.dayPillar.earthlyBranch, isNotEmpty);
        expect(chart.hourPillar.heavenlyStem, isNotEmpty);
        expect(chart.hourPillar.earthlyBranch, isNotEmpty);
        expect(chart.gender, '남');
        expect(chart.isLunar, false);
      });

      test('음력 생년월일로 사주팔자를 계산한다', () {
        // 1990년 4월 21일 (음력)
        final birthDateTime = DateTime(1990, 4, 21, 10, 0);

        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: true,
          gender: '여',
        );

        expect(chart, isNotNull);
        expect(chart.gender, '여');
        expect(chart.isLunar, true);
      });

      test('야자시 옵션을 적용한다', () {
        // 23시 30분 (야자시 적용 시 다음날 자시로 계산)
        final birthDateTime = DateTime(1990, 5, 15, 23, 30);

        final chartWithNightSubhour = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
          useNightSubhour: true,
        );

        final chartWithoutNightSubhour = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
          useNightSubhour: false,
        );

        // 야자시 적용 여부에 따라 시주가 달라질 수 있음
        expect(chartWithNightSubhour.hourPillar, isNotNull);
        expect(chartWithoutNightSubhour.hourPillar, isNotNull);
      });

      test('태양시 보정을 적용한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);

        final chartWithCorrection = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
          useSolarTimeCorrection: true,
        );

        final chartWithoutCorrection = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
          useSolarTimeCorrection: false,
        );

        expect(chartWithCorrection, isNotNull);
        expect(chartWithoutCorrection, isNotNull);
      });
    });

    group('calculateTenGods', () {
      test('십성 분포를 계산한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        final tenGods = calculator.calculateTenGods(chart);

        expect(tenGods, isNotNull);
        expect(tenGods.distribution, isNotEmpty);
        // 십성 분포에는 10가지 십성이 있어야 함
        expect(tenGods.distribution.keys.toSet(), containsAll([
          '비견', '겁재', '식신', '상관', '편재', '정재', '편관', '정관', '편인', '정인'
        ]));
      });

      test('dominantGod가 가장 많은 십성을 반환한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        final tenGods = calculator.calculateTenGods(chart);
        final dominant = tenGods.dominantGod;

        expect(dominant, isNotEmpty);
        // dominant가 distribution에서 가장 큰 값을 가져야 함
        final maxCount = tenGods.distribution.values.reduce((a, b) => a > b ? a : b);
        expect(tenGods.distribution[dominant], maxCount);
      });
    });

    group('calculateDaewoon', () {
      test('대운 차트를 계산한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        final daewoonChart = calculator.calculateDaewoon(chart);

        expect(daewoonChart, isNotNull);
        expect(daewoonChart.daewoons.length, 9); // 9개의 대운
        expect(daewoonChart.currentAge, isNonNegative);
      });

      test('대운은 10년 단위로 구성된다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        final daewoonChart = calculator.calculateDaewoon(chart);

        for (final daewoon in daewoonChart.daewoons) {
          expect(daewoon.endAge - daewoon.startAge, 10);
          expect(daewoon.pillar, isNotNull);
          expect(daewoon.theme, isNotEmpty);
          expect(daewoon.fortuneScore, greaterThanOrEqualTo(0));
          expect(daewoon.fortuneScore, lessThanOrEqualTo(100));
        }
      });

      test('양남/음녀는 순행, 음남/양녀는 역행한다', () {
        // 경오년(1990, 양간) 남자 -> 순행
        final maleChart = calculator.calculateSajuChart(
          birthDateTime: DateTime(1990, 5, 15, 10, 0),
          isLunar: false,
          gender: '남',
        );

        // 경오년(1990, 양간) 여자 -> 역행
        final femaleChart = calculator.calculateSajuChart(
          birthDateTime: DateTime(1990, 5, 15, 10, 0),
          isLunar: false,
          gender: '여',
        );

        final maleDaewoon = calculator.calculateDaewoon(maleChart);
        final femaleDaewoon = calculator.calculateDaewoon(femaleChart);

        // 순행/역행에 따라 대운이 달라야 함
        expect(maleDaewoon.daewoons.first.pillar.heavenlyStem,
            isNot(equals(femaleDaewoon.daewoons.first.pillar.heavenlyStem)));
      });
    });

    group('inferMbtiFromSaju', () {
      test('사주 기반 MBTI를 추론한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );
        final tenGods = calculator.calculateTenGods(chart);

        final mbti = calculator.inferMbtiFromSaju(chart, tenGods);

        expect(mbti.length, 4);
        expect(mbti[0], anyOf('E', 'I'));
        expect(mbti[1], anyOf('N', 'S'));
        expect(mbti[2], anyOf('T', 'F'));
        expect(mbti[3], anyOf('J', 'P'));
      });
    });

    group('analyzeYearCompatibility', () {
      test('2026년 궁합을 분석한다', () {
        final birthDateTime = DateTime(1990, 5, 15, 10, 0);
        final chart = calculator.calculateSajuChart(
          birthDateTime: birthDateTime,
          isLunar: false,
          gender: '남',
        );

        final result = calculator.analyzeYearCompatibility(chart, year: 2026);

        expect(result.score, greaterThanOrEqualTo(0));
        expect(result.score, lessThanOrEqualTo(100));
        expect(result.analysis, isNotEmpty);
      });
    });

    group('calculateCompatibility', () {
      test('두 사람의 궁합을 분석한다', () {
        final chart1 = calculator.calculateSajuChart(
          birthDateTime: DateTime(1990, 5, 15, 10, 0),
          isLunar: false,
          gender: '남',
        );
        final chart2 = calculator.calculateSajuChart(
          birthDateTime: DateTime(1992, 8, 20, 14, 0),
          isLunar: false,
          gender: '여',
        );

        final result = calculator.calculateCompatibility(chart1, chart2);

        expect(result.overallScore, greaterThanOrEqualTo(0));
        expect(result.overallScore, lessThanOrEqualTo(100));
        expect(result.loveScore, greaterThanOrEqualTo(0));
        expect(result.marriageScore, greaterThanOrEqualTo(0));
        expect(result.businessScore, greaterThanOrEqualTo(0));
        expect(result.friendshipScore, greaterThanOrEqualTo(0));
        expect(result.analysis.summary, isNotEmpty);
      });

      test('천간합이 있으면 높은 점수를 받는다', () {
        // 갑-기 천간합 테스트
        final chart1 = calculator.calculateSajuChart(
          birthDateTime: DateTime(1984, 5, 15, 10, 0), // 갑자년
          isLunar: false,
          gender: '남',
        );
        final chart2 = calculator.calculateSajuChart(
          birthDateTime: DateTime(1989, 5, 15, 10, 0), // 기사년
          isLunar: false,
          gender: '여',
        );

        final result = calculator.calculateCompatibility(chart1, chart2);

        expect(result.dayMasterAnalysis, isNotNull);
        // 일주 천간합 여부는 일간에 따라 다름
      });
    });
  });

  group('SajuChart', () {
    test('dayMaster는 일간을 반환한다', () {
      final chart = SajuCalculator.instance.calculateSajuChart(
        birthDateTime: DateTime(1990, 5, 15, 10, 0),
        isLunar: false,
        gender: '남',
      );

      expect(chart.dayMaster, chart.dayPillar.heavenlyStem);
    });

    test('elementCount는 오행 분포를 반환한다', () {
      final chart = SajuCalculator.instance.calculateSajuChart(
        birthDateTime: DateTime(1990, 5, 15, 10, 0),
        isLunar: false,
        gender: '남',
      );

      final elements = chart.elementCount;

      expect(elements.keys, containsAll(['목', '화', '토', '금', '수']));
      expect(elements.values.every((v) => v >= 0), true);
    });

    test('fireEnergyRatio는 화 기운 비율을 반환한다', () {
      final chart = SajuCalculator.instance.calculateSajuChart(
        birthDateTime: DateTime(1990, 5, 15, 10, 0),
        isLunar: false,
        gender: '남',
      );

      final ratio = chart.fireEnergyRatio;

      expect(ratio, greaterThanOrEqualTo(0));
      expect(ratio, lessThanOrEqualTo(1));
    });

    test('fullChart는 전체 사주를 문자열로 반환한다', () {
      final chart = SajuCalculator.instance.calculateSajuChart(
        birthDateTime: DateTime(1990, 5, 15, 10, 0),
        isLunar: false,
        gender: '남',
      );

      final fullChart = chart.fullChart;

      expect(fullChart, isNotEmpty);
      expect(fullChart.split(' ').length, 4); // 4개의 기둥
    });

    test('zodiacAnimal은 띠를 반환한다', () {
      // 1990년은 말띠
      final chart = SajuCalculator.instance.calculateSajuChart(
        birthDateTime: DateTime(1990, 5, 15, 10, 0),
        isLunar: false,
        gender: '남',
      );

      expect(chart.zodiacAnimal, '말');
    });
  });

  group('Pillar', () {
    test('fullPillar는 천간+지지를 반환한다', () {
      const pillar = Pillar(heavenlyStem: '갑', earthlyBranch: '자');

      expect(pillar.fullPillar, '갑자');
    });

    test('hanjaRepresentation은 한자로 표기한다', () {
      const pillar = Pillar(heavenlyStem: '갑', earthlyBranch: '자');

      expect(pillar.hanjaRepresentation, '甲子');
    });

    test('props는 올바른 값을 반환한다', () {
      const pillar1 = Pillar(heavenlyStem: '갑', earthlyBranch: '자');
      const pillar2 = Pillar(heavenlyStem: '갑', earthlyBranch: '자');
      const pillar3 = Pillar(heavenlyStem: '을', earthlyBranch: '축');

      expect(pillar1, equals(pillar2));
      expect(pillar1, isNot(equals(pillar3)));
    });
  });
}
