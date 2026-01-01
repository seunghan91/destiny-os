import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../domain/entities/fortune_2026.dart';

/// 2026년 병오년 운세 상세 페이지
class Fortune2026Page extends StatelessWidget {
  const Fortune2026Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyBloc, DestinyState>(
      builder: (context, state) {
        if (state is! DestinySuccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('2026 병오년')),
            body: const Center(
              child: Text('분석 데이터가 없습니다.\n먼저 사주 분석을 진행해주세요.'),
            ),
          );
        }

        final fortune = state.fortune2026;
        final score = fortune.overallScore.round();
        final fireScore = fortune.fireCompatibility.compatibilityScore.round();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // 헤더
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.fire,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.fire, Color(0xFFE55555)],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          const Text('🐴', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            '2026 병오년',
                            style: AppTypography.headlineLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '붉은 말의 해',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 콘텐츠
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 운세 점수 카드
                      _buildScoreCard(context, fortune, score),
                      const SizedBox(height: 24),

                      // 화기 적합도
                      _buildFireCompatibilityCard(context, fortune, fireScore),
                      const SizedBox(height: 24),

                      // 월별 운세 차트
                      _buildMonthlyChartCard(context, fortune),
                      const SizedBox(height: 24),

                      // 월별 상세 리스트
                      _buildMonthlyDetailList(context, fortune),
                      const SizedBox(height: 24),

                      // 주의사항
                      _buildCautionCard(fortune),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(BuildContext context, Fortune2026 fortune, int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(context, lightOpacity: 0.05, darkOpacity: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: AppTypography.fortuneScore.copyWith(
                  color: AppColors.fire,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '점',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.fire,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.fireLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🔥 ${fortune.yearTheme}',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.fire,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fortune.yearAdvice,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFireCompatibilityCard(BuildContext context, Fortune2026 fortune, int fireScore) {
    final fireCompatibility = fortune.fireCompatibility;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.fire.withValues(alpha: 0.1),
            AppColors.earth.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.whatshot, color: AppColors.fire),
              const SizedBox(width: 8),
              Text('화기(火氣) 적합도', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          // 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fireScore / 100,
              minHeight: 12,
              backgroundColor: AppColors.borderOf(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.fire),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('낮음', style: AppTypography.caption),
              Text('$fireScore%', style: AppTypography.labelLarge.copyWith(color: AppColors.fire)),
              Text('높음', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          // 유리한 점
          ...fireCompatibility.advantages.map(
            (item) => _buildCompatibilityItem(context, '✓', item),
          ),
          // 주의할 점
          ...fireCompatibility.cautions.map(
            (item) => _buildCompatibilityItem(context, '⚠', item),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityItem(BuildContext context, String icon, String text) {
    final isWarning = icon == '⚠';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: isWarning ? AppColors.warning : AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChartCard(BuildContext context, Fortune2026 fortune) {
    // 월별 데이터에서 차트 스팟 생성
    final spots = fortune.monthlyFortunes.map((m) {
      return FlSpot(m.month.toDouble(), m.fireEnergy);
    }).toList();

    // 가장 좋은 달 찾기
    final bestMonth = fortune.bestMonth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 화(火) 에너지 변동', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            '${bestMonth?.month ?? 6}~${(bestMonth?.month ?? 6) + 1}월은 화기가 최고조${fortune.hasNovemberClash ? ', 11월은 자오충 주의' : ''}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 == 1 && value >= 1 && value <= 12) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt()}월',
                              style: AppTypography.caption,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.fire,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final monthData = fortune.monthlyFortunes[index];
                        final isClash = monthData.hasClash;
                        return FlDotCirclePainter(
                          radius: isClash ? 6 : 4,
                          color: isClash ? AppColors.error : AppColors.fire,
                          strokeWidth: 2,
                          strokeColor: AppColors.surfaceOf(context),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.fire.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.fire, '화(火) 에너지'),
              const SizedBox(width: 20),
              if (fortune.hasNovemberClash)
                _buildLegendItem(AppColors.error, '충(沖) 주의'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildMonthlyDetailList(BuildContext context, Fortune2026 fortune) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('월별 상세 운세', style: AppTypography.titleMedium),
        const SizedBox(height: 16),
        ...fortune.monthlyFortunes.map((m) => _buildMonthItem(context, m)),
      ],
    );
  }

  Widget _buildMonthItem(BuildContext context, MonthlyFortune data) {
    final isWarning = data.hasClash;
    final displayTheme = isWarning ? '⚠️ ${data.theme}' : data.theme;
    final scoreInt = data.score.round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? (AppColors.isDarkMode(context)
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.errorLight)
            : AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.borderOf(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isWarning
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.fire.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${data.month}월',
                style: AppTypography.labelLarge.copyWith(
                  color: isWarning ? AppColors.error : AppColors.fire,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayTheme, style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  data.advice,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(scoreInt).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$scoreInt점',
              style: AppTypography.labelMedium.copyWith(
                color: _getScoreColor(scoreInt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildCautionCard(Fortune2026 fortune) {
    final cautions = fortune.fireCompatibility.cautions;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                '2026년 주의사항',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (fortune.hasNovemberClash)
            _buildCautionItem('11월 자오충(子午沖)', '대인관계 갈등 주의, 중요 결정 미루기'),
          ...cautions.map((c) => _buildCautionItem(c, _getCautionDescription(c))),
        ],
      ),
    );
  }

  String _getCautionDescription(String caution) {
    // 주의사항에 따른 상세 설명 매핑
    if (caution.contains('과신')) return '좋은 흐름에 취해 무리하지 않기';
    if (caution.contains('건강')) return '번아웃, 건강 관리 필수';
    if (caution.contains('성급')) return '충분히 고려한 후 결정하기';
    if (caution.contains('갈등')) return '대인관계에서 언행 삼가기';
    if (caution.contains('스트레스')) return '충분한 휴식과 여유 갖기';
    return caution;
  }

  Widget _buildCautionItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
