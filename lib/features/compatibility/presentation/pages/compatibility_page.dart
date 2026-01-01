import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/domain/entities/saju_chart.dart';

/// 궁합 분석 페이지
/// 두 사람의 사주를 비교하여 궁합을 분석
class CompatibilityPage extends StatefulWidget {
  final SajuChart? mySajuChart;
  final SajuChart? partnerSajuChart;

  const CompatibilityPage({
    super.key,
    this.mySajuChart,
    this.partnerSajuChart,
  });

  @override
  State<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  // 데모 데이터
  late _CompatibilityResult _compatibilityResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _initializeDemoData();
  }

  void _initializeDemoData() {
    // 데모 궁합 결과 생성
    _compatibilityResult = _CompatibilityResult(
      overallScore: 78,
      loveScore: 85,
      marriageScore: 72,
      businessScore: 68,
      friendshipScore: 82,
      myName: '나',
      partnerName: '상대방',
      mySaju: _DemoSaju(
        pillar: '甲子 丙寅 戊午 庚申',
        dayMaster: '무토(戊土)',
        element: '토',
      ),
      partnerSaju: _DemoSaju(
        pillar: '乙丑 丁卯 己未 辛酉',
        dayMaster: '기토(己土)',
        element: '토',
      ),
      analysis: _CompatibilityAnalysis(
        summary: '두 분은 같은 토(土) 오행의 일간을 가지고 있어 서로를 깊이 이해할 수 있는 관계입니다. '
            '비겁(比劫) 관계로 동료 의식이 강하며, 함께 목표를 향해 나아갈 수 있습니다.',
        strengths: [
          '서로의 가치관이 비슷하여 이해가 빠름',
          '안정적이고 신뢰할 수 있는 관계 형성',
          '함께 성장하고 발전할 수 있는 파트너십',
          '갈등 시에도 쉽게 화해할 수 있는 유대감',
        ],
        challenges: [
          '비슷한 성향으로 인한 권력 다툼 가능성',
          '새로운 자극이 부족할 수 있음',
          '서로의 영역을 존중해야 함',
        ],
        advice: [
          '각자의 영역과 역할을 명확히 하세요',
          '새로운 경험을 함께 시도하여 관계에 활력을 불어넣으세요',
          '의견 충돌 시 제3자의 조언을 구하는 것도 좋습니다',
        ],
      ),
      elementCompatibility: [
        _ElementCompatibility('목', 40, '보통', '갈등 요소'),
        _ElementCompatibility('화', 75, '좋음', '에너지 공급'),
        _ElementCompatibility('토', 90, '최고', '핵심 공감대'),
        _ElementCompatibility('금', 60, '보통', '상호 지원'),
        _ElementCompatibility('수', 55, '보통', '균형 필요'),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('궁합 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: 공유 기능
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildScoreOverview(),
                  _buildSajuComparison(),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '종합 분석'),
                    Tab(text: '오행 궁합'),
                    Tab(text: '조언'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverallAnalysisTab(),
            _buildElementCompatibilityTab(),
            _buildAdviceTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(_compatibilityResult.overallScore),
            _getScoreColor(_compatibilityResult.overallScore).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(_compatibilityResult.overallScore).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '종합 궁합',
            style: AppTypography.labelLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_compatibilityResult.overallScore}',
                style: AppTypography.fortuneScore.copyWith(
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '점',
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getScoreGrade(_compatibilityResult.overallScore),
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // 세부 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniScore('연애', _compatibilityResult.loveScore, Icons.favorite),
              _buildMiniScore('결혼', _compatibilityResult.marriageScore, Icons.home),
              _buildMiniScore('사업', _compatibilityResult.businessScore, Icons.work),
              _buildMiniScore('우정', _compatibilityResult.friendshipScore, Icons.people),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScore(String label, int score, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          '$score',
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSajuComparison() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
      child: Row(
        children: [
          // 나의 사주
          Expanded(
            child: _buildSajuCard(
              name: _compatibilityResult.myName,
              saju: _compatibilityResult.mySaju,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          // VS 아이콘
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              'VS',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 상대방 사주
          Expanded(
            child: _buildSajuCard(
              name: _compatibilityResult.partnerName,
              saju: _compatibilityResult.partnerSaju,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSajuCard({
    required String name,
    required _DemoSaju saju,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          name,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.getElementColor(saju.element).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            saju.dayMaster,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.getElementColor(saju.element),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          saju.pillar,
          style: AppTypography.bodySmall.copyWith(
            fontFamily: 'serif',
          ),
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.end
              : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildOverallAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약
          Text(_compatibilityResult.analysis.summary,
            style: AppTypography.bodyMedium.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),

          // 장점
          _buildAnalysisSection(
            title: '두 분의 장점',
            icon: Icons.thumb_up,
            color: AppColors.fortuneGood,
            items: _compatibilityResult.analysis.strengths,
          ),
          const SizedBox(height: 20),

          // 주의점
          _buildAnalysisSection(
            title: '주의할 점',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            items: _compatibilityResult.analysis.challenges,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTypography.bodyMedium),
                Expanded(
                  child: Text(item, style: AppTypography.bodyMedium),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildElementCompatibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오행 궁합 분석',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '두 분의 사주에서 각 오행이 어떻게 조화를 이루는지 분석합니다.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 24),

          // 오행별 궁합 바
          ..._compatibilityResult.elementCompatibility.map((ec) {
            return _buildElementBar(ec);
          }),

          const SizedBox(height: 32),

          // 오행 순환 다이어그램
          _buildElementCycleInfo(),
        ],
      ),
    );
  }

  Widget _buildElementBar(_ElementCompatibility ec) {
    final elementColor = AppColors.getElementColor(ec.element);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: elementColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getElementHanja(ec.element),
                        style: AppTypography.titleMedium.copyWith(
                          color: elementColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ec.element}(${_getElementHanja(ec.element)})',
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        ec.description,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getScoreColor(ec.score).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${ec.score}점',
                  style: AppTypography.labelSmall.copyWith(
                    color: _getScoreColor(ec.score),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ec.score / 100,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(elementColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementCycleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '오행 상생상극 관계',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCycleRow('상생', '목→화→토→금→수→목', AppColors.fortuneGood),
          const SizedBox(height: 8),
          _buildCycleRow('상극', '목→토, 토→수, 수→화, 화→금, 금→목', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildCycleRow(String label, String cycle, Color color) {
    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            cycle,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관계 발전을 위한 조언',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 24),

          ...List.generate(_compatibilityResult.analysis.advice.length, (index) {
            return _buildAdviceCard(
              number: index + 1,
              advice: _compatibilityResult.analysis.advice[index],
            );
          }),

          const SizedBox(height: 32),

          // CTA 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.destinyGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  'AI 상담으로 더 자세한 분석을',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '두 분의 궁합에 대해 AI에게 질문해보세요',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // TODO: AI 상담 페이지로 이동
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('AI 상담 시작'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard({required int number, required String advice}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advice,
              style: AppTypography.bodyMedium.copyWith(height: 1.5),
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
    return AppColors.fortuneBad;
  }

  String _getScoreGrade(int score) {
    if (score >= 90) return '천생연분';
    if (score >= 80) return '아주 좋은 궁합';
    if (score >= 70) return '좋은 궁합';
    if (score >= 60) return '보통 궁합';
    if (score >= 50) return '노력이 필요한 궁합';
    return '어려운 궁합';
  }

  String _getElementHanja(String element) {
    const mapping = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return mapping[element] ?? element;
  }
}

// 데모용 데이터 클래스들
class _CompatibilityResult {
  final int overallScore;
  final int loveScore;
  final int marriageScore;
  final int businessScore;
  final int friendshipScore;
  final String myName;
  final String partnerName;
  final _DemoSaju mySaju;
  final _DemoSaju partnerSaju;
  final _CompatibilityAnalysis analysis;
  final List<_ElementCompatibility> elementCompatibility;

  _CompatibilityResult({
    required this.overallScore,
    required this.loveScore,
    required this.marriageScore,
    required this.businessScore,
    required this.friendshipScore,
    required this.myName,
    required this.partnerName,
    required this.mySaju,
    required this.partnerSaju,
    required this.analysis,
    required this.elementCompatibility,
  });
}

class _DemoSaju {
  final String pillar;
  final String dayMaster;
  final String element;

  _DemoSaju({
    required this.pillar,
    required this.dayMaster,
    required this.element,
  });
}

class _CompatibilityAnalysis {
  final String summary;
  final List<String> strengths;
  final List<String> challenges;
  final List<String> advice;

  _CompatibilityAnalysis({
    required this.summary,
    required this.strengths,
    required this.challenges,
    required this.advice,
  });
}

class _ElementCompatibility {
  final String element;
  final int score;
  final String grade;
  final String description;

  _ElementCompatibility(this.element, this.score, this.grade, this.description);
}

// SliverPersistentHeader delegate for TabBar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
