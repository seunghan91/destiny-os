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
  SajuChart calculateSajuChart({
    required DateTime birthDateTime,
    required bool isLunar,
    required String gender,
    bool useNightSubhour = false,
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
    final hourPillar = _calculateHourPillar(
      dayPillar.heavenlyStem,
      birthDateTime.hour,
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
  Pillar _calculateHourPillar(String dayStem, int hour, bool useNightSubhour) {
    // 시간 → 지지 인덱스 (子시=23~01시, 丑시=01~03시, ...)
    int branchIndex;

    if (useNightSubhour && hour >= 23) {
      // 야자시 사용: 23시 이후는 다음날 자시로 계산
      branchIndex = 0;
    } else {
      branchIndex = ((hour + 1) ~/ 2) % 12;
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
    final dayMasterElement = _stemToElement[dayMaster]!;
    final dayMasterPolarity = _stemPolarity[dayMaster]!;

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
    final targetElement = _stemToElement[targetStem]!;
    final targetPolarity = _stemPolarity[targetStem]!;

    return _getTenGod(dayMasterElement, dayMasterPolarity, targetElement, targetPolarity);
  }

  /// 지지로부터 십성 계산 (정기 기준)
  String? _calculateGodFromBranch(
    String dayMaster,
    String dayMasterElement,
    bool dayMasterPolarity,
    String targetBranch,
  ) {
    final targetElement = _branchToElement[targetBranch]!;
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
      case 'overcomes': // 재성 (내가 극하는 오행)
        return samePolarity ? '편재' : '정재';
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

    // 대운 시작 나이 계산 (간략화: 평균 5세)
    final startAge = 5;

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
  ({double score, bool isFireFavorable, String analysis}) analyzeYearCompatibility(
    SajuChart chart,
    {int year = 2026}
  ) {
    final dayMaster = chart.dayPillar.heavenlyStem;
    final dayMasterElement = _stemToElement[dayMaster]!;

    // 2026년 병오년: 병(화) + 오(화) = 강한 화기
    const yearElement = '화';

    final relationship = _getElementRelationship(dayMasterElement, yearElement);

    double score;
    bool isFireFavorable;
    String analysis;

    switch (relationship) {
      case 'same': // 화일간 → 비겁운 (강해짐)
        score = 70.0;
        isFireFavorable = true;
        analysis = '2026년 화기가 당신의 기운과 같습니다. 자신감이 넘치지만 과열 주의가 필요합니다.';
        break;
      case 'generates': // 목일간 → 식상운 (재능 발휘)
        score = 85.0;
        isFireFavorable = true;
        analysis = '2026년은 당신의 재능이 빛나는 해입니다. 표현하고 창작하세요!';
        break;
      case 'overcomes': // 수일간 → 재성운 (재물)
        score = 80.0;
        isFireFavorable = true;
        analysis = '2026년 화기를 잘 다스리면 재물운이 따릅니다. 투자와 사업에 유리합니다.';
        break;
      case 'generated': // 토일간 → 인성운 (배움)
        score = 65.0;
        isFireFavorable = false;
        analysis = '2026년 화기가 당신을 자극합니다. 배움과 성장의 기회로 삼으세요.';
        break;
      case 'overcome': // 금일간 → 관성운 (도전)
        score = 55.0;
        isFireFavorable = false;
        analysis = '2026년 화기가 강하니 무리하지 마세요. 방어적 자세가 현명합니다.';
        break;
      default:
        score = 60.0;
        isFireFavorable = false;
        analysis = '2026년 평온한 흐름이 예상됩니다.';
    }

    // 사주 내 화기 비율에 따른 조정
    final fireRatio = chart.fireEnergyRatio;
    if (fireRatio > 0.3) {
      // 화가 많은 사주 → 2026년에 과열 가능성
      score -= 10;
      isFireFavorable = false;
      analysis += ' 화기가 과다할 수 있으니 휴식을 충분히 취하세요.';
    } else if (fireRatio < 0.1) {
      // 화가 부족한 사주 → 2026년에 보완
      score += 10;
      isFireFavorable = true;
      analysis += ' 부족했던 화기를 보충받는 좋은 시기입니다.';
    }

    return (
      score: score.clamp(0, 100),
      isFireFavorable: isFireFavorable,
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
}
