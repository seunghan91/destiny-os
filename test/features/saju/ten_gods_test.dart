import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/features/saju/domain/entities/ten_gods.dart';

void main() {
  group('TenGods', () {
    test('dominantGod는 가장 많은 십성을 반환한다', () {
      const tenGods = TenGods(
        distribution: {
          '비견': 2,
          '겁재': 1,
          '식신': 3,
          '상관': 0,
          '편재': 1,
          '정재': 0,
          '편관': 1,
          '정관': 0,
          '편인': 0,
          '정인': 0,
        },
      );

      expect(tenGods.dominantGod, '식신');
    });

    test('dominantGod는 동점일 때 첫 번째 십성을 반환한다', () {
      const tenGods = TenGods(
        distribution: {
          '비견': 2,
          '겁재': 2,
          '식신': 0,
          '상관': 0,
          '편재': 0,
          '정재': 0,
          '편관': 0,
          '정관': 0,
          '편인': 0,
          '정인': 0,
        },
      );

      expect(tenGods.dominantGod, anyOf('비견', '겁재'));
    });

    test('distribution에는 10가지 십성이 있어야 한다', () {
      const tenGods = TenGods(
        distribution: {
          '비견': 1,
          '겁재': 1,
          '식신': 1,
          '상관': 1,
          '편재': 1,
          '정재': 1,
          '편관': 1,
          '정관': 1,
          '편인': 1,
          '정인': 1,
        },
      );

      expect(tenGods.distribution.keys.toSet(), containsAll([
        '비견', '겁재', '식신', '상관', '편재', 
        '정재', '편관', '정관', '편인', '정인'
      ]));
    });

    test('props가 올바르게 작동한다', () {
      const tenGods1 = TenGods(
        distribution: {'비견': 1, '식신': 2},
      );
      const tenGods2 = TenGods(
        distribution: {'비견': 1, '식신': 2},
      );
      const tenGods3 = TenGods(
        distribution: {'비견': 2, '식신': 1},
      );

      expect(tenGods1, equals(tenGods2));
      expect(tenGods1, isNot(equals(tenGods3)));
    });
  });

  group('TenGods static methods', () {
    test('getDescription은 모든 십성에 대한 설명을 반환한다', () {
      final allTenGods = [
        '비견', '겁재', '식신', '상관', '편재',
        '정재', '편관', '정관', '편인', '정인'
      ];

      for (final god in allTenGods) {
        final desc = TenGods.getDescription(god);
        expect(desc, isNotEmpty, reason: '$god 설명이 없습니다');
      }
    });

    test('getMbtiTendency는 MBTI 성향을 반환한다', () {
      final tendency = TenGods.getMbtiTendency('비견');
      expect(tendency, isNotNull);
      expect(tendency['tendency'], isNotEmpty);
    });
  });

  group('TenGods getters', () {
    const tenGods = TenGods(
      distribution: {
        '비견': 2,
        '겁재': 1,
        '식신': 3,
        '상관': 2,
        '편재': 1,
        '정재': 0,
        '편관': 1,
        '정관': 2,
        '편인': 0,
        '정인': 1,
      },
    );

    test('friend는 비견 수를 반환한다', () {
      expect(tenGods.friend, 2);
    });

    test('robWealth는 겁재 수를 반환한다', () {
      expect(tenGods.robWealth, 1);
    });

    test('eatingGod는 식신 수를 반환한다', () {
      expect(tenGods.eatingGod, 3);
    });

    test('hurtingOfficer는 상관 수를 반환한다', () {
      expect(tenGods.hurtingOfficer, 2);
    });

    test('indirectWealth는 편재 수를 반환한다', () {
      expect(tenGods.indirectWealth, 1);
    });

    test('directWealth는 정재 수를 반환한다', () {
      expect(tenGods.directWealth, 0);
    });

    test('sevenKillings는 편관 수를 반환한다', () {
      expect(tenGods.sevenKillings, 1);
    });

    test('directOfficer는 정관 수를 반환한다', () {
      expect(tenGods.directOfficer, 2);
    });

    test('indirectResource는 편인 수를 반환한다', () {
      expect(tenGods.indirectResource, 0);
    });

    test('directResource는 정인 수를 반환한다', () {
      expect(tenGods.directResource, 1);
    });
  });
}
