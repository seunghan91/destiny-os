import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/data/services/saju_calculator.dart'
    hide CompatibilityResult;
import '../../../saju/domain/entities/saju_chart.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../../saju/presentation/widgets/mbti_dimension_selector.dart';
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
  String? _myMbti;

  // 상대방 입력 데이터
  final TextEditingController _partnerNameController = TextEditingController();
  DateTime? _partnerBirthDate;
  int? _partnerSijuIndex;
  Siju? _partnerSiju;
  String? _partnerMbti;
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
        _myMbti = state.mbtiType.type;
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

  bool get _canAnalyze => _partnerBirthDate != null;

  void _calculateCompatibility() {
    if (_mySajuChart == null || _partnerSajuChart == null) return;

    final calculator = CompatibilityCalculator.instance;
    _compatibilityResult = calculator.calculateCompatibility(
      _mySajuChart!,
      _partnerSajuChart!,
      myMbti: _myMbti,
      partnerMbti: _partnerMbti,
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

  // ===========================================================================
  // Partner Input UI (운세 첫 입력 화면과 동일한 스타일/흐름으로 정렬)
  // ===========================================================================

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('궁합 분석')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildPartnerInputPage() {
    final primary = AppColors.primaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('궁합 분석'),
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
                      primary.withValues(alpha: 0.1),
                      primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.2),
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
                            '상대방의 생년월일/태어난 시간/MBTI를 입력하면\n두 분의 궁합을 분석해드립니다.',
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
              const SizedBox(height: 28),

              _buildPartnerNameSection(),
              const SizedBox(height: 28),

              _buildPartnerBirthDateSection(),
              const SizedBox(height: 28),

              _buildPartnerBirthTimeSection(),
              const SizedBox(height: 28),

              _buildPartnerGenderSection(),
              const SizedBox(height: 28),

              _buildPartnerMbtiSection(),
              const SizedBox(height: 36),

              _buildPartnerAnalyzeButton(),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '태어난 시간을 모르시면 생략해도 됩니다',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiaryOf(context),
                  ),
                ),
              ),
              if (_myMbti != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    '내 MBTI: $_myMbti',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerNameSection() {
    final primary = AppColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('이름', subtitle: '선택 입력'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _partnerNameController.text.isNotEmpty
                  ? primary.withValues(alpha: 0.3)
                  : AppColors.borderOf(context),
              width: _partnerNameController.text.isNotEmpty ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _partnerNameController,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '상대방 이름을 입력하세요',
              hintStyle: AppTypography.titleMedium.copyWith(
                color: AppColors.textTertiaryOf(context),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _partnerNameController.text.isNotEmpty
                      ? primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _partnerNameController.text.isNotEmpty
                      ? primary
                      : AppColors.textTertiaryOf(context),
                  size: 24,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerBirthDateSection() {
    final primary = AppColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('생년월일', isRequired: true),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showPartnerDatePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _partnerBirthDate != null
                    ? primary.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
                width: _partnerBirthDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _partnerBirthDate != null
                        ? primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: _partnerBirthDate != null
                        ? primary
                        : AppColors.textTertiaryOf(context),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _partnerBirthDate != null
                            ? '${_partnerBirthDate!.year}년 ${_partnerBirthDate!.month}월 ${_partnerBirthDate!.day}일'
                            : '생년월일을 선택하세요',
                        style: AppTypography.titleMedium.copyWith(
                          color: _partnerBirthDate != null
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textTertiaryOf(context),
                          fontWeight: _partnerBirthDate != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_partnerBirthDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getZodiacInfo(_partnerBirthDate),
                          style: AppTypography.bodySmall.copyWith(
                            color: primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryOf(context),
                ),
              ],
            ),
          ),
        ),
        if (_partnerBirthDate != null) ...[
          const SizedBox(height: 12),
          _buildPartnerLunarToggle(),
        ],
      ],
    );
  }

  Widget _buildPartnerLunarToggle() {
    final earth = AppColors.earthOf(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _partnerIsLunar = !_partnerIsLunar);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _partnerIsLunar
              ? earth.withValues(alpha: 0.1)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _partnerIsLunar
                ? earth.withValues(alpha: 0.3)
                : AppColors.borderOf(context),
          ),
        ),
        child: Row(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              '음력으로 입력',
              style: AppTypography.bodyMedium.copyWith(
                color: _partnerIsLunar
                    ? earth
                    : AppColors.textSecondaryOf(context),
                fontWeight:
                    _partnerIsLunar ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _partnerIsLunar ? earth : Colors.transparent,
                border: Border.all(
                  color:
                      _partnerIsLunar ? earth : AppColors.grey400Of(context),
                  width: 2,
                ),
              ),
              child: _partnerIsLunar
                  ? const Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerBirthTimeSection() {
    final wood = AppColors.woodOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('태어난 시간', subtitle: '모르면 생략 가능'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showPartnerTimePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _partnerSiju != null
                    ? wood.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
                width: _partnerSiju != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _partnerSiju != null
                        ? wood.withValues(alpha: 0.1)
                        : AppColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _partnerSiju != null
                        ? Text(
                            _partnerSiju!.emoji,
                            style: const TextStyle(fontSize: 24),
                          )
                        : Icon(
                            Icons.access_time_rounded,
                            color: AppColors.textTertiaryOf(context),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _partnerSiju != null
                            ? '${_partnerSiju!.name} (${_partnerSiju!.hanja}時)'
                            : '태어난 시간을 선택하세요',
                        style: AppTypography.titleMedium.copyWith(
                          color: _partnerSiju != null
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textTertiaryOf(context),
                          fontWeight: _partnerSiju != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_partnerSiju != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _partnerSiju!.timeRange,
                          style: AppTypography.bodySmall.copyWith(color: wood),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryOf(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerGenderSection() {
    final primary = AppColors.primaryOf(context);
    final fire = AppColors.fireOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('성별', isRequired: true),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPartnerGenderButton(
                value: 'male',
                label: '남성',
                icon: Icons.male_rounded,
                color: primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPartnerGenderButton(
                value: 'female',
                label: '여성',
                icon: Icons.female_rounded,
                color: fire,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerGenderButton({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _partnerGender == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _partnerGender = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : AppColors.textSecondaryOf(context),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerMbtiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('MBTI', subtitle: '선택 입력'),
        const SizedBox(height: 8),
        Text(
          '상대방 MBTI를 알면 더 구체적인 성향 비교에 도움이 됩니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        MbtiDimensionSelector(
          initialType: _partnerMbti,
          onTypeSelected: (type) {
            setState(() => _partnerMbti = type);
          },
        ),
      ],
    );
  }

  Widget _buildPartnerAnalyzeButton() {
    final primary = AppColors.primaryOf(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canAnalyze ? _analyzeCompatibility : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: AppColors.grey300Of(context),
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledForegroundColor: AppColors.textTertiaryOf(context),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '궁합 분석하기',
                    style: AppTypography.labelLarge.copyWith(
                      color: _canAnalyze
                          ? Theme.of(context).colorScheme.onPrimary
                          : AppColors.textTertiaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionLabel(
    String title, {
    bool isRequired = false,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.fireOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ],
    );
  }

  String _getZodiacInfo(DateTime? date) {
    if (date == null) return '';
    final year = date.year;
    const animals = [
      '🐭쥐',
      '🐮소',
      '🐯호랑이',
      '🐰토끼',
      '🐲용',
      '🐍뱀',
      '🐴말',
      '🐑양',
      '🐵원숭이',
      '🐔닭',
      '🐶개',
      '🐷돼지',
    ];
    return '${animals[(year - 4) % 12]}띠';
  }

  void _showPartnerTimePicker() {
    HapticFeedback.selectionClick();
    SijuPickerBottomSheet.show(
      context,
      initialIndex: _partnerSijuIndex,
      onSelected: (index, siju) {
        setState(() {
          _partnerSijuIndex = index;
          _partnerSiju = siju;
        });
      },
    );
  }

  void _showPartnerDatePicker() {
    HapticFeedback.selectionClick();
    if (kIsWeb || _isDesktopPlatform()) {
      _showPartnerCustomWebDatePicker();
    } else {
      _showPartnerCupertinoDatePicker();
    }
  }

  bool _isDesktopPlatform() {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  void _showPartnerCupertinoDatePicker() {
    DateTime tempDate = _partnerBirthDate ?? DateTime(1990, 1, 1);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 360,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300Of(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    Text(
                      '생년월일 선택',
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _partnerBirthDate = tempDate);
                        Navigator.pop(ctx);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumYear: 1900,
                  maximumYear: DateTime.now().year,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1900, 1, 1),
                  onDateTimeChanged: (DateTime newDate) {
                    HapticFeedback.selectionClick();
                    tempDate = newDate;
                  },
                  dateOrder: DatePickerDateOrder.ymd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerCustomWebDatePicker() {
    final DateTime initialDate = _partnerBirthDate ?? DateTime(1990, 1, 1);
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    const int minYear = 1900;
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;
    final int currentDay = now.day;

    final List<int> years = List.generate(
      currentYear - minYear + 1,
      (i) => minYear + i,
    );
    final List<int> months = List.generate(12, (i) => i + 1);

    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<int> days = List.generate(
              getDaysInMonth(selectedYear, selectedMonth),
              (i) => i + 1,
            );
            if (selectedDay > days.length) {
              selectedDay = days.length;
            }

            final primary = Theme.of(context).colorScheme.primary;
            final surface = Theme.of(context).colorScheme.surface;
            final surfaceVariant =
                Theme.of(context).colorScheme.surfaceContainerHighest;

            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                '생년월일 선택',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildDropdownField<int>(
                            label: '연도',
                            value: selectedYear,
                            items: years.reversed.toList(),
                            itemLabel: (year) => '$year년',
                            onChanged: (value) {
                              setDialogState(() {
                                selectedYear = value!;
                                if (selectedYear == currentYear &&
                                    selectedMonth > currentMonth) {
                                  selectedMonth = currentMonth;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField<int>(
                            label: '월',
                            value: selectedMonth,
                            items: months.where((m) {
                              if (selectedYear == currentYear) {
                                return m <= currentMonth;
                              }
                              return true;
                            }).toList(),
                            itemLabel: (month) => '$month월',
                            onChanged: (value) {
                              setDialogState(() {
                                selectedMonth = value!;
                                if (selectedYear == currentYear &&
                                    selectedMonth == currentMonth &&
                                    selectedDay > currentDay) {
                                  selectedDay = currentDay;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField<int>(
                            label: '일',
                            value: selectedDay,
                            items: days.where((d) {
                              if (selectedYear == currentYear &&
                                  selectedMonth == currentMonth) {
                                return d <= currentDay;
                              }
                              return true;
                            }).toList(),
                            itemLabel: (day) => '$day일',
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDay = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: primary),
                          const SizedBox(width: 8),
                          Text(
                            '$selectedYear년 $selectedMonth월 $selectedDay일',
                            style: AppTypography.bodyLarge.copyWith(
                              color: primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selectedDate = DateTime(
                      selectedYear,
                      selectedMonth,
                      selectedDay,
                    );
                    HapticFeedback.mediumImpact();
                    setState(() => _partnerBirthDate = selectedDate);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    '확인',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final surface = Theme.of(context).colorScheme.surface;
    final border = AppColors.borderOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
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
                  : AppColors.surfaceVariantOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isGood
                    ? AppColors.fortuneGood.withValues(alpha: 0.3)
                    : isBad
                    ? AppColors.warning.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
              ),
            ),
            child: Text(
              relation,
              style: AppTypography.labelSmall.copyWith(
                color: isGood
                    ? AppColors.fortuneGood
                    : isBad
                    ? AppColors.warning
                    : AppColors.textSecondaryOf(context),
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
          if (result.mbtiScore != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '사주 ${result.sajuScore} · MBTI ${result.mbtiScore} → 최종 ${result.overallScore}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          if (result.mbtiScore != null) ...[
            const SizedBox(height: 20),
            _buildMbtiAnalysisCard(result),
          ],
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

  Widget _buildMbtiAnalysisCard(CompatibilityResult result) {
    final partnerName = _partnerNameController.text.isNotEmpty
        ? _partnerNameController.text
        : '상대방';
    final myMbti = _myMbti ?? '미입력';
    final partnerMbti = _partnerMbti ?? '미입력';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: AppColors.primaryOf(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'MBTI 궁합',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.primaryOf(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${result.mbtiScore}점',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primaryOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$_myName($myMbti) · $partnerName($partnerMbti)',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 12),
          if (result.mbtiRelationshipType != null)
            Text(
              '관계 유형: ${result.mbtiRelationshipType}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (result.mbtiCommunicationStyle != null) ...[
            const SizedBox(height: 8),
            Text(
              '소통: ${result.mbtiCommunicationStyle}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
          if (result.mbtiConflictPattern != null) ...[
            const SizedBox(height: 8),
            Text(
              '갈등: ${result.mbtiConflictPattern}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
          if ((result.mbtiCommonGround ?? const []).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '공통점',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...?result.mbtiCommonGround?.take(4).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: AppTypography.bodyMedium),
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
          if ((result.mbtiDifferences ?? const []).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '차이점',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...?result.mbtiDifferences?.take(4).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: AppTypography.bodyMedium),
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

  /// 궁합 분석 결과를 데이터베이스에 저장
  Future<void> _saveCompatibilityResult() async {
    if (_compatibilityResult == null) return;

    try {
      final supabase = Supabase.instance.client;
      final bloc = context.read<DestinyBloc>();
      final state = bloc.state;

      // 1. 먼저 user_results 저장/조회하여 user_result_id 얻기
      String? userResultId;

      if (state is DestinySuccess) {
        // 사용자의 정보로 user_results 저장
        final userPayload = <String, dynamic>{
          'birth_date': state.sajuChart.birthDateTime.toUtc().toIso8601String(),
          'birth_hour': state.sajuChart.birthDateTime.hour,
          'is_lunar': state.sajuChart.isLunar,
          'gender': state.sajuChart.gender,
          'mbti': state.mbtiType.type,
          'name': null,  // 이름은 사용 안 함
          'use_night_subhour': false,  // 야자시 사용 여부는 알 수 없음
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        final userResponse = await supabase
            .from('user_results')
            .insert(userPayload)
            .select('id');

        if (userResponse.isNotEmpty) {
          userResultId = userResponse.first['id'] as String;
        }
      }

      // user_result_id가 없으면 저장하지 않음
      if (userResultId == null) {
        debugPrint('⚠️ [CompatibilityPage] No user_result_id, skipping save');
        return;
      }

      // 2. 궁합 분석 결과 저장
      final partnerBirthHour = _partnerSiju?.startHour ?? 12;
      final partnerBirthDateTime = DateTime(
        _partnerBirthDate!.year,
        _partnerBirthDate!.month,
        _partnerBirthDate!.day,
        partnerBirthHour,
      );

      final compatibilityPayload = <String, dynamic>{
        'user_result_id': userResultId,
        'partner_name': _partnerNameController.text.isEmpty
            ? null
            : _partnerNameController.text,
        'partner_birth_date': partnerBirthDateTime.toUtc().toIso8601String(),
        'partner_birth_hour': partnerBirthHour,
        'partner_gender': _partnerGender,
        'partner_is_lunar': _partnerIsLunar,
        'partner_mbti': _partnerMbti,
        'overall_score': _compatibilityResult!.overallScore,
        'saju_score': _compatibilityResult!.sajuScore,
        'mbti_score': _compatibilityResult!.mbtiScore,
        'love_score': _compatibilityResult!.loveScore,
        'marriage_score': _compatibilityResult!.marriageScore,
        'business_score': _compatibilityResult!.businessScore,
        'friendship_score': _compatibilityResult!.friendshipScore,
        'mbti_relationship_type': _compatibilityResult!.mbtiRelationshipType,
        'mbti_communication_style': _compatibilityResult!.mbtiCommunicationStyle,
        'mbti_conflict_pattern': _compatibilityResult!.mbtiConflictPattern,
        'mbti_common_ground': _compatibilityResult!.mbtiCommonGround,
        'mbti_differences': _compatibilityResult!.mbtiDifferences,
        'day_pillar_analysis': {
          'score': _compatibilityResult!.dayPillarAnalysis.score,
          'description': _compatibilityResult!.dayPillarAnalysis.description,
          'relations': _compatibilityResult!.dayPillarAnalysis.relations,
        },
        'branch_relations': {
          'combinations': _compatibilityResult!.branchRelations.combinations,
          'clashes': _compatibilityResult!.branchRelations.clashes,
          'punishments': _compatibilityResult!.branchRelations.punishments,
          'harms': _compatibilityResult!.branchRelations.harms,
        },
        'element_balance': {
          'person1_elements': _compatibilityResult!.elementBalance.person1Elements,
          'person2_elements': _compatibilityResult!.elementBalance.person2Elements,
          'combined_elements': _compatibilityResult!.elementBalance.combinedElements,
          'lacking_elements': _compatibilityResult!.elementBalance.lackingElements,
          'excessive_elements': _compatibilityResult!.elementBalance.excessiveElements,
          'complementary_elements': _compatibilityResult!.elementBalance.complementaryElements,
          'balance_score': _compatibilityResult!.elementBalance.balanceScore,
        },
        'stem_relations': {
          'combinations': _compatibilityResult!.stemRelations.combinations,
          'score': _compatibilityResult!.stemRelations.score,
        },
        'insights': {
          'summary': _compatibilityResult!.insights.summary,
          'strengths': _compatibilityResult!.insights.strengths,
          'challenges': _compatibilityResult!.insights.challenges,
          'advice': _compatibilityResult!.insights.advice,
        },
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      await supabase.from('compatibility_results').insert(compatibilityPayload);

      debugPrint('✅ [CompatibilityPage] Compatibility result saved successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [CompatibilityPage] Error saving compatibility result: $e');
      debugPrint('❌ [CompatibilityPage] StackTrace: $stackTrace');
      // 저장 실패는 비치명적 (분석 결과는 이미 UI에 표시됨)
    }
  }

  void _analyzeCompatibility() {
    if (!_canAnalyze || _mySajuChart == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isAnalyzing = true);

    // 상대방 사주 계산
    try {
      final calculator = SajuCalculator.instance;
      final birthHour = _partnerSiju?.startHour ?? 12; // 시간 미선택 시 정오
      final birthDateTime = DateTime(
        _partnerBirthDate!.year,
        _partnerBirthDate!.month,
        _partnerBirthDate!.day,
        birthHour,
      );

      _partnerSajuChart = calculator.calculateSajuChart(
        birthDateTime: birthDateTime,
        gender: _partnerGender == 'male' ? '남' : '여',
        isLunar: _partnerIsLunar,
      );

      // 궁합 계산
      _calculateCompatibility();

      // 결과를 DB에 저장
      _saveCompatibilityResult();

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
