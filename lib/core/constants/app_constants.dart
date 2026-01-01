/// Destiny.OS 앱 상수
class AppConstants {
  AppConstants._();

  // === App Info ===
  static const String appName = 'Destiny.OS';
  static const String appNameKorean = '데스티니.OS';
  static const String appVersion = '1.0.0';
  static const String appDescription = '사주+MBTI 하이브리드 운세 분석';

  // === 2026년 병오년 정보 ===
  static const int targetYear = 2026;
  static const String targetYearHanja = '丙午年';
  static const String targetYearName = '병오년';
  static const String targetYearAnimal = '붉은 말의 해';
  static const String targetYearElement = '화(火)';

  // === MBTI 유형 ===
  static const List<String> mbtiTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];

  // === 십이지신 (12 Zodiac Animals) ===
  static const List<String> zodiacAnimals = [
    '쥐', '소', '호랑이', '토끼', '용', '뱀',
    '말', '양', '원숭이', '닭', '개', '돼지',
  ];

  static const List<String> zodiacAnimalsHanja = [
    '子', '丑', '寅', '卯', '辰', '巳',
    '午', '未', '申', '酉', '戌', '亥',
  ];

  // === 천간 (10 Heavenly Stems) ===
  static const List<String> heavenlyStems = [
    '갑', '을', '병', '정', '무', '기', '경', '신', '임', '계',
  ];

  static const List<String> heavenlyStemsHanja = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];

  // === 지지 (12 Earthly Branches) ===
  static const List<String> earthlyBranches = [
    '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해',
  ];

  // === 오행 (Five Elements) ===
  static const List<String> fiveElements = ['목', '화', '토', '금', '수'];
  static const List<String> fiveElementsHanja = ['木', '火', '土', '金', '水'];
  static const List<String> fiveElementsEnglish = ['Wood', 'Fire', 'Earth', 'Metal', 'Water'];

  // === 십성 (Ten Gods) ===
  static const Map<String, String> tenGods = {
    '비견': 'Friend',
    '겁재': 'Rob Wealth',
    '식신': 'Eating God',
    '상관': 'Hurting Officer',
    '편재': 'Indirect Wealth',
    '정재': 'Direct Wealth',
    '편관': 'Seven Killings',
    '정관': 'Direct Officer',
    '편인': 'Indirect Resource',
    '정인': 'Direct Resource',
  };

  // === 시주 시간 구분 ===
  static const Map<String, List<int>> hourBranches = {
    '자시': [23, 1],   // 23:00 ~ 01:00
    '축시': [1, 3],    // 01:00 ~ 03:00
    '인시': [3, 5],    // 03:00 ~ 05:00
    '묘시': [5, 7],    // 05:00 ~ 07:00
    '진시': [7, 9],    // 07:00 ~ 09:00
    '사시': [9, 11],   // 09:00 ~ 11:00
    '오시': [11, 13],  // 11:00 ~ 13:00
    '미시': [13, 15],  // 13:00 ~ 15:00
    '신시': [15, 17],  // 15:00 ~ 17:00
    '유시': [17, 19],  // 17:00 ~ 19:00
    '술시': [19, 21],  // 19:00 ~ 21:00
    '해시': [21, 23],  // 21:00 ~ 23:00
  };

  // === 대운 (Daewoon) ===
  static const int daewoonPeriodYears = 10;

  // === Storage Keys ===
  static const String keyUserBirthData = 'user_birth_data';
  static const String keyUserMbti = 'user_mbti';
  static const String keyPartnerBirthData = 'partner_birth_data';
  static const String keyPartnerMbti = 'partner_mbti';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyNightSubhourMode = 'night_subhour_mode'; // 야자시 모드

  // === Animation Durations ===
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);
}
