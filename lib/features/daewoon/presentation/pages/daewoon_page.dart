import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/domain/entities/saju_chart.dart';
import '../../../saju/domain/entities/daewoon.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';

/// 대운 타임라인 페이지
/// 10년 주기의 인생 흐름을 시각화
class DaewoonPage extends StatefulWidget {
  final DaewoonChart? daewoonChart;
  final SajuChart? sajuChart;

  const DaewoonPage({
    super.key,
    this.daewoonChart,
    this.sajuChart,
  });

  @override
  State<DaewoonPage> createState() => _DaewoonPageState();
}

class _DaewoonPageState extends State<DaewoonPage> {
  late ScrollController _timelineController;
  int _selectedDaewoonIndex = 0;

  // BLoC 또는 데모 데이터
  DaewoonChart? _daewoonChart;
  bool _isFromBloc = false;

  @override
  void initState() {
    super.initState();
    _timelineController = ScrollController();
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
      _updateSelectedIndex();
      return;
    }

    // 2. BLoC에서 데이터 가져오기 시도
    try {
      final bloc = context.read<DestinyBloc>();
      final state = bloc.state;
      if (state is DestinySuccess) {
        _daewoonChart = state.daewoonChart;
        _isFromBloc = true;
        _updateSelectedIndex();
        return;
      }
    } catch (_) {
      // BLoC이 없을 수 있음
    }

    // 3. 데모 데이터 사용
    _daewoonChart = _createDemoData();
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
          description: '식상운으로 창의력이 빛나고 재능을 발휘할 수 있는 시기입니다. 새로운 프로젝트를 시작하기 좋은 때입니다.',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BLoC에서 데이터 갱신 감지
    return BlocListener<DestinyBloc, DestinyState>(
      listener: (context, state) {
        if (state is DestinySuccess && _isFromBloc) {
          setState(() {
            _daewoonChart = state.daewoonChart;
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
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: const Center(
          child: Text('대운 데이터를 불러올 수 없습니다.\n먼저 사주 분석을 진행해주세요.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
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

            // 대운별 운세 점수 차트
            _buildFortuneScoreChart(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        '대운 타임라인',
        style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: AppColors.textPrimary),
          onPressed: () => _showDaewoonInfo(context),
        ),
      ],
    );
  }

  Widget _buildCurrentDaewoonCard() {
    final chart = _daewoonChart!;
    final currentDaewoon = chart.currentDaewoon ?? chart.daewoons[_selectedDaewoonIndex];
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
            color: _getScoreColor(currentDaewoon.fortuneScore).withValues(alpha: 0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentDaewoon.fortuneScore.toInt()}점',
                  style: AppTypography.labelMedium.copyWith(color: Colors.white),
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
                      style: AppTypography.displayMedium.copyWith(color: Colors.white),
                    ),
                    Text(
                      currentDaewoon.pillar.hanjaRepresentation[1],
                      style: AppTypography.displayMedium.copyWith(color: Colors.white),
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
          child: Text('인생 타임라인', style: AppTypography.headlineSmall),
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
                        : (isPast || isCurrent ? AppColors.primary : AppColors.grey300),
                  ),
                ),
                // 대운 노드
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 20 : 14,
                  height: isSelected ? 20 : 14,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : (isPast ? AppColors.primaryLight : AppColors.grey300),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                    boxShadow: isCurrent ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ] : null,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: index == _daewoonChart!.daewoons.length - 1
                        ? Colors.transparent
                        : (isPast ? AppColors.primary : AppColors.grey300),
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
                    ? _getScoreColor(daewoon.fortuneScore).withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _getScoreColor(daewoon.fortuneScore)
                      : (isCurrent ? AppColors.primary : AppColors.border),
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
                          : (isPast ? AppColors.textSecondary : AppColors.textPrimary),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${daewoon.startAge}~${daewoon.endAge - 1}세',
                    style: AppTypography.caption.copyWith(
                      color: isPast ? AppColors.textTertiary : AppColors.textSecondary,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '현재',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
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

    return Container(
      margin: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getElementColor(element).withValues(alpha: 0.1),
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
                    Text(daewoon.theme, style: AppTypography.headlineSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildElementBadge(element),
                        const SizedBox(width: 8),
                        Text(
                          daewoon.periodString,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            daewoon.description,
            style: AppTypography.bodyMedium.copyWith(
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // 키워드
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getKeywordsForTheme(daewoon.theme).map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  keyword,
                  style: AppTypography.labelSmall,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$yearsUntil년 후 다음 대운',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nextDaewoon.pillar.hanjaRepresentation} · ${nextDaewoon.theme}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildFortuneScoreChart() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('대운별 운세 흐름', style: AppTypography.headlineSmall),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _daewoonChart!.daewoons.asMap().entries.map((entry) {
                final index = entry.key;
                final daewoon = entry.value;
                final isSelected = index == _selectedDaewoonIndex;
                final isCurrent = daewoon.isCurrentDaewoon(_daewoonChart!.currentAge);
                final barHeight = (daewoon.fortuneScore / 100) * 120;

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
                                : AppColors.textTertiary,
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
                                    ? _getScoreColor(daewoon.fortuneScore).withValues(alpha: 0.7)
                                    : AppColors.grey300),
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
                            color: isCurrent ? AppColors.primary : AppColors.textTertiary,
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
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementBadge(String element) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getElementColor(element).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$element 기운',
        style: AppTypography.caption.copyWith(
          color: AppColors.getElementColor(element),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.fortuneGood;
    if (score >= 70) return AppColors.primary;
    if (score >= 60) return AppColors.warning;
    return AppColors.fortuneBad;
  }

  String _getPillarElement(String stem) {
    const mapping = {
      '갑': '목', '을': '목',
      '병': '화', '정': '화',
      '무': '토', '기': '토',
      '경': '금', '신': '금',
      '임': '수', '계': '수',
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
    if (theme.contains('재물')) return ['#투자', '#사업', '#수입증가', '#재테크'];
    if (theme.contains('명예')) return ['#승진', '#인정', '#성공', '#리더십'];
    if (theme.contains('학습') || theme.contains('성장')) return ['#공부', '#자격증', '#독서', '#멘토'];
    if (theme.contains('표현') || theme.contains('성취')) return ['#창작', '#예술', '#도전', '#성과'];
    if (theme.contains('자아')) return ['#자기발견', '#독립', '#정체성', '#결단'];
    if (theme.contains('도전') || theme.contains('발전')) return ['#변화', '#기회', '#용기', '#돌파'];
    if (theme.contains('안정')) return ['#평화', '#균형', '#유지', '#안식'];
    if (theme.contains('인간관계')) return ['#네트워킹', '#소통', '#협력', '#신뢰'];
    if (theme.contains('지혜')) return ['#통찰', '#경험', '#가르침', '#평온'];
    return ['#운세', '#행운', '#변화'];
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
              Text('대운이란?', style: AppTypography.headlineMedium),
              const SizedBox(height: 16),
              Text(
                '대운(大運)은 10년 단위로 변화하는 인생의 큰 흐름입니다. '
                '사주팔자의 월주(月柱)를 기준으로 순행 또는 역행하며, '
                '각 대운마다 특별한 테마와 에너지가 있습니다.',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
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
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}
