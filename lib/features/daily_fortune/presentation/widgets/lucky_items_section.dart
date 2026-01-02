import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../domain/entities/daily_fortune.dart';

/// 행운 아이템 섹션
class LuckyItemsSection extends StatelessWidget {
  const LuckyItemsSection({super.key, required this.fortune});

  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '오늘의 행운',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLuckyItem(
                  icon: '🎨',
                  label: '색상',
                  value: fortune.luckyColor,
                  context: context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLuckyItem(
                  icon: '🧭',
                  label: '방향',
                  value: fortune.luckyDirection,
                  context: context,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLuckyItem(
                  icon: '🔢',
                  label: '숫자',
                  value: '${fortune.luckyNumber}',
                  context: context,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLuckyItem(
                  icon: '💎',
                  label: '아이템',
                  value: fortune.luckyItem,
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLuckyItem({
    required String icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
