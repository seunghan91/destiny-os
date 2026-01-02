import 'package:equatable/equatable.dart';
import '../../../saju/domain/entities/saju_chart.dart';

/// 2026년 병오년 운세
class Fortune2026 extends Equatable {
  final SajuChart sajuChart;
  final double overallScore; // 전체 운세 점수 (0~100)
  final String yearTheme; // 올해의 테마
  final String yearAdvice; // 올해의 조언
  final FortuneNarrative narrative;
  final List<MonthlyFortune> monthlyFortunes; // 월별 운세
  final FireCompatibility fireCompatibility; // 화(火) 기운과의 궁합

  const Fortune2026({
    required this.sajuChart,
    required this.overallScore,
    required this.yearTheme,
    required this.yearAdvice,
    required this.narrative,
    required this.monthlyFortunes,
    required this.fireCompatibility,
  });

  /// 운세 등급
  FortuneLevel get fortuneLevel {
    if (overallScore >= 80) return FortuneLevel.excellent;
    if (overallScore >= 60) return FortuneLevel.good;
    if (overallScore >= 40) return FortuneLevel.neutral;
    if (overallScore >= 20) return FortuneLevel.caution;
    return FortuneLevel.challenge;
  }

  /// 가장 좋은 달
  MonthlyFortune? get bestMonth {
    if (monthlyFortunes.isEmpty) return null;
    return monthlyFortunes.reduce((a, b) => a.score > b.score ? a : b);
  }

  /// 주의해야 할 달
  MonthlyFortune? get worstMonth {
    if (monthlyFortunes.isEmpty) return null;
    return monthlyFortunes.reduce((a, b) => a.score < b.score ? a : b);
  }

  /// 11월 자오충 주의 여부
  bool get hasNovemberClash {
    // 병오년의 오(午)와 자(子)월의 충돌
    return monthlyFortunes.any((m) => m.month == 11 && m.hasClash);
  }

  @override
  List<Object?> get props => [
    sajuChart,
    overallScore,
    yearTheme,
    yearAdvice,
    narrative,
    monthlyFortunes,
    fireCompatibility,
  ];
}

class FortuneNarrative extends Equatable {
  final String overall;
  final String best;
  final String caution;
  final String advice;

  const FortuneNarrative({
    required this.overall,
    required this.best,
    required this.caution,
    required this.advice,
  });

  @override
  List<Object?> get props => [overall, best, caution, advice];
}

/// 월별 운세
class MonthlyFortune extends Equatable {
  final int month; // 1~12
  final double score; // 운세 점수 (0~100)
  final String theme; // 이달의 테마
  final String advice; // 이달의 조언
  final double fireEnergy; // 화기(火氣) 레벨
  final bool hasClash; // 충(沖) 여부
  final bool hasCombination; // 합(合) 여부

  const MonthlyFortune({
    required this.month,
    required this.score,
    required this.theme,
    required this.advice,
    required this.fireEnergy,
    required this.hasClash,
    required this.hasCombination,
  });

  /// 월 이름 (한국어)
  String get monthName => '$month월';

  /// 절기 기준 월명
  String get solarTermMonth {
    const months = {
      1: '축월(丑月)',
      2: '인월(寅月)',
      3: '묘월(卯月)',
      4: '진월(辰月)',
      5: '사월(巳月)',
      6: '오월(午月)',
      7: '미월(未月)',
      8: '신월(申月)',
      9: '유월(酉月)',
      10: '술월(戌月)',
      11: '해월(亥月)/자월(子月)',
      12: '축월(丑月)',
    };
    return months[month] ?? '$month월';
  }

  /// 화기(火氣) 레벨 설명
  String get fireEnergyDescription {
    if (fireEnergy >= 80) return '열정 과다 - 번아웃 주의';
    if (fireEnergy >= 60) return '활발한 에너지 - 적극적 활동 권장';
    if (fireEnergy >= 40) return '균형잡힌 에너지';
    if (fireEnergy >= 20) return '차분한 에너지 - 내면 성찰 시기';
    return '냉각 필요 - 휴식 권장';
  }

  @override
  List<Object?> get props => [
    month,
    score,
    theme,
    advice,
    fireEnergy,
    hasClash,
    hasCombination,
  ];
}

/// 화(火) 기운 궁합
class FireCompatibility extends Equatable {
  final double compatibilityScore; // 2026년 화기와의 궁합 점수
  final String description;
  final List<String> advantages; // 유리한 점
  final List<String> cautions; // 주의할 점

  const FireCompatibility({
    required this.compatibilityScore,
    required this.description,
    required this.advantages,
    required this.cautions,
  });

  /// 화(火) 기운이 보완 오행인지 (사주에 화 기운이 필요한 사람인지)
  bool get isFireBeneficial => compatibilityScore >= 60;

  /// 요약 메시지
  String get summaryMessage {
    if (isFireBeneficial) {
      return '2026년은 당신의 무대입니다. 물 들어올 때 노 저으세요!';
    } else {
      return '과열 주의보 발령. 성급한 결정은 금물입니다.';
    }
  }

  @override
  List<Object?> get props => [
    compatibilityScore,
    description,
    advantages,
    cautions,
  ];
}

/// 운세 등급
enum FortuneLevel {
  excellent, // 대길
  good, // 길
  neutral, // 평
  caution, // 주의
  challenge, // 흉
}

extension FortuneLevelExtension on FortuneLevel {
  String get korean {
    switch (this) {
      case FortuneLevel.excellent:
        return '대길';
      case FortuneLevel.good:
        return '길';
      case FortuneLevel.neutral:
        return '평';
      case FortuneLevel.caution:
        return '주의';
      case FortuneLevel.challenge:
        return '흉';
    }
  }

  String get description {
    switch (this) {
      case FortuneLevel.excellent:
        return '최고의 운세입니다. 적극적으로 도전하세요!';
      case FortuneLevel.good:
        return '좋은 흐름입니다. 꾸준히 나아가세요.';
      case FortuneLevel.neutral:
        return '평범한 시기입니다. 기본에 충실하세요.';
      case FortuneLevel.caution:
        return '조심해야 할 시기입니다. 신중하게 결정하세요.';
      case FortuneLevel.challenge:
        return '도전적인 시기입니다. 내면을 단련하는 시간입니다.';
    }
  }
}
