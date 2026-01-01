import '../entities/daewoon.dart';
import '../entities/saju_chart.dart';
import '../entities/ten_gods.dart';

/// 화면에서 바로 쓰기 위한 "문장 생성" 유틸.
/// - 데이터 모델(엔티티)은 건드리지 않고, 표시 텍스트만 풍부하게 만듭니다.
class AnalysisTextBuilder {
  AnalysisTextBuilder._();

  static const Map<String, String> _stemToElement = {
    '갑': '목', '을': '목',
    '병': '화', '정': '화',
    '무': '토', '기': '토',
    '경': '금', '신': '금',
    '임': '수', '계': '수',
  };

  static String _getStemElement(String stem) => _stemToElement[stem] ?? '토';

  /// 오행 관계 (일간 기준)
  /// - same: 동일 오행 (비겁)
  /// - generates: 내가 생함 (식상)
  /// - overcomes: 내가 극함 (재성)
  /// - generated: 나를 생함 (인성)
  /// - overcome: 나를 극함 (관성)
  static String _getElementRelationship(String myElement, String targetElement) {
    if (myElement == targetElement) return 'same';
    const generates = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
    const overcomes = {'목': '토', '토': '수', '수': '화', '화': '금', '금': '목'};

    if (generates[myElement] == targetElement) return 'generates';
    if (overcomes[myElement] == targetElement) return 'overcomes';
    if (generates[targetElement] == myElement) return 'generated';
    if (overcomes[targetElement] == myElement) return 'overcome';
    return 'same';
  }

  static String _relationshipLabel(String relationship) {
    switch (relationship) {
      case 'same':
        return '비겁(자기/경쟁)';
      case 'generates':
        return '식상(표현/성과)';
      case 'overcomes':
        return '재성(돈/성과의 대가)';
      case 'generated':
        return '인성(학습/지원)';
      case 'overcome':
        return '관성(책임/직장/압박)';
      default:
        return '균형';
    }
  }

  /// 사주 "종합분석" (결과 페이지용)
  static String buildSajuComprehensiveText({
    required SajuChart chart,
    required TenGods tenGods,
  }) {
    final elementCount = chart.elementCount;
    final dominantElement = elementCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final weakElement = chart.complementaryElement;
    final dominantGod = tenGods.dominantGod;

    final buffer = StringBuffer();
    buffer.writeln(
      '당신의 일간은 ${chart.dayMaster}(${chart.dayMasterElement})로, 기본 기질은 “${_dayMasterCoreTone(chart.dayMaster)}” 쪽에 가깝습니다.',
    );
    buffer.writeln(
      '오행 분포는 ${_elementCountSentence(elementCount)}이며, 상대적으로 강한 기운은 $dominantElement, 보완이 필요한 기운은 $weakElement 쪽으로 읽힙니다.',
    );
    buffer.writeln(
      '십성에서는 “$dominantGod” 기운이 두드러져 ${TenGods.getDescription(dominantGod)}',
    );
    buffer.writeln(
      '이 조합은 “잘할 때는 빠르게 치고 나가지만, 무리하면 한쪽으로 쏠릴 수” 있으니, 강점은 밀고 약점은 생활 습관/관계 설계로 보완하는 전략이 좋습니다.',
    );
    return buffer.toString().trim();
  }

  /// 선택된 대운 기준 "종합분석" 요약 (대운 페이지 상단용)
  static String buildDaewoonComprehensiveText({
    SajuChart? chart,
    required Daewoon daewoon,
  }) {
    final daewoonElement = _getStemElement(daewoon.pillar.heavenlyStem);
    final dayElement = chart?.dayMasterElement ?? '토';
    final relationship = _getElementRelationship(dayElement, daewoonElement);
    final label = _relationshipLabel(relationship);
    final complement = chart?.complementaryElement;

    final buffer = StringBuffer();
    buffer.writeln(
      '${daewoon.periodString}는 ${daewoon.pillar.hanjaRepresentation}($daewoonElement 기운) 대운으로, 큰 흐름은 “${daewoon.theme}”입니다.',
    );
    buffer.writeln(
      '일간 기준으로는 $label 흐름이 강해지는 구간이라, ${_relationshipOneLiner(relationship)}',
    );
    if (complement != null && complement == daewoonElement) {
      buffer.writeln('특히 이 시기는 당신에게 부족한 $complement 기운을 채워주는 쪽이라, “기회가 붙을 때 잡는 힘”이 좋아지기 쉽습니다.');
    }
    buffer.writeln('핵심은 “${_daewoonKeyStrategy(relationship)}”입니다.');
    return buffer.toString().trim();
  }

  /// 대운 항목(각운)별 텍스트
  static Map<String, String> buildDaewoonCategoryTexts({
    SajuChart? chart,
    required Daewoon daewoon,
  }) {
    final daewoonElement = _getStemElement(daewoon.pillar.heavenlyStem);
    final dayElement = chart?.dayMasterElement ?? '토';
    final relationship = _getElementRelationship(dayElement, daewoonElement);

    return {
      '직업/학업': _careerText(relationship),
      '재물': _moneyText(relationship),
      '연애/관계': _loveText(relationship),
      '대인관계': _socialText(relationship),
      '건강/리듬': _healthText(relationship),
      '실행 팁': _actionTipsText(relationship),
    };
  }

  static String _dayMasterCoreTone(String stem) {
    const map = {
      '갑': '곧게 성장하며 이끄는 힘',
      '을': '유연하게 엮고 조율하는 힘',
      '병': '밝게 확장하고 드러내는 힘',
      '정': '섬세하게 집중하고 완성하는 힘',
      '무': '중심을 잡고 버티는 힘',
      '기': '받쳐주고 다듬어 실현하는 힘',
      '경': '결단하고 정리하는 힘',
      '신': '정밀하게 다듬고 기준을 세우는 힘',
      '임': '큰 흐름을 읽고 포용하는 힘',
      '계': '스며들어 변화시키는 힘',
    };
    return map[stem] ?? '균형 있게 나아가는 힘';
  }

  static String _elementCountSentence(Map<String, int> elementCount) {
    // 보기 좋은 순서로
    const order = ['목', '화', '토', '금', '수'];
    final parts = <String>[];
    for (final e in order) {
      parts.add('$e ${elementCount[e] ?? 0}');
    }
    return parts.join(' · ');
  }

  static String _relationshipOneLiner(String relationship) {
    switch (relationship) {
      case 'same':
        return '자기주도/경쟁이 강해지고 “내가 직접 뛰어야” 일이 풀리기 쉽습니다.';
      case 'generates':
        return '표현/성과 운이 올라 “만들고 보여주는 것”이 커리어로 이어지기 쉽습니다.';
      case 'overcomes':
        return '돈의 흐름이 크게 움직여 “기회-리스크”가 함께 커지기 쉽습니다.';
      case 'generated':
        return '지원/학습이 붙어 “쌓고 준비한 것”이 힘이 되는 구간입니다.';
      case 'overcome':
        return '책임/평가가 강해져 “규칙·직장·권한” 이슈가 전면에 나올 수 있습니다.';
      default:
        return '크게 무리하지 않으면 안정적으로 정리되는 흐름입니다.';
    }
  }

  static String _daewoonKeyStrategy(String relationship) {
    switch (relationship) {
      case 'same':
        return '혼자 끌고 가되, “충돌 관리”를 시스템화하기';
      case 'generates':
        return '성과를 “포트폴리오/평판”으로 남기기';
      case 'overcomes':
        return '수입보다 “현금흐름/리스크 관리”를 먼저';
      case 'generated':
        return '공부·자격·멘토·네트워크에 투자하기';
      case 'overcome':
        return '규칙을 내 편으로 만들고, 과부하를 예방하기';
      default:
        return '루틴 유지 + 과감한 한 방은 타이밍만';
    }
  }

  static String _careerText(String relationship) {
    switch (relationship) {
      case 'same':
        return '주도권을 잡기 좋지만 경쟁도 함께 옵니다. 역할·권한을 문서로 정리하고, “내 방식”을 관철하되 협업 룰을 먼저 맞추면 성과가 안정됩니다.';
      case 'generates':
        return '기획/콘텐츠/개발/세일즈처럼 “만드는 일·표현하는 일”에 강합니다. 결과물을 외부에 보여줄수록(발표/포트폴리오/지표) 운이 붙습니다.';
      case 'overcomes':
        return '성과가 돈으로 환산되기 쉬운 구간입니다. 다만 과확장하면 체력이 먼저 무너질 수 있으니, 목표를 “분기 단위”로 끊어 관리하세요.';
      case 'generated':
        return '자격증, 학위, 레퍼런스, 문서 운이 좋아집니다. 당장 성과보다 기반(기술 스택/전문성/네트워크)을 깔면 후반에 크게 터집니다.';
      case 'overcome':
        return '조직/평가/규칙의 압박이 강해질 수 있습니다. 승진·공직·관리 역할에 기회가 있지만, 과로/스트레스 관리가 핵심입니다.';
      default:
        return '큰 변화보다 안정적 운영에 유리합니다. 루틴을 지키면서 “작은 개선”을 반복하는 전략이 좋습니다.';
    }
  }

  static String _moneyText(String relationship) {
    switch (relationship) {
      case 'same':
        return '돈은 “내가 벌고 내가 쓰는” 흐름이 강합니다. 공동지출/투자에서는 기준을 명확히 하고, 충동 지출을 예산으로 막아두면 좋습니다.';
      case 'generates':
        return '직접 만든 결과물이 수입으로 연결되기 쉽습니다. 사이드 프로젝트/부업/브랜딩에 유리하지만, 계약·정산은 꼼꼼하게 보세요.';
      case 'overcomes':
        return '재물 운의 진폭이 커집니다. 투자/사업 기회가 생기기 쉬우나 레버리지 과사용은 금물. “현금 비중 + 손절 기준”을 먼저 세우세요.';
      case 'generated':
        return '보조금/지원/안정적 수입 구조를 만들기 좋습니다. 장기 저축, 연금, 안전자산 등 “기반형 자산”에 강합니다.';
      case 'overcome':
        return '돈을 쓰게 만드는 책임(가족/조직/의무)이 늘 수 있습니다. 보험/세금/대출처럼 “규칙형 지출”을 정리하면 새는 돈이 줄어듭니다.';
      default:
        return '무리한 확장보다 지출 구조를 정리하면 체감이 좋아집니다. 작은 구독/고정비부터 슬림화하세요.';
    }
  }

  static String _loveText(String relationship) {
    switch (relationship) {
      case 'same':
        return '자기주장이 강해져 관계에서 “주도권 다툼”이 생기기 쉽습니다. 상대의 속도를 존중하고, 결정 전에 한 번 더 합의하는 습관이 필요합니다.';
      case 'generates':
        return '매력·표현력이 올라가 호감이 들어오기 쉽습니다. 다만 말/행동이 과해지면 오해가 생길 수 있어 “약속은 가볍게, 행동은 확실히”가 좋아요.';
      case 'overcomes':
        return '만남이 “선택과 집중”으로 흐르기 쉽습니다. 조건/현실을 보게 되는 시기라, 감정과 생활 설계를 같이 맞추는 관계가 오래 갑니다.';
      case 'generated':
        return '정서적 안정이 중요해지는 시기입니다. 믿을 수 있는 관계, 오래 아는 인연, 가족 같은 파트너십이 강해집니다.';
      case 'overcome':
        return '책임/결혼/약속 같은 “관계의 제도화” 이슈가 올라옵니다. 급하게 결정하기보다 기준(가치관/생활)을 먼저 맞추는 게 안전합니다.';
      default:
        return '큰 이벤트보다는 편안한 관계 유지에 유리합니다. 서로의 루틴을 존중하는 데서 안정이 나옵니다.';
    }
  }

  static String _socialText(String relationship) {
    switch (relationship) {
      case 'same':
        return '동료/친구와 경쟁·비교가 늘 수 있습니다. “협업 기준(역할/기한/의사결정)”을 먼저 잡으면 갈등을 줄일 수 있어요.';
      case 'generates':
        return '사람 앞에서 빛나는 구간이라 발표/세미나/커뮤니티 활동이 좋습니다. 연결이 곧 기회가 되니, 네트워크를 “작게 자주” 유지하세요.';
      case 'overcomes':
        return '인맥이 곧 돈/일이 되는 시기입니다. 다만 이해관계가 섞이면 관계가 빠르게 식을 수 있어, 계약/경계 설정이 중요합니다.';
      case 'generated':
        return '도와주는 사람이 생기기 쉽고, 멘토/선배/조직의 지원이 들어옵니다. 감사 표현과 꾸준한 피드백이 관계운을 키웁니다.';
      case 'overcome':
        return '권위/규칙을 가진 사람(상사/기관)과의 관계가 중요해집니다. “원칙 + 유연함”을 같이 가져가면 평판이 좋아집니다.';
      default:
        return '넓히기보다 정리/정돈에 좋습니다. 가까운 관계를 깊게 다지는 데 집중하세요.';
    }
  }

  static String _healthText(String relationship) {
    switch (relationship) {
      case 'same':
        return '에너지는 올라가지만 무리하면 번아웃이 옵니다. 운동은 “과격하게 짧게”보다 “가볍게 꾸준히”가 이득입니다.';
      case 'generates':
        return '활동량이 늘고 수면이 흔들릴 수 있습니다. 카페인/야식/밤샘을 줄이고, 루틴을 고정하면 컨디션이 안정됩니다.';
      case 'overcomes':
        return '욕심이 커져 과로/과식으로 이어지기 쉽습니다. 체중/소화/염증 반응을 체크하고, 과감히 쉬는 날을 확보하세요.';
      case 'generated':
        return '회복/재충전에 유리합니다. 스트레칭, 호흡, 공부/명상처럼 “내부 에너지 채우기”가 건강에 직결됩니다.';
      case 'overcome':
        return '스트레스가 건강으로 내려오기 쉬운 구간입니다. 규칙적 수면, 주 1회 완전 휴식, 정기검진 같은 “시스템”이 필요합니다.';
      default:
        return '크게 흔들리진 않지만 방심하면 루틴이 무너질 수 있습니다. 기본(수면/수분/걷기)을 지키세요.';
    }
  }

  static String _actionTipsText(String relationship) {
    switch (relationship) {
      case 'same':
        return '1) 경쟁 상대를 “협업 파트너”로 바꿀 장치를 만들기  2) 중요한 결정을 감정 피크 시간에 하지 않기  3) 내 루틴(운동/수면)을 최우선 고정';
      case 'generates':
        return '1) 결과물을 공개/기록(포트폴리오, SNS, 지표)  2) 말로 약속하기보다 일정/산출물로 증명  3) 피로 누적 전 “중간 휴식”을 캘린더에 넣기';
      case 'overcomes':
        return '1) 손익/리스크 기준을 숫자로 고정  2) 현금흐름 우선(고정비 점검)  3) 투자/확장 전 2주 관찰 후 실행';
      case 'generated':
        return '1) 자격/공부/문서화에 투자  2) 멘토/선배 피드백 루프 만들기  3) 장기 플랜(6~12개월)로 기반 다지기';
      case 'overcome':
        return '1) 역할·권한·기한을 문서로  2) 스트레스 해소 루틴(운동/산책/상담)  3) 과로 신호(수면/소화/두통) 오면 즉시 감속';
      default:
        return '1) 루틴 유지  2) 작은 개선 반복  3) 큰 선택은 타이밍(정보가 모인 뒤)에';
    }
  }
}

