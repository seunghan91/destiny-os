import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/shared/widgets/saju_explanations.dart';

void main() {
  group('SajuExplanation', () {
    test('모든 필수 필드가 설정된다', () {
      const explanation = SajuExplanation(
        title: '테스트 타이틀',
        shortDesc: '짧은 설명',
        detailDesc: '상세 설명',
        icon: Icons.info,
      );

      expect(explanation.title, '테스트 타이틀');
      expect(explanation.shortDesc, '짧은 설명');
      expect(explanation.detailDesc, '상세 설명');
      expect(explanation.icon, Icons.info);
    });

    test('detailDesc는 선택적이다', () {
      const explanation = SajuExplanation(
        title: '테스트 타이틀',
        shortDesc: '짧은 설명',
      );

      expect(explanation.detailDesc, isNull);
    });
  });

  group('SajuExplanations.pillars', () {
    test('4개의 기둥(년주, 월주, 일주, 시주)에 대한 설명이 있다', () {
      expect(SajuExplanations.pillars.containsKey('년주'), true);
      expect(SajuExplanations.pillars.containsKey('월주'), true);
      expect(SajuExplanations.pillars.containsKey('일주'), true);
      expect(SajuExplanations.pillars.containsKey('시주'), true);
    });

    test('년주 설명이 올바르다', () {
      final yearPillar = SajuExplanations.pillars['년주'];
      expect(yearPillar, isNotNull);
      expect(yearPillar!.title, contains('년주'));
      expect(yearPillar.shortDesc, contains('조상궁'));
      expect(yearPillar.shortDesc, contains('1~15세'));
    });

    test('월주 설명이 올바르다', () {
      final monthPillar = SajuExplanations.pillars['월주'];
      expect(monthPillar, isNotNull);
      expect(monthPillar!.title, contains('월주'));
      expect(monthPillar.shortDesc, contains('부모궁'));
      expect(monthPillar.shortDesc, contains('16~30세'));
    });

    test('일주 설명이 올바르다', () {
      final dayPillar = SajuExplanations.pillars['일주'];
      expect(dayPillar, isNotNull);
      expect(dayPillar!.title, contains('일주'));
      expect(dayPillar.shortDesc, contains('본인궁'));
      expect(dayPillar.shortDesc, contains('배우자운'));
    });

    test('시주 설명이 올바르다', () {
      final hourPillar = SajuExplanations.pillars['시주'];
      expect(hourPillar, isNotNull);
      expect(hourPillar!.title, contains('시주'));
      expect(hourPillar.shortDesc, contains('자녀궁'));
      expect(hourPillar.shortDesc, contains('말년기'));
    });
  });

  group('SajuExplanations.tenGods', () {
    test('10가지 십성에 대한 설명이 있다', () {
      final allTenGods = [
        '비견', '겁재', '식신', '상관', '편재',
        '정재', '편관', '정관', '편인', '정인', '일원'
      ];

      for (final god in allTenGods) {
        expect(SajuExplanations.tenGods.containsKey(god), true, 
            reason: '$god에 대한 설명이 없습니다');
        final explanation = SajuExplanations.tenGods[god];
        expect(explanation!.title, isNotEmpty);
        expect(explanation.shortDesc, isNotEmpty);
      }
    });

    test('비견 설명이 올바르다', () {
      final bigyeon = SajuExplanations.tenGods['비견'];
      expect(bigyeon, isNotNull);
      expect(bigyeon!.title, contains('비견'));
      expect(bigyeon.shortDesc, contains('형제'));
    });

    test('일원 설명이 올바르다', () {
      final ilwon = SajuExplanations.tenGods['일원'];
      expect(ilwon, isNotNull);
      expect(ilwon!.title, contains('일원'));
      expect(ilwon.shortDesc, contains('나 자신'));
    });
  });

  group('SajuExplanations.twelveStates', () {
    test('12가지 십이운성에 대한 설명이 있다', () {
      final allTwelveStates = [
        '장생', '목욕', '관대', '건록', '제왕', '쇠',
        '병', '사', '묘', '절', '태', '양'
      ];

      for (final state in allTwelveStates) {
        expect(SajuExplanations.twelveStates.containsKey(state), true,
            reason: '$state에 대한 설명이 없습니다');
        final explanation = SajuExplanations.twelveStates[state];
        expect(explanation!.title, isNotEmpty);
        expect(explanation.shortDesc, isNotEmpty);
      }
    });

    test('장생 설명이 올바르다', () {
      final jangsaeng = SajuExplanations.twelveStates['장생'];
      expect(jangsaeng, isNotNull);
      expect(jangsaeng!.title, contains('장생'));
      expect(jangsaeng.shortDesc, contains('탄생'));
    });

    test('제왕 설명이 올바르다', () {
      final jewang = SajuExplanations.twelveStates['제왕'];
      expect(jewang, isNotNull);
      expect(jewang!.title, contains('제왕'));
      expect(jewang.shortDesc, contains('정점'));
    });
  });

  group('SajuExplanations.elements', () {
    test('5가지 오행에 대한 설명이 있다 (한자, 한글 모두)', () {
      // 한자
      expect(SajuExplanations.elements.containsKey('木'), true);
      expect(SajuExplanations.elements.containsKey('火'), true);
      expect(SajuExplanations.elements.containsKey('土'), true);
      expect(SajuExplanations.elements.containsKey('金'), true);
      expect(SajuExplanations.elements.containsKey('水'), true);
      
      // 한글
      expect(SajuExplanations.elements.containsKey('나무'), true);
      expect(SajuExplanations.elements.containsKey('불'), true);
      expect(SajuExplanations.elements.containsKey('흙'), true);
      expect(SajuExplanations.elements.containsKey('쇠'), true);
      expect(SajuExplanations.elements.containsKey('물'), true);
    });

    test('목(木) 설명이 올바르다', () {
      final wood = SajuExplanations.elements['木'];
      expect(wood, isNotNull);
      expect(wood!.title, contains('목'));
      expect(wood.shortDesc, contains('성장'));
      expect(wood.shortDesc, contains('봄'));
    });

    test('화(火) 설명이 올바르다', () {
      final fire = SajuExplanations.elements['火'];
      expect(fire, isNotNull);
      expect(fire!.title, contains('화'));
      expect(fire.shortDesc, contains('열정'));
      expect(fire.shortDesc, contains('여름'));
    });
  });

  group('SajuExplanations.find', () {
    test('pillars에서 찾는다', () {
      final result = SajuExplanations.find('년주');
      expect(result, isNotNull);
      expect(result!.title, contains('년주'));
    });

    test('tenGods에서 찾는다', () {
      final result = SajuExplanations.find('비견');
      expect(result, isNotNull);
      expect(result!.title, contains('비견'));
    });

    test('twelveStates에서 찾는다', () {
      final result = SajuExplanations.find('건록');
      expect(result, isNotNull);
      expect(result!.title, contains('건록'));
    });

    test('elements에서 찾는다', () {
      final result = SajuExplanations.find('水');
      expect(result, isNotNull);
      expect(result!.title, contains('수'));
    });

    test('없는 키는 null을 반환한다', () {
      final result = SajuExplanations.find('없는키');
      expect(result, isNull);
    });
  });
}
