import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: 100.ms)
            .slideX(begin: -0.1, end: 0, duration: 300.ms),
        const SizedBox(height: 16),

        // 2x2 그리드
        Row(
          children: [
            Expanded(
              child:
                  _NavigationCard(
                        icon: '📊',
                        title: '대운 흐름',
                        subtitle: '10년 단위 운세',
                        color: AppColors.water,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/daewoon');
                        },
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _NavigationCard(
                        icon: '🔮',
                        title: '궁합 분석',
                        subtitle: 'MBTI vs 사주',
                        color: AppColors.fire,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/compatibility');
                        },
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                      ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child:
                  _NavigationCard(
                        icon: '☯️',
                        title: 'MBTI+사주 분석',
                        subtitle: '타고난 기질과 성향',
                        color: AppColors.wood,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showMbtiSajuBottomSheet(context);
                        },
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                      ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _NavigationCard(
                        icon: '📤',
                        title: '공유하기',
                        subtitle: '결과 내보내기',
                        color: AppColors.metalAccent,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/share');
                        },
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                      ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMbtiSajuBottomSheet(BuildContext context) {
    final mbti = data.mbtiType;
    final gap = data.gapAnalysis;
    final fortune = data.fortune2026;
    final bestMonth = fortune.bestMonth;
    final worstMonth = fortune.worstMonth;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
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

              // 제목 및 타입 표시
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
                      child: Text('☯️', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MBTI+사주 융합 분석',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                        Text(
                          '${mbti.type} (${mbti.koreanName})',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 분석 리포트 섹션
              _buildSectionTitle(context, '타고난 성향 vs 현재의 나'),
              _buildAnalysisCard(
                context,
                title: '기질 분석',
                content: gap.interpretation,
                icon: '🧬',
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                title: '2026년 잠재력',
                content: gap.hiddenPotential,
                icon: '🔥',
              ),
              const SizedBox(height: 24),

              _buildSectionTitle(context, '2026년 흐름 요약'),
              _buildAnalysisCard(
                context,
                title: fortune.yearTheme,
                content: fortune.narrative.overall,
                icon: '🐴',
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                title: '화(火) 기운 적합도',
                content: fortune.fireCompatibility.summaryMessage,
                icon: '🔥',
              ),
              const SizedBox(height: 12),
              _buildAnalysisCard(
                context,
                title: '좋은 달/주의 달',
                content:
                    '${bestMonth != null ? '좋은 달: ${bestMonth.monthName} (${bestMonth.theme})' : '좋은 달: -'}\n'
                    '${worstMonth != null ? '주의 달: ${worstMonth.monthName} (${worstMonth.theme})' : '주의 달: -'}\n'
                    '${fortune.hasNovemberClash ? '특히 11월은 충(沖) 흐름으로 대인관계/계약/큰 결정을 더 신중히.' : '11월 충(沖) 경고는 크지 않습니다.'}',
                icon: '📅',
              ),
              const SizedBox(height: 24),

              // 2026년 조언 리스트
              _buildSectionTitle(context, '2026년 핵심 조언'),
              ...gap.recommendations
                  .map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              rec,
                              style: AppTypography.bodyMedium.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              const SizedBox(height: 32),

              // 상담하기 버튼
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF8E44AD)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/consultation');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '이어서 상담하기',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'AI 상담 5회권 (5,000원)',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryOf(context),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    BuildContext context, {
    required String title,
    required String content,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.5,
            ),
          ),
        ],
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
          color: AppColors.surfaceOf(context),
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
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
