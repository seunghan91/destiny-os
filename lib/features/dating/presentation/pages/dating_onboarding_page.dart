import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../data/services/dating_service.dart';

/// MBTI 소개팅 온보딩 (추가 정보 입력) 페이지
class DatingOnboardingPage extends StatefulWidget {
  const DatingOnboardingPage({super.key});

  @override
  State<DatingOnboardingPage> createState() => _DatingOnboardingPageState();
}

class _DatingOnboardingPageState extends State<DatingOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  // 기본 정보
  int? _birthYear;
  String? _gender;
  String? _mbti;

  // 추가 정보
  final _jobController = TextEditingController();
  int? _height;
  final _bioController = TextEditingController();
  List<String> _selectedKeywords = [];

  // 선호도
  List<String> _targetMbti = [];
  int _ageMin = 25;
  int _ageMax = 35;

  bool _isLoading = false;
  bool _isSubmitting = false;

  static const List<String> _allMbtiTypes = [
    'INTJ',
    'INTP',
    'ENTJ',
    'ENTP',
    'INFJ',
    'INFP',
    'ENFJ',
    'ENFP',
    'ISTJ',
    'ISFJ',
    'ESTJ',
    'ESFJ',
    'ISTP',
    'ISFP',
    'ESTP',
    'ESFP',
  ];

  static const List<String> _availableKeywords = [
    '여행',
    '운동',
    '음악',
    '영화',
    '독서',
    '게임',
    '요리',
    '카페',
    '반려동물',
    '사진',
    'IT/개발',
    '투자',
    '패션',
    '맛집탐방',
    '등산',
    '캠핑',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    _jobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);

    // 기존 사주 분석 데이터에서 기본값 가져오기
    final destinyState = context.read<DestinyBloc>().state;
    if (destinyState is DestinySuccess) {
      final userInfo = destinyState.userInfo;
      _birthYear = userInfo.birthDate.year;
      _gender = userInfo.gender;
      _mbti = destinyState.mbtiType.type;
    }

    // 기존 AuthManager 프로필에서 추가 정보 가져오기
    final userProfile = AuthManager().userProfile;
    if (userProfile != null) {
      _birthYear ??= userProfile.birthDate?.year;
      _gender ??= userProfile.gender;
      _mbti ??= userProfile.mbti;
    }

    // 기존 소개팅 프로필이 있으면 로드
    final existingProfile = await DatingService.getProfile();
    if (existingProfile != null) {
      _birthYear = existingProfile.birthYear;
      _gender = existingProfile.gender;
      _mbti = existingProfile.mbti;
      _jobController.text = existingProfile.job ?? '';
      _height = existingProfile.height;
      _bioController.text = existingProfile.bio ?? '';
      _selectedKeywords = List.from(existingProfile.keywords);
    }

    // 기존 선호도 로드
    final existingPrefs = await DatingService.getPreferences();
    if (existingPrefs != null) {
      _targetMbti = List.from(existingPrefs.targetMbti);
      _ageMin = existingPrefs.ageMin;
      _ageMax = existingPrefs.ageMax;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthYear == null || _gender == null || _mbti == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필수 정보를 입력해주세요')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 프로필 저장
      await DatingService.upsertProfile(
        birthYear: _birthYear!,
        gender: _gender!,
        mbti: _mbti!,
        job: _jobController.text.isNotEmpty ? _jobController.text : null,
        height: _height,
        keywords: _selectedKeywords,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      // 선호도 저장
      await DatingService.upsertPreferences(
        targetMbti: _targetMbti,
        ageMin: _ageMin,
        ageMax: _ageMax,
      );

      if (!mounted) return;

      // 추천 페이지로 이동
      context.go('/dating');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('MBTI 소개팅'),
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 헤더
                    Text(
                      '프로필 설정',
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '더 정확한 매칭을 위해 정보를 입력해주세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 기본 정보 섹션
                    _buildSectionTitle('기본 정보', Icons.person_outline),
                    const SizedBox(height: 12),

                    // 출생년도
                    _buildDropdownField(
                      label: '출생년도',
                      value: _birthYear?.toString(),
                      items: List.generate(
                        50,
                        (i) => (DateTime.now().year - 18 - i).toString(),
                      ),
                      onChanged: (v) =>
                          setState(() => _birthYear = int.tryParse(v ?? '')),
                    ),
                    const SizedBox(height: 12),

                    // 성별
                    _buildDropdownField(
                      label: '성별',
                      value: _gender,
                      items: const ['male', 'female'],
                      itemLabels: const {'male': '남성', 'female': '여성'},
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                    const SizedBox(height: 12),

                    // MBTI
                    _buildDropdownField(
                      label: 'MBTI',
                      value: _mbti,
                      items: _allMbtiTypes,
                      onChanged: (v) => setState(() => _mbti = v),
                    ),
                    const SizedBox(height: 24),

                    // 추가 정보 섹션
                    _buildSectionTitle('추가 정보 (선택)', Icons.edit_note),
                    const SizedBox(height: 12),

                    // 직업
                    TextFormField(
                      controller: _jobController,
                      decoration: _inputDecoration('직업'),
                    ),
                    const SizedBox(height: 12),

                    // 키
                    _buildDropdownField(
                      label: '키 (cm)',
                      value: _height?.toString(),
                      items: List.generate(61, (i) => (140 + i).toString()),
                      onChanged: (v) =>
                          setState(() => _height = int.tryParse(v ?? '')),
                    ),
                    const SizedBox(height: 12),

                    // 관심사
                    Text(
                      '관심사 (최대 5개)',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableKeywords.map((keyword) {
                        final isSelected = _selectedKeywords.contains(keyword);
                        return FilterChip(
                          label: Text(keyword),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected && _selectedKeywords.length < 5) {
                                _selectedKeywords.add(keyword);
                              } else {
                                _selectedKeywords.remove(keyword);
                              }
                            });
                          },
                          selectedColor: primary.withAlpha(40),
                          checkmarkColor: primary,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // 자기소개
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: _inputDecoration('자기소개'),
                    ),
                    const SizedBox(height: 24),

                    // 선호도 섹션
                    _buildSectionTitle('원하는 상대', Icons.favorite_border),
                    const SizedBox(height: 12),

                    // 원하는 MBTI
                    Text(
                      '원하는 MBTI (복수 선택 가능)',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allMbtiTypes.map((mbti) {
                        final isSelected = _targetMbti.contains(mbti);
                        return FilterChip(
                          label: Text(mbti),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _targetMbti.add(mbti);
                              } else {
                                _targetMbti.remove(mbti);
                              }
                            });
                          },
                          selectedColor: primary.withAlpha(40),
                          checkmarkColor: primary,
                        );
                      }).toList(),
                    ),
                    if (_targetMbti.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '선택하지 않으면 모든 MBTI가 추천됩니다',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiaryOf(context),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // 나이대
                    Text(
                      '원하는 나이대: ${_ageMin}세 ~ ${_ageMax}세',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                        _ageMin.toDouble(),
                        _ageMax.toDouble(),
                      ),
                      min: 20,
                      max: 60,
                      divisions: 40,
                      labels: RangeLabels('${_ageMin}세', '${_ageMax}세'),
                      onChanged: (values) {
                        setState(() {
                          _ageMin = values.start.round();
                          _ageMax = values.end.round();
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? '저장 중...' : '프로필 저장하고 시작하기',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryOf(context)),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      decoration: _inputDecoration(label),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(itemLabels?[item] ?? item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceOf(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.borderOf(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryOf(context), width: 2),
      ),
    );
  }
}
