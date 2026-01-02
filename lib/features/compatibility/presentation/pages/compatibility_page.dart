import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/data/services/saju_calculator.dart'
    hide CompatibilityResult;
import '../../../saju/domain/entities/saju_chart.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../../saju/presentation/widgets/siju_picker.dart';
import '../../data/services/compatibility_calculator.dart';

/// 궁합 분석 페이지
/// 두 사람의 사주를 비교하여 궁합을 분석
class CompatibilityPage extends StatefulWidget {
  final SajuChart? mySajuChart;
  final SajuChart? partnerSajuChart;

  const CompatibilityPage({super.key, this.mySajuChart, this.partnerSajuChart});

  @override
  State<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends State<CompatibilityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 내 사주 정보 (BLoC에서 가져옴)
  SajuChart? _mySajuChart;
  final String _myName = '나';

  // 상대방 입력 데이터
  final TextEditingController _partnerNameController = TextEditingController();
  DateTime? _partnerBirthDate;
  int? _partnerSijuIndex;
  Siju? _partnerSiju;
  String _partnerGender = 'female';
  bool _partnerIsLunar = false;
  bool _isPartnerInputMode = true;
  bool _hasAnalyzed = false;
  bool _isAnalyzing = false;

  // 실제 궁합 분석 결과
  CompatibilityResult? _compatibilityResult;
  SajuChart? _partnerSajuChart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _partnerNameController.text = '';

    // BLoC에서 내 사주 정보 가져오기
    _loadMySajuFromBloc();

    // 상대방 데이터가 있으면 바로 결과 표시
    if (widget.partnerSajuChart != null && widget.mySajuChart != null) {
      _isPartnerInputMode = false;
      _hasAnalyzed = true;
      _partnerSajuChart = widget.partnerSajuChart;
      _mySajuChart = widget.mySajuChart;
      _calculateCompatibility();
    }
  }

  void _loadMySajuFromBloc() {
    try {
      final bloc = context.read<DestinyBloc>();
      final state = bloc.state;
      if (state is DestinySuccess) {
        _mySajuChart = state.sajuChart;
      }
    } catch (_) {
      // BLoC이 없으면 위젯에서 전달된 데이터 사용
      _mySajuChart = widget.mySajuChart;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _partnerNameController.dispose();
    super.dispose();
  }

  bool get _canAnalyze => _partnerBirthDate != null && _partnerSiju != null;

  void _calculateCompatibility() {
    if (_mySajuChart == null || _partnerSajuChart == null) return;

    final calculator = CompatibilityCalculator.instance;
    _compatibilityResult = calculator.calculateCompatibility(
      _mySajuChart!,
      _partnerSajuChart!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 상대방 입력 모드
    if (_isPartnerInputMode && !_hasAnalyzed) {
      return _buildPartnerInputPage();
    }

    if (_compatibilityResult == null) {
      return _buildLoadingView();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('궁합 분석'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '상대방 정보 수정',
            onPressed: () {
              setState(() {
                _isPartnerInputMode = true;
                _hasAnalyzed = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              context.push(
                '/share',
                extra: {
                  'type': 'compatibility',
                  'compatibilityResult': _compatibilityResult,
                  'partnerName': _partnerNameController.text.isNotEmpty
                      ? _partnerNameController.text
                      : '상대방',
                  'myName': _myName,
                },
              );
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
                  _buildRelationBadges(),
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
                  unselectedLabelColor: AppColors.textSecondaryOf(context),
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

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('궁합 분석')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildRelationBadges() {
    final result = _compatibilityResult!;
    final dayPillar = result.dayPillarAnalysis;
    final branches = result.branchRelations;

    final allRelations = <String>[
      ...dayPillar.relations,
      ...branches.combinations,
      ...branches.clashes,
    ];

    if (allRelations.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: allRelations.take(5).map((relation) {
          final isGood =
              relation.contains('합') ||
              relation.contains('상생') ||
              relation.contains('동일');
          final isBad =
              relation.contains('충') ||
              relation.contains('형') ||
              relation.contains('해') ||
              relation.contains('파') ||
              relation.contains('상극');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isGood
                  ? AppColors.fortuneGood.withValues(alpha: 0.1)
                  : isBad
                  ? AppColors.warning.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGood
                    ? AppColors.fortuneGood.withValues(alpha: 0.3)
                    : isBad
                    ? AppColors.warning.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Text(
              relation,
              style: AppTypography.labelSmall.copyWith(
                color: isGood
                    ? AppColors.fortuneGood
                    : isBad
                    ? AppColors.warning
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreOverview() {
    final result = _compatibilityResult!;
    final partnerName = _partnerNameController.text.isNotEmpty
        ? _partnerNameController.text
        : '상대방';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(result.overallScore),
            _getScoreColor(result.overallScore).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(result.overallScore).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _myName,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '&',
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                partnerName,
                style: AppTypography.labelMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.overallScore}',
                style: AppTypography.fortuneScore.copyWith(color: Colors.white),
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
            _getScoreGrade(result.overallScore),
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniScore('연애', result.loveScore, Icons.favorite),
              _buildMiniScore('결혼', result.marriageScore, Icons.home),
              _buildMiniScore('사업', result.businessScore, Icons.work),
              _buildMiniScore('우정', result.friendshipScore, Icons.people),
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
    final myElement = _mySajuChart != null
        ? _getStemElement(_mySajuChart!.dayPillar.heavenlyStem)
        : '토';
    final partnerElement = _partnerSajuChart != null
        ? _getStemElement(_partnerSajuChart!.dayPillar.heavenlyStem)
        : '토';
    final partnerName = _partnerNameController.text.isNotEmpty
        ? _partnerNameController.text
        : '상대방';

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
          Expanded(
            child: _buildSajuCardFromChart(
              name: _myName,
              chart: _mySajuChart,
              element: myElement,
              alignment: CrossAxisAlignment.start,
            ),
          ),
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
          Expanded(
            child: _buildSajuCardFromChart(
              name: partnerName,
              chart: _partnerSajuChart,
              element: partnerElement,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSajuCardFromChart({
    required String name,
    required SajuChart? chart,
    required String element,
    required CrossAxisAlignment alignment,
  }) {
    if (chart == null) {
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
          Text('데이터 없음', style: AppTypography.caption),
        ],
      );
    }

    final dayMaster = chart.dayPillar.heavenlyStem;
    final pillarText =
        '${_getHanja(chart.yearPillar.heavenlyStem)}${_getHanja(chart.yearPillar.earthlyBranch)} '
        '${_getHanja(chart.monthPillar.heavenlyStem)}${_getHanja(chart.monthPillar.earthlyBranch)} '
        '${_getHanja(chart.dayPillar.heavenlyStem)}${_getHanja(chart.dayPillar.earthlyBranch)} '
        '${_getHanja(chart.hourPillar.heavenlyStem)}${_getHanja(chart.hourPillar.earthlyBranch)}';

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
            color: AppColors.getElementColor(element).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$dayMaster${_getElementName(dayMaster)}',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.getElementColor(element),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pillarText,
          style: AppTypography.bodySmall.copyWith(fontFamily: 'serif'),
          textAlign: alignment == CrossAxisAlignment.end
              ? TextAlign.end
              : TextAlign.start,
        ),
      ],
    );
  }

  Widget _buildOverallAnalysisTab() {
    final result = _compatibilityResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.insights.summary,
            style: AppTypography.bodyMedium.copyWith(height: 1.6),
          ),
          const SizedBox(height: 24),
          _buildAnalysisSection(
            title: '두 분의 장점',
            icon: Icons.thumb_up,
            color: AppColors.fortuneGood,
            items: result.insights.strengths,
          ),
          const SizedBox(height: 20),
          _buildAnalysisSection(
            title: '주의할 점',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            items: result.insights.challenges,
          ),
          const SizedBox(height: 24),
          // 일주 관계 상세
          Container(
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
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '일주 분석',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.dayPillarAnalysis.description,
                  style: AppTypography.bodyMedium.copyWith(
                    height: 1.5,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementCompatibilityTab() {
    final result = _compatibilityResult!;
    final elements = result.elementBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오행 궁합 분석',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '두 분의 사주에서 각 오행이 어떻게 조화를 이루는지 분석합니다.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 24),

          // 균형 점수
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.destinyGradientOf(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오행 균형 점수',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${elements.balanceScore}점',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (elements.complementaryElements.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '상호 보완: ${elements.complementaryElements.join(", ")}',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 오행별 분포
          ...['목', '화', '토', '금', '수'].map((element) {
            final person1 = elements.person1Elements[element] ?? 0;
            final person2 = elements.person2Elements[element] ?? 0;
            final combined = elements.combinedElements[element] ?? 0;
            final elementColor = AppColors.getElementColorOf(context, element);

            return _buildElementBarWithDetails(
              element: element,
              person1: person1,
              person2: person2,
              combined: combined,
              color: elementColor,
              isLacking: elements.lackingElements.contains(element),
              isExcessive: elements.excessiveElements.contains(element),
            );
          }),

          const SizedBox(height: 32),
          _buildElementCycleInfo(),
        ],
      ),
    );
  }

  Widget _buildElementBarWithDetails({
    required String element,
    required int person1,
    required int person2,
    required int combined,
    required Color color,
    required bool isLacking,
    required bool isExcessive,
  }) {
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
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getElementHanja(element),
                        style: AppTypography.titleMedium.copyWith(
                          color: color,
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
                        '$element(${_getElementHanja(element)})',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '나: $person1',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '상대: $person2',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (isLacking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningOf(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '부족',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.warningOf(context),
                        ),
                      ),
                    ),
                  if (isExcessive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorOf(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '과다',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.errorOf(context),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '$combined',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: combined / 8.0, // 최대 8로 가정
              backgroundColor: AppColors.grey200Of(context),
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '오행 상생상극 관계',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCycleRow(
            '상생',
            '목->화->토->금->수->목',
            AppColors.fortuneGoodOf(context),
          ),
          const SizedBox(height: 8),
          _buildCycleRow(
            '상극',
            '목->토, 토->수, 수->화, 화->금, 금->목',
            AppColors.warningOf(context),
          ),
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
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceTab() {
    final result = _compatibilityResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관계 발전을 위한 조언',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(result.insights.advice.length, (index) {
            return _buildAdviceCard(
              number: index + 1,
              advice: result.insights.advice[index],
            );
          }),
          const SizedBox(height: 32),
          // CTA 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.destinyGradientOf(context),
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
                    context.push('/consultation');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryOf(context),
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
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context),
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
              style: AppTypography.bodyMedium.copyWith(
                height: 1.5,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // 상대방 정보 입력 페이지
  // ============================================
  Widget _buildPartnerInputPage() {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('상대방 정보 입력'),
        backgroundColor: AppColors.backgroundOf(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOf(context).withValues(alpha: 0.1),
                      AppColors.primaryLightOf(context).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(
                          context,
                        ).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('💗', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '궁합을 확인해보세요',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '상대방의 생년월일과 태어난 시간을 입력하면\n두 분의 궁합을 분석해드립니다.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 이름 입력
              _buildSectionTitle('이름 (선택)'),
              const SizedBox(height: 8),
              TextField(
                controller: _partnerNameController,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: '상대방 이름',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiaryOf(context),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 생년월일
              _buildSectionTitle('생년월일'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showBirthDatePicker(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: _partnerBirthDate != null
                        ? Border.all(
                            color: AppColors.primaryOf(
                              context,
                            ).withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: _partnerBirthDate != null
                            ? AppColors.primaryOf(context)
                            : AppColors.textTertiaryOf(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _partnerBirthDate != null
                              ? '${_partnerBirthDate!.year}년 ${_partnerBirthDate!.month}월 ${_partnerBirthDate!.day}일'
                              : '생년월일을 선택하세요',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _partnerBirthDate != null
                                ? AppColors.textPrimaryOf(context)
                                : AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 음력/양력 토글
              Row(
                children: [
                  _buildCalendarTypeChip('양력', !_partnerIsLunar, () {
                    setState(() => _partnerIsLunar = false);
                  }),
                  const SizedBox(width: 8),
                  _buildCalendarTypeChip('음력', _partnerIsLunar, () {
                    setState(() => _partnerIsLunar = true);
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // 태어난 시간
              _buildSectionTitle('태어난 시간'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showSijuPicker(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: _partnerSiju != null
                        ? Border.all(
                            color: AppColors.primaryOf(
                              context,
                            ).withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: _partnerSiju != null
                            ? AppColors.primaryOf(context)
                            : AppColors.textTertiaryOf(context),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _partnerSiju != null
                              ? '${_partnerSiju!.name} (${_partnerSiju!.timeRange})'
                              : '태어난 시간을 선택하세요',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _partnerSiju != null
                                ? AppColors.textPrimaryOf(context)
                                : AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 성별
              _buildSectionTitle('성별'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildGenderButton('남성', 'male', Icons.male)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderButton('여성', 'female', Icons.female),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // 분석 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canAnalyze ? _analyzeCompatibility : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOf(context),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.grey300Of(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isAnalyzing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          '궁합 분석하기',
                          style: AppTypography.labelLarge.copyWith(
                            color: _canAnalyze
                                ? Colors.white
                                : AppColors.textTertiaryOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '* 시간을 모르시면 "시간 모름"을 선택하세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondaryOf(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCalendarTypeChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOf(context)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOf(context)
                : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? Colors.white
                : AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderButton(String label, String value, IconData icon) {
    final isSelected = _partnerGender == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _partnerGender = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOf(context).withValues(alpha: 0.1)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryOf(context)
                : AppColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryOf(context)
                  : AppColors.textSecondaryOf(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.primaryOf(context)
                    : AppColors.textSecondaryOf(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBirthDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6),
        margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.grey300Of(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    Text(
                      '생년월일 선택',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                        if (_partnerBirthDate == null) {
                          setState(
                            () => _partnerBirthDate = DateTime(1990, 1, 1),
                          );
                        }
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _partnerBirthDate ?? DateTime(1990, 1, 1),
                  minimumDate: DateTime(1900, 1, 1), // 100세 시대 대응 (126세 커버)
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (date) {
                    setState(() => _partnerBirthDate = date);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSijuPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey300Of(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  Text(
                    '태어난 시간',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sijuList.length,
                itemBuilder: (context, index) {
                  final siju = sijuList[index];
                  final isSelected = _partnerSijuIndex == index;
                  return ListTile(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _partnerSijuIndex = index;
                        _partnerSiju = siju;
                      });
                      Navigator.pop(context);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryOf(
                                context,
                              ).withValues(alpha: 0.1)
                            : AppColors.surfaceVariantOf(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          siju.hanja,
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? AppColors.primaryOf(context)
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      siju.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primaryOf(context)
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                    subtitle: Text(
                      siju.timeRange,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiaryOf(context),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: AppColors.primaryOf(context),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _analyzeCompatibility() {
    if (!_canAnalyze || _mySajuChart == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);

    // 상대방 사주 계산
    try {
      final calculator = SajuCalculator.instance;
      final birthDateTime = DateTime(
        _partnerBirthDate!.year,
        _partnerBirthDate!.month,
        _partnerBirthDate!.day,
        _partnerSiju!.startHour,
      );

      _partnerSajuChart = calculator.calculateSajuChart(
        birthDateTime: birthDateTime,
        gender: _partnerGender == 'male' ? '남' : '여',
        isLunar: _partnerIsLunar,
      );

      // 궁합 계산
      _calculateCompatibility();

      setState(() {
        _isPartnerInputMode = false;
        _hasAnalyzed = true;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('분석 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.errorOf(context),
        ),
      );
    }
  }

  // Helper methods
  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.fortuneGoodOf(context);
    if (score >= 60) return AppColors.primaryOf(context);
    if (score >= 40) return AppColors.warningOf(context);
    return AppColors.fortuneBadOf(context);
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

  String _getStemElement(String stem) {
    const mapping = {
      '갑': '목',
      '을': '목',
      '병': '화',
      '정': '화',
      '무': '토',
      '기': '토',
      '경': '금',
      '신': '금',
      '임': '수',
      '계': '수',
    };
    return mapping[stem] ?? '토';
  }

  String _getElementName(String stem) {
    final element = _getStemElement(stem);
    return '(${_getElementHanja(element)})';
  }

  String _getHanja(String korean) {
    const cheonganMap = {
      '갑': '甲',
      '을': '乙',
      '병': '丙',
      '정': '丁',
      '무': '戊',
      '기': '己',
      '경': '庚',
      '신': '辛',
      '임': '壬',
      '계': '癸',
    };
    const jijiMap = {
      '자': '子',
      '축': '丑',
      '인': '寅',
      '묘': '卯',
      '진': '辰',
      '사': '巳',
      '오': '午',
      '미': '未',
      '신': '申',
      '유': '酉',
      '술': '戌',
      '해': '亥',
    };
    return cheonganMap[korean] ?? jijiMap[korean] ?? korean;
  }
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.backgroundOf(context), child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    // 테마 변경 등으로 TabBar의 색/스타일이 바뀔 수 있으므로 비교 후 재빌드
    return tabBar != oldDelegate.tabBar;
  }
}
