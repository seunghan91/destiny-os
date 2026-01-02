import 'dart:math';

import '../../../saju/domain/entities/saju_chart.dart';
import '../../domain/entities/daily_fortune.dart';
import '../models/daily_fortune_model.dart';
import 'stem_branch_service.dart';

/// 오늘의 운세 생성 서비스
class DailyFortuneGenerator {
  const DailyFortuneGenerator();

  /// 오늘의 운세 생성
  DailyFortune generate({
    required DateTime date,
    required SajuChart sajuChart,
    bool includePremium = false,
  }) {
    // 오늘의 간지 계산
    final dayStemBranch = StemBranchService.getDayStemBranch(date);

    // 일관성 있는 난수 생성을 위한 시드
    final seed = _generateSeed(date, sajuChart);
    final random = Random(seed);

    // 사주와 오늘 간지의 오행 관계 분석
    final compatibility = _analyzeCompatibility(
      sajuChart,
      dayStemBranch['stemElement']!,
      dayStemBranch['branchElement']!,
    );

    // 점수 계산
    final scores = _calculateScores(compatibility, random);

    // 행운 아이템 생성
    final luckyItems = _generateLuckyItems(
      dayStemBranch['stemElement']!,
      dayStemBranch['branchElement']!,
      random,
    );

    // 메시지 생성
    final messages = _generateMessages(
      scores,
      compatibility,
      dayStemBranch,
      sajuChart,
    );

    return DailyFortuneModel(
      date: DateTime(date.year, date.month, date.day),
      dayName: dayStemBranch['dayName']!,
      heavenlyStem: dayStemBranch['stem']!,
      earthlyBranch: dayStemBranch['branch']!,
      overallScore: scores['overall']!,
      loveScore: scores['love']!,
      wealthScore: scores['wealth']!,
      healthScore: scores['health']!,
      careerScore: scores['career']!,
      overallMessage: messages['overall']!,
      loveMessage: messages['love']!,
      wealthMessage: messages['wealth']!,
      healthMessage: messages['health']!,
      careerMessage: messages['career']!,
      luckyColor: luckyItems['color']!,
      luckyDirection: luckyItems['direction']!,
      luckyNumber: int.parse(luckyItems['number']!),
      luckyItem: luckyItems['item']!,
      caution: messages['caution']!,
      advice: messages['advice']!,
      morningFortune: includePremium
          ? _generateTimeFortune('06:00-12:00', '오전', scores, random)
          : null,
      afternoonFortune: includePremium
          ? _generateTimeFortune('12:00-18:00', '오후', scores, random)
          : null,
      eveningFortune: includePremium
          ? _generateTimeFortune('18:00-24:00', '저녁', scores, random)
          : null,
      weeklyPreview:
          includePremium ? _generateWeeklyPreview(date, sajuChart) : null,
    );
  }

  /// 일관성 있는 시드 생성
  int _generateSeed(DateTime date, SajuChart saju) {
    final dateHash = date.year * 10000 + date.month * 100 + date.day;
    final sajuHash = saju.dayPillar.hashCode;
    return dateHash ^ sajuHash;
  }

  /// 사주와 오늘 간지의 오행 호환성 분석
  Map<String, dynamic> _analyzeCompatibility(
    SajuChart saju,
    String todayStemElement,
    String todayBranchElement,
  ) {
    final dayMasterElement = saju.dayMasterElement;

    // 상생, 상극 관계 확인
    final stemGenerating =
        StemBranchService.isGenerating(dayMasterElement, todayStemElement);
    final stemOvercoming =
        StemBranchService.isOvercoming(dayMasterElement, todayStemElement);
    final branchGenerating =
        StemBranchService.isGenerating(dayMasterElement, todayBranchElement);
    final branchOvercoming =
        StemBranchService.isOvercoming(dayMasterElement, todayBranchElement);

    // 호환성 점수 계산 (0-100)
    int compatibilityScore = 50; // 기본

    if (stemGenerating) compatibilityScore += 15;
    if (branchGenerating) compatibilityScore += 10;
    if (stemOvercoming) compatibilityScore -= 15;
    if (branchOvercoming) compatibilityScore -= 10;

    // 동일 오행
    if (dayMasterElement == todayStemElement) compatibilityScore += 10;
    if (dayMasterElement == todayBranchElement) compatibilityScore += 5;

    return {
      'score': compatibilityScore.clamp(0, 100),
      'stemGenerating': stemGenerating,
      'stemOvercoming': stemOvercoming,
      'branchGenerating': branchGenerating,
      'branchOvercoming': branchOvercoming,
      'dayMasterElement': dayMasterElement,
    };
  }

  /// 항목별 점수 계산
  Map<String, int> _calculateScores(
    Map<String, dynamic> compatibility,
    Random random,
  ) {
    final baseScore = compatibility['score'] as int;

    // 기본 점수를 중심으로 각 항목별 점수 변화
    return {
      'overall': baseScore,
      'love': (baseScore + random.nextInt(21) - 10).clamp(0, 100),
      'wealth': (baseScore + random.nextInt(21) - 10).clamp(0, 100),
      'health': (baseScore + random.nextInt(21) - 10).clamp(0, 100),
      'career': (baseScore + random.nextInt(21) - 10).clamp(0, 100),
    };
  }

  /// 행운 아이템 생성
  Map<String, String> _generateLuckyItems(
    String stemElement,
    String branchElement,
    Random random,
  ) {
    // 오행별 행운의 색상
    const elementColors = {
      '목': ['초록색', '청록색', '연두색'],
      '화': ['빨강색', '주황색', '분홍색'],
      '토': ['노랑색', '갈색', '베이지색'],
      '금': ['흰색', '은색', '금색'],
      '수': ['파랑색', '검정색', '남색'],
    };

    // 오행별 방향
    const elementDirections = {
      '목': '동쪽',
      '화': '남쪽',
      '토': '중앙',
      '금': '서쪽',
      '수': '북쪽',
    };

    // 행운 아이템 목록
    const items = [
      '반지',
      '목걸이',
      '시계',
      '열쇠고리',
      '수첩',
      '펜',
      '가방',
      '모자',
      '스카프',
      '향수',
    ];

    final colors = elementColors[stemElement]!;
    final colorIndex = random.nextInt(colors.length);

    return {
      'color': colors[colorIndex],
      'direction': elementDirections[branchElement] ?? '동쪽',
      'number': '${random.nextInt(9) + 1}',
      'item': items[random.nextInt(items.length)],
    };
  }

  /// 메시지 생성
  Map<String, String> _generateMessages(
    Map<String, int> scores,
    Map<String, dynamic> compatibility,
    Map<String, String> dayStemBranch,
    SajuChart saju,
  ) {
    final overall = scores['overall']!;
    final love = scores['love']!;
    final wealth = scores['wealth']!;
    final health = scores['health']!;
    final career = scores['career']!;

    return {
      'overall': _getOverallMessage(overall, compatibility),
      'love': _getLoveMessage(love),
      'wealth': _getWealthMessage(wealth),
      'health': _getHealthMessage(health),
      'career': _getCareerMessage(career),
      'caution': _getCautionMessage(overall, compatibility),
      'advice': _getAdviceMessage(overall, dayStemBranch, saju),
    };
  }

  String _getOverallMessage(int score, Map<String, dynamic> compatibility) {
    if (score >= 85) {
      return '오늘은 최상의 운세가 펼쳐지는 날입니다. 하고자 하는 일에 적극적으로 도전해보세요. 특히 새로운 시작이나 중요한 결정을 내리기에 좋은 날입니다.';
    } else if (score >= 70) {
      return '전반적으로 좋은 기운이 흐르는 날입니다. 긍정적인 마음가짐으로 하루를 시작하면 좋은 결과를 얻을 수 있을 것입니다.';
    } else if (score >= 55) {
      return '평범한 하루가 예상됩니다. 무리하지 않고 차분하게 일상을 보내는 것이 좋겠습니다. 작은 것에 감사하는 마음을 가져보세요.';
    } else if (score >= 40) {
      return '조금 주의가 필요한 날입니다. 중요한 결정은 미루고, 신중하게 행동하는 것이 좋습니다. 휴식과 재정비의 시간으로 활용하세요.';
    } else {
      return '오늘은 수비적인 자세가 필요합니다. 새로운 일보다는 기존의 일을 점검하고 보완하는데 집중하세요. 무리한 도전은 피하는 것이 좋습니다.';
    }
  }

  String _getLoveMessage(int score) {
    if (score >= 80) {
      return '애정운이 매우 좋습니다. 솔직한 대화를 통해 관계가 더욱 돈독해질 수 있습니다. 싱글이라면 좋은 만남의 기회가 찾아올 수 있으니 적극적으로 나서보세요.';
    } else if (score >= 60) {
      return '평온한 애정 운세입니다. 작은 배려와 관심으로 상대방의 마음을 얻을 수 있습니다. 감사의 표현을 아끼지 마세요.';
    } else {
      return '감정 조절에 신경 쓰세요. 사소한 오해가 생길 수 있으니 차분한 대화가 필요합니다. 상대방의 입장을 먼저 생각해보세요.';
    }
  }

  String _getWealthMessage(int score) {
    if (score >= 80) {
      return '금전운이 상승하는 날입니다. 투자나 재테크에 관심을 가져보세요. 예상치 못한 수입이 있을 수 있습니다.';
    } else if (score >= 60) {
      return '안정적인 재물운입니다. 계획적인 소비와 저축이 중요합니다. 충동구매는 자제하세요.';
    } else {
      return '지출 관리에 신경 쓰세요. 불필요한 소비를 줄이고, 꼭 필요한 것만 구매하는 것이 좋습니다.';
    }
  }

  String _getHealthMessage(int score) {
    if (score >= 80) {
      return '건강 운세가 좋습니다. 활기찬 하루를 보낼 수 있습니다. 운동이나 야외 활동을 즐겨보세요.';
    } else if (score >= 60) {
      return '평범한 건강 운세입니다. 규칙적인 생활 습관을 유지하세요. 충분한 수면과 영양 섭취가 중요합니다.';
    } else {
      return '컨디션 관리에 주의하세요. 무리한 일정은 피하고 충분한 휴식을 취하세요. 스트레스 관리도 중요합니다.';
    }
  }

  String _getCareerMessage(int score) {
    if (score >= 80) {
      return '직업운이 활발합니다. 새로운 프로젝트나 업무에 도전해보세요. 능력을 인정받을 수 있는 기회입니다.';
    } else if (score >= 60) {
      return '안정적인 직업 운세입니다. 맡은 업무에 충실하면 좋은 결과를 얻을 수 있습니다.';
    } else {
      return '업무 처리에 신중함이 필요합니다. 실수하지 않도록 꼼꼼히 확인하세요. 협업에서는 원활한 소통을 유지하세요.';
    }
  }

  String _getCautionMessage(int score, Map<String, dynamic> compatibility) {
    if (score >= 70) {
      return '과신하지 말고 겸손한 태도를 유지하세요.';
    } else if (score >= 50) {
      return '성급한 판단을 피하고 신중하게 결정하세요.';
    } else {
      return '중요한 결정은 미루고, 휴식을 취하는 것이 좋습니다.';
    }
  }

  String _getAdviceMessage(
    int score,
    Map<String, String> dayStemBranch,
    SajuChart saju,
  ) {
    if (score >= 80) {
      return '오늘은 ${dayStemBranch['dayName']}로 ${dayStemBranch['stemElement']} 기운이 강한 날입니다. 적극적으로 나서되 다른 사람에 대한 배려도 잊지 마세요.';
    } else if (score >= 60) {
      return '균형잡힌 하루를 보내세요. ${dayStemBranch['stemElement']} 기운을 활용하여 조화로운 결정을 내리세요.';
    } else {
      return '${dayStemBranch['stemElement']} 기운이 강한 날이지만, 오늘은 신중하게 행동하는 것이 좋습니다. 내일을 준비하는 하루로 만드세요.';
    }
  }

  /// 시간대별 운세 생성 (프리미엄)
  TimeFortuneModel _generateTimeFortune(
    String timeRange,
    String timeName,
    Map<String, int> baseScores,
    Random random,
  ) {
    final score =
        (baseScores['overall']! + random.nextInt(21) - 10).clamp(0, 100);

    final messages = {
      '오전': score >= 70
          ? '오전 시간대가 가장 활발합니다. 중요한 일은 오전에 처리하세요.'
          : '오전에는 여유롭게 시작하세요. 급하게 서두르지 마세요.',
      '오후': score >= 70
          ? '오후에 좋은 기회가 찾아올 수 있습니다. 적극적으로 대응하세요.'
          : '오후에는 차분하게 업무를 정리하는 시간을 가지세요.',
      '저녁': score >= 70
          ? '저녁 시간을 활용하여 소중한 사람들과 시간을 보내세요.'
          : '저녁에는 휴식을 취하며 내일을 준비하세요.',
    };

    final recommendations = {
      '오전': score >= 70 ? '중요한 회의나 미팅 진행' : '가벼운 업무로 시작',
      '오후': score >= 70 ? '새로운 도전이나 제안' : '업무 정리 및 검토',
      '저녁': score >= 70 ? '사교 활동, 만남' : '휴식 및 재충전',
    };

    return TimeFortuneModel(
      timeRange: timeRange,
      score: score,
      message: messages[timeName]!,
      recommendation: recommendations[timeName]!,
    );
  }

  /// 주간 운세 미리보기 생성 (프리미엄)
  WeeklyPreviewModel _generateWeeklyPreview(
    DateTime date,
    SajuChart saju,
  ) {
    // 주의 시작일 (월요일)
    final weekStart =
        date.subtract(Duration(days: date.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    // 요일별 점수 생성
    final dailyScores = <String, int>{};
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    int peakScore = 0;
    int cautionScore = 100;
    String peakDay = '';
    String cautionDay = '';

    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final dayFortune = generate(date: dayDate, sajuChart: saju);
      final score = dayFortune.overallScore;

      dailyScores[days[i]] = score;

      if (score > peakScore) {
        peakScore = score;
        peakDay = '${days[i]}요일';
      }
      if (score < cautionScore) {
        cautionScore = score;
        cautionDay = '${days[i]}요일';
      }
    }

    // 평균 점수로 주간 테마 결정
    final avgScore =
        dailyScores.values.reduce((a, b) => a + b) / dailyScores.length;

    final weeklyTheme = avgScore >= 75
        ? '도약의 한 주'
        : avgScore >= 60
            ? '안정의 한 주'
            : '재정비의 한 주';

    final weeklyAdvice = avgScore >= 75
        ? '이번 주는 적극적으로 기회를 잡으세요. 특히 $peakDay에 중요한 일정을 잡는 것이 좋습니다.'
        : avgScore >= 60
            ? '꾸준함이 중요한 한 주입니다. 계획적으로 일을 진행하세요.'
            : '무리하지 말고 현재 상태를 점검하고 보완하는 시간을 가지세요.';

    return WeeklyPreviewModel(
      weekRange:
          '${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day}',
      dailyScores: dailyScores,
      peakDay: peakDay,
      cautionDay: cautionDay,
      weeklyTheme: weeklyTheme,
      weeklyAdvice: weeklyAdvice,
    );
  }
}
