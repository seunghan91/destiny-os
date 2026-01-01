import '../../../saju/domain/entities/saju_chart.dart';

/// 궁합 계산 서비스
/// 일주 기반 합/충/형/파/해 분석 및 오행 균형 분석
class CompatibilityCalculator {
  CompatibilityCalculator._();
  static final CompatibilityCalculator instance = CompatibilityCalculator._();

  // 천간 오행
  static const Map<String, String> _stemToElement = {
    '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
    '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
  };

  // 지지 오행
  static const Map<String, String> _branchToElement = {
    '자': '수', '축': '토', '인': '목', '묘': '목', '진': '토', '사': '화',
    '오': '화', '미': '토', '신': '금', '유': '금', '술': '토', '해': '수',
  };

  // ============================================
  // 천간합 (天干合) - 서로 합이 되는 관계
  // ============================================
  static const Map<String, String> _stemCombinations = {
    '갑': '기', '기': '갑', // 갑기합토
    '을': '경', '경': '을', // 을경합금
    '병': '신', '신': '병', // 병신합수
    '정': '임', '임': '정', // 정임합목
    '무': '계', '계': '무', // 무계합화
  };

  // ============================================
  // 지지 육합 (六合) - 서로 합이 되는 관계
  // ============================================
  static const Map<String, String> _branchSixCombinations = {
    '자': '축', '축': '자', // 자축합토
    '인': '해', '해': '인', // 인해합목
    '묘': '술', '술': '묘', // 묘술합화
    '진': '유', '유': '진', // 진유합금
    '사': '신', '신': '사', // 사신합수
    '오': '미', '미': '오', // 오미합화
  };

  // ============================================
  // 지지 삼합 (三合) - 세 지지가 합하여 오행 형성
  // ============================================
  static const Map<String, List<String>> _branchTripleCombinations = {
    '목': ['인', '오', '술'], // 인오술 삼합 화국
    '화': ['사', '유', '축'], // 사유축 삼합 금국
    '금': ['신', '자', '진'], // 신자진 삼합 수국
    '수': ['해', '묘', '미'], // 해묘미 삼합 목국
  };

  // 반합(半合) - 삼합의 부분
  static const List<List<String>> _branchHalfCombinations = [
    ['인', '오'], ['오', '술'], ['인', '술'], // 인오술의 반합
    ['사', '유'], ['유', '축'], ['사', '축'], // 사유축의 반합
    ['신', '자'], ['자', '진'], ['신', '진'], // 신자진의 반합
    ['해', '묘'], ['묘', '미'], ['해', '미'], // 해묘미의 반합
  ];

  // ============================================
  // 지지충 (地支沖) - 서로 충돌하는 관계
  // ============================================
  static const Map<String, String> _branchClashes = {
    '자': '오', '오': '자', // 자오충
    '축': '미', '미': '축', // 축미충
    '인': '신', '신': '인', // 인신충
    '묘': '유', '유': '묘', // 묘유충
    '진': '술', '술': '진', // 진술충
    '사': '해', '해': '사', // 사해충
  };

  // ============================================
  // 지지형 (地支刑) - 서로 형벌하는 관계
  // ============================================
  // 인사신형(무례지형), 축술미형(지세지형), 자묘형(무례지형), 자기형(자형)
  static const List<List<String>> _branchPunishments = [
    ['인', '사'], ['사', '신'], ['신', '인'], // 인사신 삼형
    ['축', '술'], ['술', '미'], ['미', '축'], // 축술미 삼형
    ['자', '묘'], ['묘', '자'], // 자묘형
  ];

  // 자형 (스스로 형벌)
  static const List<String> _selfPunishments = ['진', '오', '유', '해'];

  // ============================================
  // 지지파 (地支破) - 서로 파괴하는 관계
  // ============================================
  static const Map<String, String> _branchBreaks = {
    '자': '유', '유': '자',
    '축': '진', '진': '축',
    '인': '해', '해': '인',
    '묘': '오', '오': '묘',
    '사': '신', '신': '사',
    '미': '술', '술': '미',
  };

  // ============================================
  // 지지해 (地支害) - 서로 해를 끼치는 관계
  // ============================================
  static const Map<String, String> _branchHarms = {
    '자': '미', '미': '자',
    '축': '오', '오': '축',
    '인': '사', '사': '인',
    '묘': '진', '진': '묘',
    '신': '해', '해': '신',
    '유': '술', '술': '유',
  };

  /// 두 사주의 궁합 분석
  CompatibilityResult calculateCompatibility(
    SajuChart chart1,
    SajuChart chart2,
  ) {
    // 일주 분석 (가장 중요)
    final dayPillarAnalysis = _analyzeDayPillars(
      chart1.dayPillar,
      chart2.dayPillar,
    );

    // 전체 지지 관계 분석
    final branchRelations = _analyzeAllBranchRelations(chart1, chart2);

    // 오행 균형 분석
    final elementBalance = _analyzeElementBalance(chart1, chart2);

    // 천간 관계 분석
    final stemRelations = _analyzeStemRelations(chart1, chart2);

    // 종합 점수 계산
    final overallScore = _calculateOverallScore(
      dayPillarAnalysis,
      branchRelations,
      elementBalance,
      stemRelations,
    );

    // 카테고리별 점수
    final categoryScores = _calculateCategoryScores(
      dayPillarAnalysis,
      branchRelations,
      elementBalance,
    );

    return CompatibilityResult(
      overallScore: overallScore,
      loveScore: categoryScores['love']!,
      marriageScore: categoryScores['marriage']!,
      businessScore: categoryScores['business']!,
      friendshipScore: categoryScores['friendship']!,
      dayPillarAnalysis: dayPillarAnalysis,
      branchRelations: branchRelations,
      elementBalance: elementBalance,
      stemRelations: stemRelations,
      insights: _generateInsights(
        dayPillarAnalysis,
        branchRelations,
        elementBalance,
      ),
    );
  }

  /// 일주 분석
  DayPillarAnalysis _analyzeDayPillars(Pillar day1, Pillar day2) {
    final relations = <String>[];
    var score = 60; // 기본 점수

    // 천간합 확인
    if (_stemCombinations[day1.heavenlyStem] == day2.heavenlyStem) {
      relations.add('천간합');
      score += 15;
    }

    // 지지 육합 확인
    if (_branchSixCombinations[day1.earthlyBranch] == day2.earthlyBranch) {
      relations.add('육합');
      score += 20;
    }

    // 지지 삼합/반합 확인
    for (final combo in _branchHalfCombinations) {
      if ((combo[0] == day1.earthlyBranch && combo[1] == day2.earthlyBranch) ||
          (combo[1] == day1.earthlyBranch && combo[0] == day2.earthlyBranch)) {
        relations.add('반합');
        score += 10;
        break;
      }
    }

    // 지지충 확인
    if (_branchClashes[day1.earthlyBranch] == day2.earthlyBranch) {
      relations.add('충');
      score -= 15;
    }

    // 지지형 확인
    for (final punishment in _branchPunishments) {
      if ((punishment[0] == day1.earthlyBranch && punishment[1] == day2.earthlyBranch) ||
          (punishment[1] == day1.earthlyBranch && punishment[0] == day2.earthlyBranch)) {
        relations.add('형');
        score -= 10;
        break;
      }
    }

    // 지지파 확인
    if (_branchBreaks[day1.earthlyBranch] == day2.earthlyBranch) {
      relations.add('파');
      score -= 8;
    }

    // 지지해 확인
    if (_branchHarms[day1.earthlyBranch] == day2.earthlyBranch) {
      relations.add('해');
      score -= 12;
    }

    // 같은 오행/상생/상극 확인 (천간이 깨진 경우에도 크래시 방지)
    final element1 = _stemToElement[day1.heavenlyStem];
    final element2 = _stemToElement[day2.heavenlyStem];
    if (element1 != null && element2 != null) {
      if (element1 == element2) {
        relations.add('동일오행');
        score += 5;
      }

      // 상생 관계 확인
      if (_isGenerating(element1, element2)) {
        relations.add('상생');
        score += 10;
      }

      // 상극 관계 확인
      if (_isOvercoming(element1, element2)) {
        relations.add('상극');
        score -= 5;
      }
    } else {
      relations.add('천간오류');
      score -= 20;
    }

    return DayPillarAnalysis(
      pillar1: day1,
      pillar2: day2,
      relations: relations,
      score: score.clamp(0, 100),
      description: _describeDayPillarRelation(relations),
    );
  }

  /// 전체 지지 관계 분석
  BranchRelations _analyzeAllBranchRelations(SajuChart chart1, SajuChart chart2) {
    final branches1 = [
      chart1.yearPillar.earthlyBranch,
      chart1.monthPillar.earthlyBranch,
      chart1.dayPillar.earthlyBranch,
      chart1.hourPillar.earthlyBranch,
    ];

    final branches2 = [
      chart2.yearPillar.earthlyBranch,
      chart2.monthPillar.earthlyBranch,
      chart2.dayPillar.earthlyBranch,
      chart2.hourPillar.earthlyBranch,
    ];

    final combinations = <String>[];
    final clashes = <String>[];
    final punishments = <String>[];
    final breaks = <String>[];
    final harms = <String>[];

    for (final b1 in branches1) {
      for (final b2 in branches2) {
        // 육합
        if (_branchSixCombinations[b1] == b2 && !combinations.contains('$b1-$b2')) {
          combinations.add('$b1$b2합');
        }
        // 충
        if (_branchClashes[b1] == b2 && !clashes.contains('$b1-$b2')) {
          clashes.add('$b1$b2충');
        }
        // 파
        if (_branchBreaks[b1] == b2 && !breaks.contains('$b1-$b2')) {
          breaks.add('$b1$b2파');
        }
        // 해
        if (_branchHarms[b1] == b2 && !harms.contains('$b1-$b2')) {
          harms.add('$b1$b2해');
        }
      }
    }

    // 형 분석 (복잡함)
    for (final punishment in _branchPunishments) {
      for (final b1 in branches1) {
        for (final b2 in branches2) {
          if ((punishment[0] == b1 && punishment[1] == b2) ||
              (punishment[1] == b1 && punishment[0] == b2)) {
            final key = '${punishment[0]}${punishment[1]}형';
            if (!punishments.contains(key)) {
              punishments.add(key);
            }
          }
        }
      }
    }

    // 자형(自刑) 분석 - 같은 지지가 반복될 때(두 사람 합산 기준)
    final branchCounts = <String, int>{};
    for (final b in [...branches1, ...branches2]) {
      branchCounts[b] = (branchCounts[b] ?? 0) + 1;
    }
    for (final b in _selfPunishments) {
      if ((branchCounts[b] ?? 0) >= 2) {
        // 한글이 뒤에 붙는 경우 보간 파서/린트 혼선을 피하기 위해 문자열 결합 사용
        final key = '$b' '자형';
        if (!punishments.contains(key)) {
          punishments.add(key);
        }
      }
    }

    // 삼합 분석 (두 사람의 지지를 합쳐 3개가 모두 충족되면 시너지로 판단)
    final allBranches = <String>{...branches1, ...branches2};
    for (final entry in _branchTripleCombinations.entries) {
      final triple = entry.value;
      if (triple.every(allBranches.contains)) {
        // 예: 인오술삼합
        final key = '${triple.join()}삼합';
        if (!combinations.contains(key)) {
          combinations.add(key);
        }
      }
    }

    return BranchRelations(
      combinations: combinations,
      clashes: clashes,
      punishments: punishments,
      breaks: breaks,
      harms: harms,
    );
  }

  /// 오행 균형 분석
  ElementBalance _analyzeElementBalance(SajuChart chart1, SajuChart chart2) {
    // 각 사주의 오행 분포 계산
    final elements1 = _countElements(chart1);
    final elements2 = _countElements(chart2);

    // 합산 분포
    final combined = <String, int>{};
    for (final element in ['목', '화', '토', '금', '수']) {
      combined[element] = (elements1[element] ?? 0) + (elements2[element] ?? 0);
    }

    // 부족한 오행 찾기
    final lacking = <String>[];
    final excessive = <String>[];
    final total = combined.values.reduce((a, b) => a + b);
    final average = total / 5;

    for (final entry in combined.entries) {
      if (entry.value < average * 0.5) {
        lacking.add(entry.key);
      } else if (entry.value > average * 1.5) {
        excessive.add(entry.key);
      }
    }

    // 상호 보완 분석
    final complementary = <String>[];
    for (final element in ['목', '화', '토', '금', '수']) {
      final v1 = elements1[element] ?? 0;
      final v2 = elements2[element] ?? 0;
      // 한쪽이 부족하고 다른쪽이 많으면 보완
      if ((v1 <= 1 && v2 >= 2) || (v2 <= 1 && v1 >= 2)) {
        complementary.add(element);
      }
    }

    // 균형 점수 계산 (0-100)
    final balanceScore = _calculateBalanceScore(combined);

    return ElementBalance(
      person1Elements: elements1,
      person2Elements: elements2,
      combinedElements: combined,
      lackingElements: lacking,
      excessiveElements: excessive,
      complementaryElements: complementary,
      balanceScore: balanceScore,
    );
  }

  /// 천간 관계 분석
  StemRelations _analyzeStemRelations(SajuChart chart1, SajuChart chart2) {
    final stems1 = [
      chart1.yearPillar.heavenlyStem,
      chart1.monthPillar.heavenlyStem,
      chart1.dayPillar.heavenlyStem,
      chart1.hourPillar.heavenlyStem,
    ];

    final stems2 = [
      chart2.yearPillar.heavenlyStem,
      chart2.monthPillar.heavenlyStem,
      chart2.dayPillar.heavenlyStem,
      chart2.hourPillar.heavenlyStem,
    ];

    final combinations = <String>[];

    for (final s1 in stems1) {
      for (final s2 in stems2) {
        if (_stemCombinations[s1] == s2) {
          final comboName = _getStemComboName(s1, s2);
          if (!combinations.contains(comboName)) {
            combinations.add(comboName);
          }
        }
      }
    }

    return StemRelations(
      combinations: combinations,
      score: 60 + (combinations.length * 8).clamp(0, 30),
    );
  }

  /// 오행 개수 계산
  Map<String, int> _countElements(SajuChart chart) {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};

    // 천간 오행
    for (final stem in [
      chart.yearPillar.heavenlyStem,
      chart.monthPillar.heavenlyStem,
      chart.dayPillar.heavenlyStem,
      chart.hourPillar.heavenlyStem,
    ]) {
      final element = _stemToElement[stem];
      if (element == null) continue;
      counts[element] = counts[element]! + 1;
    }

    // 지지 오행
    for (final branch in [
      chart.yearPillar.earthlyBranch,
      chart.monthPillar.earthlyBranch,
      chart.dayPillar.earthlyBranch,
      chart.hourPillar.earthlyBranch,
    ]) {
      final element = _branchToElement[branch];
      if (element == null) continue;
      counts[element] = counts[element]! + 1;
    }

    return counts;
  }

  /// 균형 점수 계산
  int _calculateBalanceScore(Map<String, int> combined) {
    final values = combined.values.toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final range = max - min;

    // 범위가 작을수록 균형이 좋음
    if (range <= 2) return 90;
    if (range <= 4) return 75;
    if (range <= 6) return 60;
    return 45;
  }

  /// 상생 관계 확인
  bool _isGenerating(String element1, String element2) {
    const generates = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
    return generates[element1] == element2 || generates[element2] == element1;
  }

  /// 상극 관계 확인
  bool _isOvercoming(String element1, String element2) {
    const overcomes = {'목': '토', '토': '수', '수': '화', '화': '금', '금': '목'};
    return overcomes[element1] == element2 || overcomes[element2] == element1;
  }

  /// 종합 점수 계산
  int _calculateOverallScore(
    DayPillarAnalysis dayPillar,
    BranchRelations branches,
    ElementBalance elements,
    StemRelations stems,
  ) {
    // 가중치 적용
    var score = 0.0;

    // 일주 분석 (40%)
    score += dayPillar.score * 0.4;

    // 지지 관계 (30%)
    var branchScore = 60.0;
    branchScore += branches.combinations.length * 5;
    branchScore -= branches.clashes.length * 8;
    branchScore -= branches.punishments.length * 5;
    branchScore -= branches.breaks.length * 4;
    branchScore -= branches.harms.length * 6;
    score += branchScore.clamp(0, 100) * 0.3;

    // 오행 균형 (20%)
    score += elements.balanceScore * 0.2;

    // 천간 관계 (10%)
    score += stems.score * 0.1;

    return score.round().clamp(0, 100);
  }

  /// 카테고리별 점수 계산
  Map<String, int> _calculateCategoryScores(
    DayPillarAnalysis dayPillar,
    BranchRelations branches,
    ElementBalance elements,
  ) {
    final base = dayPillar.score;

    // 연애: 감정적 교류 중시 (합이 많으면 좋음)
    var love = base + branches.combinations.length * 8 - branches.clashes.length * 10;

    // 결혼: 안정성 중시 (균형, 형/해 적으면 좋음)
    var marriage = base + elements.balanceScore ~/ 4 -
        branches.punishments.length * 6 - branches.harms.length * 6;

    // 사업: 실질적 협력 (충이 있어도 활력으로 해석 가능)
    var business = base + branches.combinations.length * 5 -
        branches.clashes.length * 3 + elements.complementaryElements.length * 5;

    // 우정: 편안함 (해가 적으면 좋음)
    var friendship = base + branches.combinations.length * 6 -
        branches.harms.length * 8 - branches.breaks.length * 5;

    return {
      'love': love.clamp(0, 100),
      'marriage': marriage.clamp(0, 100),
      'business': business.clamp(0, 100),
      'friendship': friendship.clamp(0, 100),
    };
  }

  /// 일주 관계 설명
  String _describeDayPillarRelation(List<String> relations) {
    if (relations.contains('천간합') && relations.contains('육합')) {
      return '천지합(天地合)으로 최상의 인연입니다.';
    }
    if (relations.contains('천간합')) {
      return '천간합으로 마음이 잘 통하는 관계입니다.';
    }
    if (relations.contains('육합')) {
      return '육합으로 서로 끌리는 인연입니다.';
    }
    if (relations.contains('반합')) {
      return '반합으로 좋은 시너지를 낼 수 있습니다.';
    }
    if (relations.contains('충')) {
      if (relations.contains('상생')) {
        return '충이 있지만 상생으로 보완됩니다.';
      }
      return '충이 있어 갈등이 생길 수 있습니다.';
    }
    if (relations.contains('형')) {
      return '형이 있어 서로 자극이 될 수 있습니다.';
    }
    if (relations.contains('해')) {
      return '해가 있어 오해가 생기기 쉽습니다.';
    }
    if (relations.contains('동일오행')) {
      return '같은 오행으로 서로 이해하기 쉽습니다.';
    }
    if (relations.contains('상생')) {
      return '상생 관계로 서로 도움을 줄 수 있습니다.';
    }
    return '평범한 관계이나 노력으로 발전 가능합니다.';
  }

  /// 천간합 이름
  String _getStemComboName(String s1, String s2) {
    final sorted = [s1, s2]..sort();
    const names = {
      '갑기': '갑기합토',
      '기갑': '갑기합토',
      '경을': '을경합금',
      '을경': '을경합금',
      '병신': '병신합수',
      '신병': '병신합수',
      '임정': '정임합목',
      '정임': '정임합목',
      '계무': '무계합화',
      '무계': '무계합화',
    };
    return names['${sorted[0]}${sorted[1]}'] ?? '$s1$s2합';
  }

  /// 인사이트 생성
  CompatibilityInsights _generateInsights(
    DayPillarAnalysis dayPillar,
    BranchRelations branches,
    ElementBalance elements,
  ) {
    final strengths = <String>[];
    final challenges = <String>[];
    final advice = <String>[];

    // 강점 분석
    if (dayPillar.relations.contains('천간합') || dayPillar.relations.contains('육합')) {
      strengths.add('서로 끌리고 이해하는 깊은 인연');
    }
    if (branches.combinations.isNotEmpty) {
      strengths.add('좋은 시너지를 낼 수 있는 조합 (${branches.combinations.join(', ')})');
    }
    if (elements.complementaryElements.isNotEmpty) {
      strengths.add('서로 부족한 부분을 채워주는 보완 관계');
    }
    if (dayPillar.relations.contains('상생')) {
      strengths.add('상생 관계로 서로에게 힘이 됨');
    }
    if (elements.balanceScore >= 75) {
      strengths.add('함께 있을 때 오행 균형이 좋아짐');
    }

    // 도전 분석
    if (branches.clashes.isNotEmpty) {
      challenges.add('갈등 요소 존재 (${branches.clashes.join(', ')})');
    }
    if (branches.punishments.isNotEmpty) {
      challenges.add('서로 자극이 될 수 있음 (${branches.punishments.join(', ')})');
    }
    if (branches.harms.isNotEmpty) {
      challenges.add('오해가 생기기 쉬운 관계 (${branches.harms.join(', ')})');
    }
    if (elements.lackingElements.length >= 2) {
      challenges.add('함께 부족한 오행이 있음 (${elements.lackingElements.join(', ')})');
    }
    if (dayPillar.relations.contains('상극')) {
      challenges.add('의견 충돌이 있을 수 있음');
    }

    // 조언
    if (branches.clashes.isNotEmpty) {
      advice.add('충돌 시 감정보다 이성적 대화를 우선하세요');
    }
    if (branches.harms.isNotEmpty) {
      advice.add('서로의 의도를 확인하며 오해를 줄이세요');
    }
    if (elements.lackingElements.contains('목')) {
      advice.add('함께 자연 속 활동을 하면 좋습니다');
    }
    if (elements.lackingElements.contains('화')) {
      advice.add('열정적인 공동 목표를 세워보세요');
    }
    if (elements.lackingElements.contains('토')) {
      advice.add('안정적인 일상 루틴을 만들어보세요');
    }
    if (elements.lackingElements.contains('금')) {
      advice.add('명확한 규칙과 경계를 정해두세요');
    }
    if (elements.lackingElements.contains('수')) {
      advice.add('깊은 대화와 교감의 시간을 가지세요');
    }
    if (strengths.isEmpty) {
      advice.add('서로의 차이를 인정하고 배려하는 노력이 필요합니다');
    }

    // 기본값 보장
    if (strengths.isEmpty) {
      strengths.add('서로 다른 관점으로 시야를 넓혀줄 수 있음');
    }
    if (challenges.isEmpty) {
      challenges.add('특별한 갈등 요소 없음');
    }
    if (advice.isEmpty) {
      advice.add('현재의 좋은 관계를 유지하며 발전시켜 나가세요');
    }

    // 요약
    final summary = _generateSummary(dayPillar, branches, elements);

    return CompatibilityInsights(
      summary: summary,
      strengths: strengths,
      challenges: challenges,
      advice: advice,
    );
  }

  /// 요약 생성
  String _generateSummary(
    DayPillarAnalysis dayPillar,
    BranchRelations branches,
    ElementBalance elements,
  ) {
    final score = dayPillar.score;

    if (score >= 85) {
      return '두 분은 천생연분에 가까운 좋은 인연입니다. '
          '${dayPillar.description} '
          '서로를 이해하고 지지하는 관계가 될 수 있습니다.';
    }
    if (score >= 70) {
      return '두 분은 좋은 궁합입니다. '
          '${dayPillar.description} '
          '작은 노력으로 더 깊은 관계로 발전할 수 있습니다.';
    }
    if (score >= 55) {
      return '두 분은 평균적인 궁합입니다. '
          '${dayPillar.description} '
          '서로의 장단점을 이해하면 좋은 관계가 될 수 있습니다.';
    }
    return '두 분은 노력이 필요한 궁합입니다. '
        '${dayPillar.description} '
        '갈등 요소를 인지하고 대화로 풀어가는 것이 중요합니다.';
  }
}

// ============================================
// 결과 데이터 클래스들
// ============================================

/// 궁합 분석 결과
class CompatibilityResult {
  final int overallScore;
  final int loveScore;
  final int marriageScore;
  final int businessScore;
  final int friendshipScore;
  final DayPillarAnalysis dayPillarAnalysis;
  final BranchRelations branchRelations;
  final ElementBalance elementBalance;
  final StemRelations stemRelations;
  final CompatibilityInsights insights;

  const CompatibilityResult({
    required this.overallScore,
    required this.loveScore,
    required this.marriageScore,
    required this.businessScore,
    required this.friendshipScore,
    required this.dayPillarAnalysis,
    required this.branchRelations,
    required this.elementBalance,
    required this.stemRelations,
    required this.insights,
  });
}

/// 일주 분석
class DayPillarAnalysis {
  final Pillar pillar1;
  final Pillar pillar2;
  final List<String> relations;
  final int score;
  final String description;

  const DayPillarAnalysis({
    required this.pillar1,
    required this.pillar2,
    required this.relations,
    required this.score,
    required this.description,
  });
}

/// 지지 관계
class BranchRelations {
  final List<String> combinations; // 합
  final List<String> clashes; // 충
  final List<String> punishments; // 형
  final List<String> breaks; // 파
  final List<String> harms; // 해

  const BranchRelations({
    required this.combinations,
    required this.clashes,
    required this.punishments,
    required this.breaks,
    required this.harms,
  });
}

/// 오행 균형
class ElementBalance {
  final Map<String, int> person1Elements;
  final Map<String, int> person2Elements;
  final Map<String, int> combinedElements;
  final List<String> lackingElements;
  final List<String> excessiveElements;
  final List<String> complementaryElements;
  final int balanceScore;

  const ElementBalance({
    required this.person1Elements,
    required this.person2Elements,
    required this.combinedElements,
    required this.lackingElements,
    required this.excessiveElements,
    required this.complementaryElements,
    required this.balanceScore,
  });
}

/// 천간 관계
class StemRelations {
  final List<String> combinations;
  final int score;

  const StemRelations({
    required this.combinations,
    required this.score,
  });
}

/// 인사이트
class CompatibilityInsights {
  final String summary;
  final List<String> strengths;
  final List<String> challenges;
  final List<String> advice;

  const CompatibilityInsights({
    required this.summary,
    required this.strengths,
    required this.challenges,
    required this.advice,
  });
}
