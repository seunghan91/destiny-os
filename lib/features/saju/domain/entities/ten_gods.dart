import 'package:equatable/equatable.dart';

/// 십성 (Ten Gods) - 사주 해석의 핵심
/// 일간을 기준으로 다른 간지와의 관계를 정의
class TenGods extends Equatable {
  final Map<String, int> distribution;  // 십성 분포

  const TenGods({required this.distribution});

  /// 비견 (Friend) - 같은 오행, 같은 음양
  int get friend => distribution['비견'] ?? 0;

  /// 겁재 (Rob Wealth) - 같은 오행, 다른 음양
  int get robWealth => distribution['겁재'] ?? 0;

  /// 식신 (Eating God) - 내가 생하는 오행, 같은 음양
  int get eatingGod => distribution['식신'] ?? 0;

  /// 상관 (Hurting Officer) - 내가 생하는 오행, 다른 음양
  int get hurtingOfficer => distribution['상관'] ?? 0;

  /// 편재 (Indirect Wealth) - 내가 극하는 오행, 같은 음양
  int get indirectWealth => distribution['편재'] ?? 0;

  /// 정재 (Direct Wealth) - 내가 극하는 오행, 다른 음양
  int get directWealth => distribution['정재'] ?? 0;

  /// 편관 (Seven Killings) - 나를 극하는 오행, 같은 음양
  int get sevenKillings => distribution['편관'] ?? 0;

  /// 정관 (Direct Officer) - 나를 극하는 오행, 다른 음양
  int get directOfficer => distribution['정관'] ?? 0;

  /// 편인 (Indirect Resource) - 나를 생하는 오행, 같은 음양
  int get indirectResource => distribution['편인'] ?? 0;

  /// 정인 (Direct Resource) - 나를 생하는 오행, 다른 음양
  int get directResource => distribution['정인'] ?? 0;

  /// 가장 강한 십성
  String get dominantGod {
    String? dominant;
    int maxCount = 0;

    distribution.forEach((god, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = god;
      }
    });

    return dominant ?? '비견';
  }

  /// 십성 설명 (장점과 주의점 포함)
  static String getDescription(String god) {
    const descriptions = {
      '비견': '자아의 주체성과 독립심이 강합니다. 다만 고집이 세고 타인과 충돌하기 쉬우니 협력하는 자세를 기르세요. 경쟁심이 과하면 외로워질 수 있습니다.',
      '겁재': '강한 추진력과 승부욕이 있습니다. 그러나 욕심이 과하면 손해를 볼 수 있고, 주변 사람과 마찰이 생기기 쉽습니다. 나눔을 배우세요.',
      '식신': '표현력과 창의성이 뛰어납니다. 다만 말이 많아지면 실수할 수 있고, 지나친 낙관으로 현실을 놓칠 수 있습니다. 신중함을 갖추세요.',
      '상관': '창의적이고 혁신적인 기질이 있습니다. 그러나 권위에 대한 반항심이 과하면 조직에서 어려움을 겪을 수 있습니다. 때로는 따르는 것도 지혜입니다.',
      '편재': '사업가적 기질과 통 큰 재물 운이 있습니다. 하지만 도박성 투자나 무리한 확장은 위험합니다. 안정적인 기반 위에서 도전하세요.',
      '정재': '꼼꼼하고 성실한 재물 관리 능력이 있습니다. 다만 지나치게 아끼다 보면 인색해 보일 수 있고, 기회를 놓칠 수 있습니다. 적절한 투자도 필요합니다.',
      '편관': '카리스마와 통솔력이 있습니다. 그러나 과격하거나 강압적으로 비칠 수 있으니 부드러운 리더십을 배우세요. 스트레스 관리도 중요합니다.',
      '정관': '책임감과 명예를 중시합니다. 다만 원칙에 지나치게 얽매이면 융통성이 부족해 보일 수 있습니다. 때로는 유연함도 필요합니다.',
      '편인': '비범한 직관력과 통찰력이 있습니다. 그러나 지나치면 의심이 많아지고 현실과 동떨어질 수 있습니다. 현실에 발을 딛고 행동하세요.',
      '정인': '학문과 지식을 사랑하며 배려심이 깊습니다. 다만 지나친 걱정과 과보호는 오히려 해가 됩니다. 신뢰하고 놓아주는 연습도 필요합니다.',
    };
    return descriptions[god] ?? '';
  }

  /// 십성 -> MBTI 성향 매핑 (Gap Analysis용)
  static Map<String, String> getMbtiTendency(String god) {
    const mapping = {
      '비견': {'E': 0.6, 'I': 0.4, 'tendency': 'E 성향 (자기주장이 강함)'},
      '겁재': {'E': 0.7, 'I': 0.3, 'tendency': 'E 성향 (경쟁적, 활동적)'},
      '식신': {'N': 0.6, 'S': 0.4, 'P': 0.7, 'J': 0.3, 'tendency': 'NP 성향 (창의적, 유연함)'},
      '상관': {'N': 0.7, 'S': 0.3, 'P': 0.8, 'J': 0.2, 'tendency': 'NP 성향 (반항적, 창조적)'},
      '편재': {'E': 0.8, 'I': 0.2, 'T': 0.6, 'F': 0.4, 'tendency': 'ET 성향 (사업가적)'},
      '정재': {'S': 0.7, 'N': 0.3, 'J': 0.8, 'P': 0.2, 'tendency': 'SJ 성향 (꼼꼼함, 실용적)'},
      '편관': {'E': 0.7, 'I': 0.3, 'T': 0.8, 'F': 0.2, 'J': 0.7, 'tendency': 'ETJ 성향 (리더십, 카리스마)'},
      '정관': {'I': 0.5, 'E': 0.5, 'S': 0.6, 'J': 0.8, 'tendency': 'STJ 성향 (책임감, 원칙주의)'},
      '편인': {'I': 0.7, 'E': 0.3, 'N': 0.8, 'T': 0.7, 'tendency': 'INT 성향 (통찰력, 분석적)'},
      '정인': {'I': 0.6, 'E': 0.4, 'S': 0.5, 'F': 0.7, 'J': 0.6, 'tendency': 'ISF 성향 (배려, 보호본능)'},
    };
    return {
      'tendency': mapping[god]?['tendency']?.toString() ?? '',
    };
  }

  @override
  List<Object?> get props => [distribution];
}
