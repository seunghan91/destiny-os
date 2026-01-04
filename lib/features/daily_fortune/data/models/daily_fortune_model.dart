import '../../domain/entities/daily_fortune.dart';

/// 오늘의 운세 모델
class DailyFortuneModel extends DailyFortune {
  const DailyFortuneModel({
    required super.date,
    required super.dayName,
    required super.heavenlyStem,
    required super.earthlyBranch,
    required super.overallScore,
    required super.loveScore,
    required super.wealthScore,
    required super.healthScore,
    required super.careerScore,
    required super.overallMessage,
    required super.loveMessage,
    required super.wealthMessage,
    required super.healthMessage,
    required super.careerMessage,
    required super.luckyColor,
    required super.luckyDirection,
    required super.luckyNumber,
    required super.luckyItem,
    required super.caution,
    required super.advice,
    super.loveCaution,
    super.wealthCaution,
    super.healthCaution,
    super.careerCaution,
    super.morningFortune,
    super.afternoonFortune,
    super.eveningFortune,
    super.weeklyPreview,
  });

  factory DailyFortuneModel.fromJson(Map<String, dynamic> json) {
    return DailyFortuneModel(
      date: DateTime.parse(json['date'] as String),
      dayName: json['dayName'] as String,
      heavenlyStem: json['heavenlyStem'] as String,
      earthlyBranch: json['earthlyBranch'] as String,
      overallScore: json['overallScore'] as int,
      loveScore: json['loveScore'] as int,
      wealthScore: json['wealthScore'] as int,
      healthScore: json['healthScore'] as int,
      careerScore: json['careerScore'] as int,
      overallMessage: json['overallMessage'] as String,
      loveMessage: json['loveMessage'] as String,
      wealthMessage: json['wealthMessage'] as String,
      healthMessage: json['healthMessage'] as String,
      careerMessage: json['careerMessage'] as String,
      luckyColor: json['luckyColor'] as String,
      luckyDirection: json['luckyDirection'] as String,
      luckyNumber: json['luckyNumber'] as int,
      luckyItem: json['luckyItem'] as String,
      caution: json['caution'] as String,
      advice: json['advice'] as String,
      loveCaution: json['loveCaution'] as String?,
      wealthCaution: json['wealthCaution'] as String?,
      healthCaution: json['healthCaution'] as String?,
      careerCaution: json['careerCaution'] as String?,
      morningFortune: json['morningFortune'] != null
          ? TimeFortuneModel.fromJson(
              json['morningFortune'] as Map<String, dynamic>,
            )
          : null,
      afternoonFortune: json['afternoonFortune'] != null
          ? TimeFortuneModel.fromJson(
              json['afternoonFortune'] as Map<String, dynamic>,
            )
          : null,
      eveningFortune: json['eveningFortune'] != null
          ? TimeFortuneModel.fromJson(
              json['eveningFortune'] as Map<String, dynamic>,
            )
          : null,
      weeklyPreview: json['weeklyPreview'] != null
          ? WeeklyPreviewModel.fromJson(
              json['weeklyPreview'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'dayName': dayName,
      'heavenlyStem': heavenlyStem,
      'earthlyBranch': earthlyBranch,
      'overallScore': overallScore,
      'loveScore': loveScore,
      'wealthScore': wealthScore,
      'healthScore': healthScore,
      'careerScore': careerScore,
      'overallMessage': overallMessage,
      'loveMessage': loveMessage,
      'wealthMessage': wealthMessage,
      'healthMessage': healthMessage,
      'careerMessage': careerMessage,
      'luckyColor': luckyColor,
      'luckyDirection': luckyDirection,
      'luckyNumber': luckyNumber,
      'luckyItem': luckyItem,
      'caution': caution,
      'advice': advice,
      if (loveCaution != null) 'loveCaution': loveCaution,
      if (wealthCaution != null) 'wealthCaution': wealthCaution,
      if (healthCaution != null) 'healthCaution': healthCaution,
      if (careerCaution != null) 'careerCaution': careerCaution,
      if (morningFortune != null)
        'morningFortune': (morningFortune! as TimeFortuneModel).toJson(),
      if (afternoonFortune != null)
        'afternoonFortune': (afternoonFortune! as TimeFortuneModel).toJson(),
      if (eveningFortune != null)
        'eveningFortune': (eveningFortune! as TimeFortuneModel).toJson(),
      if (weeklyPreview != null)
        'weeklyPreview': (weeklyPreview! as WeeklyPreviewModel).toJson(),
    };
  }
}

/// 시간대별 운세 모델
class TimeFortuneModel extends TimeFortune {
  const TimeFortuneModel({
    required super.timeRange,
    required super.score,
    required super.message,
    required super.recommendation,
  });

  factory TimeFortuneModel.fromJson(Map<String, dynamic> json) {
    return TimeFortuneModel(
      timeRange: json['timeRange'] as String,
      score: json['score'] as int,
      message: json['message'] as String,
      recommendation: json['recommendation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeRange': timeRange,
      'score': score,
      'message': message,
      'recommendation': recommendation,
    };
  }
}

/// 주간 운세 미리보기 모델
class WeeklyPreviewModel extends WeeklyPreview {
  const WeeklyPreviewModel({
    required super.weekRange,
    required super.dailyScores,
    required super.peakDay,
    required super.cautionDay,
    required super.weeklyTheme,
    required super.weeklyAdvice,
  });

  factory WeeklyPreviewModel.fromJson(Map<String, dynamic> json) {
    return WeeklyPreviewModel(
      weekRange: json['weekRange'] as String,
      dailyScores: Map<String, int>.from(json['dailyScores'] as Map),
      peakDay: json['peakDay'] as String,
      cautionDay: json['cautionDay'] as String,
      weeklyTheme: json['weeklyTheme'] as String,
      weeklyAdvice: json['weeklyAdvice'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekRange': weekRange,
      'dailyScores': dailyScores,
      'peakDay': peakDay,
      'cautionDay': cautionDay,
      'weeklyTheme': weeklyTheme,
      'weeklyAdvice': weeklyAdvice,
    };
  }
}
