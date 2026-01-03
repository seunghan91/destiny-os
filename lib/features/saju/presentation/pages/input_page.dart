import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../bloc/destiny_bloc.dart';
import '../../../fortune_2026/data/services/fortune_view_access_service.dart';
import '../widgets/siju_picker.dart';
import '../widgets/mbti_dimension_selector.dart';

/// 사주 정보 입력 페이지 - 토스 디자인 시스템 기반
class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> with TickerProviderStateMixin {
  // 입력 데이터
  final TextEditingController _nameController = TextEditingController();
  DateTime? _birthDate;
  int? _selectedSijuIndex;
  Siju? _selectedSiju;
  String _gender = 'male';
  bool _isLunar = false;
  String? _selectedMbti;

  // 분석 옵션
  bool _analyzeSaju = true;
  bool _analyzeMbti = true;

  // 애니메이션
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinyBloc, DestinyState>(
      listener: (context, state) {
        if (state is DestinySuccess) {
          HapticFeedback.heavyImpact();
          FortuneViewAccessService.resetToInitialCredits();
          context.go('/result');
        } else if (state is DestinyFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.errorOf(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundOf(context),
        body: BlocBuilder<DestinyBloc, DestinyState>(
          builder: (context, state) {
            if (state is DestinyAnalyzing) {
              return _buildAnalyzingScreen(state);
            }

            return SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildNameSection(),
                            const SizedBox(height: 24),
                            _buildBirthDateSection(),
                            const SizedBox(height: 24),
                            _buildGenderSection(),
                            const SizedBox(height: 24),
                            _buildBirthTimeSection(),
                            const SizedBox(height: 32),
                            _buildAnalysisOptions(),
                            if (_analyzeMbti) ...[
                              const SizedBox(height: 24),
                              _buildMbtiSection(),
                            ],
                            const SizedBox(height: 40),
                            _buildAnalyzeButton(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/onboarding'),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: AppColors.textPrimaryOf(context),
          ),
          const Spacer(),
          TextButton(
            onPressed: _showInfoDialog,
            child: Text(
              '도움말',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '당신의 운명을\n분석해 드릴게요',
          style: AppTypography.displaySmall.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '생년월일과 MBTI로 2026년 운세를 알아보세요',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildNameSection() {
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
              color: _nameController.text.isNotEmpty
                  ? primary.withValues(alpha: 0.3)
                  : AppColors.borderOf(context),
              width: _nameController.text.isNotEmpty ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _nameController,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '이름을 입력하세요',
              hintStyle: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _nameController.text.isNotEmpty
                      ? primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariantOf(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _nameController.text.isNotEmpty
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
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '결과에 "OOO님의 운세"로 표시됩니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisOptions() {
    final bool showGapBadge = _analyzeSaju && _analyzeMbti;

    final primary = AppColors.primaryOf(context);
    final fire = AppColors.fireOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('분석 옵션'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFilterChip(
              label: '사주 분석',
              emoji: '🔮',
              isSelected: _analyzeSaju,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _analyzeSaju = !_analyzeSaju);
              },
            ),
            const SizedBox(width: 10),
            _buildFilterChip(
              label: 'MBTI',
              emoji: '🧠',
              isSelected: _analyzeMbti,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _analyzeMbti = !_analyzeMbti);
              },
            ),
            if (showGapBadge) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary.withValues(alpha: 0.15),
                      fire.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Gap',
                      style: AppTypography.caption.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = AppColors.primaryOf(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primary : AppColors.borderOf(context),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: 16,
              color: isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9)
                  : AppColors.textTertiaryOf(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthDateSection() {
    final primary = AppColors.primaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('생년월일', isRequired: true),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _birthDate != null
                    ? primary.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
                width: _birthDate != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _birthDate != null
                        ? primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: _birthDate != null
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
                        _birthDate != null
                            ? '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일'
                            : '생년월일을 선택하세요',
                        style: AppTypography.titleMedium.copyWith(
                          color: _birthDate != null
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textSecondaryOf(context),
                          fontWeight: _birthDate != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_birthDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getZodiacInfo(),
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
        if (_birthDate != null) ...[
          const SizedBox(height: 12),
          _buildLunarToggle(),
        ],
      ],
    );
  }

  Widget _buildLunarToggle() {
    final earth = AppColors.earthOf(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _isLunar = !_isLunar);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isLunar
              ? earth.withValues(alpha: 0.1)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLunar
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
                color: _isLunar ? earth : AppColors.textSecondaryOf(context),
                fontWeight: _isLunar ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLunar ? earth : Colors.transparent,
                border: Border.all(
                  color: _isLunar ? earth : AppColors.grey400Of(context),
                  width: 2,
                ),
              ),
              child: _isLunar
                  ? const Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthTimeSection() {
    final wood = AppColors.woodOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('출생 시간', subtitle: '모르면 생략 가능'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showTimePicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedSiju != null
                    ? wood.withValues(alpha: 0.3)
                    : AppColors.borderOf(context),
                width: _selectedSiju != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedSiju != null
                        ? wood.withValues(alpha: 0.1)
                        : AppColors.surfaceVariantOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _selectedSiju != null
                        ? Text(
                            _selectedSiju!.emoji,
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
                        _selectedSiju != null
                            ? '${_selectedSiju!.name} (${_selectedSiju!.hanja}時)'
                            : '출생 시간을 선택하세요',
                        style: AppTypography.titleMedium.copyWith(
                          color: _selectedSiju != null
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textSecondaryOf(context),
                          fontWeight: _selectedSiju != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_selectedSiju != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedSiju!.timeRange,
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

  Widget _buildGenderSection() {
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
              child: _buildGenderButton(
                value: 'male',
                label: '남성',
                icon: Icons.male_rounded,
                color: primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderButton(
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

  Widget _buildGenderButton({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _gender == value;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _gender = value);
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

  Widget _buildMbtiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('MBTI', subtitle: 'Gap 분석에 사용됩니다'),
        const SizedBox(height: 8),
        Text(
          '각 차원에서 자신에게 맞는 유형을 선택하세요',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
        ),
        const SizedBox(height: 16),
        // 인라인 차원 선택기 (4x2 타일 형식)
        MbtiDimensionSelector(
          initialType: _selectedMbti,
          onTypeSelected: (type) {
            setState(() => _selectedMbti = type);
          },
        ),
      ],
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

  Widget _buildAnalyzeButton() {
    final canProceed =
        _birthDate != null &&
        (_analyzeSaju || (_analyzeMbti && _selectedMbti != null));

    final primary = AppColors.primaryOf(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canProceed ? _startAnalysis : null,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 20),
                const SizedBox(width: 8),
                Text(
                  '2026년 운세 분석하기',
                  style: AppTypography.labelLarge.copyWith(
                    color: canProceed
                        ? Theme.of(context).colorScheme.onPrimary
                        : AppColors.textTertiaryOf(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '입력된 정보는 분석에만 사용되며 저장되지 않습니다',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyzingScreen(DestinyAnalyzing state) {
    final primary = AppColors.primaryOf(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.05),
            AppColors.backgroundOf(context),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingController.value * 2 * 3.14159,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.fireOf(context),
                              AppColors.earthOf(context),
                              AppColors.woodOf(context),
                              AppColors.waterOf(context),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundOf(context),
                            ),
                            child: Center(
                              child: Text(
                                '命',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  state.message,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '천간과 지지의 조화를 분석하고 있어요',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.grey200Of(context),
                    valueColor: AlwaysStoppedAnimation(primary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getZodiacInfo() {
    if (_birthDate == null) return '';
    final year = _birthDate!.year;
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

  void _showDatePicker() {
    HapticFeedback.selectionClick();

    // 웹이나 데스크톱에서는 Material DatePicker 사용
    if (kIsWeb || _isDesktopPlatform()) {
      _showMaterialDatePicker();
    } else {
      // 모바일에서는 CupertinoDatePicker 사용
      _showCupertinoDatePicker();
    }
  }

  bool _isDesktopPlatform() {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  Future<void> _showMaterialDatePicker() async {
    // 웹에서는 커스텀 DatePicker를 사용하여 더 쉬운 월 선택 제공
    _showCustomWebDatePicker();
  }

  void _showCustomWebDatePicker() {
    final DateTime initialDate = _birthDate ?? DateTime(1990, 1, 1);
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    // 100세 시대 대응: 1900년부터 현재까지 (126세 커버)
    const int minYear = 1900;
    final DateTime now = DateTime.now(); // 성능: DateTime.now() 한 번만 호출
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
            // 선택된 날짜가 해당 월의 일수를 초과하면 조정
            if (selectedDay > days.length) {
              selectedDay = days.length;
            }

            final primary = Theme.of(context).colorScheme.primary;
            final surface = Theme.of(context).colorScheme.surface;
            final surfaceVariant = Theme.of(context).colorScheme.surfaceContainerHighest;

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
                    // 연도/월/일 선택 Row
                    Row(
                      children: [
                        // 연도 선택
                        Expanded(
                          flex: 3,
                          child: _buildDropdownField(
                            label: '연도',
                            value: selectedYear,
                            items: years.reversed.toList(),
                            itemLabel: (year) => '$year년',
                            onChanged: (value) {
                              setDialogState(() {
                                selectedYear = value!;
                                // 미래 날짜 방지
                                if (selectedYear == currentYear &&
                                    selectedMonth > currentMonth) {
                                  selectedMonth = currentMonth;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 월 선택
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField(
                            label: '월',
                            value: selectedMonth,
                            items: months.where((m) {
                              // 현재 연도면 현재 월까지만
                              if (selectedYear == currentYear) {
                                return m <= currentMonth;
                              }
                              return true;
                            }).toList(),
                            itemLabel: (month) => '$month월',
                            onChanged: (value) {
                              setDialogState(() {
                                selectedMonth = value!;
                                // 미래 날짜 방지
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
                        // 일 선택
                        Expanded(
                          flex: 2,
                          child: _buildDropdownField(
                            label: '일',
                            value: selectedDay,
                            items: days.where((d) {
                              // 현재 연도, 현재 월이면 현재 일까지만
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
                    // 선택된 날짜 표시
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
                    setState(() => _birthDate = selectedDate);
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
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final border = AppColors.borderOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondaryOf(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondaryOf(context),
                size: 20,
              ),
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              dropdownColor: AppColors.surfaceOf(context),
              menuMaxHeight: 300,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoDatePicker() {
    DateTime tempDate = _birthDate ?? DateTime(1990, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderOf(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '취소',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                  Text(
                    '생년월일 선택',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _birthDate = tempDate);
                      Navigator.pop(context);
                    },
                    child: Text(
                      '확인',
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumYear: 1900, // 100세 시대 대응 (126세 커버)
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
    );
  }

  void _showTimePicker() {
    HapticFeedback.selectionClick();
    SijuPickerBottomSheet.show(
      context,
      initialIndex: _selectedSijuIndex,
      onSelected: (index, siju) {
        setState(() {
          _selectedSijuIndex = index;
          _selectedSiju = siju;
        });
      },
    );
  }

  void _showInfoDialog() {
    int secretTapCount = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('입력 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('📅', '생년월일', '양력 기준으로 입력해주세요. 음력인 경우 토글을 켜세요.'),
            const SizedBox(height: 12),
            _buildInfoItem('🕐', '출생 시간', '정확한 시간을 모르면 생략해도 됩니다.'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                secretTapCount++;
                if (secretTapCount >= 5) {
                  Navigator.pop(context);
                  context.push('/admin');
                  secretTapCount = 0;
                }
              },
              child: _buildInfoItem('🧠', 'MBTI', '사주와 MBTI의 Gap 분석에 사용됩니다.'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                desc,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startAnalysis() {
    HapticFeedback.mediumImpact();

    if (_birthDate == null) return;
    if (_analyzeMbti && _selectedMbti == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('MBTI를 선택해 주세요'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    DateTime birthDateTime = _birthDate!;
    int birthHour = 12; // 기본값: 정오
    if (_selectedSiju != null) {
      birthHour = (_selectedSiju!.startHour + 1) % 24;
      birthDateTime = DateTime(
        _birthDate!.year,
        _birthDate!.month,
        _birthDate!.day,
        birthHour,
        0,
      );
    }

    // 로그인된 사용자의 경우 사주 정보를 Supabase에 저장
    _saveSajuInfoIfLoggedIn(birthHour);

    context.read<DestinyBloc>().add(
      AnalyzeFortune(
        birthDateTime: birthDateTime,
        isLunar: _isLunar,
        mbtiType: _selectedMbti!,
        gender: _gender,
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        useNightSubhour: true,
      ),
    );
  }

  /// 로그인된 사용자의 사주 정보를 Supabase에 저장
  Future<void> _saveSajuInfoIfLoggedIn(int birthHour) async {
    final authManager = AuthManager();

    if (!authManager.isAuthenticated || _birthDate == null) return;

    try {
      await authManager.saveSajuInfo(
        birthDate: _birthDate!,
        birthHour: birthHour,
        gender: _gender,
        isLunar: _isLunar,
        mbti: _selectedMbti,
      );
      debugPrint('✅ 사주 정보가 Supabase에 저장되었습니다.');
    } catch (e) {
      debugPrint('⚠️ 사주 정보 저장 실패: $e');
      // 저장 실패해도 분석은 계속 진행
    }
  }
}
