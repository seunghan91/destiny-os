import '../entities/daewoon.dart';
import '../entities/saju_chart.dart';
import '../entities/ten_gods.dart';

/// 화면에서 바로 쓰기 위한 "문장 생성" 유틸.
/// - 데이터 모델(엔티티)은 건드리지 않고, 표시 텍스트만 풍부하게 만듭니다.
class AnalysisTextBuilder {
  AnalysisTextBuilder._();

  static const Map<String, String> _stemToElement = {
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
  };

  static String _getStemElement(String stem) => _stemToElement[stem] ?? '토';

  /// 오행 관계 (일간 기준)
  /// - same: 동일 오행 (비겁)
  /// - generates: 내가 생함 (식상)
  /// - overcomes: 내가 극함 (재성)
  /// - generated: 나를 생함 (인성)
  /// - overcome: 나를 극함 (관성)
  static String _getElementRelationship(
    String myElement,
    String targetElement,
  ) {
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
    final dominantElement = elementCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
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
      buffer.writeln(
        '특히 이 시기는 당신에게 부족한 $complement 기운을 채워주는 쪽이라, “기회가 붙을 때 잡는 힘”이 좋아지기 쉽습니다.',
      );
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
        return '요약: 주도권을 잡기 좋지만 경쟁·충돌도 함께 옵니다.\n'
            '포인트: 1) 역할·권한·의사결정 기준을 문서로 먼저 정리  2) “내 방식”을 관철하기 전에 협업 룰(리뷰/보고/일정)을 합의  3) 경쟁은 성장 동력으로 쓰되 비교에 휘둘리지 않기\n'
            '주의: 힘으로 밀어붙이면 평판이 깎이기 쉬우니, 결과보다 “과정의 공정함”을 챙기면 커리어가 안정됩니다.';
      case 'generates':
        return '요약: “만들고 보여주는 것”이 곧 성과로 이어지는 구간입니다.\n'
            '포인트: 1) 기획/콘텐츠/개발/세일즈 등 산출물 중심 업무에 강점  2) 발표·포트폴리오·지표 공개처럼 외부 노출이 곧 기회  3) 개인 브랜딩/레퍼런스를 쌓을수록 속도가 붙습니다.\n'
            '실행: 주 1회 “결과물 공개(데모/리포트/글)”를 루틴으로 만들면 운의 체감이 커집니다.';
      case 'overcomes':
        return '요약: 성과가 돈/보상으로 환산되기 쉬운 대신, 욕심이 과해지면 번아웃이 빨리 옵니다.\n'
            '포인트: 1) KPI/인센/매출처럼 “결과=보상” 구조가 열림  2) 확장(프로젝트/사업/투자)이 동시에 유혹  3) 효율이 좋을 때 더 무리하기 쉬움\n'
            '주의/실행: 목표를 “분기 단위”로 끊고, 리소스(시간/체력/팀)를 숫자로 제한하면 성과가 오래 갑니다.';
      case 'generated':
        return '요약: 당장 성과보다 “기반을 쌓을수록 후반이 크게 터지는” 흐름입니다.\n'
            '포인트: 1) 자격증/학위/레퍼런스/문서화 운이 좋음  2) 멘토·조직의 지원을 받기 쉬움  3) 실력의 누적이 평판으로 전환되기 쉬움\n'
            '실행: 기술 스택 정리, 포트폴리오 구조화, 네트워크 관리(정기 피드백) 같은 “기반 작업”을 우선순위로 두세요.';
      case 'overcome':
        return '요약: 책임·평가·규칙이 강해져 “관리/승진/공식 역할” 기회가 오기 쉽습니다.\n'
            '포인트: 1) 조직/상사/제도의 영향력이 커짐  2) 권한과 책임이 함께 늘어남  3) 성과뿐 아니라 “리스크 관리” 능력이 중요\n'
            '주의/실행: 과로/스트레스가 누적되기 쉬우니, 보고·결재·의사결정을 표준화하고(템플릿/체크리스트) 휴식 루틴을 고정하세요.';
      default:
        return '요약: 큰 변화보다 안정적 운영에 유리합니다.\n'
            '포인트: 1) 급한 변동보다 정리/개선이 성과로 이어짐  2) 루틴이 곧 실력  3) 작은 승리의 누적이 중요\n'
            '실행: 루틴을 지키면서 “작은 개선”을 반복하고, 분기마다 한 번만 방향 전환을 검토하세요.';
    }
  }

  static String _moneyText(String relationship) {
    switch (relationship) {
      case 'same':
        return '요약: “내가 벌고 내가 쓰는” 흐름이 강해, 통제가 되면 빠르게 모이고 무너지면 빠르게 새기 쉽습니다.\n'
            '포인트: 1) 수입/지출 의사결정이 내 손에 있을수록 유리  2) 공동지출/동업은 기준이 흐려지기 쉬움  3) 충동지출이 누적되면 체감 손실이 커짐\n'
            '실행: 고정비/변동비를 분리하고, 공동지출/투자는 “규칙(비율·한도·정산일)”을 먼저 합의하세요.';
      case 'generates':
        return '요약: 만든 결과물이 수입으로 연결되기 쉬워 “부업/브랜딩/콘텐츠 수익화”에 강합니다.\n'
            '포인트: 1) 실력/산출물이 곧 매출로 전환  2) 수익 채널(의뢰/강의/콘텐츠/프로덕트)을 늘리기 좋음  3) 다만 정산·권리 이슈가 함께 따라옴\n'
            '주의/실행: 계약서(범위/납기/수정/정산/저작권)와 세금/정산 루틴을 먼저 만들어 “수익이 새지 않게” 하세요.';
      case 'overcomes':
        return '요약: 재물 운의 진폭이 커져 기회와 리스크가 동시에 커집니다.\n'
            '포인트: 1) 투자/사업/확장 기회가 자주 보임  2) 판단이 맞으면 수익이 크지만, 틀리면 회복이 오래 감  3) 레버리지 유혹이 강해짐\n'
            '주의/실행: “현금 비중 + 손절 기준 + 최대 손실 한도”를 숫자로 고정하고, 확장 전 2주 검증(데이터/리스크 점검)을 거치세요.';
      case 'generated':
        return '요약: 안정적인 수입 구조/지원 운이 붙어 “기반형 자산”을 만들기 좋습니다.\n'
            '포인트: 1) 보조금/지원/안정적 계약에 유리  2) 장기 저축·연금·안전자산과 궁합  3) 복리/누적이 강점으로 작동\n'
            '실행: 자동이체(저축/투자/비상금)로 시스템을 만들고, 한 번 만든 구조를 오래 유지하는 전략이 가장 효율적입니다.';
      case 'overcome':
        return '요약: 책임과 의무가 늘어 “규칙형 지출(세금/보험/대출/가족비)”이 커질 수 있습니다.\n'
            '포인트: 1) 지출의 성격이 감정이 아니라 의무로 바뀜  2) 미정리된 계약/대출/보험이 새는 돈을 만듦  3) 관리가 되면 오히려 재무가 단단해짐\n'
            '실행: 보험/대출/세금/구독을 일괄 점검하고, 월 고정비 상한선을 정하면 스트레스가 크게 줄어듭니다.';
      default:
        return '요약: 무리한 확장보다 “지출 구조 정리”가 바로 체감되는 흐름입니다.\n'
            '포인트: 1) 큰 수익보다 누수가 문제  2) 고정비가 체감 만족도를 좌우  3) 정리만 해도 여유가 생김\n'
            '실행: 작은 구독/고정비부터 슬림화하고, 3개월 단위로 지출 리포트를 한 번씩 보세요.';
    }
  }

  static String _loveText(String relationship) {
    switch (relationship) {
      case 'same':
        return '요약: 자기주장이 강해져 관계에서 “주도권 다툼”이 생기기 쉬운 구간입니다.\n'
            '포인트: 1) 끌림은 강하지만 양보가 어려울 수 있음  2) 말투/결정 방식이 상대에게 압박으로 느껴질 수 있음  3) 기준이 명확한 관계는 오히려 빨리 안정\n'
            '실행: 상대의 속도를 존중하고, 큰 결정을 내리기 전 “한 번 더 합의(오늘 말고 내일 확정)”하는 습관이 도움이 됩니다.';
      case 'generates':
        return '요약: 매력·표현력이 올라가 호감이 들어오기 쉬운 시기입니다.\n'
            '포인트: 1) 소개/모임/활동에서 인연이 생기기 쉬움  2) 표현이 관계를 진전시키는 열쇠  3) 다만 말이 앞서면 기대치가 커짐\n'
            '주의/실행: “약속은 가볍게, 행동은 확실히”를 원칙으로 하고, 관계의 속도는 상대의 반응에 맞춰 조절하세요.';
      case 'overcomes':
        return '요약: 만남이 “선택과 집중”으로 흐르고, 현실 조건을 더 또렷하게 보게 됩니다.\n'
            '포인트: 1) 감정보다 생활/가치관/시간 배분이 중요해짐  2) 관계에서 손익·균형을 따지기 쉬움  3) 맞는 사람과는 빠르게 구체화\n'
            '실행: 감정과 생활 설계(돈/시간/미래 계획)를 같이 맞추는 관계가 오래 가며, 불확실한 관계는 정리하는 것이 마음이 편해집니다.';
      case 'generated':
        return '요약: 정서적 안정이 중요해져 “믿고 기대도 되는 관계”가 강해집니다.\n'
            '포인트: 1) 오래 아는 인연/지인 연결이 유리  2) 신뢰·배려가 관계의 핵심  3) 마음이 편한 사람이 곧 좋은 사람\n'
            '실행: 관계의 온도를 유지하는 작은 루틴(주 1회 데이트/대화 시간)을 만들면 안정감이 커집니다.';
      case 'overcome':
        return '요약: 책임/결혼/약속 같은 “관계의 제도화” 이슈가 올라옵니다.\n'
            '포인트: 1) 관계가 공식화되거나, 반대로 책임 문제로 정리될 수 있음  2) 가족/직장/현실 변수의 영향이 커짐  3) 기준이 맞으면 빠르게 안정\n'
            '주의/실행: 급하게 결정하기보다 가치관/생활(돈·시간·가사·커리어) 기준을 먼저 맞추는 게 안전합니다.';
      default:
        return '요약: 큰 이벤트보다는 편안한 관계 유지에 유리합니다.\n'
            '포인트: 1) 과한 밀당보다 일상 공유가 효과적  2) 관계의 안정이 에너지를 올려줌  3) 작은 배려가 큰 만족으로 이어짐\n'
            '실행: 서로의 루틴을 존중하고, 자주 만남보다 “정해진 시간의 꾸준함”을 우선해 보세요.';
    }
  }

  static String _socialText(String relationship) {
    switch (relationship) {
      case 'same':
        return '요약: 경쟁·비교가 늘어 관계가 예민해질 수 있습니다.\n'
            '포인트: 1) 말보다 성과/포지션으로 부딪히기 쉬움  2) 사소한 오해가 확대될 수 있음  3) 기준이 명확하면 오히려 강한 팀을 만들 수 있음\n'
            '실행: “협업 기준(역할/기한/의사결정)”을 먼저 잡고, 감정이 올라갈 땐 메시지보다 대면/통화로 정리하세요.';
      case 'generates':
        return '요약: 사람 앞에서 빛나는 구간이라 네트워킹이 곧 기회로 이어집니다.\n'
            '포인트: 1) 발표/세미나/커뮤니티에서 존재감 상승  2) 소개·추천이 자연스럽게 발생  3) 연결이 늘수록 일/수입도 따라오는 흐름\n'
            '실행: 네트워크를 “작게 자주” 유지하세요. (월 2회 모임 + 주 1회 안부/피드백)처럼 루틴화하면 효과가 큽니다.';
      case 'overcomes':
        return '요약: 인맥이 곧 돈/일이 되는 시기라 연결의 질이 성과를 좌우합니다.\n'
            '포인트: 1) 소개/파트너십이 수익으로 직결  2) 이해관계가 섞이면서 갈등도 쉬움  3) 신뢰가 깨지면 회복이 느림\n'
            '주의/실행: 계약/정산/역할을 문서로 남기고, “경계(가능/불가능)”를 처음부터 말하면 오히려 관계가 오래 갑니다.';
      case 'generated':
        return '요약: 도와주는 사람이 생기기 쉬워 멘토/조직의 지원을 잘 받는 구간입니다.\n'
            '포인트: 1) 선배/조직/커뮤니티의 도움 운  2) 추천/연결이 자연스럽게 들어옴  3) 관계의 “신뢰”가 자산이 됨\n'
            '실행: 감사 표현을 구체적으로 하고(무엇이 도움이 됐는지), 진행 상황을 짧게 공유하는 피드백 루프가 관계운을 키웁니다.';
      case 'overcome':
        return '요약: 권위/규칙을 가진 사람(상사/기관)과의 관계가 중요해집니다.\n'
            '포인트: 1) 원칙·규정·프로세스가 관계의 기준이 됨  2) 평판이 커리어/기회로 연결  3) 선을 넘으면 제재/불이익이 생기기 쉬움\n'
            '실행: “원칙 + 유연함”을 같이 가져가되, 애매한 건 기록(메일/메모)으로 남기면 안전합니다.';
      default:
        return '요약: 넓히기보다 정리/정돈에 좋습니다.\n'
            '포인트: 1) 관계를 다이어트하면 에너지가 회복  2) 가까운 사람이 더 중요한 시기  3) 불필요한 갈등을 줄이면 운의 체감이 좋아짐\n'
            '실행: 연락 빈도/거리감을 재정리하고, “가까운 관계를 깊게” 다지는 데 집중하세요.';
    }
  }

  static String _healthText(String relationship) {
    switch (relationship) {
      case 'same':
        return '요약: 에너지는 올라가지만 무리하면 번아웃이 빠르게 올 수 있습니다.\n'
            '포인트: 1) 활동량이 늘며 무리하기 쉬움  2) 승부욕이 체력을 갉아먹을 수 있음  3) 회복이 늦어지면 일/관계까지 흔들림\n'
            '실행: 운동은 “과격하게 짧게”보다 “가볍게 꾸준히”가 이득입니다. 수면/휴식도 목표로 관리하세요.';
      case 'generates':
        return '요약: 활동량이 늘고 흥분도가 올라 수면 리듬이 흔들리기 쉽습니다.\n'
            '포인트: 1) 밤샘/야식/카페인이 누적되기 쉬움  2) 컨디션이 들쭉날쭉하면 집중력이 떨어짐  3) 규칙만 잡아도 체감 개선이 큼\n'
            '실행: 카페인/야식/밤샘을 줄이고, 기상·취침 시간을 고정하면 컨디션이 빠르게 안정됩니다.';
      case 'overcomes':
        return '요약: 욕심이 커져 과로/과식으로 이어지기 쉬운 구간입니다.\n'
            '포인트: 1) 무리해서 “성과를 당겨오는” 패턴이 생김  2) 과식/음주/야근이 쌓이면 회복이 느려짐  3) 몸의 경고 신호가 빨리 옴\n'
            '실행: 체중/소화/염증 반응을 체크하고, 과감히 쉬는 날(주 1회)을 확보하세요.';
      case 'generated':
        return '요약: 회복/재충전에 유리해 몸을 “채우는 활동”이 바로 효과로 나타납니다.\n'
            '포인트: 1) 컨디션을 끌어올리기 쉬움  2) 작은 습관이 큰 차이를 만듦  3) 마음 안정이 곧 몸의 안정으로 연결\n'
            '실행: 스트레칭, 호흡, 공부/명상처럼 “내부 에너지 채우기”를 루틴화하면 건강과 집중이 함께 올라갑니다.';
      case 'overcome':
        return '요약: 스트레스가 건강으로 내려오기 쉬워 “관리 시스템”이 필수입니다.\n'
            '포인트: 1) 압박/책임이 늘며 긴장도가 올라감  2) 수면/소화/두통 같은 신호가 먼저 올 수 있음  3) 방치하면 회복에 시간이 걸림\n'
            '실행: 규칙적 수면, 주 1회 완전 휴식, 정기검진 같은 “시스템”을 만들면 리스크가 크게 줄어듭니다.';
      default:
        return '요약: 크게 흔들리진 않지만 방심하면 루틴이 무너질 수 있습니다.\n'
            '포인트: 1) 기본만 지켜도 컨디션이 유지  2) 변동의 원인은 대부분 생활패턴  3) 작은 무너짐이 누적되기 쉬움\n'
            '실행: 기본(수면/수분/걷기)을 지키고, 한 번 무너지면 “다음 날 바로 복구”를 원칙으로 하세요.';
    }
  }

  static String _actionTipsText(String relationship) {
    switch (relationship) {
      case 'same':
        return '1) 경쟁 상대를 “협업 파트너”로 바꿀 장치 만들기\n'
            '2) 중요한 결정을 감정 피크 시간(화/흥분)에 하지 않기\n'
            '3) 내 루틴(운동/수면/식사)을 최우선 고정\n'
            '4) 갈등은 기록/합의(역할·기한·기준)로 줄이기';
      case 'generates':
        return '1) 결과물을 공개/기록(포트폴리오, SNS, 지표)\n'
            '2) 말로 약속하기보다 일정/산출물로 증명\n'
            '3) 피로 누적 전 “중간 휴식”을 캘린더에 넣기\n'
            '4) 한 번에 크게 하기보다 주 1회 꾸준히 업데이트';
      case 'overcomes':
        return '1) 손익/리스크 기준을 숫자로 고정(최대 손실/손절)\n'
            '2) 현금흐름 우선(고정비 점검 + 비상금)\n'
            '3) 투자/확장 전 2주 관찰 후 실행(데이터 확인)\n'
            '4) 레버리지는 “필요할 때만, 작게”';
      case 'generated':
        return '1) 자격/공부/문서화에 투자\n'
            '2) 멘토/선배 피드백 루프 만들기(월 1회 점검)\n'
            '3) 장기 플랜(6~12개월)로 기반 다지기\n'
            '4) 성과는 늦어도 되니 “누적”을 끊지 않기';
      case 'overcome':
        return '1) 역할·권한·기한을 문서로(기준을 내 편으로)\n'
            '2) 스트레스 해소 루틴(운동/산책/상담)을 고정\n'
            '3) 과로 신호(수면/소화/두통) 오면 즉시 감속\n'
            '4) “완벽”보다 “지속가능”을 목표로';
      default:
        return '1) 루틴 유지\n'
            '2) 작은 개선 반복(주간 회고 10분)\n'
            '3) 큰 선택은 타이밍(정보가 모인 뒤)에\n'
            '4) 급할수록 기본을 지키기';
    }
  }
}
