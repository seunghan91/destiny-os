import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

/// MBTI 유형 데이터
class MbtiType {
  final String type;
  final String nickname;
  final String description;
  final Color color;
  final String emoji;

  const MbtiType({
    required this.type,
    required this.nickname,
    required this.description,
    required this.color,
    required this.emoji,
  });
}

/// MBTI 16 유형 데이터
const Map<String, List<MbtiType>> mbtiGroups = {
  '분석가형 (NT)': [
    MbtiType(type: 'INTJ', nickname: '전략가', description: '독창적인 전략가', color: Color(0xFF7C3AED), emoji: '🧠'),
    MbtiType(type: 'INTP', nickname: '논리술사', description: '혁신적인 발명가', color: Color(0xFF7C3AED), emoji: '🔬'),
    MbtiType(type: 'ENTJ', nickname: '통솔자', description: '대담한 리더', color: Color(0xFF7C3AED), emoji: '👑'),
    MbtiType(type: 'ENTP', nickname: '변론가', description: '논쟁을 즐기는 발명가', color: Color(0xFF7C3AED), emoji: '💡'),
  ],
  '외교관형 (NF)': [
    MbtiType(type: 'INFJ', nickname: '옹호자', description: '조용하고 신비로운', color: Color(0xFF059669), emoji: '🌟'),
    MbtiType(type: 'INFP', nickname: '중재자', description: '이상주의적 치유자', color: Color(0xFF059669), emoji: '🦋'),
    MbtiType(type: 'ENFJ', nickname: '선도자', description: '카리스마 넘치는', color: Color(0xFF059669), emoji: '🌈'),
    MbtiType(type: 'ENFP', nickname: '활동가', description: '열정적인 탐험가', color: Color(0xFF059669), emoji: '✨'),
  ],
  '관리자형 (SJ)': [
    MbtiType(type: 'ISTJ', nickname: '현실주의자', description: '신뢰할 수 있는', color: Color(0xFF0284C7), emoji: '📊'),
    MbtiType(type: 'ISFJ', nickname: '수호자', description: '헌신적인 보호자', color: Color(0xFF0284C7), emoji: '🛡️'),
    MbtiType(type: 'ESTJ', nickname: '경영자', description: '체계적인 관리자', color: Color(0xFF0284C7), emoji: '📋'),
    MbtiType(type: 'ESFJ', nickname: '집정관', description: '친절한 협력자', color: Color(0xFF0284C7), emoji: '🤝'),
  ],
  '탐험가형 (SP)': [
    MbtiType(type: 'ISTP', nickname: '장인', description: '대담한 탐험가', color: Color(0xFFDC2626), emoji: '🛠️'),
    MbtiType(type: 'ISFP', nickname: '모험가', description: '유연한 예술가', color: Color(0xFFDC2626), emoji: '🎨'),
    MbtiType(type: 'ESTP', nickname: '사업가', description: '영리한 행동가', color: Color(0xFFDC2626), emoji: '🚀'),
    MbtiType(type: 'ESFP', nickname: '연예인', description: '즉흥적인 연예인', color: Color(0xFFDC2626), emoji: '🎭'),
  ],
};

/// MBTI 그리드 선택 위젯
class MbtiGridSelector extends StatelessWidget {
  const MbtiGridSelector({
    super.key,
    this.selectedType,
    required this.onSelected,
    this.compact = false,
  });

  final String? selectedType;
  final Function(String type, MbtiType mbti) onSelected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mbtiGroups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                entry.key,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: compact ? 4 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: compact ? 1.3 : 2.2,
              ),
              itemCount: entry.value.length,
              itemBuilder: (context, index) {
                final mbti = entry.value[index];
                final isSelected = selectedType == mbti.type;

                return compact
                    ? _CompactMbtiCard(
                        mbti: mbti,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(mbti.type, mbti);
                        },
                      )
                    : _MbtiCard(
                        mbti: mbti,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onSelected(mbti.type, mbti);
                        },
                      );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }
}

class _MbtiCard extends StatelessWidget {
  const _MbtiCard({
    required this.mbti,
    required this.isSelected,
    required this.onTap,
  });

  final MbtiType mbti;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? mbti.color : AppColors.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: mbti.color, width: 2)
              : Border.all(color: AppColors.borderOf(context), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mbti.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              mbti.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mbti.type,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.textPrimaryOf(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mbti.nickname,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.9)
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactMbtiCard extends StatelessWidget {
  const _CompactMbtiCard({
    required this.mbti,
    required this.isSelected,
    required this.onTap,
  });

  final MbtiType mbti;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? mbti.color : AppColors.surfaceVariantOf(context),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: mbti.color, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mbti.emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              mbti.type,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.white
                    : AppColors.textPrimaryOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// MBTI 선택 바텀시트
class MbtiSelectorBottomSheet extends StatefulWidget {
  const MbtiSelectorBottomSheet({
    super.key,
    this.initialType,
    required this.onSelected,
  });

  final String? initialType;
  final Function(String type) onSelected;

  static Future<void> show(
    BuildContext context, {
    String? initialType,
    required Function(String type) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MbtiSelectorBottomSheet(
        initialType: initialType,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<MbtiSelectorBottomSheet> createState() =>
      _MbtiSelectorBottomSheetState();
}

class _MbtiSelectorBottomSheetState extends State<MbtiSelectorBottomSheet> {
  String? _selectedType;
  MbtiType? _selectedMbti;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    if (_selectedType != null) {
      // Find the MbtiType for the initial type
      for (final group in mbtiGroups.values) {
        for (final mbti in group) {
          if (mbti.type == _selectedType) {
            _selectedMbti = mbti;
            break;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300Of(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 헤더
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
                      'MBTI 선택',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _selectedType != null
                          ? () {
                              HapticFeedback.mediumImpact();
                              widget.onSelected(_selectedType!);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Text(
                        '확인',
                        style: AppTypography.bodyLarge.copyWith(
                          color: _selectedType != null
                              ? AppColors.primaryOf(context)
                              : AppColors.textTertiaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // MBTI 그리드
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 선택된 MBTI 프리뷰
                      if (_selectedMbti != null) ...[
                        _buildSelectedPreview(),
                        const SizedBox(height: 24),
                      ],

                      // MBTI 그리드
                      MbtiGridSelector(
                        selectedType: _selectedType,
                        onSelected: (type, mbti) {
                          setState(() {
                            _selectedType = type;
                            _selectedMbti = mbti;
                          });
                        },
                      ),

                      // 모르겠어요 버튼
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'MBTI를 모르겠어요',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiaryOf(context),
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
      },
    );
  }

  Widget _buildSelectedPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedMbti!.color.withValues(alpha: 0.15),
            _selectedMbti!.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedMbti!.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _selectedMbti!.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _selectedMbti!.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedMbti!.type,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _selectedMbti!.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedMbti!.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedMbti!.nickname,
                        style: AppTypography.labelSmall.copyWith(
                          color: _selectedMbti!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMbti!.description,
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
}
