import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/domain/entities/saju_chart.dart';
import '../../../saju/domain/entities/daewoon.dart';
import '../../../saju/domain/services/analysis_text_builder.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';

/// 대운 타임라인 페이지
/// 10년 주기의 인생 흐름을 시각화하고 종합 분석 제공
class DaewoonPage extends StatefulWidget {
  final DaewoonChart? daewoonChart;
  final SajuChart? sajuChart;

  const DaewoonPage({super.key, this.daewoonChart, this.sajuChart});

  @override
  State<DaewoonPage> createState() => _DaewoonPageState();
}

/// 대운 분석 탭 유형
enum DaewoonTab {
  overview, // 종합 분석
  timeline, // 타임라인
  detail, // 상세 분석
}

class _DaewoonPageState extends State<DaewoonPage>
    with SingleTickerProviderStateMixin {
  late ScrollController _timelineController;
  late TabController _tabController;
  int _selectedDaewoonIndex = 0;

  // BLoC 또는 데모 데이터
  DaewoonChart? _daewoonChart;
  SajuChart? _sajuChart;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();

    // 현재 대운으로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDaewoon();
    });
  }

  void _initializeData() {
    // 1. 먼저 위젯 파라미터 확인
    if (widget.daewoonChart != null) {
      _daewoonChart = widget.daewoonChart!;
      _sajuChart = widget.sajuChart;
      _updateSelectedIndex();
      return;
    }

    // 2. BLoC에서 데이터 가져오기 시도
    try {
      final bloc = context.read<DestinyBloc>();
      final state = bloc.state;
      if (state is DestinySuccess) {
        _daewoonChart = state.daewoonChart;
        _sajuChart = state.sajuChart;
        _updateSelectedIndex();
        return;
      }
    } catch (_) {
      // BLoC이 없을 수 있음
    }

    // 3. 데모 데이터 사용
    _daewoonChart = _createDemoData();
    _sajuChart = _createDemoSajuChart();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    if (_daewoonChart != null) {
      _selectedDaewoonIndex = _daewoonChart!.daewoons.indexWhere(
        (d) => d.isCurrentDaewoon(_daewoonChart!.currentAge),
      );
      if (_selectedDaewoonIndex < 0) _selectedDaewoonIndex = 0;
    }
  }

  DaewoonChart _createDemoData() {
    return DaewoonChart(
      currentAge: 35,
      daewoons: [
        Daewoon(
          startAge: 5,
          endAge: 15,
          pillar: const Pillar(heavenlyStem: '기', earthlyBranch: '묘'),
          theme: '학습과 성장의 시기',
          description: '인성운으로 학문적 성취와 정신적 성장이 이루어지는 시기입니다.',
          fortuneScore: 68.0,
        ),
        Daewoon(
          startAge: 15,
          endAge: 25,
          pillar: const Pillar(heavenlyStem: '경', earthlyBranch: '진'),
          theme: '도전과 발전의 시기',
          description: '관성운으로 사회적 지위와 명예를 얻을 수 있는 시기입니다.',
          fortuneScore: 72.0,
        ),
        Daewoon(
          startAge: 25,
          endAge: 35,
          pillar: const Pillar(heavenlyStem: '신', earthlyBranch: '사'),
          theme: '재물 축적의 시기',
          description: '재성운으로 경제적 기회가 많아지고 재물이 축적되는 시기입니다.',
          fortuneScore: 80.0,
        ),
        Daewoon(
          startAge: 35,
          endAge: 45,
          pillar: const Pillar(heavenlyStem: '임', earthlyBranch: '오'),
          theme: '표현과 성취의 시기',
          description:
              '식상운으로 창의력이 빛나고 재능을 발휘할 수 있는 시기입니다. 새로운 프로젝트를 시작하기 좋은 때입니다.',
          fortuneScore: 85.0,
        ),
        Daewoon(
          startAge: 45,
          endAge: 55,
          pillar: const Pillar(heavenlyStem: '계', earthlyBranch: '미'),
          theme: '자아 확립의 시기',
          description: '비겁운으로 자아 정체성이 강화되고 독립심이 높아지는 시기입니다.',
          fortuneScore: 70.0,
        ),
        Daewoon(
          startAge: 55,
          endAge: 65,
          pillar: const Pillar(heavenlyStem: '갑', earthlyBranch: '신'),
          theme: '안정 유지의 시기',
          description: '평온하게 흘러가며 지혜를 쌓는 시기입니다.',
          fortuneScore: 65.0,
        ),
        Daewoon(
          startAge: 65,
          endAge: 75,
          pillar: const Pillar(heavenlyStem: '을', earthlyBranch: '유'),
          theme: '인간관계 확장기',
          description: '주변 사람들과의 관계가 깊어지고 지혜를 전수하는 시기입니다.',
          fortuneScore: 62.0,
        ),
        Daewoon(
          startAge: 75,
          endAge: 85,
          pillar: const Pillar(heavenlyStem: '병', earthlyBranch: '술'),
          theme: '명예 수확의 시기',
          description: '삶의 결실을 맺고 명예를 얻는 시기입니다.',
          fortuneScore: 68.0,
        ),
        Daewoon(
          startAge: 85,
          endAge: 95,
          pillar: const Pillar(heavenlyStem: '정', earthlyBranch: '해'),
          theme: '지혜의 완성기',
          description: '인생의 지혜가 완성되고 평온함을 누리는 시기입니다.',
          fortuneScore: 60.0,
        ),
      ],
    );
  }

  void _scrollToCurrentDaewoon() {
    if (!_timelineController.hasClients) return;

    if (_selectedDaewoonIndex > 0) {
      final offset = (_selectedDaewoonIndex * 100.0) - 50;
      _timelineController.animateTo(
        offset.clamp(0, _timelineController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BLoC에서 데이터 갱신 감지
    return BlocListener<DestinyBloc, DestinyState>(
      listener: (context, state) {
        // 라우트가 const DaewoonPage()로 열리기 때문에,
        // 위젯 파라미터가 없는 경우에는 BLoC 성공 데이터를 항상 반영하도록 한다.
        if (state is DestinySuccess && widget.daewoonChart == null) {
          setState(() {
            _daewoonChart = state.daewoonChart;
            _sajuChart = state.sajuChart;
            _updateSelectedIndex();
          });
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // 데이터가 없으면 빈 상태 표시
    if (_daewoonChart == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        appBar: _buildAppBar(),
        body: Center(
          child: Text(
            '대운 데이터를 불러올 수 없습니다.\n먼저 사주 분석을 진행해주세요.',
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 탭 바
          _buildTabBar(),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 종합 분석 탭
                _buildOverviewTab(),
                // 타임라인 탭
                _buildTimelineTab(),
                // 상세 분석 탭
                _buildDetailTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surfaceOf(context),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryOf(context),
        indicatorWeight: 3,
        labelColor: AppColors.primaryOf(context),
        unselectedLabelColor: AppColors.textSecondaryOf(context),
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: '종합 분석'),
          Tab(text: '타임라인'),
          Tab(text: '상세 분석'),
        ],
      ),
    );
  }

  /// 종합 분석 탭 - 대운 전체 흐름의 종합적인 분석
  Widget _buildOverviewTab() {
    final chart = _daewoonChart!;
    final currentDaewoon =
        chart.currentDaewoon ?? chart.daewoons[_selectedDaewoonIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사주팔자 요약 (있는 경우)
          if (_sajuChart != null) _buildSajuSummaryCard(),

          // 인생 대운 종합 분석
          _buildLifeOverviewCard(),

          const SizedBox(height: 20),

          // 현재 대운 심층 분석
          _buildCurrentDaewoonAnalysis(currentDaewoon),

          const SizedBox(height: 20),

          // 항목별 분석 (현재 대운 기준)
          _buildCategoryAnalysisCards(currentDaewoon),

          const SizedBox(height: 20),

          // 오행 균형 분석
          _buildElementBalanceCard(),

          const SizedBox(height: 20),

          // 대운별 운세 점수 차트
          _buildFortuneScoreChart(),

          const SizedBox(height: 20),

          // 인생 조언
          _buildLifeAdviceCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 타임라인 탭
  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 현재 대운 하이라이트 카드
          _buildCurrentDaewoonCard(),

          // 대운 타임라인
          _buildTimelineSection(),

          // 선택된 대운 상세 정보
          _buildSelectedDaewoonDetail(),

          // 다음 대운 미리보기
          _buildNextDaewoonPreview(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 상세 분석 탭
  Widget _buildDetailTab() {
    final daewoon = _daewoonChart!.daewoons[_selectedDaewoonIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대운 선택기
          _buildDaewoonSelector(),

          const SizedBox(height: 20),

          // 선택된 대운 상세 분석
          _buildDetailedDaewoonAnalysis(daewoon),

          const SizedBox(height: 20),

          // 십신 분석
          _buildTenGodAnalysis(daewoon),

          const SizedBox(height: 20),

          // 오행 분석
          _buildElementAnalysis(daewoon),

          const SizedBox(height: 20),

          // 주의사항 및 조언
          _buildDaewoonAdviceCard(daewoon),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 사주팔자 요약 카드
  Widget _buildSajuSummaryCard() {
    if (_sajuChart == null) return const SizedBox.shrink();

    final saju = _sajuChart!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                '나의 사주팔자',
                style: AppTypography.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 사주 간지 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillarColumn(
                '년주',
                saju.yearPillar,
                const Color(0xFF4CAF50),
              ),
              _buildPillarColumn(
                '월주',
                saju.monthPillar,
                const Color(0xFFFF9800),
              ),
              _buildPillarColumn('일주', saju.dayPillar, const Color(0xFF2196F3)),
              _buildPillarColumn(
                '시주',
                saju.hourPillar,
                const Color(0xFF9C27B0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSajuInfo('일간 (나)', saju.dayMaster, AppColors.primary),
              _buildSajuInfo(
                '일간 오행',
                saju.dayMasterElement,
                _getElementColor(saju.dayMasterElement),
              ),
              _buildSajuInfo(
                '용신',
                saju.complementaryElement,
                _getElementColor(saju.complementaryElement),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillarColumn(String label, Pillar pillar, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Text(
                pillar.hanjaRepresentation[0],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                pillar.hanjaRepresentation[1],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          pillar.fullPillar,
          style: AppTypography.caption.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSajuInfo(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 인생 대운 종합 분석 카드
  Widget _buildLifeOverviewCard() {
    final chart = _daewoonChart!;
    final overview = _generateLifeOverview(chart);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(
              context,
              lightOpacity: 0.05,
              darkOpacity: 0.12,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '인생 대운 종합 분석',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      '${chart.currentAge}세 기준',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 핵심 분석
          Text(
            overview['summary'] ?? '',
            style: AppTypography.bodyLarge.copyWith(
              height: 1.8,
              color: AppColors.textPrimaryOf(context),
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.borderOf(context)),
          const SizedBox(height: 16),

          // 대운 흐름 요약
          Text(
            '대운 흐름 요약',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(3, (index) {
            final items = overview['phases'] as List<Map<String, String>>?;
            if (items == null || index >= items.length) {
              return const SizedBox.shrink();
            }
            final phase = items[index];
            return _buildPhaseItem(
              phase['period'] ?? '',
              phase['theme'] ?? '',
              phase['description'] ?? '',
              index,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhaseItem(
    String period,
    String theme,
    String description,
    int index,
  ) {
    final colors = [
      AppColors.fireOf(context),
      AppColors.waterOf(context),
      AppColors.woodOf(context),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      period,
                      style: AppTypography.labelMedium.copyWith(color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        theme,
                        style: AppTypography.labelSmall.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 현재 대운 심층 분석
  Widget _buildCurrentDaewoonAnalysis(Daewoon daewoon) {
    final analysis = _generateDaewoonAnalysis(daewoon);
    final comprehensiveText = AnalysisTextBuilder.buildDaewoonComprehensiveText(
      chart: _sajuChart,
      daewoon: daewoon,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(daewoon.fortuneScore),
            _getScoreColor(daewoon.fortuneScore).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      daewoon.pillar.hanjaRepresentation[0],
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      daewoon.pillar.hanjaRepresentation[1],
                      style: AppTypography.displaySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '현재 대운',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      daewoon.theme,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      daewoon.periodString,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${daewoon.fortuneScore.toInt()}',
                  style: AppTypography.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 심층 분석 내용
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 핵심 분석',
                  style: AppTypography.titleSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis['core'] ?? daewoon.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🧭 종합분석',
                  style: AppTypography.titleSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  comprehensiveText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '💡 이 시기의 조언',
                  style: AppTypography.titleSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis['advice'] ?? '',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysisCards(Daewoon daewoon) {
    final categories = AnalysisTextBuilder.buildDaewoonCategoryTexts(
      chart: _sajuChart,
      daewoon: daewoon,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '항목별 분석',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '선택한 대운 기준으로 영역별 포인트를 정리했어요. (눌러서 펼치기)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...categories.entries.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  e.key,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                children: [
                  Text(
                    e.value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 오행 균형 분석 카드
  Widget _buildElementBalanceCard() {
    final elementBalance = _calculateElementBalance();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오행 균형 분석',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '대운 흐름에서의 오행 에너지 분포',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 20),

          // 오행 바 차트
          ...['목', '화', '토', '금', '수'].map((element) {
            final value = elementBalance[element] ?? 0;
            final maxValue = elementBalance.values.reduce(
              (a, b) => a > b ? a : b,
            );
            final percentage = maxValue > 0 ? value / maxValue : 0.0;

            return _buildElementBar(element, value, percentage);
          }),

          const SizedBox(height: 16),
          Divider(color: AppColors.borderOf(context)),
          const SizedBox(height: 12),

          // 분석 결과
          Text(
            _generateElementAnalysisText(elementBalance),
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBar(String element, int value, double percentage) {
    final elementColor = AppColors.getElementColorOf(context, element);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: elementColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              element,
              style: AppTypography.labelMedium.copyWith(
                color: elementColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 24,
                  width: (MediaQuery.of(context).size.width - 140) * percentage,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        elementColor,
                        elementColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              '$value',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 인생 조언 카드
  Widget _buildLifeAdviceCard() {
    final advice = _generateLifeAdvice();
    final primaryColor = AppColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💫', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                '인생 조언',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...advice.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyMedium.copyWith(
                        height: 1.5,
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

  /// 대운 선택기
  Widget _buildDaewoonSelector() {
    final primaryColor = AppColors.primaryOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '대운 선택',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _daewoonChart!.daewoons.length,
              itemBuilder: (context, index) {
                final daewoon = _daewoonChart!.daewoons[index];
                final isSelected = index == _selectedDaewoonIndex;
                final isCurrent = daewoon.isCurrentDaewoon(
                  _daewoonChart!.currentAge,
                );

                return GestureDetector(
                  onTap: () => setState(() => _selectedDaewoonIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isCurrent
                                ? primaryColor.withValues(alpha: 0.2)
                                : AppColors.surfaceVariantOf(context)),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent && !isSelected
                          ? Border.all(color: primaryColor, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          daewoon.pillar.hanjaRepresentation,
                          style: AppTypography.titleMedium.copyWith(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : AppColors.textPrimaryOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${daewoon.startAge}~${daewoon.endAge - 1}세',
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withValues(alpha: 0.7)
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 상세 대운 분석
  Widget _buildDetailedDaewoonAnalysis(Daewoon daewoon) {
    final comprehensiveText = AnalysisTextBuilder.buildDaewoonComprehensiveText(
      chart: _sajuChart,
      daewoon: daewoon,
    );
    final categories = AnalysisTextBuilder.buildDaewoonCategoryTexts(
      chart: _sajuChart,
      daewoon: daewoon,
    );
    final primaryColor = AppColors.primaryOf(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getThemeEmoji(daewoon.theme),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daewoon.theme,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      '${daewoon.pillar.fullPillar} (${daewoon.pillar.hanjaRepresentation})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              _buildScoreBadge(daewoon.fortuneScore),
            ],
          ),
          const SizedBox(height: 20),

          // 상세 설명
          Text(
            daewoon.description,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.8,
              color: AppColors.textPrimaryOf(context),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.borderOf(context)),
          const SizedBox(height: 16),

          // 종합분석 (선택 대운 기준)
          Text(
            '종합분석',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comprehensiveText,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.8,
              color: AppColors.textSecondaryOf(context),
            ),
          ),

          const SizedBox(height: 20),

          // 키워드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getKeywordsForTheme(daewoon.theme).map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  keyword,
                  style: AppTypography.labelSmall.copyWith(color: primaryColor),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // 항목별 분석 (선택 대운 기준)
          Text(
            '항목별 분석',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          ...categories.entries.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  e.key,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                children: [
                  Text(
                    e.value,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getScoreColor(score)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            score >= 70
                ? Icons.trending_up
                : (score >= 60 ? Icons.trending_flat : Icons.trending_down),
            color: _getScoreColor(score),
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '${score.toInt()}점',
            style: AppTypography.labelLarge.copyWith(
              color: _getScoreColor(score),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 십신 분석
  Widget _buildTenGodAnalysis(Daewoon daewoon) {
    final tenGod = _getTenGodFromStem(daewoon.pillar.heavenlyStem);
    final tenGodInfo = _getTenGodInfo(tenGod);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (tenGodInfo['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tenGodInfo['emoji'] as String,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '십신 분석',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (tenGodInfo['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tenGod,
                            style: AppTypography.labelMedium.copyWith(
                              color: tenGodInfo['color'] as Color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tenGodInfo['name'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tenGodInfo['description'] as String,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),

          // 십신 특성
          Row(
            children: [
              Expanded(
                child: _buildTenGodTrait(
                  '강점',
                  tenGodInfo['strength'] as String,
                  AppColors.successOf(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTenGodTrait(
                  '주의점',
                  tenGodInfo['weakness'] as String,
                  AppColors.warningOf(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenGodTrait(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  /// 오행 분석
  Widget _buildElementAnalysis(Daewoon daewoon) {
    final element = _getPillarElement(daewoon.pillar.heavenlyStem);
    final elementInfo = _getElementInfo(element);
    final elementColor = AppColors.getElementColorOf(context, element);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            elementColor.withValues(alpha: 0.1),
            elementColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: elementColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: elementColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    element,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오행 분석',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      '$element(${elementInfo['hanja']}) 기운의 대운',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            elementInfo['description'] as String,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textPrimaryOf(context),
            ),
          ),

          const SizedBox(height: 16),

          // 오행 특성 그리드
          Row(
            children: [
              Expanded(
                child: _buildElementTrait(
                  '계절',
                  elementInfo['season'] as String,
                ),
              ),
              Expanded(
                child: _buildElementTrait(
                  '방위',
                  elementInfo['direction'] as String,
                ),
              ),
              Expanded(
                child: _buildElementTrait('색상', elementInfo['color'] as String),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    elementInfo['advice'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryOf(context),
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

  Widget _buildElementTrait(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  /// 대운 조언 카드
  Widget _buildDaewoonAdviceCard(Daewoon daewoon) {
    final advice = _getDaewoonAdvice(daewoon);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${daewoon.periodString} 조언',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 16),

          // 해야 할 것
          _buildAdviceSection(
            '✅ 이 시기에 해야 할 것',
            advice['do'] as List<String>,
            AppColors.successOf(context),
          ),

          const SizedBox(height: 16),

          // 주의할 것
          _buildAdviceSection(
            '⚠️ 주의해야 할 것',
            advice['dont'] as List<String>,
            AppColors.warningOf(context),
          ),

          const SizedBox(height: 16),

          // 행운의 요소
          _buildAdviceSection(
            '🍀 행운의 요소',
            advice['lucky'] as List<String>,
            AppColors.primaryOf(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleSmall.copyWith(color: color)),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceOf(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimaryOf(context),
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        '대운 타임라인',
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryOf(context),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Icons.info_outline,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () => _showDaewoonInfo(context),
        ),
      ],
    );
  }

  Widget _buildCurrentDaewoonCard() {
    final chart = _daewoonChart!;
    final currentDaewoon =
        chart.currentDaewoon ?? chart.daewoons[_selectedDaewoonIndex];
    final yearsRemaining = currentDaewoon.endAge - chart.currentAge;
    final progress = (chart.currentAge - currentDaewoon.startAge) / 10;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getScoreColor(currentDaewoon.fortuneScore),
            _getScoreColor(currentDaewoon.fortuneScore).withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor(
              currentDaewoon.fortuneScore,
            ).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '현재 대운',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentDaewoon.fortuneScore.toInt()}점',
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 대운 간지
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      currentDaewoon.pillar.hanjaRepresentation[0],
                      style: AppTypography.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      currentDaewoon.pillar.hanjaRepresentation[1],
                      style: AppTypography.displayMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentDaewoon.theme,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDaewoon.periodString,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 대운 진행률
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '대운 진행률',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '$yearsRemaining년 남음',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '인생 타임라인',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            controller: _timelineController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _daewoonChart!.daewoons.length,
            itemBuilder: (context, index) {
              return _buildTimelineItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(int index) {
    final daewoon = _daewoonChart!.daewoons[index];
    final isSelected = index == _selectedDaewoonIndex;
    final isCurrent = daewoon.isCurrentDaewoon(_daewoonChart!.currentAge);
    final isPast = daewoon.endAge <= _daewoonChart!.currentAge;

    return GestureDetector(
      onTap: () => setState(() => _selectedDaewoonIndex = index),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // 연결선
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 2,
                    color: index == 0
                        ? Colors.transparent
                        : (isPast || isCurrent
                              ? AppColors.primaryOf(context)
                              : AppColors.grey300Of(context)),
                  ),
                ),
                // 대운 노드
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 20 : 14,
                  height: isSelected ? 20 : 14,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryOf(context)
                        : (isPast
                              ? AppColors.primaryLightOf(context)
                              : AppColors.grey300Of(context)),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primaryOf(context),
                            width: 3,
                          )
                        : null,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primaryOf(
                                context,
                              ).withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: index == _daewoonChart!.daewoons.length - 1
                        ? Colors.transparent
                        : (isPast
                              ? AppColors.primaryOf(context)
                              : AppColors.grey300Of(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 대운 카드
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getScoreColor(
                        daewoon.fortuneScore,
                      ).withValues(alpha: 0.1)
                    : AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _getScoreColor(daewoon.fortuneScore)
                      : (isCurrent
                            ? AppColors.primaryOf(context)
                            : AppColors.borderOf(context)),
                  width: isSelected || isCurrent ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    daewoon.pillar.hanjaRepresentation,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected
                          ? _getScoreColor(daewoon.fortuneScore)
                          : (isPast
                                ? AppColors.textSecondaryOf(context)
                                : AppColors.textPrimaryOf(context)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${daewoon.startAge}~${daewoon.endAge - 1}세',
                    style: AppTypography.caption.copyWith(
                      color: isPast
                          ? AppColors.textTertiaryOf(context)
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '현재',
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 9,
                        ),
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

  Widget _buildSelectedDaewoonDetail() {
    final daewoon = _daewoonChart!.daewoons[_selectedDaewoonIndex];
    final element = _getPillarElement(daewoon.pillar.heavenlyStem);
    final elementColor = AppColors.getElementColorOf(context, element);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(
              context,
              lightOpacity: 0.05,
              darkOpacity: 0.12,
            ),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: elementColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getThemeEmoji(daewoon.theme),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daewoon.theme,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildElementBadge(element),
                        const SizedBox(width: 8),
                        Text(
                          daewoon.periodString,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.borderOf(context)),
          const SizedBox(height: 16),
          Text(
            daewoon.description,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          // 키워드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getKeywordsForTheme(daewoon.theme).map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  keyword,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDaewoonPreview() {
    final nextDaewoon = _daewoonChart!.nextDaewoon;
    if (nextDaewoon == null) return const SizedBox.shrink();

    final yearsUntil = _daewoonChart!.yearsUntilNextDaewoon ?? 0;
    final primaryColor = AppColors.primaryOf(context);

    void goToNextDaewoon() {
      final nextIndex = _daewoonChart!.daewoons.indexWhere(
        (d) =>
            d.startAge == nextDaewoon.startAge &&
            d.endAge == nextDaewoon.endAge,
      );
      if (nextIndex < 0) return;

      setState(() => _selectedDaewoonIndex = nextIndex);
      _tabController.animateTo(DaewoonTab.timeline.index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentDaewoon();
      });
    }

    return GestureDetector(
      onTap: goToNextDaewoon,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$yearsUntil년 후 다음 대운',
                    style: AppTypography.labelMedium.copyWith(
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${nextDaewoon.pillar.hanjaRepresentation} · ${nextDaewoon.theme}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondaryOf(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFortuneScoreChart() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '대운별 운세 흐름',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _daewoonChart!.daewoons.asMap().entries.map((entry) {
                final index = entry.key;
                final daewoon = entry.value;
                final isSelected = index == _selectedDaewoonIndex;
                final isCurrent = daewoon.isCurrentDaewoon(
                  _daewoonChart!.currentAge,
                );
                final barHeight = (daewoon.fortuneScore / 100) * 120;
                final primaryColor = AppColors.primaryOf(context);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDaewoonIndex = index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${daewoon.fortuneScore.toInt()}',
                          style: AppTypography.caption.copyWith(
                            color: isSelected || isCurrent
                                ? _getScoreColor(daewoon.fortuneScore)
                                : AppColors.textTertiaryOf(context),
                            fontWeight: isSelected || isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: barHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? _getScoreColor(daewoon.fortuneScore)
                                : (isSelected
                                      ? _getScoreColor(
                                          daewoon.fortuneScore,
                                        ).withValues(alpha: 0.7)
                                      : AppColors.grey300Of(context)),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${daewoon.startAge}',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: isCurrent
                                ? primaryColor
                                : AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '나이 (세)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBadge(String element) {
    final elementColor = AppColors.getElementColorOf(context, element);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: elementColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$element 기운',
        style: AppTypography.caption.copyWith(
          color: elementColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.fortuneGoodOf(context);
    if (score >= 70) return AppColors.primaryOf(context);
    if (score >= 60) return AppColors.warningOf(context);
    return AppColors.fortuneBadOf(context);
  }

  String _getPillarElement(String stem) {
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

  String _getThemeEmoji(String theme) {
    if (theme.contains('재물')) return '💰';
    if (theme.contains('명예')) return '🏆';
    if (theme.contains('학습') || theme.contains('성장')) return '📚';
    if (theme.contains('표현') || theme.contains('성취')) return '🎨';
    if (theme.contains('자아')) return '🧘';
    if (theme.contains('도전') || theme.contains('발전')) return '🚀';
    if (theme.contains('안정')) return '🏠';
    if (theme.contains('인간관계')) return '🤝';
    if (theme.contains('지혜')) return '🦉';
    return '✨';
  }

  List<String> _getKeywordsForTheme(String theme) {
    if (theme.contains('재물')) {
      return ['#투자', '#사업', '#수입증가', '#재테크'];
    }
    if (theme.contains('명예')) {
      return ['#승진', '#인정', '#성공', '#리더십'];
    }
    if (theme.contains('학습') || theme.contains('성장')) {
      return ['#공부', '#자격증', '#독서', '#멘토'];
    }
    if (theme.contains('표현') || theme.contains('성취')) {
      return ['#창작', '#예술', '#도전', '#성과'];
    }
    if (theme.contains('자아')) {
      return ['#자기발견', '#독립', '#정체성', '#결단'];
    }
    if (theme.contains('도전') || theme.contains('발전')) {
      return ['#변화', '#기회', '#용기', '#돌파'];
    }
    if (theme.contains('안정')) {
      return ['#평화', '#균형', '#유지', '#안식'];
    }
    if (theme.contains('인간관계')) {
      return ['#네트워킹', '#소통', '#협력', '#신뢰'];
    }
    if (theme.contains('지혜')) {
      return ['#통찰', '#경험', '#가르침', '#평온'];
    }
    return ['#운세', '#행운', '#변화'];
  }

  // ========== 데이터 생성 및 분석 헬퍼 메서드 ==========

  /// 데모용 사주팔자 데이터 생성
  SajuChart _createDemoSajuChart() {
    return SajuChart(
      yearPillar: const Pillar(heavenlyStem: '기', earthlyBranch: '사'),
      monthPillar: const Pillar(heavenlyStem: '경', earthlyBranch: '오'),
      dayPillar: const Pillar(heavenlyStem: '임', earthlyBranch: '신'),
      hourPillar: const Pillar(heavenlyStem: '계', earthlyBranch: '축'),
      birthDateTime: DateTime(1989, 6, 15, 14, 30),
      isLunar: false,
      gender: '남',
    );
  }

  /// 인생 종합 분석 생성
  Map<String, dynamic> _generateLifeOverview(DaewoonChart chart) {
    final daewoons = chart.daewoons;
    final currentAge = chart.currentAge;

    // 과거, 현재, 미래 대운 분석
    final pastDaewoons = daewoons.where((d) => d.endAge <= currentAge).toList();
    final currentDaewoon = chart.currentDaewoon;
    final futureDaewoons = daewoons
        .where((d) => d.startAge > currentAge)
        .toList();

    // 전체 운세 점수 평균
    final avgScore =
        daewoons.map((d) => d.fortuneScore).reduce((a, b) => a + b) /
        daewoons.length;

    // 최고점, 최저점 대운
    final bestDaewoon = daewoons.reduce(
      (a, b) => a.fortuneScore > b.fortuneScore ? a : b,
    );
    final worstDaewoon = daewoons.reduce(
      (a, b) => a.fortuneScore < b.fortuneScore ? a : b,
    );

    String summary = '당신의 인생 대운을 분석한 결과, ';

    if (avgScore >= 75) {
      summary += '전반적으로 매우 양호한 대운 흐름을 가지고 있습니다. ';
    } else if (avgScore >= 65) {
      summary += '전반적으로 안정적인 대운 흐름을 가지고 있습니다. ';
    } else {
      summary += '도전과 기회가 교차하는 대운 흐름을 가지고 있습니다. ';
    }

    summary +=
        '특히 ${bestDaewoon.startAge}~${bestDaewoon.endAge - 1}세 (${bestDaewoon.theme})가 가장 좋은 시기이며, ';

    if (currentDaewoon != null) {
      summary += '현재 ${currentDaewoon.theme}의 시기를 보내고 있습니다. ';

      if (currentDaewoon.fortuneScore >= 80) {
        summary += '지금은 적극적으로 기회를 잡을 때입니다!';
      } else if (currentDaewoon.fortuneScore >= 70) {
        summary += '꾸준히 노력하면 좋은 결실을 맺을 수 있습니다.';
      } else if (currentDaewoon.fortuneScore >= 60) {
        summary += '내면을 다지며 다음 기회를 준비하는 것이 좋습니다.';
      } else {
        summary += '신중하게 행동하고 건강 관리에 신경 쓰세요.';
      }
    }

    // 대운 흐름 3단계 분석
    final phases = <Map<String, String>>[];

    if (pastDaewoons.isNotEmpty) {
      final lastPast = pastDaewoons.last;
      phases.add({
        'period': '${lastPast.startAge}~${lastPast.endAge - 1}세 (과거)',
        'theme': lastPast.theme,
        'description': '이 시기의 경험이 현재의 기반이 되었습니다. ${lastPast.description}',
      });
    }

    if (currentDaewoon != null) {
      phases.add({
        'period':
            '${currentDaewoon.startAge}~${currentDaewoon.endAge - 1}세 (현재)',
        'theme': currentDaewoon.theme,
        'description': currentDaewoon.description,
      });
    }

    if (futureDaewoons.isNotEmpty) {
      final nextFuture = futureDaewoons.first;
      phases.add({
        'period': '${nextFuture.startAge}~${nextFuture.endAge - 1}세 (다가올)',
        'theme': nextFuture.theme,
        'description':
            '앞으로 펼쳐질 ${nextFuture.theme}를 준비하세요. ${nextFuture.description}',
      });
    }

    return {
      'summary': summary,
      'phases': phases,
      'avgScore': avgScore,
      'bestPeriod': bestDaewoon,
      'worstPeriod': worstDaewoon,
    };
  }

  /// 대운 심층 분석 생성
  Map<String, String> _generateDaewoonAnalysis(Daewoon daewoon) {
    final element = _getPillarElement(daewoon.pillar.heavenlyStem);
    final tenGod = _getTenGodFromStem(daewoon.pillar.heavenlyStem);

    String core = daewoon.description;
    core += '\n\n이 대운의 천간 ${daewoon.pillar.heavenlyStem}($element 기운)은 ';

    switch (tenGod) {
      case '비겁':
        core += '자아와 독립심을 강화하는 에너지입니다. 경쟁 상황에서 자신감을 가지고 주도적으로 행동하세요.';
        break;
      case '식상':
        core += '표현과 창조의 에너지입니다. 새로운 아이디어를 실현하고 재능을 발휘할 기회가 많아집니다.';
        break;
      case '재성':
        core += '재물과 현실적 성취의 에너지입니다. 경제적 기회를 잡고 실용적인 목표를 달성할 수 있습니다.';
        break;
      case '관성':
        core += '명예와 사회적 지위의 에너지입니다. 승진, 인정, 책임감 있는 역할을 맡게 될 수 있습니다.';
        break;
      case '인성':
        core += '학습과 지혜의 에너지입니다. 공부, 자격증, 멘토와의 만남이 인생에 큰 영향을 줍니다.';
        break;
      default:
        core += '다양한 기회와 변화의 에너지입니다.';
    }

    String advice = '';
    if (daewoon.fortuneScore >= 80) {
      advice =
          '이 시기는 적극적으로 도전하세요! 새로운 사업, 이직, 투자 등 큰 결정을 내리기 좋은 때입니다. 단, 과욕은 금물이며 겸손함을 잃지 마세요.';
    } else if (daewoon.fortuneScore >= 70) {
      advice =
          '꾸준한 노력이 결실을 맺는 시기입니다. 무리하지 않으면서 착실하게 목표를 향해 나아가세요. 주변 사람들과의 관계도 소중히 하세요.';
    } else if (daewoon.fortuneScore >= 60) {
      advice =
          '내면을 다지는 시기입니다. 큰 변화보다는 현재 상황을 유지하며 실력을 쌓는 것이 좋습니다. 건강 관리와 자기 계발에 투자하세요.';
    } else {
      advice =
          '신중함이 필요한 시기입니다. 중요한 결정은 미루고, 리스크 있는 투자나 변화는 피하세요. 가까운 사람들의 조언을 경청하세요.';
    }

    return {'core': core, 'advice': advice};
  }

  /// 오행 균형 계산
  Map<String, int> _calculateElementBalance() {
    final balance = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};

    for (final daewoon in _daewoonChart!.daewoons) {
      final stemElement = _getPillarElement(daewoon.pillar.heavenlyStem);
      final branchElement = _getBranchElement(daewoon.pillar.earthlyBranch);

      if (balance.containsKey(stemElement)) {
        balance[stemElement] = (balance[stemElement] ?? 0) + 1;
      }
      if (balance.containsKey(branchElement)) {
        balance[branchElement] = (balance[branchElement] ?? 0) + 1;
      }
    }

    return balance;
  }

  String _generateElementAnalysisText(Map<String, int> balance) {
    final entries = balance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongest = entries.first;
    final weakest = entries.last;

    String text =
        '대운 전체에서 ${strongest.key}(${_getElementInfo(strongest.key)['hanja']}) 기운이 가장 강하고, ';
    text +=
        '${weakest.key}(${_getElementInfo(weakest.key)['hanja']}) 기운이 상대적으로 약합니다.\n\n';

    switch (strongest.key) {
      case '목':
        text += '목 기운이 강한 대운을 가졌습니다. 성장과 발전의 에너지가 넘치며, 새로운 시작과 도전에 유리합니다.';
        break;
      case '화':
        text += '화 기운이 강한 대운을 가졌습니다. 열정과 표현의 에너지가 넘치며, 사회적 활동과 인지도 상승에 유리합니다.';
        break;
      case '토':
        text += '토 기운이 강한 대운을 가졌습니다. 안정과 중재의 에너지가 있어 꾸준한 성장과 신뢰 구축에 유리합니다.';
        break;
      case '금':
        text += '금 기운이 강한 대운을 가졌습니다. 결단력과 정리의 에너지가 있어 목표 달성과 성과 수확에 유리합니다.';
        break;
      case '수':
        text += '수 기운이 강한 대운을 가졌습니다. 지혜와 적응의 에너지가 있어 학습과 유연한 대처에 유리합니다.';
        break;
    }

    return text;
  }

  /// 인생 조언 생성
  List<String> _generateLifeAdvice() {
    final chart = _daewoonChart!;
    final currentDaewoon = chart.currentDaewoon;
    final advice = <String>[];

    if (currentDaewoon != null) {
      // 현재 대운 기반 조언
      if (currentDaewoon.fortuneScore >= 75) {
        advice.add('현재 운이 좋은 시기입니다. 새로운 도전이나 투자를 고려해보세요.');
      }

      final yearsRemaining = currentDaewoon.endAge - chart.currentAge;
      if (yearsRemaining <= 3) {
        final nextDaewoon = chart.nextDaewoon;
        if (nextDaewoon != null) {
          advice.add(
            '$yearsRemaining년 후 "${nextDaewoon.theme}" 대운이 시작됩니다. 미리 준비하세요.',
          );
        }
      }
    }

    // 오행 균형 기반 조언
    final balance = _calculateElementBalance();
    final weakest = balance.entries.reduce((a, b) => a.value < b.value ? a : b);
    advice.add(
      '${weakest.key} 기운을 보충하면 더 균형 잡힌 삶을 살 수 있습니다. ${_getElementAdvice(weakest.key)}',
    );

    // 일반적인 조언
    advice.add('대운은 큰 흐름일 뿐, 노력과 선택이 운명을 바꿀 수 있습니다.');
    advice.add('어려운 시기도 반드시 지나갑니다. 긍정적인 마음가짐을 유지하세요.');

    return advice;
  }

  String _getElementAdvice(String element) {
    switch (element) {
      case '목':
        return '푸른색 옷이나 소품을 활용하고, 식물을 기르거나 산책을 자주 하세요.';
      case '화':
        return '붉은색 계열의 소품을 활용하고, 따뜻한 차를 마시며 열정적인 취미를 가져보세요.';
      case '토':
        return '황색이나 베이지 계열을 활용하고, 명상이나 안정적인 루틴을 만들어보세요.';
      case '금':
        return '흰색이나 메탈릭 소품을 활용하고, 정리정돈과 결단력 있는 행동을 연습하세요.';
      case '수':
        return '검은색이나 파란색을 활용하고, 물 관련 활동(수영, 목욕)이나 독서를 즐기세요.';
      default:
        return '';
    }
  }

  /// 십신 정보 반환
  String _getTenGodFromStem(String stem) {
    // 일간 기준으로 십신 계산 (데모용으로 간략화)
    final dayMaster = _sajuChart?.dayMaster ?? '임';

    // 간략화된 십신 매핑
    final stemElement = _getPillarElement(stem);
    final dayElement = _getPillarElement(dayMaster);

    if (stemElement == dayElement) return '비겁';

    // 생극 관계로 십신 결정
    final generating = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
    final controlling = {'목': '토', '토': '수', '수': '화', '화': '금', '금': '목'};

    if (generating[dayElement] == stemElement) return '식상';
    if (generating[stemElement] == dayElement) return '인성';
    if (controlling[dayElement] == stemElement) return '재성';
    if (controlling[stemElement] == dayElement) return '관성';

    return '비겁';
  }

  Map<String, dynamic> _getTenGodInfo(String tenGod) {
    final info = {
      '비겁': {
        'name': '비겁 (比劫)',
        'emoji': '🤝',
        'color': AppColors.woodOf(context),
        'description':
            '비겁은 나와 같은 오행으로, 자아 정체성과 독립심을 나타냅니다. 이 시기에는 경쟁심이 강해지고 자기 주장이 분명해집니다. 협력과 경쟁이 공존하는 시기입니다.',
        'strength': '자신감, 리더십, 독립심이 강화됩니다.',
        'weakness': '고집이 세지고 타협이 어려울 수 있습니다.',
      },
      '식상': {
        'name': '식상 (食傷)',
        'emoji': '🎨',
        'color': AppColors.fireOf(context),
        'description':
            '식상은 내가 생하는 오행으로, 표현력과 창의성을 나타냅니다. 이 시기에는 아이디어가 넘치고 재능을 발휘할 기회가 많습니다. 새로운 것을 창조하는 에너지가 강해집니다.',
        'strength': '창의력, 표현력, 말솜씨가 향상됩니다.',
        'weakness': '생각이 많아지고 결정이 어려울 수 있습니다.',
      },
      '재성': {
        'name': '재성 (財星)',
        'emoji': '💰',
        'color': AppColors.earthOf(context),
        'description':
            '재성은 내가 극하는 오행으로, 재물과 현실적 성취를 나타냅니다. 이 시기에는 경제적 기회가 많아지고 물질적 욕구가 강해집니다. 돈을 벌고 관리하는 능력이 중요해집니다.',
        'strength': '재정 능력, 현실 감각이 좋아집니다.',
        'weakness': '물질에 집착하거나 인색해질 수 있습니다.',
      },
      '관성': {
        'name': '관성 (官星)',
        'emoji': '👔',
        'color': AppColors.metalOf(context),
        'description':
            '관성은 나를 극하는 오행으로, 명예와 사회적 지위를 나타냅니다. 이 시기에는 책임감이 커지고 사회적 인정을 받을 기회가 많습니다. 직장이나 조직에서의 역할이 중요해집니다.',
        'strength': '책임감, 규율, 사회적 인정이 높아집니다.',
        'weakness': '스트레스와 부담감이 커질 수 있습니다.',
      },
      '인성': {
        'name': '인성 (印星)',
        'emoji': '📚',
        'color': AppColors.waterOf(context),
        'description':
            '인성은 나를 생하는 오행으로, 학습과 지혜를 나타냅니다. 이 시기에는 배움의 욕구가 강해지고 멘토나 후원자를 만날 수 있습니다. 정신적 성장과 지식 축적이 이루어집니다.',
        'strength': '학습 능력, 통찰력, 후원운이 좋아집니다.',
        'weakness': '의존적이 되거나 행동력이 떨어질 수 있습니다.',
      },
    };

    return info[tenGod] ?? info['비겁']!;
  }

  /// 오행 정보 반환
  Map<String, dynamic> _getElementInfo(String element) {
    final info = {
      '목': {
        'hanja': '木',
        'season': '봄',
        'direction': '동쪽',
        'color': '청색',
        'description':
            '목(木)은 성장과 발전의 에너지입니다. 나무가 위로 뻗어가듯 도전과 확장의 기운이 강합니다. 새로운 시작, 학습, 계획 수립에 좋은 에너지입니다.',
        'advice': '새로운 시작을 두려워하지 마세요. 이 시기는 씨앗을 뿌리는 때입니다.',
      },
      '화': {
        'hanja': '火',
        'season': '여름',
        'direction': '남쪽',
        'color': '적색',
        'description':
            '화(火)는 열정과 표현의 에너지입니다. 불꽃처럼 활발하고 밝은 기운이 강합니다. 사회 활동, 인지도 상승, 예술적 표현에 좋은 에너지입니다.',
        'advice': '열정을 불태우되 과열을 조심하세요. 건강 관리가 중요합니다.',
      },
      '토': {
        'hanja': '土',
        'season': '환절기',
        'direction': '중앙',
        'color': '황색',
        'description':
            '토(土)는 안정과 중재의 에너지입니다. 땅처럼 묵직하고 신뢰를 주는 기운입니다. 조율, 협상, 부동산 관련 사안에 좋은 에너지입니다.',
        'advice': '급하게 서두르지 말고 착실하게 기반을 다지세요.',
      },
      '금': {
        'hanja': '金',
        'season': '가을',
        'direction': '서쪽',
        'color': '백색',
        'description':
            '금(金)은 결단과 정리의 에너지입니다. 쇠처럼 단단하고 결단력 있는 기운입니다. 수확, 완성, 결정에 좋은 에너지입니다.',
        'advice': '불필요한 것을 정리하고 핵심에 집중하세요.',
      },
      '수': {
        'hanja': '水',
        'season': '겨울',
        'direction': '북쪽',
        'color': '흑색',
        'description':
            '수(水)는 지혜와 적응의 에너지입니다. 물처럼 유연하고 깊은 기운입니다. 학습, 연구, 내면 성찰에 좋은 에너지입니다.',
        'advice': '조용히 내면을 살피고 다음을 준비하세요.',
      },
    };

    return info[element] ?? info['토']!;
  }

  Color _getElementColor(String element) {
    return AppColors.getElementColorOf(context, element);
  }

  String _getBranchElement(String branch) {
    const mapping = {
      '인': '목',
      '묘': '목',
      '사': '화',
      '오': '화',
      '진': '토',
      '술': '토',
      '축': '토',
      '미': '토',
      '신': '금',
      '유': '금',
      '해': '수',
      '자': '수',
    };
    return mapping[branch] ?? '토';
  }

  /// 대운별 조언 생성
  Map<String, List<String>> _getDaewoonAdvice(Daewoon daewoon) {
    final element = _getPillarElement(daewoon.pillar.heavenlyStem);
    final tenGod = _getTenGodFromStem(daewoon.pillar.heavenlyStem);

    final doList = <String>[];
    final dontList = <String>[];
    final luckyList = <String>[];

    // 십신별 조언
    switch (tenGod) {
      case '비겁':
        doList.addAll(['자기 계발과 독립적인 프로젝트', '동업보다는 단독 사업', '체력 단련과 스포츠']);
        dontList.addAll(['파트너와의 금전 거래', '과도한 경쟁심', '독단적인 결정']);
        luckyList.addAll(['동기, 동료, 친구', '경쟁 스포츠', '자기 브랜딩']);
        break;
      case '식상':
        doList.addAll(['창작 활동과 예술', '새로운 아이디어 실현', '콘텐츠 제작, SNS 활동']);
        dontList.addAll(['말실수와 과한 자기 표현', '시작만 하고 마무리 안 함', '산만한 계획']);
        luckyList.addAll(['창작 활동', '강연/강의', '자녀, 후배와의 관계']);
        break;
      case '재성':
        doList.addAll(['재테크와 투자', '수입원 다변화', '현실적인 목표 설정']);
        dontList.addAll(['무리한 투자', '과소비', '재물에 대한 집착']);
        luckyList.addAll(['금전 운용', '비즈니스 파트너', '배우자와의 관계']);
        break;
      case '관성':
        doList.addAll(['직장에서의 성실함', '자격증 취득', '사회적 책임 수행']);
        dontList.addAll(['법적 분쟁', '상사와의 갈등', '과도한 업무 스트레스']);
        luckyList.addAll(['승진과 인정', '공식적인 자리', '사회적 지위']);
        break;
      case '인성':
        doList.addAll(['학습과 자기 계발', '자격증 취득', '멘토 찾기']);
        dontList.addAll(['우유부단함', '너무 많은 조언 의존', '결정 미루기']);
        luckyList.addAll(['교육 기회', '어른의 조언', '정신적 성장']);
        break;
    }

    // 오행별 행운 요소 추가
    switch (element) {
      case '목':
        luckyList.add('푸른색, 식물, 동쪽 방향');
        break;
      case '화':
        luckyList.add('붉은색, 따뜻한 장소, 남쪽 방향');
        break;
      case '토':
        luckyList.add('황색/베이지, 안정적인 환경, 중앙');
        break;
      case '금':
        luckyList.add('흰색/메탈릭, 정돈된 공간, 서쪽 방향');
        break;
      case '수':
        luckyList.add('검정/남색, 물 관련 장소, 북쪽 방향');
        break;
    }

    return {'do': doList, 'dont': dontList, 'lucky': luckyList};
  }

  void _showDaewoonInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대운이란?',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '대운(大運)은 10년 단위로 변화하는 인생의 큰 흐름입니다. '
                '사주팔자의 월주(月柱)를 기준으로 순행 또는 역행하며, '
                '각 대운마다 특별한 테마와 에너지가 있습니다.',
                style: AppTypography.bodyMedium.copyWith(
                  height: 1.6,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoRow('순행', '양년생 남자, 음년생 여자'),
              _buildInfoRow('역행', '음년생 남자, 양년생 여자'),
              _buildInfoRow('시작 나이', '월주와 생일 절입일 기준 계산'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primaryOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
