import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../domain/entities/daily_fortune.dart';

/// 프리미엄 기능 섹션
class PremiumFeaturesSection extends StatelessWidget {
  const PremiumFeaturesSection({super.key, required this.fortune});

  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              '프리미엄 기능',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 시간대별 운세
        if (fortune.morningFortune != null ||
            fortune.afternoonFortune != null ||
            fortune.eveningFortune != null)
          _buildTimeFortuneSection(context),

        const SizedBox(height: 16),

        // 주간 운세 미리보기
        if (fortune.weeklyPreview != null) _buildWeeklyPreview(context),
      ],
    );
  }

  Widget _buildTimeFortuneSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시간대별 운세',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          if (fortune.morningFortune != null)
            _buildTimeFortune('🌅', fortune.morningFortune!, context),
          if (fortune.afternoonFortune != null) ...[
            const SizedBox(height: 12),
            _buildTimeFortune('☀️', fortune.afternoonFortune!, context),
          ],
          if (fortune.eveningFortune != null) ...[
            const SizedBox(height: 12),
            _buildTimeFortune('🌙', fortune.eveningFortune!, context),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeFortune(
    String icon,
    TimeFortune timeFortune,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getScoreColor(timeFortune.score).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                timeFortune.timeRange,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(timeFortune.score),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${timeFortune.score}점',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeFortune.message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeFortune.recommendation,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPreview(BuildContext context) {
    final weekly = fortune.weeklyPreview!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '주간 운세 미리보기',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const Spacer(),
              Text(
                weekly.weekRange,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              weekly.weeklyTheme,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 요일별 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekly.dailyScores.entries.map((entry) {
              return _buildDayScore(
                entry.key,
                entry.value,
                entry.key == weekly.peakDay.replaceAll('요일', ''),
                context,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.borderOf(context)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHighlightDay(
                  '📈',
                  '최고의 날',
                  weekly.peakDay,
                  AppColors.fortuneGood,
                  context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHighlightDay(
                  '⚠️',
                  '주의할 날',
                  weekly.cautionDay,
                  AppColors.warning,
                  context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            weekly.weeklyAdvice,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScore(
    String day,
    int score,
    bool isPeak,
    BuildContext context,
  ) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPeak
                ? AppColors.primary
                : _getScoreColor(score).withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: isPeak
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$score',
              style: AppTypography.labelMedium.copyWith(
                color: isPeak ? Colors.white : _getScoreColor(score),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightDay(
    String icon,
    String label,
    String day,
    Color color,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
                Text(
                  day,
                  style: AppTypography.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.fortuneGood;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }
}
