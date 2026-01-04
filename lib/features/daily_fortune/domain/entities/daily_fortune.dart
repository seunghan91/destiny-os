/// 오늘의 운세 엔티티
class DailyFortune {
  const DailyFortune({
    required this.date,
    required this.dayName,
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.overallScore,
    required this.loveScore,
    required this.wealthScore,
    required this.healthScore,
    required this.careerScore,
    required this.overallMessage,
    required this.loveMessage,
    required this.wealthMessage,
    required this.healthMessage,
    required this.careerMessage,
    required this.luckyColor,
    required this.luckyDirection,
    required this.luckyNumber,
    required this.luckyItem,
    required this.caution,
    required this.advice,
    this.loveCaution,
    this.wealthCaution,
    this.healthCaution,
    this.careerCaution,
    this.morningFortune,
    this.afternoonFortune,
    this.eveningFortune,
    this.weeklyPreview,
  });

  final DateTime date;
  final String dayName; // 예: "갑자일", "을축일"
  final String heavenlyStem; // 천간
  final String earthlyBranch; // 지지

  // 운세 점수 (0-100)
  final int overallScore;
  final int loveScore;
  final int wealthScore;
  final int healthScore;
  final int careerScore;

  // 운세 설명
  final String overallMessage;
  final String loveMessage;
  final String wealthMessage;
  final String healthMessage;
  final String careerMessage;

  // 행운 아이템
  final String luckyColor; // 행운의 색상
  final String luckyDirection; // 행운의 방향
  final int luckyNumber; // 행운의 숫자
  final String luckyItem; // 행운의 아이템

  // 주의사항
  final String caution;

  // 한마디 조언
  final String advice;

  // 카테고리별 주의사항
  final String? loveCaution;
  final String? wealthCaution;
  final String? healthCaution;
  final String? careerCaution;

  // 프리미엄 기능
  final TimeFortune? morningFortune; // 오전 운세
  final TimeFortune? afternoonFortune; // 오후 운세
  final TimeFortune? eveningFortune; // 저녁 운세
  final WeeklyPreview? weeklyPreview; // 주간 운세 미리보기

  /// 평균 점수 계산
  double get averageScore =>
      (loveScore + wealthScore + healthScore + careerScore) / 4;

  /// 운세 등급 (S, A, B, C, D)
  String get grade {
    if (overallScore >= 90) return 'S';
    if (overallScore >= 80) return 'A';
    if (overallScore >= 70) return 'B';
    if (overallScore >= 60) return 'C';
    return 'D';
  }

  /// 별 개수 (5점 만점)
  int get stars {
    if (overallScore >= 90) return 5;
    if (overallScore >= 75) return 4;
    if (overallScore >= 60) return 3;
    if (overallScore >= 45) return 2;
    return 1;
  }
}

/// 시간대별 운세 (프리미엄)
class TimeFortune {
  const TimeFortune({
    required this.timeRange,
    required this.score,
    required this.message,
    required this.recommendation,
  });

  final String timeRange; // "06:00-12:00"
  final int score;
  final String message;
  final String recommendation; // 추천 활동
}

/// 주간 운세 미리보기 (프리미엄)
class WeeklyPreview {
  const WeeklyPreview({
    required this.weekRange,
    required this.dailyScores,
    required this.peakDay,
    required this.cautionDay,
    required this.weeklyTheme,
    required this.weeklyAdvice,
  });

  final String weekRange; // "1/6 - 1/12"
  final Map<String, int> dailyScores; // {월: 85, 화: 78, ...}
  final String peakDay; // "수요일"
  final String cautionDay; // "금요일"
  final String weeklyTheme; // "도약의 한 주"
  final String weeklyAdvice;
}
