import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

/// 2026년 병오년 운세 상세 페이지
class Fortune2026Page extends StatelessWidget {
  const Fortune2026Page({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _buildScoreCard(),
                  const SizedBox(height: 24),

                  // 화기 적합도
                  _buildFireCompatibilityCard(),
                  const SizedBox(height: 24),

                  // 월별 운세 차트
                  _buildMonthlyChartCard(),
                  const SizedBox(height: 24),

                  // 월별 상세 리스트
                  _buildMonthlyDetailList(),
                  const SizedBox(height: 24),

                  // 주의사항
                  _buildCautionCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                '78',
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
              '🔥 불꽃 같은 성장의 해',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.fire,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '2026년은 열정과 에너지가 넘치는 해입니다. '
            '당신의 화기 적합도가 높아 좋은 기회가 많이 찾아올 것입니다.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFireCompatibilityCard() {
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
              value: 0.78,
              minHeight: 12,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.fire),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('낮음', style: AppTypography.caption),
              Text('78%', style: AppTypography.labelLarge.copyWith(color: AppColors.fire)),
              Text('높음', style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          _buildCompatibilityItem('✓', '활발한 사회 활동에 유리'),
          _buildCompatibilityItem('✓', '새로운 기회 포착 가능'),
          _buildCompatibilityItem('✓', '인지도 상승의 시기'),
          _buildCompatibilityItem('⚠', '과신은 금물'),
        ],
      ),
    );
  }

  Widget _buildCompatibilityItem(String icon, String text) {
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
                color: isWarning ? AppColors.warning : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('월별 화(火) 에너지 변동', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Text(
            '5~7월은 화기가 최고조, 11월은 자오충 주의',
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
                    spots: const [
                      FlSpot(1, 50),
                      FlSpot(2, 55),
                      FlSpot(3, 60),
                      FlSpot(4, 70),
                      FlSpot(5, 90),
                      FlSpot(6, 95),
                      FlSpot(7, 85),
                      FlSpot(8, 70),
                      FlSpot(9, 60),
                      FlSpot(10, 55),
                      FlSpot(11, 35), // 자오충
                      FlSpot(12, 50),
                    ],
                    isCurved: true,
                    color: AppColors.fire,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isClash = index == 10; // 11월
                        return FlDotCirclePainter(
                          radius: isClash ? 6 : 4,
                          color: isClash ? AppColors.error : AppColors.fire,
                          strokeWidth: 2,
                          strokeColor: AppColors.surface,
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

  Widget _buildMonthlyDetailList() {
    final months = [
      _MonthData(1, '새로운 시작', 65, '차분하게 계획을 세우는 시기'),
      _MonthData(2, '준비와 계획', 68, '기반을 다지는 시기'),
      _MonthData(3, '성장의 싹', 72, '새싹이 트는 것처럼 성장의 기운'),
      _MonthData(4, '활발한 교류', 78, '인간관계가 활발해지는 시기'),
      _MonthData(5, '열정의 시작', 88, '화기가 강해지기 시작'),
      _MonthData(6, '최고의 에너지', 95, '가장 좋은 운세, 적극적 행동 추천'),
      _MonthData(7, '결실 준비', 85, '성과가 나타나기 시작'),
      _MonthData(8, '성과 수확', 75, '노력의 결과물 수확'),
      _MonthData(9, '정리의 시간', 68, '마무리와 정리'),
      _MonthData(10, '마무리', 60, '한 해를 돌아보는 시기'),
      _MonthData(11, '⚠️ 자오충 주의', 40, '중요한 결정 미루고 신중하게', isWarning: true),
      _MonthData(12, '휴식과 성찰', 55, '다음 해를 준비하는 시기'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('월별 상세 운세', style: AppTypography.titleMedium),
        const SizedBox(height: 16),
        ...months.map((m) => _buildMonthItem(m)),
      ],
    );
  }

  Widget _buildMonthItem(_MonthData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: data.isWarning ? AppColors.errorLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: data.isWarning ? AppColors.error.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.isWarning
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.fire.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${data.month}월',
                style: AppTypography.labelLarge.copyWith(
                  color: data.isWarning ? AppColors.error : AppColors.fire,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.theme, style: AppTypography.titleSmall),
                const SizedBox(height: 4),
                Text(
                  data.advice,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getScoreColor(data.score).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${data.score}점',
              style: AppTypography.labelMedium.copyWith(
                color: _getScoreColor(data.score),
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

  Widget _buildCautionCard() {
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
          _buildCautionItem('11월 자오충(子午沖)', '대인관계 갈등 주의, 중요 결정 미루기'),
          _buildCautionItem('화기 과다 주의', '번아웃, 건강 관리 필수'),
          _buildCautionItem('과신 경계', '좋은 흐름에 취해 무리하지 않기'),
        ],
      ),
    );
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

class _MonthData {
  final int month;
  final String theme;
  final int score;
  final String advice;
  final bool isWarning;

  const _MonthData(
    this.month,
    this.theme,
    this.score,
    this.advice, {
    this.isWarning = false,
  });
}
