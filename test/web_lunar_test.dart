import 'package:flutter_test/flutter_test.dart';
import 'package:lunar/lunar.dart';

/// Critical test for lunar package web compatibility
///
/// This package is the core of saju (四柱) calculation system.
/// If this fails on web, the entire fortune-telling feature won't work.
void main() {
  group('Lunar Package Web Compatibility', () {
    test('lunar package basic initialization works on web', () {
      final lunar = Lunar.fromDate(DateTime(2026, 1, 1));
      expect(lunar, isNotNull);
    });

    test('lunar can calculate 60甲子 (sexagenary cycle) for 2026', () {
      // 사주에서 새해는 입춘부터 시작
      // 2026-01-01은 입춘 전이므로 아직 을사년 (乙巳年)
      final lunar = Lunar.fromDate(DateTime(2026, 1, 1));
      final yearGanZhi = lunar.getYearInGanZhi();

      // 입춘 전이므로 을사년이어야 함
      expect(yearGanZhi, equals('乙巳'));
    });

    test('lunar can calculate month pillar (월주)', () {
      final lunar = Lunar.fromDate(DateTime(2026, 6, 15));
      final monthGanZhi = lunar.getMonthInGanZhi();

      expect(monthGanZhi, isNotNull);
      expect(monthGanZhi.length, greaterThan(0));
    });

    test('lunar can calculate day pillar (일주)', () {
      final lunar = Lunar.fromDate(DateTime(2026, 6, 15));
      final dayGanZhi = lunar.getDayInGanZhi();

      expect(dayGanZhi, isNotNull);
      expect(dayGanZhi.length, greaterThan(0));
    });

    test('lunar can convert between solar and lunar calendar', () {
      // 양력 2026-01-01 → 음력 변환 테스트
      final lunar = Lunar.fromDate(DateTime(2026, 1, 1));
      final lunarYear = lunar.getYear();
      final lunarMonth = lunar.getMonth();
      final lunarDay = lunar.getDay();

      expect(lunarYear, isNotNull);
      expect(lunarMonth, greaterThan(0));
      expect(lunarMonth, lessThanOrEqualTo(12));
      expect(lunarDay, greaterThan(0));
      expect(lunarDay, lessThanOrEqualTo(30));
    });

    test('lunar can get solar terms (절기)', () {
      // 절기 정보 가져오기 테스트
      final lunar = Lunar.fromDate(DateTime(2026, 2, 4)); // 입춘 근처
      final jieQi = lunar.getJieQi(); // 현재 절기 이름

      expect(jieQi, isNotNull);
    });

    test('lunar handles edge cases: year boundaries', () {
      // 연말연초 경계 테스트
      // 사주에서는 입춘 전까지 이전 년도로 간주
      final lastDay2025 = Lunar.fromDate(DateTime(2025, 12, 31));
      final firstDay2026 = Lunar.fromDate(DateTime(2026, 1, 1));

      expect(lastDay2025.getYearInGanZhi(), isNotNull);
      // 2026-01-01은 입춘 전이므로 아직 을사년
      expect(firstDay2026.getYearInGanZhi(), equals('乙巳'));
    });

    test('lunar package performance on web', () {
      final stopwatch = Stopwatch()..start();

      // 100번 연속 계산 (성능 테스트)
      for (int i = 0; i < 100; i++) {
        final lunar = Lunar.fromDate(DateTime(2026, 1, 1 + i));
        lunar.getYearInGanZhi();
        lunar.getMonthInGanZhi();
        lunar.getDayInGanZhi();
      }

      stopwatch.stop();

      // 100번 계산이 1초 이내여야 함
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Lunar calculations should be fast enough for real-time use');
    });
  });
}
