import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/ten_gods.dart';
import '../../domain/entities/daewoon.dart';
import '../../data/services/saju_calculator.dart';
import '../../../mbti/domain/entities/mbti_type.dart';
import '../../../fortune_2026/domain/entities/fortune_2026.dart';

// ========== Events ==========

abstract class DestinyEvent extends Equatable {
  const DestinyEvent();

  @override
  List<Object?> get props => [];
}

/// 운세 분석 시작
class AnalyzeFortune extends DestinyEvent {
  final DateTime birthDateTime;
  final bool isLunar;
  final String mbtiType;
  final String gender;
  final bool useNightSubhour;  // 야자시 사용 여부

  const AnalyzeFortune({
    required this.birthDateTime,
    required this.isLunar,
    required this.mbtiType,
    required this.gender,
    this.useNightSubhour = false,
  });

  @override
  List<Object?> get props => [birthDateTime, isLunar, mbtiType, gender, useNightSubhour];
}

/// 생년월일 업데이트
class UpdateBirthData extends DestinyEvent {
  final DateTime birthDateTime;
  final bool isLunar;

  const UpdateBirthData({
    required this.birthDateTime,
    required this.isLunar,
  });

  @override
  List<Object?> get props => [birthDateTime, isLunar];
}

/// MBTI 업데이트
class UpdateMbti extends DestinyEvent {
  final String mbtiType;

  const UpdateMbti({required this.mbtiType});

  @override
  List<Object?> get props => [mbtiType];
}

/// 데이터 초기화
class ResetDestinyData extends DestinyEvent {}

// ========== States ==========

abstract class DestinyState extends Equatable {
  const DestinyState();

  @override
  List<Object?> get props => [];
}

/// 초기 상태
class DestinyInitial extends DestinyState {}

/// 분석 중
class DestinyAnalyzing extends DestinyState {
  final String message;

  const DestinyAnalyzing({this.message = '운명을 분석하고 있습니다...'});

  @override
  List<Object?> get props => [message];
}

/// 분석 성공
class DestinySuccess extends DestinyState {
  final SajuChart sajuChart;
  final TenGods tenGods;
  final DaewoonChart daewoonChart;
  final MbtiType mbtiType;
  final Fortune2026 fortune2026;
  final GapAnalysisResult gapAnalysis;

  const DestinySuccess({
    required this.sajuChart,
    required this.tenGods,
    required this.daewoonChart,
    required this.mbtiType,
    required this.fortune2026,
    required this.gapAnalysis,
  });

  @override
  List<Object?> get props => [
    sajuChart, tenGods, daewoonChart, mbtiType, fortune2026, gapAnalysis,
  ];
}

/// 분석 실패
class DestinyFailure extends DestinyState {
  final String errorMessage;

  const DestinyFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// 입력 진행 중
class DestinyInputProgress extends DestinyState {
  final DateTime? birthDateTime;
  final bool? isLunar;
  final String? mbtiType;
  final String? gender;

  const DestinyInputProgress({
    this.birthDateTime,
    this.isLunar,
    this.mbtiType,
    this.gender,
  });

  bool get isComplete =>
      birthDateTime != null &&
      isLunar != null &&
      mbtiType != null &&
      gender != null;

  DestinyInputProgress copyWith({
    DateTime? birthDateTime,
    bool? isLunar,
    String? mbtiType,
    String? gender,
  }) {
    return DestinyInputProgress(
      birthDateTime: birthDateTime ?? this.birthDateTime,
      isLunar: isLunar ?? this.isLunar,
      mbtiType: mbtiType ?? this.mbtiType,
      gender: gender ?? this.gender,
    );
  }

  @override
  List<Object?> get props => [birthDateTime, isLunar, mbtiType, gender];
}

// ========== Gap Analysis Result ==========

/// MBTI 차원별 괴리 분석
class DimensionGap extends Equatable {
  final String dimension;     // E/I, N/S, T/F, J/P
  final String sajuValue;     // 사주 기반 값
  final String actualValue;   // 실제 값
  final bool hasGap;          // 괴리 여부
  final String description;   // 차원 설명
  final String insight;       // 인사이트

  const DimensionGap({
    required this.dimension,
    required this.sajuValue,
    required this.actualValue,
    required this.hasGap,
    required this.description,
    required this.insight,
  });

  @override
  List<Object?> get props => [dimension, sajuValue, actualValue, hasGap, description, insight];
}

/// 사주-MBTI 괴리 분석 결과
class GapAnalysisResult extends Equatable {
  final String sajuBasedMbti;         // 사주 기반 추정 MBTI
  final String actualMbti;            // 실제 MBTI
  final double gapScore;              // 괴리 점수 (0~100)
  final String interpretation;        // 해석
  final String hiddenPotential;       // 숨겨진 잠재력
  final List<DimensionGap> dimensionGaps;  // 차원별 분석
  final List<String> recommendations;      // 조언 목록

  const GapAnalysisResult({
    required this.sajuBasedMbti,
    required this.actualMbti,
    required this.gapScore,
    required this.interpretation,
    required this.hiddenPotential,
    this.dimensionGaps = const [],
    this.recommendations = const [],
  });

  bool get hasSignificantGap => gapScore >= 50;

  /// 일치하는 차원 수
  int get matchCount => dimensionGaps.where((d) => !d.hasGap).length;

  /// 불일치하는 차원 수
  int get mismatchCount => dimensionGaps.where((d) => d.hasGap).length;

  @override
  List<Object?> get props => [
    sajuBasedMbti, actualMbti, gapScore, interpretation, hiddenPotential,
    dimensionGaps, recommendations,
  ];
}

// ========== BLoC ==========

class DestinyBloc extends Bloc<DestinyEvent, DestinyState> {
  final SajuCalculator _calculator = SajuCalculator.instance;

  DestinyBloc() : super(DestinyInitial()) {
    on<AnalyzeFortune>(_onAnalyzeFortune);
    on<UpdateBirthData>(_onUpdateBirthData);
    on<UpdateMbti>(_onUpdateMbti);
    on<ResetDestinyData>(_onResetDestinyData);
  }

  Future<void> _onAnalyzeFortune(
    AnalyzeFortune event,
    Emitter<DestinyState> emit,
  ) async {
    debugPrint('🔮 [DestinyBloc] AnalyzeFortune event received');
    debugPrint('🔮 [DestinyBloc] birthDateTime: ${event.birthDateTime}');
    debugPrint('🔮 [DestinyBloc] mbtiType: ${event.mbtiType}');
    emit(const DestinyAnalyzing(message: '사주팔자를 계산하고 있습니다...'));

    try {
      // 1. 사주팔자 계산 (SajuCalculator 사용)
      await Future.delayed(const Duration(milliseconds: 500));
      emit(const DestinyAnalyzing(message: '십성을 분석하고 있습니다...'));

      final sajuChart = _calculator.calculateSajuChart(
        birthDateTime: event.birthDateTime,
        isLunar: event.isLunar,
        gender: event.gender == 'male' ? '남' : '여',
        useNightSubhour: event.useNightSubhour,
      );

      // 2. 십성 계산
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const DestinyAnalyzing(message: '대운을 분석하고 있습니다...'));

      final tenGods = _calculator.calculateTenGods(sajuChart);

      // 3. 대운 계산
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const DestinyAnalyzing(message: '2026년 운세를 분석하고 있습니다...'));

      final daewoonChart = _calculator.calculateDaewoon(sajuChart);

      // 4. 2026년 운세 계산
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const DestinyAnalyzing(message: 'MBTI와 사주를 비교 분석하고 있습니다...'));

      final fortune2026 = _calculateFortune2026(sajuChart);

      // 5. Gap Analysis (사주-MBTI 괴리 분석)
      await Future.delayed(const Duration(milliseconds: 300));

      final mbtiType = MbtiType(type: event.mbtiType);
      final sajuBasedMbti = _calculator.inferMbtiFromSaju(sajuChart, tenGods);
      final gapAnalysis = _performGapAnalysis(sajuBasedMbti, mbtiType);

      debugPrint('🔮 [DestinyBloc] Analysis complete, emitting DestinySuccess');
      emit(DestinySuccess(
        sajuChart: sajuChart,
        tenGods: tenGods,
        daewoonChart: daewoonChart,
        mbtiType: mbtiType,
        fortune2026: fortune2026,
        gapAnalysis: gapAnalysis,
      ));
    } catch (e, stackTrace) {
      debugPrint('❌ [DestinyBloc] Error: $e');
      debugPrint('❌ [DestinyBloc] StackTrace: $stackTrace');
      emit(DestinyFailure(errorMessage: '분석 중 오류가 발생했습니다: $e'));
    }
  }

  void _onUpdateBirthData(
    UpdateBirthData event,
    Emitter<DestinyState> emit,
  ) {
    final currentState = state;
    if (currentState is DestinyInputProgress) {
      emit(currentState.copyWith(
        birthDateTime: event.birthDateTime,
        isLunar: event.isLunar,
      ));
    } else {
      emit(DestinyInputProgress(
        birthDateTime: event.birthDateTime,
        isLunar: event.isLunar,
      ));
    }
  }

  void _onUpdateMbti(
    UpdateMbti event,
    Emitter<DestinyState> emit,
  ) {
    final currentState = state;
    if (currentState is DestinyInputProgress) {
      emit(currentState.copyWith(mbtiType: event.mbtiType));
    } else {
      emit(DestinyInputProgress(mbtiType: event.mbtiType));
    }
  }

  void _onResetDestinyData(
    ResetDestinyData event,
    Emitter<DestinyState> emit,
  ) {
    emit(DestinyInitial());
  }

  // ========== 2026 운세 계산 ==========

  Fortune2026 _calculateFortune2026(SajuChart chart) {
    // 2026년 병오년 운세 계산
    // 화기 비율은 yearAnalysis에서 활용됨

    // 2026년 궁합 분석 (SajuCalculator 사용)
    final yearAnalysis = _calculator.analyzeYearCompatibility(chart, year: 2026);

    final monthlyFortunes = List.generate(12, (index) {
      final month = index + 1;
      // 5~6월은 화기 최고, 11월은 자오충
      double baseScore = 50 + (15 * (1 - (month - 6).abs() / 6));
      double fireEnergy = 50 + (month >= 5 && month <= 7 ? 40 : 0);

      if (month == 11) {
        baseScore -= 20;  // 자오충
      }

      if (yearAnalysis.isFireBeneficial) {
        baseScore += 15;
      }

      return MonthlyFortune(
        month: month,
        score: baseScore.clamp(0, 100),
        theme: _getMonthTheme(month),
        advice: _getMonthAdvice(month, yearAnalysis.isFireBeneficial),
        fireEnergy: fireEnergy,
        hasClash: month == 11,
        hasCombination: month == 6,
      );
    });

    return Fortune2026(
      sajuChart: chart,
      overallScore: yearAnalysis.score.toDouble(),
      yearTheme: yearAnalysis.isFireBeneficial ? '불꽃 같은 성장의 해' : '내면 단련의 해',
      yearAdvice: yearAnalysis.analysis,
      monthlyFortunes: monthlyFortunes,
      fireCompatibility: FireCompatibility(
        compatibilityScore: yearAnalysis.score.toDouble(),
        description: yearAnalysis.isFireBeneficial
            ? '2026년은 당신의 무대입니다!'
            : '과열 주의보. 냉각 시스템이 필요합니다.',
        advantages: yearAnalysis.isFireBeneficial
            ? ['활발한 사회 활동', '새로운 기회 포착', '인지도 상승']
            : ['내면 성장', '신중한 판단력', '재충전의 기회'],
        cautions: yearAnalysis.isFireBeneficial
            ? ['과신 주의', '건강 관리 필요']
            : ['성급한 결정 금물', '갈등 상황 회피', '스트레스 관리'],
      ),
    );
  }

  String _getMonthTheme(int month) {
    const themes = {
      1: '새로운 시작', 2: '준비와 계획', 3: '성장의 싹',
      4: '활발한 교류', 5: '열정의 절정', 6: '최고의 에너지',
      7: '결실 준비', 8: '성과 수확', 9: '정리의 시간',
      10: '마무리', 11: '변화의 바람', 12: '휴식과 성찰',
    };
    return themes[month] ?? '평온';
  }

  String _getMonthAdvice(int month, bool isFireBeneficial) {
    if (month == 11) {
      return '충(沖) 주의: 대인관계에서 언행을 삼가고 중요한 결정은 미루세요.';
    }
    if (month >= 5 && month <= 7) {
      return isFireBeneficial
          ? '최고의 시기입니다. 과감하게 도전하세요!'
          : '열기가 과합니다. 휴식을 충분히 취하세요.';
    }
    return '균형 잡힌 시기입니다. 꾸준히 나아가세요.';
  }

  // ========== Gap 분석 ==========

  GapAnalysisResult _performGapAnalysis(
    String sajuBasedMbti,
    MbtiType actualMbti,
  ) {
    // 차원별 괴리 분석
    final dimensionGaps = <DimensionGap>[];
    final recommendations = <String>[];

    // E/I 차원 분석
    dimensionGaps.add(_analyzeDimension(
      'E/I',
      sajuBasedMbti[0],
      actualMbti.type[0],
      '에너지 방향',
    ));

    // N/S 차원 분석
    dimensionGaps.add(_analyzeDimension(
      'N/S',
      sajuBasedMbti[1],
      actualMbti.type[1],
      '정보 수집',
    ));

    // T/F 차원 분석
    dimensionGaps.add(_analyzeDimension(
      'T/F',
      sajuBasedMbti[2],
      actualMbti.type[2],
      '의사 결정',
    ));

    // J/P 차원 분석
    dimensionGaps.add(_analyzeDimension(
      'J/P',
      sajuBasedMbti[3],
      actualMbti.type[3],
      '생활 양식',
    ));

    // 괴리 점수 계산
    final matchCount = dimensionGaps.where((d) => !d.hasGap).length;
    final gapScore = (4 - matchCount) * 25.0;

    // 맞춤형 조언 생성
    for (final gap in dimensionGaps) {
      if (gap.hasGap) {
        recommendations.add(_getRecommendation(gap.dimension, gap.sajuValue, gap.actualValue));
      }
    }

    // 해석 생성
    String interpretation;
    String hiddenPotential;

    if (gapScore >= 75) {
      interpretation = '현재의 모습과 내면의 잠재력 사이에 큰 괴리가 있습니다. '
          '당신은 ${actualMbti.koreanName}(${actualMbti.type})로 살고 있지만, '
          '사주는 ${_getMbtiKoreanName(sajuBasedMbti)}($sajuBasedMbti)의 기질을 품고 있습니다. '
          '이것은 결함이 아니라 풍부한 잠재력의 증거입니다.';
      hiddenPotential = '2026년 병오년에는 숨겨진 ${_getMbtiKoreanName(sajuBasedMbti)} 기질이 '
          '깨어날 수 있습니다. 화(火)의 강한 에너지가 내면의 잠재력을 자극합니다. '
          '새로운 도전을 두려워하지 마세요!';
      recommendations.add('내면의 목소리에 귀 기울여 보세요. 사주가 말하는 당신의 모습을 탐구해보는 것도 좋습니다.');
    } else if (gapScore >= 50) {
      interpretation = '내면과 외면 사이에 흥미로운 차이가 있습니다. '
          '이 괴리는 때로는 내적 갈등의 원인이 되기도 하지만, '
          '동시에 상황에 따라 다양한 모습을 보여줄 수 있는 유연성의 원천이기도 합니다.';
      hiddenPotential = '양면성을 긍정적으로 활용하면 다양한 상황에서 빛날 수 있습니다. '
          '2026년에는 두 성향 모두를 활용할 기회가 올 것입니다.';
      recommendations.add('상황에 따라 두 가지 모드를 의식적으로 전환해보세요.');
    } else if (gapScore >= 25) {
      interpretation = '대체로 자연스러운 흐름 속에 살고 있습니다. '
          '약간의 괴리는 오히려 성장의 여지를 남겨둡니다.';
      hiddenPotential = '현재의 방향을 유지하면서 작은 변화를 시도해보세요.';
    } else {
      interpretation = '현재의 모습이 타고난 기질과 매우 잘 일치합니다! '
          '자연스럽고 진정성 있게 자신만의 길을 걸어가고 있습니다. '
          '이것은 매우 드문 조화입니다.';
      hiddenPotential = '당신은 이미 최적의 상태에 있습니다. '
          '현재의 방향을 믿고 꾸준히 나아가세요. 2026년에도 순조로울 것입니다.';
    }

    return GapAnalysisResult(
      sajuBasedMbti: sajuBasedMbti,
      actualMbti: actualMbti.type,
      gapScore: gapScore,
      interpretation: interpretation,
      hiddenPotential: hiddenPotential,
      dimensionGaps: dimensionGaps,
      recommendations: recommendations,
    );
  }

  DimensionGap _analyzeDimension(
    String dimension,
    String sajuValue,
    String actualValue,
    String dimensionName,
  ) {
    final hasGap = sajuValue != actualValue;

    String description;
    String insight;

    switch (dimension) {
      case 'E/I':
        if (hasGap) {
          if (sajuValue == 'E') {
            description = '사주는 외향적 에너지를 가졌지만, 현재는 내향적으로 생활합니다.';
            insight = '사교적 기회를 더 활용하면 숨은 리더십이 발휘될 수 있습니다.';
          } else {
            description = '사주는 내향적 기질이지만, 현재는 외향적으로 생활합니다.';
            insight = '혼자만의 시간을 더 갖는 것이 내면의 균형에 도움이 됩니다.';
          }
        } else {
          description = '에너지 방향이 자연스럽게 일치합니다.';
          insight = sajuValue == 'E'
              ? '사교적 활동이 당신에게 활력을 줍니다.'
              : '내면의 세계에서 에너지를 충전합니다.';
        }
        break;

      case 'N/S':
        if (hasGap) {
          if (sajuValue == 'N') {
            description = '사주는 직관적 사고를 가졌지만, 현재는 감각적으로 인식합니다.';
            insight = '큰 그림을 보는 연습이 창의력을 깨울 수 있습니다.';
          } else {
            description = '사주는 감각적 기질이지만, 현재는 직관적으로 사고합니다.';
            insight = '구체적인 사실에 집중하면 실행력이 높아집니다.';
          }
        } else {
          description = '정보 수집 방식이 일관됩니다.';
          insight = sajuValue == 'N'
              ? '패턴과 가능성을 읽는 능력이 뛰어납니다.'
              : '현실적이고 실용적인 관점이 강점입니다.';
        }
        break;

      case 'T/F':
        if (hasGap) {
          if (sajuValue == 'T') {
            description = '사주는 논리적 판단을 가졌지만, 현재는 감정적으로 결정합니다.';
            insight = '중요한 결정에서 객관적 분석을 더하면 균형이 잡힙니다.';
          } else {
            description = '사주는 감정적 기질이지만, 현재는 논리적으로 판단합니다.';
            insight = '타인의 감정을 더 고려하면 관계가 깊어집니다.';
          }
        } else {
          description = '의사 결정 방식이 자연스럽습니다.';
          insight = sajuValue == 'T'
              ? '논리와 공정함으로 신뢰를 얻습니다.'
              : '공감 능력이 대인관계의 핵심입니다.';
        }
        break;

      case 'J/P':
        if (hasGap) {
          if (sajuValue == 'J') {
            description = '사주는 계획적 성향이지만, 현재는 유연하게 생활합니다.';
            insight = '일정 관리에 조금 더 집중하면 성과가 높아집니다.';
          } else {
            description = '사주는 자유로운 기질이지만, 현재는 계획적으로 생활합니다.';
            insight = '가끔은 계획 없이 흘러가는 것도 좋습니다.';
          }
        } else {
          description = '생활 양식이 타고난 기질과 맞습니다.';
          insight = sajuValue == 'J'
              ? '체계적인 접근이 당신의 강점입니다.'
              : '유연성이 새로운 기회를 만들어냅니다.';
        }
        break;

      default:
        description = '';
        insight = '';
    }

    return DimensionGap(
      dimension: dimension,
      sajuValue: sajuValue,
      actualValue: actualValue,
      hasGap: hasGap,
      description: description,
      insight: insight,
    );
  }

  String _getRecommendation(String dimension, String sajuValue, String actualValue) {
    switch (dimension) {
      case 'E/I':
        if (sajuValue == 'E') {
          return '2026년에는 새로운 모임이나 네트워킹에 참여해보세요. 내면의 사교적 에너지가 빛날 수 있습니다.';
        } else {
          return '2026년에는 명상이나 독서 시간을 늘려보세요. 내면의 평화가 외부 활동의 균형을 맞춥니다.';
        }
      case 'N/S':
        if (sajuValue == 'N') {
          return '2026년에는 창의적 프로젝트나 미래 계획에 시간을 투자해보세요.';
        } else {
          return '2026년에는 실용적인 스킬을 배우거나 구체적인 목표를 세워보세요.';
        }
      case 'T/F':
        if (sajuValue == 'T') {
          return '2026년 중요한 결정에서는 데이터와 논리를 더 활용해보세요.';
        } else {
          return '2026년에는 팀워크와 협업에서 공감 능력을 발휘해보세요.';
        }
      case 'J/P':
        if (sajuValue == 'J') {
          return '2026년에는 장기 목표를 세우고 단계적으로 실행해보세요.';
        } else {
          return '2026년에는 즉흥적인 여행이나 새로운 경험을 시도해보세요.';
        }
      default:
        return '';
    }
  }

  String _getMbtiKoreanName(String type) {
    const names = {
      'INTJ': '전략가', 'INTP': '논리술사', 'ENTJ': '통솔자', 'ENTP': '변론가',
      'INFJ': '옹호자', 'INFP': '중재자', 'ENFJ': '선도자', 'ENFP': '활동가',
      'ISTJ': '현실주의자', 'ISFJ': '수호자', 'ESTJ': '경영자', 'ESFJ': '집정관',
      'ISTP': '장인', 'ISFP': '모험가', 'ESTP': '사업가', 'ESFP': '연예인',
    };
    return names[type] ?? type;
  }
}
