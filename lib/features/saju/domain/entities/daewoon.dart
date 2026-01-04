import 'package:equatable/equatable.dart';
import 'saju_chart.dart';

/// 대운 (Daewoon) - 10년 주기의 인생 흐름
class Daewoon extends Equatable {
  final int startAge;      // 시작 나이
  final int endAge;        // 종료 나이
  final Pillar pillar;     // 대운의 간지
  final String theme;      // 이 시기의 테마
  final String description;
  final double fortuneScore;  // 운세 점수 (0~100)
  final String? caution;   // 주의사항

  const Daewoon({
    required this.startAge,
    required this.endAge,
    required this.pillar,
    required this.theme,
    required this.description,
    required this.fortuneScore,
    this.caution,
  });

  /// 현재 대운인지 확인
  bool isCurrentDaewoon(int currentAge) {
    return currentAge >= startAge && currentAge < endAge;
  }

  /// 대운 기간 문자열
  String get periodString => '$startAge세 ~ ${endAge - 1}세';

  /// 대운 테마 아이콘
  String get themeEmoji {
    switch (theme) {
      case '재물 축적기':
        return '💰';
      case '명예 추구기':
        return '🏆';
      case '학업 성취기':
        return '📚';
      case '사업 확장기':
        return '🚀';
      case '안정 유지기':
        return '🏠';
      case '도전 모험기':
        return '⚔️';
      case '인간관계 확장기':
        return '🤝';
      case '자아 성찰기':
        return '🧘';
      default:
        return '✨';
    }
  }

  @override
  List<Object?> get props => [startAge, endAge, pillar, theme, description, fortuneScore, caution];
}

/// 대운 목록 (인생 전체 대운)
class DaewoonChart extends Equatable {
  final List<Daewoon> daewoons;
  final int currentAge;

  const DaewoonChart({
    required this.daewoons,
    required this.currentAge,
  });

  /// 현재 대운
  Daewoon? get currentDaewoon {
    try {
      return daewoons.firstWhere((d) => d.isCurrentDaewoon(currentAge));
    } catch (_) {
      return null;
    }
  }

  /// 다음 대운
  Daewoon? get nextDaewoon {
    final current = currentDaewoon;
    if (current == null) return null;

    final currentIndex = daewoons.indexOf(current);
    if (currentIndex < daewoons.length - 1) {
      return daewoons[currentIndex + 1];
    }
    return null;
  }

  /// 다음 대운까지 남은 기간
  int? get yearsUntilNextDaewoon {
    final current = currentDaewoon;
    if (current == null) return null;
    return current.endAge - currentAge;
  }

  @override
  List<Object?> get props => [daewoons, currentAge];
}
