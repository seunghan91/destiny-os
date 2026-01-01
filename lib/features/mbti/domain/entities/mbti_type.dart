import 'package:equatable/equatable.dart';

/// MBTI 유형
class MbtiType extends Equatable {
  final String type;  // e.g., "INTJ"

  const MbtiType({required this.type});

  /// 각 지표별 성향
  String get energyDirection => type[0];  // E or I
  String get information => type[1];       // S or N
  String get decision => type[2];          // T or F
  String get lifestyle => type[3];         // J or P

  /// 외향형인지
  bool get isExtrovert => energyDirection == 'E';

  /// 직관형인지
  bool get isIntuitive => information == 'N';

  /// 사고형인지
  bool get isThinker => decision == 'T';

  /// 판단형인지
  bool get isJudger => lifestyle == 'J';

  /// 유형 이름 (한글)
  String get koreanName {
    const names = {
      'INTJ': '전략가',
      'INTP': '논리술사',
      'ENTJ': '통솔자',
      'ENTP': '변론가',
      'INFJ': '옹호자',
      'INFP': '중재자',
      'ENFJ': '선도자',
      'ENFP': '활동가',
      'ISTJ': '현실주의자',
      'ISFJ': '수호자',
      'ESTJ': '경영자',
      'ESFJ': '집정관',
      'ISTP': '장인',
      'ISFP': '모험가',
      'ESTP': '사업가',
      'ESFP': '연예인',
    };
    return names[type] ?? type;
  }

  /// 유형 설명
  String get description {
    const descriptions = {
      'INTJ': '독창적이고 독립적인 전략가. 모든 것에 대해 계획을 세우며, 자신만의 높은 기준을 가지고 있습니다.',
      'INTP': '조용하고 분석적인 사색가. 논리적인 설명과 아이디어의 세계에 빠져 있습니다.',
      'ENTJ': '대담하고 상상력이 풍부한 리더. 항상 방법을 찾거나 만들어냅니다.',
      'ENTP': '똑똑하고 호기심 많은 사색가. 지적 도전을 즐깁니다.',
      'INFJ': '조용하고 신비로운 이상주의자. 영감을 주는 비전을 가지고 있습니다.',
      'INFP': '시적이고 친절하며 이타적인 사람. 항상 선한 일을 돕고자 합니다.',
      'ENFJ': '카리스마 있고 영감을 주는 리더. 청중을 사로잡을 수 있습니다.',
      'ENFP': '열정적이고 창의적인 자유 영혼. 항상 이유를 찾아 미소 짓습니다.',
      'ISTJ': '실용적이고 사실적인 개인. 신뢰성이 의심의 여지가 없습니다.',
      'ISFJ': '매우 헌신적이고 따뜻한 보호자. 항상 사랑하는 사람들을 지킵니다.',
      'ESTJ': '뛰어난 관리자. 사물이나 사람을 관리하는 데 탁월합니다.',
      'ESFJ': '매우 배려심이 있고 사교적이며 인기 있는 사람. 항상 도움을 줍니다.',
      'ISTP': '대담하고 실용적인 실험가. 모든 종류의 도구를 다루는 데 능숙합니다.',
      'ISFP': '유연하고 매력적인 예술가. 항상 새로운 것을 탐색합니다.',
      'ESTP': '똑똑하고 에너지 넘치며 매우 통찰력 있는 사람. 위험한 삶을 즐깁니다.',
      'ESFP': '자발적이고 에너지 넘치며 열정적인 연예인. 주변이 지루할 틈이 없습니다.',
    };
    return descriptions[type] ?? '';
  }

  /// 인지 기능 스택 (Cognitive Function Stack)
  List<String> get cognitiveFunctions {
    const stacks = {
      'INTJ': ['Ni', 'Te', 'Fi', 'Se'],
      'INTP': ['Ti', 'Ne', 'Si', 'Fe'],
      'ENTJ': ['Te', 'Ni', 'Se', 'Fi'],
      'ENTP': ['Ne', 'Ti', 'Fe', 'Si'],
      'INFJ': ['Ni', 'Fe', 'Ti', 'Se'],
      'INFP': ['Fi', 'Ne', 'Si', 'Te'],
      'ENFJ': ['Fe', 'Ni', 'Se', 'Ti'],
      'ENFP': ['Ne', 'Fi', 'Te', 'Si'],
      'ISTJ': ['Si', 'Te', 'Fi', 'Ne'],
      'ISFJ': ['Si', 'Fe', 'Ti', 'Ne'],
      'ESTJ': ['Te', 'Si', 'Ne', 'Fi'],
      'ESFJ': ['Fe', 'Si', 'Ne', 'Ti'],
      'ISTP': ['Ti', 'Se', 'Ni', 'Fe'],
      'ISFP': ['Fi', 'Se', 'Ni', 'Te'],
      'ESTP': ['Se', 'Ti', 'Fe', 'Ni'],
      'ESFP': ['Se', 'Fi', 'Te', 'Ni'],
    };
    return stacks[type] ?? [];
  }

  /// 주요 인지 기능 (Dominant Function)
  String get dominantFunction => cognitiveFunctions.isNotEmpty ? cognitiveFunctions[0] : '';

  /// MBTI 테마 컬러
  String get themeColorHex {
    // 분석가(NT), 외교관(NF), 관리자(SJ), 탐험가(SP)
    if (isIntuitive && isThinker) return '#9B59B6';      // 보라 - 분석가
    if (isIntuitive && !isThinker) return '#27AE60';     // 초록 - 외교관
    if (!isIntuitive && isJudger) return '#2980B9';      // 파랑 - 관리자
    return '#F1C40F';  // 노랑 - 탐험가
  }

  @override
  List<Object?> get props => [type];
}

/// MBTI 그룹 (기질 유형)
enum MbtiGroup {
  analyst,    // NT - 분석가
  diplomat,   // NF - 외교관
  sentinel,   // SJ - 관리자
  explorer,   // SP - 탐험가
}

extension MbtiGroupExtension on MbtiType {
  MbtiGroup get group {
    if (isIntuitive && isThinker) return MbtiGroup.analyst;
    if (isIntuitive && !isThinker) return MbtiGroup.diplomat;
    if (!isIntuitive && isJudger) return MbtiGroup.sentinel;
    return MbtiGroup.explorer;
  }

  String get groupName {
    switch (group) {
      case MbtiGroup.analyst:
        return '분석가형';
      case MbtiGroup.diplomat:
        return '외교관형';
      case MbtiGroup.sentinel:
        return '관리자형';
      case MbtiGroup.explorer:
        return '탐험가형';
    }
  }
}
