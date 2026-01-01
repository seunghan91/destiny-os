import 'package:equatable/equatable.dart';
import '../../../saju/domain/entities/saju_chart.dart';
import '../../../mbti/domain/entities/mbti_type.dart';

/// 궁합 분석 결과
class CompatibilityResult extends Equatable {
  final SajuChart myChart;
  final SajuChart partnerChart;
  final MbtiType myMbti;
  final MbtiType partnerMbti;
  final double overallScore;         // 전체 궁합 점수 (0~100)
  final SajuCompatibility sajuCompatibility;
  final MbtiCompatibility mbtiCompatibility;
  final CrossAnalysis crossAnalysis;  // 사주-MBTI 크로스 분석

  const CompatibilityResult({
    required this.myChart,
    required this.partnerChart,
    required this.myMbti,
    required this.partnerMbti,
    required this.overallScore,
    required this.sajuCompatibility,
    required this.mbtiCompatibility,
    required this.crossAnalysis,
  });

  /// 궁합 등급
  CompatibilityGrade get grade {
    if (overallScore >= 90) return CompatibilityGrade.soulmate;
    if (overallScore >= 75) return CompatibilityGrade.excellent;
    if (overallScore >= 60) return CompatibilityGrade.good;
    if (overallScore >= 45) return CompatibilityGrade.neutral;
    if (overallScore >= 30) return CompatibilityGrade.challenging;
    return CompatibilityGrade.difficult;
  }

  /// 한줄 요약
  String get oneLiner {
    switch (grade) {
      case CompatibilityGrade.soulmate:
        return '운명의 상대입니다. 서로를 완성시키는 조합!';
      case CompatibilityGrade.excellent:
        return '환상의 조합입니다. 함께할 때 시너지가 폭발합니다.';
      case CompatibilityGrade.good:
        return '좋은 궁합입니다. 노력하면 더 좋아질 수 있어요.';
      case CompatibilityGrade.neutral:
        return '평범한 궁합입니다. 서로의 차이를 이해하면 괜찮습니다.';
      case CompatibilityGrade.challenging:
        return '도전적인 궁합입니다. 서로 배울 점이 많습니다.';
      case CompatibilityGrade.difficult:
        return '까다로운 궁합입니다. 많은 노력이 필요합니다.';
    }
  }

  @override
  List<Object?> get props => [
    myChart, partnerChart, myMbti, partnerMbti,
    overallScore, sajuCompatibility, mbtiCompatibility, crossAnalysis,
  ];
}

/// 사주 궁합
class SajuCompatibility extends Equatable {
  final double score;
  final String dayPillarAnalysis;     // 일주 분석 (핵심)
  final bool hasClash;                // 충(沖) 여부
  final bool hasCombination;          // 합(合) 여부
  final String temperatureAnalysis;   // 조후(온도) 궁합
  final List<String> strengths;       // 강점
  final List<String> weaknesses;      // 약점

  const SajuCompatibility({
    required this.score,
    required this.dayPillarAnalysis,
    required this.hasClash,
    required this.hasCombination,
    required this.temperatureAnalysis,
    required this.strengths,
    required this.weaknesses,
  });

  /// 충/합 상태 요약
  String get clashCombinationSummary {
    if (hasCombination && !hasClash) return '합(合) - 자연스러운 조화';
    if (hasClash && !hasCombination) return '충(沖) - 강렬한 끌림 또는 갈등';
    if (hasCombination && hasClash) return '합충(合沖) - 복잡한 관계';
    return '보통 - 평범한 관계';
  }

  @override
  List<Object?> get props => [
    score, dayPillarAnalysis, hasClash, hasCombination,
    temperatureAnalysis, strengths, weaknesses,
  ];
}

/// MBTI 궁합
class MbtiCompatibility extends Equatable {
  final double score;
  final String relationshipType;      // 관계 유형
  final String communicationStyle;    // 소통 스타일
  final String conflictPattern;       // 갈등 패턴
  final List<String> commonGround;    // 공통점
  final List<String> differences;     // 차이점

  const MbtiCompatibility({
    required this.score,
    required this.relationshipType,
    required this.communicationStyle,
    required this.conflictPattern,
    required this.commonGround,
    required this.differences,
  });

  @override
  List<Object?> get props => [
    score, relationshipType, communicationStyle,
    conflictPattern, commonGround, differences,
  ];
}

/// 사주-MBTI 크로스 분석 (Gap Analysis)
class CrossAnalysis extends Equatable {
  final GapAnalysis myGap;        // 나의 사주-MBTI 괴리
  final GapAnalysis partnerGap;   // 상대의 사주-MBTI 괴리
  final String relationshipDynamic;  // 관계 역학
  final List<String> insights;       // 인사이트

  const CrossAnalysis({
    required this.myGap,
    required this.partnerGap,
    required this.relationshipDynamic,
    required this.insights,
  });

  @override
  List<Object?> get props => [myGap, partnerGap, relationshipDynamic, insights];
}

/// 사주-MBTI 괴리 분석
class GapAnalysis extends Equatable {
  final String sajuBasedMbti;     // 사주 기반 추정 MBTI
  final String actualMbti;        // 실제 MBTI
  final double gapScore;          // 괴리 정도 (0~100, 높을수록 큰 차이)
  final String interpretation;    // 해석

  const GapAnalysis({
    required this.sajuBasedMbti,
    required this.actualMbti,
    required this.gapScore,
    required this.interpretation,
  });

  /// 괴리가 큰지
  bool get hasSignificantGap => gapScore >= 50;

  @override
  List<Object?> get props => [sajuBasedMbti, actualMbti, gapScore, interpretation];
}

/// 궁합 등급
enum CompatibilityGrade {
  soulmate,     // 천생연분
  excellent,    // 최상
  good,         // 좋음
  neutral,      // 보통
  challenging,  // 도전적
  difficult,    // 어려움
}

extension CompatibilityGradeExtension on CompatibilityGrade {
  String get korean {
    switch (this) {
      case CompatibilityGrade.soulmate:
        return '천생연분';
      case CompatibilityGrade.excellent:
        return '최상';
      case CompatibilityGrade.good:
        return '좋음';
      case CompatibilityGrade.neutral:
        return '보통';
      case CompatibilityGrade.challenging:
        return '도전적';
      case CompatibilityGrade.difficult:
        return '노력 필요';
    }
  }

  String get emoji {
    switch (this) {
      case CompatibilityGrade.soulmate:
        return '💕';
      case CompatibilityGrade.excellent:
        return '❤️';
      case CompatibilityGrade.good:
        return '💛';
      case CompatibilityGrade.neutral:
        return '💙';
      case CompatibilityGrade.challenging:
        return '🧡';
      case CompatibilityGrade.difficult:
        return '💜';
    }
  }
}
