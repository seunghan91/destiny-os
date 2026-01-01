import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../bloc/destiny_bloc.dart';

/// 결과 페이지 네비게이션 그리드 (2x2)
class ResultNavigationGrid extends StatelessWidget {
  final DestinySuccess data;

  const ResultNavigationGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '더 알아보기',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // 2x2 그리드
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                icon: '📊',
                title: '대운 흐름',
                subtitle: '10년 단위 운세',
                color: AppColors.water,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/daewoon');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NavigationCard(
                icon: '🔮',
                title: '궁합 분석',
                subtitle: 'MBTI vs 사주',
                color: AppColors.fire,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/compatibility');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NavigationCard(
                icon: '🧬',
                title: 'MBTI 분석',
                subtitle: data.mbtiType.type,
                color: AppColors.wood,
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showMbtiBottomSheet(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NavigationCard(
                icon: '📤',
                title: '공유하기',
                subtitle: '결과 내보내기',
                color: AppColors.metalAccent,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/share');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getMbtiTraits(String type) {
    const traits = {
      'INTJ': ['전략적', '독립적', '논리적', '비전 중심'],
      'INTP': ['분석적', '창의적', '논리적', '이론 중심'],
      'ENTJ': ['리더십', '효율적', '결단력', '목표 지향'],
      'ENTP': ['혁신적', '논쟁적', '호기심', '다재다능'],
      'INFJ': ['통찰력', '이상주의', '헌신적', '창의적'],
      'INFP': ['공감적', '창의적', '이상주의', '진정성'],
      'ENFJ': ['카리스마', '이타적', '조화', '영감 주는'],
      'ENFP': ['열정적', '창의적', '사교적', '자유로운'],
      'ISTJ': ['책임감', '신뢰할 수 있는', '철저한', '실용적'],
      'ISFJ': ['배려심', '충실한', '세심한', '조화로운'],
      'ESTJ': ['체계적', '리더십', '효율적', '전통적'],
      'ESFJ': ['사교적', '협력적', '배려심', '조직적'],
      'ISTP': ['분석적', '실용적', '적응력', '독립적'],
      'ISFP': ['예술적', '온화한', '유연한', '감성적'],
      'ESTP': ['활동적', '실용적', '적응력', '현실적'],
      'ESFP': ['사교적', '낙관적', '활발한', '즉흥적'],
    };
    return traits[type] ?? ['분석적', '창의적'];
  }

  void _showMbtiBottomSheet(BuildContext context) {
    final mbti = data.mbtiType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // MBTI 타입
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('🧬', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mbti.type,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      mbti.koreanName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 설명
            Text(
              mbti.description,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // 특성 태그
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _getMbtiTraits(mbti.type).map((trait) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  trait,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
