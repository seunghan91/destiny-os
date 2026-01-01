import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../shared/widgets/saju_explanations.dart';
import '../../domain/services/analysis_text_builder.dart';
import '../../domain/entities/saju_chart.dart';
import '../bloc/destiny_bloc.dart';
import '../widgets/result_hero_card.dart';
import '../widgets/result_navigation_grid.dart';
import '../widgets/result_ai_cta.dart';

/// 사주 분석 결과 페이지 - Toss 디자인 시스템
class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? _selectedPillar;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyBloc, DestinyState>(
      builder: (context, state) {
        if (state is! DestinySuccess) {
          return _buildEmptyState(context);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 앱바
              _buildAppBar(context, state),

              // 콘텐츠
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // 히어로 카드 - 2026 운세
                      ResultHeroCard(data: state),
                      const SizedBox(height: 24),

                      // 사주팔자 상세 표시
                      _buildSajuDetailSection(state.sajuChart),
                      const SizedBox(height: 24),

                      // 2x2 네비게이션 그리드
                      ResultNavigationGrid(data: state),
                      const SizedBox(height: 24),

                      // 종합 분석 섹션
                      _buildComprehensiveAnalysis(state),
                      const SizedBox(height: 24),

                      // AI 상담 CTA
                      const ResultAiCta(),
                      const SizedBox(height: 32),

                      // 다시 분석하기
                      _buildResetButton(context),
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

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔮', style: TextStyle(fontSize: 48)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '분석 결과가 없습니다',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '생년월일과 MBTI를 입력하고\n운명을 분석해보세요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.go('/input');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      '정보 입력하기',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, DestinySuccess state) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.go('/input');
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showShareBottomSheet(context, state);
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/settings');
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          '분석 완료',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withAlpha(20),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 천간/지지 변환 맵
  static const _stemToHanja = {
    '갑': '甲', '을': '乙', '병': '丙', '정': '丁', '무': '戊',
    '기': '己', '경': '庚', '신': '辛', '임': '壬', '계': '癸',
  };
  static const _branchToHanja = {
    '자': '子', '축': '丑', '인': '寅', '묘': '卯', '진': '辰', '사': '巳',
    '오': '午', '미': '未', '신': '申', '유': '酉', '술': '戌', '해': '亥',
  };
  static const _stemToElement = {
    '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
    '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
  };

  Color _getElementColor(String stem) {
    final element = _stemToElement[stem] ?? '토';
    switch (element) {
      case '목': return AppColors.wood;
      case '화': return AppColors.fire;
      case '토': return AppColors.earth;
      case '금': return AppColors.metalAccent;
      case '수': return AppColors.water;
      default: return AppColors.primary;
    }
  }

  Widget _buildSajuDetailSection(SajuChart chart) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // 헤더
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('命', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '사주팔자',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '각 기둥을 탭하면 상세 설명을 볼 수 있어요',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4주 표시 (탭 가능)
          Row(
            children: [
              Expanded(
                child: _buildTappablePillar(
                  '년주',
                  _stemToHanja[chart.yearPillar.heavenlyStem] ?? '',
                  _branchToHanja[chart.yearPillar.earthlyBranch] ?? '',
                  _getElementColor(chart.yearPillar.heavenlyStem),
                ),
              ),
              Expanded(
                child: _buildTappablePillar(
                  '월주',
                  _stemToHanja[chart.monthPillar.heavenlyStem] ?? '',
                  _branchToHanja[chart.monthPillar.earthlyBranch] ?? '',
                  _getElementColor(chart.monthPillar.heavenlyStem),
                ),
              ),
              Expanded(
                child: _buildTappablePillar(
                  '일주',
                  _stemToHanja[chart.dayPillar.heavenlyStem] ?? '',
                  _branchToHanja[chart.dayPillar.earthlyBranch] ?? '',
                  _getElementColor(chart.dayPillar.heavenlyStem),
                  isHighlighted: true,
                ),
              ),
              Expanded(
                child: _buildTappablePillar(
                  '시주',
                  _stemToHanja[chart.hourPillar.heavenlyStem] ?? '',
                  _branchToHanja[chart.hourPillar.earthlyBranch] ?? '',
                  _getElementColor(chart.hourPillar.heavenlyStem),
                ),
              ),
            ],
          ),

          // 선택된 기둥 설명
          if (_selectedPillar != null) ...[
            const SizedBox(height: 16),
            _buildPillarExplanation(_selectedPillar!, chart),
          ],

          const SizedBox(height: 16),

          // 일간 설명
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getElementColor(chart.dayPillar.heavenlyStem).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: _getElementColor(chart.dayPillar.heavenlyStem),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getDayMasterDescription(chart.dayPillar.heavenlyStem),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTappablePillar(
    String label,
    String stem,
    String branch,
    Color color, {
    bool isHighlighted = false,
  }) {
    final isSelected = _selectedPillar == label;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedPillar = isSelected ? null : label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isSelected || isHighlighted ? color : AppColors.textTertiary,
                fontWeight: isSelected || isHighlighted ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withAlpha(40)
                    : (isHighlighted ? color.withAlpha(25) : AppColors.surfaceVariant),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: color, width: 2)
                    : (isHighlighted
                        ? Border.all(color: color.withAlpha(100), width: 1.5)
                        : null),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    stem,
                    style: AppTypography.hanja.copyWith(
                      color: color,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    branch,
                    style: AppTypography.hanja.copyWith(
                      color: color,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarExplanation(String pillarName, SajuChart chart) {
    final explanation = SajuExplanations.pillars[pillarName];
    if (explanation == null) return const SizedBox.shrink();

    // 해당 기둥의 상세 정보 가져오기
    Pillar pillar;
    String pillarMeaning;
    switch (pillarName) {
      case '년주':
        pillar = chart.yearPillar;
        pillarMeaning = '조상운, 사회적 환경, 유년기(1~15세)의 운세를 나타냅니다.';
        break;
      case '월주':
        pillar = chart.monthPillar;
        pillarMeaning = '부모운, 성장환경, 청년기(16~30세)의 운세를 나타냅니다.';
        break;
      case '일주':
        pillar = chart.dayPillar;
        pillarMeaning = '본인의 핵심 성격, 배우자운, 중년기(31~45세)의 운세를 나타냅니다.';
        break;
      case '시주':
        pillar = chart.hourPillar;
        pillarMeaning = '자녀운, 말년기(46세~)의 운세, 인생의 결실을 나타냅니다.';
        break;
      default:
        return const SizedBox.shrink();
    }

    final element = _stemToElement[pillar.heavenlyStem] ?? '토';
    final color = _getElementColor(pillar.heavenlyStem);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withAlpha(15),
            color.withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  explanation.icon,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      explanation.title,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      explanation.shortDesc,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
                onPressed: () {
                  setState(() {
                    _selectedPillar = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 상세 설명
          Text(
            pillarMeaning,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // 오행 정보
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '천간: ${pillar.heavenlyStem} ($element)',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '지지: ${pillar.earthlyBranch}',
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 종합 분석 섹션
  Widget _buildComprehensiveAnalysis(DestinySuccess state) {
    final gap = state.gapAnalysis;
    final tenGods = state.tenGods;
    final sajuComprehensive = AnalysisTextBuilder.buildSajuComprehensiveText(
      chart: state.sajuChart,
      tenGods: tenGods,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(15),
            AppColors.wood.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('📊', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '종합 분석',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '사주와 MBTI를 종합한 당신의 운명 분석',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 사주 종합 요약 (텍스트 강화)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '사주 종합 요약',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sajuComprehensive,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gap 분석 요약
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.compare_arrows, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'MBTI Gap 분석',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getGapColor(gap.gapScore).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${gap.gapScore.toInt()}% 괴리',
                        style: AppTypography.labelSmall.copyWith(
                          color: _getGapColor(gap.gapScore),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMbtiCompare('사주 추론', gap.sajuBasedMbti, AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.grey400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMbtiCompare('현재 MBTI', gap.actualMbti, AppColors.wood),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  gap.interpretation,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 십성 분포
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline, size: 18, color: AppColors.fire),
                    const SizedBox(width: 8),
                    Text(
                      '십성 분포',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '주요: ${tenGods.dominantGod}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.fire,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: () {
                    final entries = tenGods.distribution.entries
                        .where((e) => e.value > 0)
                        .toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    return entries.take(5).map((entry) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${entry.key} ${entry.value}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    )).toList();
                  }(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 숨겨진 잠재력
          if (gap.hiddenPotential.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fortuneGood.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fortuneGood.withAlpha(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, size: 18, color: AppColors.fortuneGood),
                      const SizedBox(width: 8),
                      Text(
                        '숨겨진 잠재력',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.fortuneGood,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gap.hiddenPotential,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMbtiCompare(String label, String mbti, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mbti,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGapColor(double score) {
    if (score >= 75) return AppColors.fire;
    if (score >= 50) return AppColors.warning;
    if (score >= 25) return AppColors.primary;
    return AppColors.fortuneGood;
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

  Widget _buildResetButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.read<DestinyBloc>().add(ResetDestinyData());
          context.go('/input');
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              '다시 분석하기',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context, DestinySuccess state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '분석 결과 공유하기',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.image_rounded,
                  label: '이미지로 저장',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 이미지 저장 기능
                  },
                ),
                _buildShareOption(
                  icon: Icons.copy_rounded,
                  label: '텍스트 복사',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 텍스트 복사 기능
                  },
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  label: '공유하기',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: 공유 기능
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
