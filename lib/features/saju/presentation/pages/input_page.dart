import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../bloc/destiny_bloc.dart';

/// 사주 정보 입력 페이지
class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  DateTime? _birthDate;
  TimeOfDay? _birthTime;
  String _gender = 'male';
  bool _isLunar = false;
  bool _applyYajasi = true;

  // 분석 옵션
  bool _analyzeSaju = true;
  bool _analyzeMbti = true;
  String? _selectedMbti;

  final List<String> _mbtiTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<DestinyBloc, DestinyState>(
      listener: (context, state) {
        if (state is DestinySuccess) {
          // 분석 성공 시 결과 페이지로 이동
          context.go('/result');
        } else if (state is DestinyFailure) {
          // 에러 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('정보 입력'),
        ),
        body: BlocBuilder<DestinyBloc, DestinyState>(
          builder: (context, state) {
            // 분석 중일 때 로딩 표시
            if (state is DestinyAnalyzing) {
              return _buildLoadingScreen(state.message);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 분석 옵션 선택
                  _buildSectionTitle('분석 옵션 선택'),
                  const SizedBox(height: 12),
                  _buildAnalysisOptions(),

                  const SizedBox(height: 32),

                  // 생년월일 (사주 분석 시)
                  if (_analyzeSaju) ...[
                    _buildSectionTitle('생년월일'),
                    const SizedBox(height: 12),
                    _buildDatePicker(),

                    const SizedBox(height: 24),

                    // 출생 시간
                    _buildSectionTitle('출생 시간 (선택)'),
                    const SizedBox(height: 12),
                    _buildTimePicker(),

                    const SizedBox(height: 24),

                    // 성별
                    _buildSectionTitle('성별'),
                    const SizedBox(height: 12),
                    _buildGenderSelector(),

                    const SizedBox(height: 24),

                    // 옵션
                    _buildOptions(),
                  ],

                  // MBTI 선택 (MBTI 분석 시)
                  if (_analyzeMbti) ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('MBTI 유형'),
                    const SizedBox(height: 12),
                    _buildMbtiSelector(),
                  ],

                  const SizedBox(height: 48),

                  // 분석 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProceed ? _startAnalysis : null,
                      child: const Text('분석 시작'),
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

  Widget _buildLoadingScreen(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTypography.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요...',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTypography.titleMedium);
  }

  Widget _buildAnalysisOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('사주 분석'),
            subtitle: const Text('생년월일시 기반 운명 분석'),
            value: _analyzeSaju,
            onChanged: (v) => setState(() => _analyzeSaju = v ?? true),
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('MBTI 분석'),
            subtitle: const Text('현재 성격 유형 분석'),
            value: _analyzeMbti,
            onChanged: (v) => setState(() => _analyzeMbti = v ?? true),
            contentPadding: EdgeInsets.zero,
          ),
          if (_analyzeSaju && _analyzeMbti)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gap 분석 활성화: 선천적 기질 vs 현재 성향 비교',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
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

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _showDatePickerSheet,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: _birthDate != null
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _birthDate != null
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: _birthDate != null
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _birthDate != null ? '생년월일' : '생년월일을 선택하세요',
                    style: AppTypography.caption.copyWith(
                      color: _birthDate != null
                          ? AppColors.textSecondary
                          : AppColors.textTertiary,
                    ),
                  ),
                  if (_birthDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_birthDate!.year}년 ${_birthDate!.month}월 ${_birthDate!.day}일',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePickerSheet() {
    // 임시 날짜 저장용 변수
    DateTime tempDate = _birthDate ?? DateTime(1990, 1, 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

            // CupertinoDatePicker - 연/월/일 휠 선택
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: tempDate,
                minimumYear: 1920,
                maximumYear: DateTime.now().year,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1920, 1, 1),
                onDateTimeChanged: (DateTime newDate) {
                  tempDate = newDate;
                },
                dateOrder: DatePickerDateOrder.ymd, // 년-월-일 순서 (한국식)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              _birthTime != null
                  ? '${_birthTime!.hour.toString().padLeft(2, '0')}:${_birthTime!.minute.toString().padLeft(2, '0')}'
                  : '시간을 선택하세요 (모르면 생략)',
              style: AppTypography.bodyLarge.copyWith(
                color: _birthTime != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderButton('male', '남성', Icons.male),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGenderButton('female', '여성', Icons.female),
        ),
      ],
    );
  }

  Widget _buildGenderButton(String value, String label, IconData icon) {
    final isSelected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('음력으로 입력'),
          value: _isLunar,
          onChanged: (v) => setState(() => _isLunar = v),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('야자시 적용'),
          subtitle: Text(
            '23:00~24:00 출생 시 다음 날로 계산',
            style: AppTypography.caption,
          ),
          value: _applyYajasi,
          onChanged: (v) => setState(() => _applyYajasi = v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildMbtiSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _mbtiTypes.map((mbti) {
        final isSelected = _selectedMbti == mbti;
        return InkWell(
          onTap: () => setState(() => _selectedMbti = mbti),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mbti,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool get _canProceed {
    if (_analyzeSaju && _birthDate == null) return false;
    if (_analyzeMbti && _selectedMbti == null) return false;
    if (!_analyzeSaju && !_analyzeMbti) return false;
    return true;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (time != null) {
      setState(() => _birthTime = time);
    }
  }

  void _startAnalysis() {
    // 생년월일시 조합
    DateTime birthDateTime = _birthDate!;
    if (_birthTime != null) {
      birthDateTime = DateTime(
        _birthDate!.year,
        _birthDate!.month,
        _birthDate!.day,
        _birthTime!.hour,
        _birthTime!.minute,
      );
    }

    // BLoC 이벤트 발송
    context.read<DestinyBloc>().add(
      AnalyzeFortune(
        birthDateTime: birthDateTime,
        isLunar: _isLunar,
        mbtiType: _selectedMbti ?? 'INFP',
        gender: _gender,
        useNightSubhour: _applyYajasi,
      ),
    );
  }
}
