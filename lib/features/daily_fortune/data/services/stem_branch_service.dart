/// 간지(干支) 계산 서비스
class StemBranchService {
  StemBranchService._();

  // 천간(天干) 10개
  static const List<String> _heavenlyStems = [
    '갑', // 0 - 甲 (목)
    '을', // 1 - 乙 (목)
    '병', // 2 - 丙 (화)
    '정', // 3 - 丁 (화)
    '무', // 4 - 戊 (토)
    '기', // 5 - 己 (토)
    '경', // 6 - 庚 (금)
    '신', // 7 - 辛 (금)
    '임', // 8 - 壬 (수)
    '계', // 9 - 癸 (수)
  ];

  // 지지(地支) 12개
  static const List<String> _earthlyBranches = [
    '자', // 0 - 子 (수)
    '축', // 1 - 丑 (토)
    '인', // 2 - 寅 (목)
    '묘', // 3 - 卯 (목)
    '진', // 4 - 辰 (토)
    '사', // 5 - 巳 (화)
    '오', // 6 - 午 (화)
    '미', // 7 - 未 (토)
    '신', // 8 - 申 (금)
    '유', // 9 - 酉 (금)
    '술', // 10 - 戌 (토)
    '해', // 11 - 亥 (수)
  ];

  // 한자 표기
  static const Map<String, String> _hanjaMap = {
    '갑': '甲',
    '을': '乙',
    '병': '丙',
    '정': '丁',
    '무': '戊',
    '기': '己',
    '경': '庚',
    '신': '辛',
    '임': '壬',
    '계': '癸',
    '자': '子',
    '축': '丑',
    '인': '寅',
    '묘': '卯',
    '진': '辰',
    '사': '巳',
    '오': '午',
    '미': '未',
    '유': '酉',
    '술': '戌',
    '해': '亥',
  };

  // 오행 매핑
  static const Map<String, String> _elementMap = {
    '갑': '목',
    '을': '목',
    '병': '화',
    '정': '화',
    '무': '토',
    '기': '토',
    '경': '금',
    '신': '금',
    '임': '수',
    '계': '수',
    '자': '수',
    '축': '토',
    '인': '목',
    '묘': '목',
    '진': '토',
    '사': '화',
    '오': '화',
    '미': '토',
    '유': '금',
    '술': '토',
    '해': '수',
  };

  /// 특정 날짜의 일주(日柱) 간지 계산
  /// 기준일: 1900년 1월 1일 = 갑자일(甲子日)
  static Map<String, String> getDayStemBranch(DateTime date) {
    // 1900년 1월 1일을 기준으로 경과 일수 계산
    final baseDate = DateTime(1900, 1, 1);
    final daysDiff = date.difference(baseDate).inDays;

    // 60갑자 순환
    final stemIndex = daysDiff % 10;
    final branchIndex = daysDiff % 12;

    final stem = _heavenlyStems[stemIndex];
    final branch = _earthlyBranches[branchIndex];

    return {
      'stem': stem,
      'branch': branch,
      'stemHanja': _hanjaMap[stem]!,
      'branchHanja': _hanjaMap[branch]!,
      'dayName': '$stem$branch일',
      'dayNameHanja': '${_hanjaMap[stem]}${_hanjaMap[branch]}日',
      'stemElement': _elementMap[stem]!,
      'branchElement': _elementMap[branch]!,
    };
  }

  /// 천간으로 오행 가져오기
  static String getStemElement(String stem) {
    return _elementMap[stem] ?? '알 수 없음';
  }

  /// 지지로 오행 가져오기
  static String getBranchElement(String branch) {
    return _elementMap[branch] ?? '알 수 없음';
  }

  /// 한자 변환
  static String toHanja(String koreanChar) {
    return _hanjaMap[koreanChar] ?? koreanChar;
  }

  /// 오행 상생 관계 확인
  static bool isGenerating(String element1, String element2) {
    const generating = {
      '목': '화',
      '화': '토',
      '토': '금',
      '금': '수',
      '수': '목',
    };
    return generating[element1] == element2;
  }

  /// 오행 상극 관계 확인
  static bool isOvercoming(String element1, String element2) {
    const overcoming = {
      '목': '토',
      '토': '수',
      '수': '화',
      '화': '금',
      '금': '목',
    };
    return overcoming[element1] == element2;
  }
}
