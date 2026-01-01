import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../domain/entities/saju_chart.dart';
import '../bloc/destiny_bloc.dart';

/// 사주 분석 결과 페이지
class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyBloc, DestinyState>(
      builder: (context, state) {
        if (state is! DestinySuccess) {
          // 데이터가 없으면 입력 페이지로 이동
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('분석 데이터가 없습니다'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/input'),
                    child: const Text('정보 입력하기'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('분석 결과'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: 공유 기능
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 사주팔자 카드
                _buildSajuCard(data.sajuChart),
                const SizedBox(height: 24),

                // 십성 분포 카드
                _buildTenGodsCard(data),
                const SizedBox(height: 24),

                // MBTI Gap 분석
                _buildGapAnalysisCard(data),
                const SizedBox(height: 24),

                // 2026 운세 미리보기
                _buildFortunePreview(context, data),
                const SizedBox(height: 24),

                // 대운 타임라인 미리보기
                _buildDaewoonPreview(context, data),
                const SizedBox(height: 24),

                // 궁합 분석 버튼
                _buildCompatibilityButton(context),
                const SizedBox(height: 24),

                // AI 상담 버튼
                _buildAiConsultationButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSajuCard(SajuChart chart) {
    // 천간/지지를 한자로 변환
    final stemToHanja = {
      '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
      '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
    };
    final branchToHanja = {
      '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
      '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
    };

    // 오행 색상 매핑
    Color getElementColor(String stem) {
      const stemToElement = {
        '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
        '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
      };
      final element = stemToElement[stem] ?? '토';
      switch (element) {
        case '목': return AppColors.wood;
        case '화': return AppColors.fire;
        case '토': return AppColors.earth;
        case '금': return AppColors.metalAccent;
        case '수': return AppColors.water;
        default: return AppColors.primary;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('사주팔자', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),

          // 4주 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPillar(
                '년주',
                stemToHanja[chart.yearPillar.heavenlyStem] ?? chart.yearPillar.heavenlyStem,
                branchToHanja[chart.yearPillar.earthlyBranch] ?? chart.yearPillar.earthlyBranch,
                getElementColor(chart.yearPillar.heavenlyStem),
              ),
              _buildPillar(
                '월주',
                stemToHanja[chart.monthPillar.heavenlyStem] ?? chart.monthPillar.heavenlyStem,
                branchToHanja[chart.monthPillar.earthlyBranch] ?? chart.monthPillar.earthlyBranch,
                getElementColor(chart.monthPillar.heavenlyStem),
              ),
              _buildPillar(
                '일주',
                stemToHanja[chart.dayPillar.heavenlyStem] ?? chart.dayPillar.heavenlyStem,
                branchToHanja[chart.dayPillar.earthlyBranch] ?? chart.dayPillar.earthlyBranch,
                getElementColor(chart.dayPillar.heavenlyStem),
              ),
              _buildPillar(
                '시주',
                stemToHanja[chart.hourPillar.heavenlyStem] ?? chart.hourPillar.heavenlyStem,
                branchToHanja[chart.hourPillar.earthlyBranch] ?? chart.hourPillar.earthlyBranch,
                getElementColor(chart.hourPillar.heavenlyStem),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // 일간 설명
          Text(
            '일간: ${stemToHanja[chart.dayPillar.heavenlyStem]}${_getElementName(chart.dayPillar.heavenlyStem)}',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            _getDayMasterDescription(chart.dayPillar.heavenlyStem),
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getElementName(String stem) {
    const mapping = {
      '갑': '木 (양목)', '을': '木 (음목)',
      '병': '火 (양화)', '정': '火 (음화)',
      '무': '土 (양토)', '기': '土 (음토)',
      '경': '金 (양금)', '신': '金 (음금)',
      '임': '水 (양수)', '계': '水 (음수)',
    };
    return mapping[stem] ?? '';
  }

  String _getDayMasterDescription(String stem) {
    const descriptions = {
      '갑': '큰 나무처럼 곧고 정직합니다. 리더십이 강하고 성장을 추구합니다.',
      '을': '풀과 덩굴처럼 유연합니다. 적응력이 뛰어나고 섬세합니다.',
      '병': '태양처럼 밝고 따뜻합니다. 열정적이고 사람들의 주목을 받습니다.',
      '정': '촛불처럼 은은합니다. 섬세하고 배려심이 깊습니다.',
      '무': '산처럼 듬직합니다. 안정적이고 신뢰감을 줍니다.',
      '기': '논밭처럼 포용력이 있습니다. 실용적이고 중재자 역할에 능합니다.',
      '경': '강철처럼 단단합니다. 결단력이 있고 원칙을 중시합니다.',
      '신': '보석처럼 섬세합니다. 완벽주의적이고 예리합니다.',
      '임': '바다처럼 깊습니다. 지혜롭고 포용력이 큽니다.',
      '계': '비처럼 스며듭니다. 감수성이 풍부하고 적응력이 뛰어납니다.',
    };
    return descriptions[stem] ?? '안정적이고 신뢰감 있는 성격입니다.';
  }

  Widget _buildPillar(String label, String stem, String branch, Color color) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(stem, style: AppTypography.hanja.copyWith(color: color)),
              const SizedBox(height: 4),
              Text(branch, style: AppTypography.hanja.copyWith(color: color)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTenGodsCard(DestinySuccess data) {
    final distribution = data.tenGods.distribution;
    final sortedGods = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('십성 분포', style: AppTypography.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedGods.where((e) => e.value > 0).map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${entry.key} ${entry.value}',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '주요 십성: ${data.tenGods.dominantGod}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGapAnalysisCard(DestinySuccess data) {
    final gap = data.gapAnalysis;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.wood.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Gap 분석', style: AppTypography.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),

          // Gap 점수
          Row(
            children: [
              Text(
                '${gap.gapScore.toInt()}',
                style: AppTypography.numberLarge,
              ),
              Text(
                '%',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('사주 추론: ${gap.sajuBasedMbti}', style: AppTypography.labelMedium),
                    Text('현재 MBTI: ${gap.actualMbti}', style: AppTypography.labelMedium),
                  ],
                ),
              ),
            ],
          ),

          // 차원별 일치/불일치 표시
          if (gap.dimensionGaps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: gap.dimensionGaps.map((d) {
                final isMatch = !d.hasGap;
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMatch
                            ? AppColors.wood.withValues(alpha: 0.2)
                            : AppColors.fire.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.dimension,
                        style: AppTypography.labelSmall.copyWith(
                          color: isMatch ? AppColors.wood : AppColors.fire,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      isMatch ? Icons.check_circle : Icons.swap_horiz,
                      size: 16,
                      color: isMatch ? AppColors.wood : AppColors.fire,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            gap.interpretation,
            style: AppTypography.bodyMedium,
          ),
          if (gap.hasSignificantGap) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      gap.hiddenPotential,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 맞춤형 조언
          if (gap.recommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...gap.recommendations.take(2).map((rec) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildFortunePreview(BuildContext context, DestinySuccess data) {
    final fortune = data.fortune2026;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fireLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐴', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('2026 병오년 운세', style: AppTypography.headlineSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.fire,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${fortune.overallScore.toInt()}점',
                  style: AppTypography.labelMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fortune.yearTheme,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.fire,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fortune.yearAdvice,
            style: AppTypography.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/fortune'),
            child: const Text('자세히 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDaewoonPreview(BuildContext context, DestinySuccess data) {
    final daewoon = data.daewoonChart;
    final currentDaewoon = daewoon.currentDaewoon;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('대운 타임라인', style: AppTypography.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          if (currentDaewoon != null) ...[
            Text(
              '현재 대운 (${currentDaewoon.startAge}~${currentDaewoon.endAge}세)',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '${currentDaewoon.pillar.heavenlyStem}${currentDaewoon.pillar.earthlyBranch}',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDaewoon.theme,
                          style: AppTypography.titleSmall,
                        ),
                        Text(
                          currentDaewoon.description,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/daewoon'),
            child: const Text('전체 대운 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💕', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('궁합 분석', style: AppTypography.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '연인, 친구, 비즈니스 파트너와의 궁합을 사주로 분석해보세요.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.go('/compatibility'),
            child: const Text('궁합 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiConsultationButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            'AI에게 질문하기',
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '1회 무료 상담',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: AI 상담 페이지로 이동
                context.go('/consultation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              child: const Text('상담 시작'),
            ),
          ),
        ],
      ),
    );
  }
}
