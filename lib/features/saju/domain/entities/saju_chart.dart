import 'package:equatable/equatable.dart';

/// 사주팔자 (Four Pillars of Destiny)
/// 년주, 월주, 일주, 시주로 구성
class SajuChart extends Equatable {
  final Pillar yearPillar;   // 년주 (Year Pillar)
  final Pillar monthPillar;  // 월주 (Month Pillar)
  final Pillar dayPillar;    // 일주 (Day Pillar) - 일간이 본인
  final Pillar hourPillar;   // 시주 (Hour Pillar)
  final DateTime birthDateTime;
  final bool isLunar;        // 음력 여부
  final String gender;       // 성별 (남/여)

  const SajuChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.birthDateTime,
    required this.isLunar,
    required this.gender,
  });

  /// 일간 (Day Master) - 사주의 주인공
  String get dayMaster => dayPillar.heavenlyStem;

  /// 일간의 오행
  String get dayMasterElement => _getElement(dayPillar.heavenlyStem);

  /// 보완 오행 - 사주에서 부족하여 보완이 필요한 오행
  /// (전통 명리학의 '용신' 개념을 현대적으로 표현)
  /// 실제 계산은 복잡하므로 간략화된 버전
  String get complementaryElement {
    final elements = elementCount;
    String? weakest;
    int minCount = 999;

    elements.forEach((element, count) {
      if (count < minCount) {
        minCount = count;
        weakest = element;
      }
    });

    return weakest ?? '토';
  }

  /// 오행 분포 카운트
  Map<String, int> get elementCount {
    final count = <String, int>{
      '목': 0, '화': 0, '토': 0, '금': 0, '수': 0,
    };

    void addElement(String stem, String branch) {
      final stemElement = _getElement(stem);
      final branchElement = _getBranchElement(branch);
      if (stemElement.isNotEmpty) count[stemElement] = (count[stemElement] ?? 0) + 1;
      if (branchElement.isNotEmpty) count[branchElement] = (count[branchElement] ?? 0) + 1;
    }

    addElement(yearPillar.heavenlyStem, yearPillar.earthlyBranch);
    addElement(monthPillar.heavenlyStem, monthPillar.earthlyBranch);
    addElement(dayPillar.heavenlyStem, dayPillar.earthlyBranch);
    addElement(hourPillar.heavenlyStem, hourPillar.earthlyBranch);

    return count;
  }

  /// 화(火) 기운 비율 - 2026 병오년 궁합 계산용
  double get fireEnergyRatio {
    final total = elementCount.values.fold(0, (a, b) => a + b);
    if (total == 0) return 0;
    return (elementCount['화'] ?? 0) / total;
  }

  /// 천간 -> 오행 매핑
  String _getElement(String stem) {
    const mapping = {
      '갑': '목', '을': '목',
      '병': '화', '정': '화',
      '무': '토', '기': '토',
      '경': '금', '신': '금',
      '임': '수', '계': '수',
    };
    return mapping[stem] ?? '';
  }

  /// 지지 -> 오행 매핑
  String _getBranchElement(String branch) {
    const mapping = {
      '인': '목', '묘': '목',
      '사': '화', '오': '화',
      '진': '토', '술': '토', '축': '토', '미': '토',
      '신': '금', '유': '금',
      '해': '수', '자': '수',
    };
    return mapping[branch] ?? '';
  }

  /// 사주 전체를 문자열로 표현
  String get fullChart {
    return '${yearPillar.fullPillar} ${monthPillar.fullPillar} '
           '${dayPillar.fullPillar} ${hourPillar.fullPillar}';
  }

  /// 띠 (Zodiac Animal)
  String get zodiacAnimal {
    const animals = ['원숭이', '닭', '개', '돼지', '쥐', '소', '호랑이', '토끼', '용', '뱀', '말', '양'];
    final year = birthDateTime.year;
    return animals[year % 12];
  }

  @override
  List<Object?> get props => [
    yearPillar, monthPillar, dayPillar, hourPillar,
    birthDateTime, isLunar, gender,
  ];
}

/// 기둥 (Pillar) - 천간 + 지지
class Pillar extends Equatable {
  final String heavenlyStem;   // 천간 (갑을병정무기경신임계)
  final String earthlyBranch;  // 지지 (자축인묘진사오미신유술해)

  const Pillar({
    required this.heavenlyStem,
    required this.earthlyBranch,
  });

  /// 60갑자 형태로 표현
  String get fullPillar => '$heavenlyStem$earthlyBranch';

  /// 한자 표기
  String get hanjaRepresentation {
    const stemHanja = {
      '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
      '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
    };
    const branchHanja = {
      '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
      '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
    };
    return '${stemHanja[heavenlyStem]}${branchHanja[earthlyBranch]}';
  }

  @override
  List<Object?> get props => [heavenlyStem, earthlyBranch];
}
