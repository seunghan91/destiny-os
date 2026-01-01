// 사주명리학 상수 정의

// 천간 (天干) - 10개
const List<String> heavenlyStemsHanja = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> heavenlyStemsKorean = ['갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'];

const Map<String, String> heavenlyStemElements = {
  '甲': '목', '乙': '목', '丙': '화', '丁': '화', '戊': '토',
  '己': '토', '庚': '금', '辛': '금', '壬': '수', '癸': '수',
};

const Map<String, bool> heavenlyStemPolarities = {
  '甲': true, '乙': false, '丙': true, '丁': false, '戊': true,
  '己': false, '庚': true, '辛': false, '壬': true, '癸': false,
};

// 지지 (地支) - 12개
const List<String> earthlyBranchesHanja = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
const List<String> earthlyBranchesKorean = ['자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'];
const List<String> earthlyBranchesAnimals = ['쥐', '소', '호랑이', '토끼', '용', '뱀', '말', '양', '원숭이', '닭', '개', '돼지'];
const List<String> earthlyBranchesEmoji = ['🐭', '🐮', '🐯', '🐰', '🐲', '🐍', '🐴', '🐑', '🐵', '🐔', '🐶', '🐷'];

const Map<String, String> earthlyBranchElements = {
  '子': '수', '丑': '토', '寅': '목', '卯': '목', '辰': '토', '巳': '화',
  '午': '화', '未': '토', '申': '금', '酉': '금', '戌': '토', '亥': '수',
};

const Map<String, int> earthlyBranchHours = {
  '子': 23, '丑': 1, '寅': 3, '卯': 5, '辰': 7, '巳': 9,
  '午': 11, '未': 13, '申': 15, '酉': 17, '戌': 19, '亥': 21,
};

// 오행 (五行)
const List<String> fiveElementsHanja = ['木', '火', '土', '金', '水'];
const List<String> fiveElementsKorean = ['목', '화', '토', '금', '수'];

const Map<String, String> elementGenerates = {
  '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
};

const Map<String, String> elementOvercomes = {
  '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
};

// 십성 (十星)
const List<String> tenGodsHanja = ['比肩', '劫財', '食神', '傷官', '偏財', '正財', '偏官', '正官', '偏印', '正印'];
const List<String> tenGodsKorean = ['비견', '겁재', '식신', '상관', '편재', '정재', '편관', '정관', '편인', '정인'];

const Map<String, List<String>> tenGodsKeywords = {
  '비견': ['자아', '독립', '경쟁', '동료'],
  '겁재': ['도전', '공격성', '승부욕', '야망'],
  '식신': ['표현', '창의', '예술', '자녀'],
  '상관': ['혁신', '반항', '개혁', '재능'],
  '편재': ['사업', '투자', '모험', '유동자산'],
  '정재': ['안정', '저축', '꼼꼼함', '고정자산'],
  '편관': ['권력', '카리스마', '도전', '변화'],
  '정관': ['명예', '질서', '책임', '규율'],
  '편인': ['직관', '통찰', '의심', '독창성'],
  '정인': ['학습', '지혜', '수용', '어머니'],
};

const Map<String, String> tenGodsMbtiMapping = {
  '비견': 'E', '겁재': 'ET', '식신': 'NP', '상관': 'ENTP',
  '편재': 'ET', '정재': 'SJ', '편관': 'ENTJ', '정관': 'STJ',
  '편인': 'INT', '정인': 'ISF',
};

// 60갑자 생성
List<String> generate60Jiazi() {
  final result = <String>[];
  for (int i = 0; i < 60; i++) {
    result.add('${heavenlyStemsHanja[i % 10]}${earthlyBranchesHanja[i % 12]}');
  }
  return result;
}

final List<String> sixtyJiazi = generate60Jiazi();

// 2026년 병오년
const String year2026Pillar = '丙午';
const String year2026Element = '화';
const List<String> year2026Keywords = ['폭발적 에너지', '가시성', '급격한 변화', '열정', '주목'];

// 분석 모드
enum AnalysisMode { sajuOnly, mbtiOnly, hybrid }

const Map<AnalysisMode, String> analysisModeDescriptions = {
  AnalysisMode.sajuOnly: '생년월일시 기반 운명 분석',
  AnalysisMode.mbtiOnly: '현재 성격 유형 분석',
  AnalysisMode.hybrid: '사주 + MBTI 통합 분석 (Gap 분석 포함)',
};
