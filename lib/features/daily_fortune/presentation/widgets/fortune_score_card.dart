import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../domain/entities/daily_fortune.dart';

/// 종합 운세 점수 카드
class FortuneScoreCard extends StatelessWidget {
  const FortuneScoreCard({super.key, required this.fortune});

  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getGradient(fortune.overallScore),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getColor(fortune.overallScore).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '종합 운세',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${fortune.overallScore}',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              fortune.stars,
              (index) => const Icon(
                Icons.star,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getGradeText(fortune.grade),
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fortune.overallMessage,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getColor(int score) {
    if (score >= 85) return AppColors.fortuneGood;
    if (score >= 70) return AppColors.primary;
    if (score >= 55) return AppColors.earth;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Gradient _getGradient(int score) {
    final color = _getColor(score);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        color.withValues(alpha: 0.7),
      ],
    );
  }

  String _getGradeText(String grade) {
    switch (grade) {
      case 'S':
        return '최상급';
      case 'A':
        return '상급';
      case 'B':
        return '중급';
      case 'C':
        return '하급';
      case 'D':
        return '주의';
      default:
        return grade;
    }
  }
}
