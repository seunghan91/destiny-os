import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../bloc/destiny_bloc.dart';
import '../widgets/siju_picker.dart';
import '../widgets/mbti_grid_selector.dart';

/// 사주 정보 입력 페이지 - 토스 디자인 시스템 기반
class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> with TickerProviderStateMixin {
  // 입력 데이터
  DateTime? _birthDate;
  int? _selectedSijuIndex;
  Siju? _selectedSiju;
  String _gender = 'male';
  bool _isLunar = false;
  String? _selectedMbti;

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
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinyBloc, DestinyState>(
      listener: (context, state) {
        if (state is DestinySuccess) {
          HapticFeedback.heavyImpact();
          context.go('/result');
        } else if (state is DestinyFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                            _buildBirthDateSection(),
                            const SizedBox(height: 24),
                            _buildBirthTimeSection(),
                            const SizedBox(height: 24),
                            _buildGenderSection(),
                            const SizedBox(height: 24),
                            _buildLunarOption(),
                            const SizedBox(height: 32),
                            _buildMbtiSection(),
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
            color: AppColors.textPrimary,
          ),
          const Spacer(),
          TextButton(
            onPressed: _showInfoDialog,
            child: Text(
              '도움말',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
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
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateSection() {
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _birthDate != null
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
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
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: _birthDate != null
                        ? AppColors.primary
                        : AppColors.textTertiary,
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
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
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
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthTimeSection() {
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedSiju != null
                    ? AppColors.wood.withValues(alpha: 0.3)
                    : AppColors.border,
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
                        ? AppColors.wood.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
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
                            color: AppColors.textTertiary,
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
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: _selectedSiju != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_selectedSiju != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedSiju!.timeRange,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.wood,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSection() {
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
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderButton(
                value: 'female',
                label: '여성',
                icon: Icons.female_rounded,
                color: AppColors.fire,
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
          color: isSelected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
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
              color: isSelected ? AppColors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLunarOption() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.earth.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('🌙', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '음력으로 입력',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '생년월일이 음력이면 켜세요',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isLunar,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _isLunar = v);
            },
            activeTrackColor: AppColors.primary,
            activeThumbColor: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMbtiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('MBTI', subtitle: 'Gap 분석에 사용됩니다'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showMbtiPicker,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedMbti != null
                    ? _getMbtiColor().withValues(alpha: 0.3)
                    : AppColors.border,
                width: _selectedMbti != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _selectedMbti != null
                        ? _getMbtiColor().withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _selectedMbti != null
                        ? Text(
                            _getMbtiEmoji(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : Icon(
                            Icons.psychology_outlined,
                            color: AppColors.textTertiary,
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
                        _selectedMbti ?? 'MBTI를 선택하세요',
                        style: AppTypography.titleMedium.copyWith(
                          color: _selectedMbti != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                          fontWeight: _selectedMbti != null
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (_selectedMbti != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _getMbtiNickname(),
                          style: AppTypography.bodySmall.copyWith(
                            color: _getMbtiColor(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
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
              color: AppColors.fire,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    final canProceed = _birthDate != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canProceed ? _startAnalysis : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.grey300,
              foregroundColor: AppColors.white,
              disabledForegroundColor: AppColors.textTertiary,
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
                    color: canProceed ? AppColors.white : AppColors.textTertiary,
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
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAnalyzingScreen(DestinyAnalyzing state) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            AppColors.background,
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
                // 애니메이션 로고
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
                              AppColors.fire,
                              AppColors.earth,
                              AppColors.wood,
                              AppColors.water,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.background,
                            ),
                            child: const Center(
                              child: Text(
                                '命',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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

                // 분석 메시지
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
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 프로그레스
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
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

  // 헬퍼 메서드들
  String _getZodiacInfo() {
    if (_birthDate == null) return '';
    final year = _birthDate!.year;
    final animals = ['🐭쥐', '🐮소', '🐯호랑이', '🐰토끼', '🐲용', '🐍뱀',
                     '🐴말', '🐑양', '🐵원숭이', '🐔닭', '🐶개', '🐷돼지'];
    final index = (year - 4) % 12;
    return '${animals[index]}띠';
  }

  Color _getMbtiColor() {
    if (_selectedMbti == null) return AppColors.grey400;
    if (['INTJ', 'INTP', 'ENTJ', 'ENTP'].contains(_selectedMbti)) {
      return const Color(0xFF7C3AED);
    }
    if (['INFJ', 'INFP', 'ENFJ', 'ENFP'].contains(_selectedMbti)) {
      return const Color(0xFF059669);
    }
    if (['ISTJ', 'ISFJ', 'ESTJ', 'ESFJ'].contains(_selectedMbti)) {
      return const Color(0xFF0284C7);
    }
    return const Color(0xFFDC2626);
  }

  String _getMbtiEmoji() {
    final emojis = {
      'INTJ': '🧠', 'INTP': '🔬', 'ENTJ': '👑', 'ENTP': '💡',
      'INFJ': '🌟', 'INFP': '🦋', 'ENFJ': '🌈', 'ENFP': '✨',
      'ISTJ': '📊', 'ISFJ': '🛡️', 'ESTJ': '📋', 'ESFJ': '🤝',
      'ISTP': '🛠️', 'ISFP': '🎨', 'ESTP': '🚀', 'ESFP': '🎭',
    };
    return emojis[_selectedMbti] ?? '🔮';
  }

  String _getMbtiNickname() {
    final nicknames = {
      'INTJ': '전략가', 'INTP': '논리술사', 'ENTJ': '통솔자', 'ENTP': '변론가',
      'INFJ': '옹호자', 'INFP': '중재자', 'ENFJ': '선도자', 'ENFP': '활동가',
      'ISTJ': '현실주의자', 'ISFJ': '수호자', 'ESTJ': '경영자', 'ESFJ': '집정관',
      'ISTP': '장인', 'ISFP': '모험가', 'ESTP': '사업가', 'ESFP': '연예인',
    };
    return nicknames[_selectedMbti] ?? '';
  }

  // 다이얼로그/피커
  void _showDatePicker() {
    HapticFeedback.selectionClick();
    DateTime tempDate = _birthDate ?? DateTime(1990, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
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
                        color: AppColors.textSecondary,
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
                        color: AppColors.primary,
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
                minimumYear: 1920,
                maximumYear: DateTime.now().year,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1920, 1, 1),
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

  void _showMbtiPicker() {
    HapticFeedback.selectionClick();
    MbtiSelectorBottomSheet.show(
      context,
      initialType: _selectedMbti,
      onSelected: (type) {
        setState(() => _selectedMbti = type);
      },
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('입력 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('📅', '생년월일', '양력 기준으로 입력해주세요. 음력인 경우 토글을 켜세요.'),
            const SizedBox(height: 12),
            _buildInfoItem('🕐', '출생 시간', '정확한 시간을 모르면 생략해도 됩니다.'),
            const SizedBox(height: 12),
            _buildInfoItem('🧠', 'MBTI', '사주와 MBTI의 Gap 분석에 사용됩니다.'),
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
                  color: AppColors.textSecondary,
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

    DateTime birthDateTime = _birthDate!;
    if (_selectedSiju != null) {
      final hour = (_selectedSiju!.startHour + 1) % 24;
      birthDateTime = DateTime(
        _birthDate!.year,
        _birthDate!.month,
        _birthDate!.day,
        hour,
        0,
      );
    }

    context.read<DestinyBloc>().add(
      AnalyzeFortune(
        birthDateTime: birthDateTime,
        isLunar: _isLunar,
        mbtiType: _selectedMbti ?? 'INFP',
        gender: _gender,
        useNightSubhour: true,
      ),
    );
  }
}
