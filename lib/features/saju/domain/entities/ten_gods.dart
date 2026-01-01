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

  /// 십성 설명
  static String getDescription(String god) {
    const descriptions = {
      '비견': '자아의 주체성과 독립심을 나타냅니다. 경쟁심과 자존심이 강합니다.',
      '겁재': '강한 추진력과 승부욕을 상징합니다. 재물에 대한 욕구가 있습니다.',
      '식신': '표현력과 창의성을 나타냅니다. 언변이 좋고 예술적 감각이 있습니다.',
      '상관': '반항적이고 창의적인 기질입니다. 권위에 도전하는 성향이 있습니다.',
      '편재': '사업가적 기질과 활동적인 재물 운을 나타냅니다.',
      '정재': '정직하고 꼼꼼한 재물 관리 능력을 상징합니다.',
      '편관': '카리스마와 통솔력을 나타냅니다. 위엄이 있으나 과격할 수 있습니다.',
      '정관': '책임감과 명예를 중시합니다. 질서와 규율을 따릅니다.',
      '편인': '비범한 재능과 직관력을 상징합니다. 신비로운 것에 관심이 있습니다.',
      '정인': '학문과 지식을 사랑합니다. 모성애와 인자함을 나타냅니다.',
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
