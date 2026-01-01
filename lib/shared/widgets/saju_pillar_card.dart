import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// 오행 색상 매핑
class ElementColors {
  static Color getColor(String element) {
    switch (element) {
      case '木':
      case '나무':
        return AppColors.wood;
      case '火':
      case '불':
        return AppColors.fire;
      case '土':
      case '흙':
        return AppColors.earth;
      case '金':
      case '쇠':
        return AppColors.grey400;
      case '水':
      case '물':
        return AppColors.water;
      default:
        return AppColors.grey500;
    }
  }

  static Color getTextColor(String element) {
    switch (element) {
      case '金':
      case '쇠':
        return AppColors.grey700;
      case '土':
      case '흙':
        return AppColors.grey800;
      default:
        return AppColors.white;
    }
  }
}

/// 천간/지지 개별 카드
class GanZhiCard extends StatelessWidget {
  final String character; // 한자 (癸, 乙, 庚 등)
  final String reading; // 한글 읽기 (계, 을, 경 등)
  final String element; // 오행 (水, 木, 金 등)
  final String elementKorean; // 오행 한글 (물, 나무, 쇠 등)

  const GanZhiCard({
    super.key,
    required this.character,
    required this.reading,
    required this.element,
    required this.elementKorean,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = ElementColors.getColor(element);
    final textColor = ElementColors.getTextColor(element);

    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 오행 표시 (상단)
          Text(
            '$element, $elementKorean',
            style: TextStyle(
              fontSize: 11,
              color: textColor.withAlpha((0.8 * 255).round()),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // 한자 (중앙 - 크게)
          Text(
            character,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          // 한글 읽기 (하단)
          Text(
            reading,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withAlpha((0.9 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }
}

/// 사주 기둥 (시주/일주/월주/년주) 하나를 표현
class SajuPillarCard extends StatelessWidget {
  final String pillarName; // 시주, 일주, 월주, 년주
  final String tenGodTop; // 천간 십신 (편인, 일원 등)
  final String tenGodBottom; // 지지 십신
  final String heavenlyStem; // 천간 한자
  final String heavenlyStemReading; // 천간 한글
  final String heavenlyStemElement; // 천간 오행
  final String heavenlyStemElementKr; // 천간 오행 한글
  final String earthlyBranch; // 지지 한자
  final String earthlyBranchReading; // 지지 한글
  final String earthlyBranchElement; // 지지 오행
  final String earthlyBranchElementKr; // 지지 오행 한글
  final String twelveState; // 십이운성 (양, 건록, 병 등)

  const SajuPillarCard({
    super.key,
    required this.pillarName,
    required this.tenGodTop,
    required this.tenGodBottom,
    required this.heavenlyStem,
    required this.heavenlyStemReading,
    required this.heavenlyStemElement,
    required this.heavenlyStemElementKr,
    required this.earthlyBranch,
    required this.earthlyBranchReading,
    required this.earthlyBranchElement,
    required this.earthlyBranchElementKr,
    required this.twelveState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 기둥 이름 (시주, 일주 등)
        Text(
          pillarName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        // 천간 카드
        GanZhiCard(
          character: heavenlyStem,
          reading: heavenlyStemReading,
          element: heavenlyStemElement,
          elementKorean: heavenlyStemElementKr,
        ),
        const SizedBox(height: 8),
        // 지지 카드
        GanZhiCard(
          character: earthlyBranch,
          reading: earthlyBranchReading,
          element: earthlyBranchElement,
          elementKorean: earthlyBranchElementKr,
        ),
      ],
    );
  }
}
