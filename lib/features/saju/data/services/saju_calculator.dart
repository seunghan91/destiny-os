import 'package:lunar/lunar.dart';
import '../../domain/entities/saju_chart.dart';
import '../../domain/entities/ten_gods.dart';
import '../../domain/entities/daewoon.dart';

/// 사주명리학 계산 서비스
/// lunar 패키지를 활용한 정확한 사주팔자 계산
class SajuCalculator {
  SajuCalculator._();

  static final SajuCalculator instance = SajuCalculator._();

  // 천간 목록 (한글)
  static const List<String> _stems = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];
  static const List<String> _stemsHanja = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

  // 지지 목록 (한글)
  static const List<String> _branches = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
  static const List<String> _branchesHanja = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // 오행 (천간 → 오행)
  static const Map<String, String> _stemToElement = {
    '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
    '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
  };

  // 오행 (지지 → 오행)
  static const Map<String, String> _branchToElement = {
    '자': '수', '축': '토', '인': '목', '묘': '목', '진': '토', '사': '화',
    '오': '화', '미': '토', '신': '금', '유': '금', '술': '토', '해': '수',
  };

  // 음양 (천간)
  static const Map<String, bool> _stemPolarity = {
    '갑': true, '을': false, '병': true, '정': false, '무': true,
    '기': false, '경': true, '신': false, '임': true, '계': false,
  };

  /// 사주팔자 계산 (메인 함수)
  /// [useSolarTimeCorrection]: 태양시 보정 사용 여부 (한국 표준시 → 태양시, 약 -30분)
  SajuChart calculateSajuChart({
    required DateTime birthDateTime,
    required bool isLunar,
    required String gender,
    bool useNightSubhour = false,
    bool useSolarTimeCorrection = false,
  }) {
    // Lunar 패키지를 사용하여 음력/양력 변환 및 사주 계산
    late Lunar lunar;
    late Solar solar;

    if (isLunar) {
      // 음력 입력 → 양력으로 변환
      lunar = Lunar.fromYmd(
        birthDateTime.year,
        birthDateTime.month,
        birthDateTime.day,
      );
      solar = lunar.getSolar();
    } else {
      // 양력 입력 → 음력으로 변환
      solar = Solar.fromYmdHms(
        birthDateTime.year,
        birthDateTime.month,
        birthDateTime.day,
        birthDateTime.hour,
        birthDateTime.minute,
        0,
      );
      lunar = solar.getLunar();
    }

    // 시간 정보를 포함한 EightChar(八字) 계산
    final eightChar = lunar.getEightChar();

    // 년주 (年柱)
    final yearPillar = Pillar(
      heavenlyStem: _convertToKoreanStem(eightChar.getYear()),
      earthlyBranch: _convertToKoreanBranch(eightChar.getYearZhi()),
    );

    // 월주 (月柱)
    final monthPillar = Pillar(
      heavenlyStem: _convertToKoreanStem(eightChar.getMonth()),
      earthlyBranch: _convertToKoreanBranch(eightChar.getMonthZhi()),
    );

    // 일주 (日柱)
    final dayPillar = Pillar(
      heavenlyStem: _convertToKoreanStem(eightChar.getDay()),
      earthlyBranch: _convertToKoreanBranch(eightChar.getDayZhi()),
    );

    // 시주 (時柱) - 시간 정보 필요
    // 태양시 보정: 한국 표준시(KST, 동경135도)에서 한국 태양시(동경127.5도)로 변환 시 약 30분 차이
    final correctedHour = useSolarTimeCorrection
        ? birthDateTime.hour + (birthDateTime.minute - 30) / 60.0
        : birthDateTime.hour + birthDateTime.minute / 60.0;

    final hourPillar = _calculateHourPillar(
      dayPillar.heavenlyStem,
      correctedHour,
      useNightSubhour,
    );

    return SajuChart(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      birthDateTime: birthDateTime,
      isLunar: isLunar,
      gender: gender,
    );
  }

  /// 시주 계산 (일간 기준)
  /// [hour]: 시간 (소수점 포함, 예: 11.5 = 11시 30분)
  Pillar _calculateHourPillar(String dayStem, double hour, bool useNightSubhour) {
    // 시간 → 지지 인덱스 (子시=23~01시, 丑시=01~03시, ...)
    // 각 시(時)는 2시간 단위: 자시(23-01), 축시(01-03), 인시(03-05), ...
    int branchIndex;

    if (useNightSubhour && hour >= 23) {
      // 야자시 사용: 23시 이후는 다음날 자시로 계산
      branchIndex = 0;
    } else {
      // 시간을 2시간 단위로 나누어 지지 인덱스 결정
      branchIndex = (((hour + 1) / 2).floor()) % 12;
    }

    // 시간 천간 계산 (일간 기준 오자시두법)
    // 갑/기일 → 갑자시, 을/경일 → 병자시, 병/신일 → 무자시, 정/임일 → 경자시, 무/계일 → 임자시
    final dayStemIndex = _stems.indexOf(dayStem);
    final startStemIndex = (dayStemIndex % 5) * 2;
    final hourStemIndex = (startStemIndex + branchIndex) % 10;

    return Pillar(
      heavenlyStem: _stems[hourStemIndex],
      earthlyBranch: _branches[branchIndex],
    );
  }

  /// 십성 계산 (일간 기준)
  TenGods calculateTenGods(SajuChart chart) {
    final dayMaster = chart.dayPillar.heavenlyStem;

    // 한자로 들어온 경우 한글로 변환
    final koreanDayMaster = _convertToKoreanStem(dayMaster);

    final dayMasterElement = _stemToElement[koreanDayMaster] ?? '토';
    final dayMasterPolarity = _stemPolarity[koreanDayMaster] ?? true;

    final distribution = <String, int>{
      '비견': 0, '겁재': 0, '식신': 0, '상관': 0, '편재': 0,
      '정재': 0, '편관': 0, '정관': 0, '편인': 0, '정인': 0,
    };

    // 모든 기둥의 천간/지지에서 십성 계산
    final allStems = [
      chart.yearPillar.heavenlyStem,
      chart.monthPillar.heavenlyStem,
      chart.hourPillar.heavenlyStem,
    ];

    final allBranches = [
      chart.yearPillar.earthlyBranch,
      chart.monthPillar.earthlyBranch,
      chart.dayPillar.earthlyBranch,
      chart.hourPillar.earthlyBranch,
    ];

    // 천간에서 십성 계산
    for (final stem in allStems) {
      final god = _calculateGodFromStem(dayMaster, dayMasterElement, dayMasterPolarity, stem);
      if (god != null) distribution[god] = distribution[god]! + 1;
    }

    // 지지 본기에서 십성 계산 (간략화 - 정기만 사용)
    for (final branch in allBranches) {
      final god = _calculateGodFromBranch(dayMaster, dayMasterElement, dayMasterPolarity, branch);
      if (god != null) distribution[god] = distribution[god]! + 1;
    }

    return TenGods(distribution: distribution);
  }

  /// 천간으로부터 십성 계산
  String? _calculateGodFromStem(
    String dayMaster,
    String dayMasterElement,
    bool dayMasterPolarity,
    String targetStem,
  ) {
    final targetElement = _stemToElement[targetStem];
    final targetPolarity = _stemPolarity[targetStem];

    // null 안전성 검사
    if (targetElement == null || targetPolarity == null) {
      return null;
    }

    return _getTenGod(dayMasterElement, dayMasterPolarity, targetElement, targetPolarity);
  }

  /// 지지로부터 십성 계산 (정기 기준)
  String? _calculateGodFromBranch(
    String dayMaster,
    String dayMasterElement,
    bool dayMasterPolarity,
    String targetBranch,
  ) {
    final targetElement = _branchToElement[targetBranch];

    // null 안전성 검사
    if (targetElement == null) {
      return null;
    }

    // 지지는 음양 결정: 자/인/진/오/신/술=양, 축/묘/사/미/유/해=음
    final yangBranches = {'자', '인', '진', '오', '신', '술'};
    final targetPolarity = yangBranches.contains(targetBranch);

    return _getTenGod(dayMasterElement, dayMasterPolarity, targetElement, targetPolarity);
  }

  /// 오행 관계로부터 십성 결정
  String _getTenGod(
    String myElement,
    bool myPolarity,
    String targetElement,
    bool targetPolarity,
  ) {
    final samePolarity = myPolarity == targetPolarity;

    // 오행 관계 판단
    final relationship = _getElementRelationship(myElement, targetElement);

    switch (relationship) {
      case 'same': // 비겁 (나와 같은 오행)
        return samePolarity ? '비견' : '겁재';
      case 'generates': // 식상 (내가 생하는 오행)
        return samePolarity ? '식신' : '상관';
      case 'overcomes': // 재성 (내가 극하는 오행) - 같은 음양=정재, 다른 음양=편재
        return samePolarity ? '정재' : '편재';
      case 'generated': // 인성 (나를 생하는 오행)
        return samePolarity ? '편인' : '정인';
      case 'overcome': // 관성 (나를 극하는 오행)
        return samePolarity ? '편관' : '정관';
      default:
        return '비견';
    }
  }

  /// 오행 관계 결정
  String _getElementRelationship(String myElement, String targetElement) {
    if (myElement == targetElement) return 'same';

    // 상생 관계: 목→화→토→금→수→목
    const generates = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
    // 상극 관계: 목→토→수→화→금→목
    const overcomes = {'목': '토', '토': '수', '수': '화', '화': '금', '금': '목'};

    if (generates[myElement] == targetElement) return 'generates';
    if (overcomes[myElement] == targetElement) return 'overcomes';
    if (generates[targetElement] == myElement) return 'generated';
    if (overcomes[targetElement] == myElement) return 'overcome';

    return 'same';
  }

  /// 대운 계산
  DaewoonChart calculateDaewoon(SajuChart chart, {int? currentYear}) {
    final gender = chart.gender;
    final yearStem = chart.yearPillar.heavenlyStem;
    final monthStem = chart.monthPillar.heavenlyStem;
    final monthBranch = chart.monthPillar.earthlyBranch;

    // 대운 방향 결정 (양남음녀=순행, 음남양녀=역행)
    final yearPolarity = _stemPolarity[yearStem]!;
    final isMale = gender == '남';
    final isForward = (yearPolarity && isMale) || (!yearPolarity && !isMale);

    // 대운 시작 나이 계산 (절입일 기반)
    final startAge = _calculateDaewoonStartAge(
      chart.birthDateTime,
      isForward,
    );

    // 월주 인덱스
    var stemIndex = _stems.indexOf(monthStem);
    var branchIndex = _branches.indexOf(monthBranch);

    final daewoons = <Daewoon>[];

    for (int i = 0; i < 9; i++) {
      // 순행/역행에 따라 인덱스 조정
      if (isForward) {
        stemIndex = (stemIndex + 1) % 10;
        branchIndex = (branchIndex + 1) % 12;
      } else {
        stemIndex = (stemIndex - 1 + 10) % 10;
        branchIndex = (branchIndex - 1 + 12) % 12;
      }

      final pillar = Pillar(
        heavenlyStem: _stems[stemIndex],
        earthlyBranch: _branches[branchIndex],
      );

      final daewoonStart = startAge + (i * 10);
      final daewoonEnd = daewoonStart + 10;

      // 대운 테마 결정 (오행 기반)
      final theme = _getDaewoonTheme(pillar, chart.dayPillar.heavenlyStem);

      daewoons.add(Daewoon(
        startAge: daewoonStart,
        endAge: daewoonEnd,
        pillar: pillar,
        theme: theme.theme,
        description: theme.description,
        fortuneScore: theme.score,
      ));
    }

    final currentAge = (currentYear ?? DateTime.now().year) - chart.birthDateTime.year;

    return DaewoonChart(daewoons: daewoons, currentAge: currentAge);
  }

  /// 대운 테마 결정
  ({String theme, String description, double score}) _getDaewoonTheme(
    Pillar daewoonPillar,
    String dayMaster,
  ) {
    final daewoonElement = _stemToElement[daewoonPillar.heavenlyStem]!;
    final dayMasterElement = _stemToElement[dayMaster]!;

    final relationship = _getElementRelationship(dayMasterElement, daewoonElement);

    switch (relationship) {
      case 'same':
        return (
          theme: '자아 확립의 시기',
          description: '비겁운으로 자아 정체성이 강화되고 독립심이 높아지는 시기입니다.',
          score: 65.0,
        );
      case 'generates':
        return (
          theme: '표현과 성취의 시기',
          description: '식상운으로 창의력이 빛나고 재능을 발휘할 수 있는 시기입니다.',
          score: 75.0,
        );
      case 'overcomes':
        return (
          theme: '재물 축적의 시기',
          description: '재성운으로 경제적 기회가 많아지고 재물이 축적되는 시기입니다.',
          score: 80.0,
        );
      case 'generated':
        return (
          theme: '학습과 성장의 시기',
          description: '인성운으로 학문적 성취와 정신적 성장이 이루어지는 시기입니다.',
          score: 70.0,
        );
      case 'overcome':
        return (
          theme: '도전과 발전의 시기',
          description: '관성운으로 사회적 지위와 명예를 얻을 수 있는 시기입니다.',
          score: 72.0,
        );
      default:
        return (
          theme: '안정의 시기',
          description: '평온하게 흘러가는 시기입니다.',
          score: 60.0,
        );
    }
  }

  /// 한자 천간 → 한글 천간 변환
  String _convertToKoreanStem(String hanjaStem) {
    final index = _stemsHanja.indexOf(hanjaStem);
    return index >= 0 ? _stems[index] : hanjaStem;
  }

  /// 한자 지지 → 한글 지지 변환
  String _convertToKoreanBranch(String hanjaBranch) {
    final index = _branchesHanja.indexOf(hanjaBranch);
    return index >= 0 ? _branches[index] : hanjaBranch;
  }

  /// 특정 연도와의 궁합 분석 (2026 병오년용)
  /// [isFireBeneficial]: 화(火) 기운이 이 사람에게 도움이 되는지 여부
  ({double score, bool isFireBeneficial, String analysis}) analyzeYearCompatibility(
    SajuChart chart,
    {int year = 2026}
  ) {
    final dayMaster = chart.dayPillar.heavenlyStem;
    final dayMasterElement = _stemToElement[dayMaster]!;

    // 2026년 병오년: 병(화) + 오(화) = 강한 화기
    const yearElement = '화';

    final relationship = _getElementRelationship(dayMasterElement, yearElement);

    double score;
    bool isFireBeneficial;
    String analysis;

    switch (relationship) {
      case 'same': // 화일간 → 비겁운 (강해짐)
        score = 70.0;
        isFireBeneficial = true;
        analysis = '2026년 화기가 당신의 기운과 같습니다. 자신감이 넘치지만 과열 주의가 필요합니다.';
        break;
      case 'generates': // 목일간 → 식상운 (재능 발휘)
        score = 85.0;
        isFireBeneficial = true;
        analysis = '2026년은 당신의 재능이 빛나는 해입니다. 표현하고 창작하세요!';
        break;
      case 'overcomes': // 수일간 → 재성운 (재물)
        score = 80.0;
        isFireBeneficial = true;
        analysis = '2026년 화기를 잘 다스리면 재물운이 따릅니다. 투자와 사업에 유리합니다.';
        break;
      case 'generated': // 토일간 → 인성운 (배움)
        score = 65.0;
        isFireBeneficial = false;
        analysis = '2026년 화기가 당신을 자극합니다. 배움과 성장의 기회로 삼으세요.';
        break;
      case 'overcome': // 금일간 → 관성운 (도전)
        score = 55.0;
        isFireBeneficial = false;
        analysis = '2026년 화기가 강하니 무리하지 마세요. 방어적 자세가 현명합니다.';
        break;
      default:
        score = 60.0;
        isFireBeneficial = false;
        analysis = '2026년 평온한 흐름이 예상됩니다.';
    }

    // 사주 내 화기 비율에 따른 조정
    final fireRatio = chart.fireEnergyRatio;
    if (fireRatio > 0.3) {
      // 화가 많은 사주 → 2026년에 과열 가능성
      score -= 10;
      isFireBeneficial = false;
      analysis += ' 화기가 과다할 수 있으니 휴식을 충분히 취하세요.';
    } else if (fireRatio < 0.1) {
      // 화가 부족한 사주 → 2026년에 보완
      score += 10;
      isFireBeneficial = true;
      analysis += ' 부족했던 화기를 보충받는 좋은 시기입니다.';
    }

    return (
      score: score.clamp(0, 100),
      isFireBeneficial: isFireBeneficial,
      analysis: analysis,
    );
  }

  /// 사주 기반 MBTI 추론
  String inferMbtiFromSaju(SajuChart chart, TenGods tenGods) {
    // 주요 십성 기반 MBTI 추론
    String estimatedType = '';

    // E/I 결정 (비겁, 식상, 재성 많으면 E)
    final extrovertScore = (tenGods.distribution['비견'] ?? 0) +
        (tenGods.distribution['겁재'] ?? 0) +
        (tenGods.distribution['식신'] ?? 0) +
        (tenGods.distribution['상관'] ?? 0) +
        (tenGods.distribution['편재'] ?? 0);
    final introvertScore = (tenGods.distribution['정관'] ?? 0) +
        (tenGods.distribution['편인'] ?? 0) +
        (tenGods.distribution['정인'] ?? 0);

    estimatedType += extrovertScore > introvertScore ? 'E' : 'I';

    // N/S 결정 (식상, 인성 많으면 N)
    final intuitiveScore = (tenGods.distribution['식신'] ?? 0) +
        (tenGods.distribution['상관'] ?? 0) +
        (tenGods.distribution['편인'] ?? 0) +
        (tenGods.distribution['정인'] ?? 0);
    final sensingScore = (tenGods.distribution['정재'] ?? 0) +
        (tenGods.distribution['정관'] ?? 0) +
        (tenGods.distribution['비견'] ?? 0);

    estimatedType += intuitiveScore > sensingScore ? 'N' : 'S';

    // T/F 결정 (관성, 겁재 많으면 T)
    final thinkingScore = (tenGods.distribution['편관'] ?? 0) +
        (tenGods.distribution['정관'] ?? 0) +
        (tenGods.distribution['겁재'] ?? 0) +
        (tenGods.distribution['편재'] ?? 0);
    final feelingScore = (tenGods.distribution['정인'] ?? 0) +
        (tenGods.distribution['식신'] ?? 0) +
        (tenGods.distribution['정재'] ?? 0);

    estimatedType += thinkingScore > feelingScore ? 'T' : 'F';

    // J/P 결정 (관성, 정재 많으면 J)
    final judgingScore = (tenGods.distribution['정관'] ?? 0) +
        (tenGods.distribution['정재'] ?? 0) +
        (tenGods.distribution['정인'] ?? 0);
    final perceivingScore = (tenGods.distribution['상관'] ?? 0) +
        (tenGods.distribution['편재'] ?? 0) +
        (tenGods.distribution['편인'] ?? 0);

    estimatedType += judgingScore > perceivingScore ? 'J' : 'P';

    return estimatedType;
  }

  /// 대운 시작 나이 계산 (절입일 기반)
  /// [birthDateTime]: 생년월일시
  /// [isForward]: 순행 여부 (true=순행, false=역행)
  ///
  /// 공식:
  /// - 순행: (생일 → 다음 절입일 일수) ÷ 3
  /// - 역행: (생일 → 이전 절입일 일수) ÷ 3
  /// - 나머지 1이면 버림, 2이면 올림
  int _calculateDaewoonStartAge(DateTime birthDateTime, bool isForward) {
    try {
      // Solar 객체 생성
      final solar = Solar.fromYmdHms(
        birthDateTime.year,
        birthDateTime.month,
        birthDateTime.day,
        birthDateTime.hour,
        birthDateTime.minute,
        0,
      );

      final lunar = solar.getLunar();

      // 다음 절기(節) 찾기 (24절기 중 월 변화를 나타내는 12절기)
      final nextJie = lunar.getNextJie();
      final prevJie = lunar.getPrevJie();

      late final Solar targetSolar;

      if (isForward) {
        // 순행: 다음 절입일까지 일수
        targetSolar = nextJie.getSolar();
      } else {
        // 역행: 이전 절입일까지 일수
        targetSolar = prevJie.getSolar();
      }

      // 생일과 절입일 간의 일수 계산
      final birthDate = DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
      final targetDate = DateTime(targetSolar.getYear(), targetSolar.getMonth(), targetSolar.getDay());
      final daysDiff = targetDate.difference(birthDate).inDays.abs();

      // 대운수 = 일수 ÷ 3
      final quotient = daysDiff ~/ 3;
      final remainder = daysDiff % 3;

      // 나머지 처리: 1이면 버림, 2이면 올림
      int startAge = quotient;
      if (remainder == 2) {
        startAge += 1;
      }

      // 최소 1세, 최대 10세로 제한 (일반적으로 1~10세 사이)
      return startAge.clamp(1, 10);
    } catch (e) {
      // 에러 발생 시 기본값 5세 반환
      return 5;
    }
  }

  // ========== 궁합 계산 ==========

  /// 두 사람의 궁합 분석
  CompatibilityResult calculateCompatibility(SajuChart chart1, SajuChart chart2) {
    // 1. 일간 궁합 분석
    final dayMasterResult = _analyzeDayMasterCompatibility(
      chart1.dayPillar.heavenlyStem,
      chart2.dayPillar.heavenlyStem,
    );

    // 2. 지지 궁합 분석 (합/충/형/파/해)
    final branchResult = _analyzeBranchCompatibility(
      chart1.dayPillar.earthlyBranch,
      chart2.dayPillar.earthlyBranch,
    );

    // 3. 오행 균형 분석
    final elementBalance = _analyzeElementBalance(chart1, chart2);

    // 4. 종합 점수 계산
    final overallScore = (dayMasterResult.score * 0.35 +
        branchResult.score * 0.35 +
        elementBalance.score * 0.30).round();

    // 5. 관계 유형별 점수 조정
    final loveScore = _adjustScoreForRelation(overallScore, 'love', dayMasterResult, branchResult);
    final marriageScore = _adjustScoreForRelation(overallScore, 'marriage', dayMasterResult, branchResult);
    final businessScore = _adjustScoreForRelation(overallScore, 'business', dayMasterResult, branchResult);
    final friendshipScore = _adjustScoreForRelation(overallScore, 'friendship', dayMasterResult, branchResult);

    // 6. 분석 결과 생성
    final analysis = _generateCompatibilityAnalysis(
      dayMasterResult,
      branchResult,
      elementBalance,
      overallScore,
    );

    return CompatibilityResult(
      overallScore: overallScore,
      loveScore: loveScore,
      marriageScore: marriageScore,
      businessScore: businessScore,
      friendshipScore: friendshipScore,
      dayMasterAnalysis: dayMasterResult,
      branchAnalysis: branchResult,
      elementBalance: elementBalance,
      analysis: analysis,
    );
  }

  /// 일간(천간) 궁합 분석
  DayMasterCompatibility _analyzeDayMasterCompatibility(String stem1, String stem2) {
    final element1 = _stemToElement[stem1]!;
    final element2 = _stemToElement[stem2]!;

    // 천간합 체크 (갑기합, 을경합, 병신합, 정임합, 무계합)
    final stemCombinations = {
      '갑': '기', '기': '갑',
      '을': '경', '경': '을',
      '병': '신', '신': '병',
      '정': '임', '임': '정',
      '무': '계', '계': '무',
    };

    final hasCombination = stemCombinations[stem1] == stem2;

    double score;
    String relationship;
    String description;

    if (hasCombination) {
      score = 95;
      relationship = '천간합';
      description = '천생연분! 서로를 완벽하게 보완하는 최상의 궁합입니다.';
    } else if (element1 == element2) {
      final polarity1 = _stemPolarity[stem1]!;
      final polarity2 = _stemPolarity[stem2]!;
      score = polarity1 == polarity2 ? 65 : 70;
      relationship = '비겁';
      description = '같은 오행이라 이해가 빠르지만, 경쟁 심리가 생길 수 있습니다.';
    } else {
      final rel = _getElementRelationship(element1, element2);
      switch (rel) {
        case 'generates':
          score = 80;
          relationship = '상생(생)';
          description = '자연스럽게 상대를 돕는 관계입니다.';
          break;
        case 'generated':
          score = 78;
          relationship = '상생(받)';
          description = '상대의 지원을 받는 관계입니다.';
          break;
        case 'overcomes':
          score = 55;
          relationship = '상극(극)';
          description = '주도권을 가지려는 경향이 있습니다.';
          break;
        case 'overcome':
          score = 50;
          relationship = '상극(받)';
          description = '상대의 압박을 느낄 수 있습니다.';
          break;
        default:
          score = 60;
          relationship = '무관';
          description = '특별한 연결점이 없어 노력이 필요합니다.';
      }
    }

    return DayMasterCompatibility(
      stem1: stem1,
      stem2: stem2,
      element1: element1,
      element2: element2,
      relationship: relationship,
      hasCombination: hasCombination,
      score: score,
      description: description,
    );
  }

  /// 지지 궁합 분석 (합/충/형/파/해)
  BranchCompatibility _analyzeBranchCompatibility(String branch1, String branch2) {
    // 육합
    const sixCombinations = {
      '자': '축', '축': '자', '인': '해', '해': '인',
      '묘': '술', '술': '묘', '진': '유', '유': '진',
      '사': '신', '신': '사', '오': '미', '미': '오',
    };

    // 충
    const clashes = {
      '자': '오', '오': '자', '축': '미', '미': '축',
      '인': '신', '신': '인', '묘': '유', '유': '묘',
      '진': '술', '술': '진', '사': '해', '해': '사',
    };

    // 형
    const punishments = {
      '인': '사', '사': '신', '신': '인',
      '축': '술', '술': '미', '미': '축',
      '자': '묘', '묘': '자',
    };

    // 해
    const harms = {
      '자': '미', '미': '자', '축': '오', '오': '축',
      '인': '사', '사': '인', '묘': '진', '진': '묘',
      '신': '해', '해': '신', '유': '술', '술': '유',
    };

    final hasSixCombination = sixCombinations[branch1] == branch2;
    final hasClash = clashes[branch1] == branch2;
    final hasPunishment = punishments[branch1] == branch2;
    final hasHarm = harms[branch1] == branch2;

    // 삼합 여부
    const tripleHarmony = ['신자진', '해묘미', '인오술', '사유축'];
    bool hasTripleHarmony = false;
    for (final combo in tripleHarmony) {
      if (combo.contains(branch1) && combo.contains(branch2)) {
        hasTripleHarmony = true;
        break;
      }
    }

    double score;
    String relationship;
    String description;

    if (hasSixCombination) {
      score = 90;
      relationship = '육합';
      description = '서로 끌리는 자연스러운 인연입니다.';
    } else if (hasTripleHarmony) {
      score = 85;
      relationship = '삼합';
      description = '함께할 때 시너지가 발생합니다.';
    } else if (hasClash) {
      score = 40;
      relationship = '충';
      description = '에너지가 충돌합니다. 갈등 해소가 필요합니다.';
    } else if (hasPunishment) {
      score = 45;
      relationship = '형';
      description = '서로에게 상처를 줄 수 있습니다.';
    } else if (hasHarm) {
      score = 48;
      relationship = '해';
      description = '은근한 갈등이 생길 수 있습니다.';
    } else {
      score = 65;
      relationship = '보통';
      description = '특별한 상호작용 없이 평범한 관계입니다.';
    }

    return BranchCompatibility(
      branch1: branch1,
      branch2: branch2,
      hasSixCombination: hasSixCombination,
      hasTripleHarmony: hasTripleHarmony,
      hasClash: hasClash,
      hasPunishment: hasPunishment,
      hasHarm: hasHarm,
      mainRelationship: relationship,
      score: score,
      description: description,
    );
  }

  /// 오행 균형 분석
  ElementBalanceResult _analyzeElementBalance(SajuChart chart1, SajuChart chart2) {
    final elements1 = _countElements(chart1);
    final elements2 = _countElements(chart2);

    final combined = <String, int>{};
    for (final elem in ['목', '화', '토', '금', '수']) {
      combined[elem] = (elements1[elem] ?? 0) + (elements2[elem] ?? 0);
    }

    // 균형 점수
    final values = combined.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    final balanceScore = (100 - variance * 5).clamp(0.0, 100.0);

    // 보완 관계 분석
    final complementary = <String>[];
    final lacking = <String>[];

    for (final elem in ['목', '화', '토', '금', '수']) {
      final c1 = elements1[elem] ?? 0;
      final c2 = elements2[elem] ?? 0;
      if (c1 <= 1 && c2 >= 2) complementary.add('$elem(상대가 보완)');
      else if (c2 <= 1 && c1 >= 2) complementary.add('$elem(내가 보완)');
      else if (c1 + c2 <= 1) lacking.add(elem);
    }

    return ElementBalanceResult(
      elements1: elements1,
      elements2: elements2,
      combined: combined,
      score: balanceScore,
      complementary: complementary,
      lacking: lacking,
    );
  }

  /// 사주의 오행 분포 계산
  Map<String, int> _countElements(SajuChart chart) {
    final counts = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};

    for (final stem in [
      chart.yearPillar.heavenlyStem,
      chart.monthPillar.heavenlyStem,
      chart.dayPillar.heavenlyStem,
      chart.hourPillar.heavenlyStem,
    ]) {
      final elem = _stemToElement[stem];
      if (elem != null) counts[elem] = counts[elem]! + 1;
    }

    for (final branch in [
      chart.yearPillar.earthlyBranch,
      chart.monthPillar.earthlyBranch,
      chart.dayPillar.earthlyBranch,
      chart.hourPillar.earthlyBranch,
    ]) {
      final elem = _branchToElement[branch];
      if (elem != null) counts[elem] = counts[elem]! + 1;
    }

    return counts;
  }

  /// 관계 유형별 점수 조정
  int _adjustScoreForRelation(
    int baseScore,
    String relationType,
    DayMasterCompatibility dayMaster,
    BranchCompatibility branch,
  ) {
    int adjusted = baseScore;
    switch (relationType) {
      case 'love':
        if (branch.hasSixCombination) adjusted += 8;
        if (dayMaster.hasCombination) adjusted += 10;
        if (branch.hasClash) adjusted -= 5;
        break;
      case 'marriage':
        if (branch.hasTripleHarmony) adjusted += 5;
        if (branch.hasClash) adjusted -= 10;
        if (branch.hasPunishment) adjusted -= 8;
        if (branch.hasHarm) adjusted -= 6;
        break;
      case 'business':
        if (dayMaster.relationship == '상생(생)') adjusted += 5;
        if (dayMaster.relationship == '비겁') adjusted += 3;
        break;
      case 'friendship':
        if (dayMaster.relationship == '비겁') adjusted += 8;
        if (branch.hasTripleHarmony) adjusted += 5;
        break;
    }
    return adjusted.clamp(0, 100);
  }

  /// 궁합 분석 결과 생성
  CompatibilityAnalysisResult _generateCompatibilityAnalysis(
    DayMasterCompatibility dayMaster,
    BranchCompatibility branch,
    ElementBalanceResult elementBalance,
    int overallScore,
  ) {
    String summary;
    final strengths = <String>[];
    final challenges = <String>[];
    final advice = <String>[];

    if (overallScore >= 85) {
      summary = '천생연분에 가까운 좋은 궁합! ${dayMaster.description}';
    } else if (overallScore >= 70) {
      summary = '좋은 궁합입니다. ${dayMaster.description}';
    } else if (overallScore >= 55) {
      summary = '보통의 궁합. 노력하면 좋은 관계가 됩니다.';
    } else {
      summary = '도전적인 궁합. 서로 이해하려는 노력이 필요합니다.';
    }

    if (dayMaster.hasCombination) strengths.add('천간합으로 자연스럽게 끌리는 인연');
    if (branch.hasSixCombination) strengths.add('육합으로 서로 보완하는 관계');
    if (branch.hasTripleHarmony) strengths.add('삼합으로 함께할 때 시너지 발생');
    if (elementBalance.complementary.isNotEmpty) {
      strengths.add('오행 보완: ${elementBalance.complementary.join(", ")}');
    }

    if (branch.hasClash) challenges.add('지지 충으로 갈등 가능성');
    if (branch.hasPunishment) challenges.add('지지 형으로 상처 가능성');
    if (branch.hasHarm) challenges.add('지지 해로 은근한 갈등');
    if (elementBalance.lacking.isNotEmpty) {
      challenges.add('부족한 오행: ${elementBalance.lacking.join(", ")}');
    }

    if (branch.hasClash) advice.add('갈등 시 잠시 거리를 두고 대화하세요');
    advice.add('서로의 차이를 인정하고 강점에 집중하세요');

    return CompatibilityAnalysisResult(
      summary: summary,
      strengths: strengths,
      challenges: challenges,
      advice: advice,
    );
  }
}

// ========== 궁합 결과 클래스 ==========

class CompatibilityResult {
  final int overallScore;
  final int loveScore;
  final int marriageScore;
  final int businessScore;
  final int friendshipScore;
  final DayMasterCompatibility dayMasterAnalysis;
  final BranchCompatibility branchAnalysis;
  final ElementBalanceResult elementBalance;
  final CompatibilityAnalysisResult analysis;

  CompatibilityResult({
    required this.overallScore,
    required this.loveScore,
    required this.marriageScore,
    required this.businessScore,
    required this.friendshipScore,
    required this.dayMasterAnalysis,
    required this.branchAnalysis,
    required this.elementBalance,
    required this.analysis,
  });
}

class DayMasterCompatibility {
  final String stem1;
  final String stem2;
  final String element1;
  final String element2;
  final String relationship;
  final bool hasCombination;
  final double score;
  final String description;

  DayMasterCompatibility({
    required this.stem1,
    required this.stem2,
    required this.element1,
    required this.element2,
    required this.relationship,
    required this.hasCombination,
    required this.score,
    required this.description,
  });
}

class BranchCompatibility {
  final String branch1;
  final String branch2;
  final bool hasSixCombination;
  final bool hasTripleHarmony;
  final bool hasClash;
  final bool hasPunishment;
  final bool hasHarm;
  final String mainRelationship;
  final double score;
  final String description;

  BranchCompatibility({
    required this.branch1,
    required this.branch2,
    required this.hasSixCombination,
    required this.hasTripleHarmony,
    required this.hasClash,
    required this.hasPunishment,
    required this.hasHarm,
    required this.mainRelationship,
    required this.score,
    required this.description,
  });
}

class ElementBalanceResult {
  final Map<String, int> elements1;
  final Map<String, int> elements2;
  final Map<String, int> combined;
  final double score;
  final List<String> complementary;
  final List<String> lacking;

  ElementBalanceResult({
    required this.elements1,
    required this.elements2,
    required this.combined,
    required this.score,
    required this.complementary,
    required this.lacking,
  });
}

class CompatibilityAnalysisResult {
  final String summary;
  final List<String> strengths;
  final List<String> challenges;
  final List<String> advice;

  CompatibilityAnalysisResult({
    required this.summary,
    required this.strengths,
    required this.challenges,
    required this.advice,
  });
}
