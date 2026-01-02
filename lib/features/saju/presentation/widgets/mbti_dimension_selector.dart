import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

/// MBTI 차원 데이터
class MbtiDimension {
  final String left;
  final String right;
  final String leftLabel;
  final String rightLabel;
  final String leftDescription;
  final String rightDescription;
  final IconData leftIcon;
  final IconData rightIcon;

  const MbtiDimension({
    required this.left,
    required this.right,
    required this.leftLabel,
    required this.rightLabel,
    required this.leftDescription,
    required this.rightDescription,
    required this.leftIcon,
    required this.rightIcon,
  });
}

/// MBTI 4가지 차원 정의
const List<MbtiDimension> mbtiDimensions = [
  MbtiDimension(
    left: 'E',
    right: 'I',
    leftLabel: '외향형',
    rightLabel: '내향형',
    leftDescription: '사람들과 어울리며 에너지를 얻어요',
    rightDescription: '혼자만의 시간에서 에너지를 얻어요',
    leftIcon: Icons.groups_outlined,
    rightIcon: Icons.person_outline,
  ),
  MbtiDimension(
    left: 'S',
    right: 'N',
    leftLabel: '감각형',
    rightLabel: '직관형',
    leftDescription: '현실적이고 구체적인 것을 선호해요',
    rightDescription: '가능성과 미래 지향적인 것을 선호해요',
    leftIcon: Icons.touch_app_outlined,
    rightIcon: Icons.lightbulb_outline,
  ),
  MbtiDimension(
    left: 'T',
    right: 'F',
    leftLabel: '사고형',
    rightLabel: '감정형',
    leftDescription: '논리와 객관적 분석으로 결정해요',
    rightDescription: '감정과 가치관을 기반으로 결정해요',
    leftIcon: Icons.psychology_outlined,
    rightIcon: Icons.favorite_outline,
  ),
  MbtiDimension(
    left: 'J',
    right: 'P',
    leftLabel: '판단형',
    rightLabel: '인식형',
    leftDescription: '계획적이고 체계적인 것을 선호해요',
    rightDescription: '유연하고 자유로운 것을 선호해요',
    leftIcon: Icons.checklist_outlined,
    rightIcon: Icons.explore_outlined,
  ),
];

/// MBTI 유형별 닉네임과 설명
const Map<String, Map<String, dynamic>> mbtiTypeInfo = {
  'INTJ': {
    'nickname': '전략가',
    'emoji': '🧠',
    'description': '독창적인 전략가',
    'color': 0xFF7C3AED,
  },
  'INTP': {
    'nickname': '논리술사',
    'emoji': '🔬',
    'description': '혁신적인 발명가',
    'color': 0xFF7C3AED,
  },
  'ENTJ': {
    'nickname': '통솔자',
    'emoji': '👑',
    'description': '대담한 리더',
    'color': 0xFF7C3AED,
  },
  'ENTP': {
    'nickname': '변론가',
    'emoji': '💡',
    'description': '논쟁을 즐기는 발명가',
    'color': 0xFF7C3AED,
  },
  'INFJ': {
    'nickname': '옹호자',
    'emoji': '🌟',
    'description': '조용하고 신비로운',
    'color': 0xFF059669,
  },
  'INFP': {
    'nickname': '중재자',
    'emoji': '🦋',
    'description': '이상주의적 치유자',
    'color': 0xFF059669,
  },
  'ENFJ': {
    'nickname': '선도자',
    'emoji': '🌈',
    'description': '카리스마 넘치는',
    'color': 0xFF059669,
  },
  'ENFP': {
    'nickname': '활동가',
    'emoji': '✨',
    'description': '열정적인 탐험가',
    'color': 0xFF059669,
  },
  'ISTJ': {
    'nickname': '현실주의자',
    'emoji': '📊',
    'description': '신뢰할 수 있는',
    'color': 0xFF0284C7,
  },
  'ISFJ': {
    'nickname': '수호자',
    'emoji': '🛡️',
    'description': '헌신적인 보호자',
    'color': 0xFF0284C7,
  },
  'ESTJ': {
    'nickname': '경영자',
    'emoji': '📋',
    'description': '체계적인 관리자',
    'color': 0xFF0284C7,
  },
  'ESFJ': {
    'nickname': '집정관',
    'emoji': '🤝',
    'description': '친절한 협력자',
    'color': 0xFF0284C7,
  },
  'ISTP': {
    'nickname': '장인',
    'emoji': '🛠️',
    'description': '대담한 탐험가',
    'color': 0xFFDC2626,
  },
  'ISFP': {
    'nickname': '모험가',
    'emoji': '🎨',
    'description': '유연한 예술가',
    'color': 0xFFDC2626,
  },
  'ESTP': {
    'nickname': '사업가',
    'emoji': '🚀',
    'description': '영리한 행동가',
    'color': 0xFFDC2626,
  },
  'ESFP': {
    'nickname': '연예인',
    'emoji': '🎭',
    'description': '즉흥적인 연예인',
    'color': 0xFFDC2626,
  },
};

/// MBTI 차원 선택 위젯 (4x2 타일 형식)
class MbtiDimensionSelector extends StatefulWidget {
  const MbtiDimensionSelector({
    super.key,
    this.initialType,
    required this.onTypeSelected,
  });

  final String? initialType;
  final Function(String type) onTypeSelected;

  @override
  State<MbtiDimensionSelector> createState() => _MbtiDimensionSelectorState();
}

class _MbtiDimensionSelectorState extends State<MbtiDimensionSelector> {
  // 각 차원별 선택 상태 (null = 미선택, true = left, false = right)
  final List<bool?> _selections = [null, null, null, null];

  @override
  void initState() {
    super.initState();
    _initializeFromType(widget.initialType);
  }

  @override
  void didUpdateWidget(MbtiDimensionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialType != oldWidget.initialType) {
      setState(() {
        _initializeFromType(widget.initialType);
      });
    }
  }

  void _initializeFromType(String? type) {
    if (type == null || type.length != 4) return;

    final chars = type.toUpperCase().split('');
    _selections[0] = chars[0] == 'E'; // E = true, I = false
    _selections[1] = chars[1] == 'S'; // S = true, N = false
    _selections[2] = chars[2] == 'T'; // T = true, F = false
    _selections[3] = chars[3] == 'J'; // J = true, P = false
  }

  String? get _currentType {
    if (_selections.any((s) => s == null)) return null;

    return [
      _selections[0]! ? 'E' : 'I',
      _selections[1]! ? 'S' : 'N',
      _selections[2]! ? 'T' : 'F',
      _selections[3]! ? 'J' : 'P',
    ].join();
  }

  void _selectDimension(int index, bool isLeft) {
    HapticFeedback.selectionClick();
    setState(() {
      _selections[index] = isLeft;
    });

    final type = _currentType;
    if (type != null) {
      widget.onTypeSelected(type);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _currentType;
    final typeInfo = currentType != null ? mbtiTypeInfo[currentType] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4개 차원 선택 그리드
        ...List.generate(mbtiDimensions.length, (index) {
          final dimension = mbtiDimensions[index];
          final selection = _selections[index];

          return Padding(
            padding: EdgeInsets.only(bottom: index < 3 ? 12 : 0),
            child: _DimensionRow(
              dimension: dimension,
              selection: selection,
              onSelectLeft: () => _selectDimension(index, true),
              onSelectRight: () => _selectDimension(index, false),
            ),
          );
        }),

        // 결과 표시
        if (currentType != null && typeInfo != null) ...[
          const SizedBox(height: 20),
          _MbtiResultCard(
            type: currentType,
            nickname: typeInfo['nickname'] as String,
            emoji: typeInfo['emoji'] as String,
            description: typeInfo['description'] as String,
            color: Color(typeInfo['color'] as int),
          ),
        ],
      ],
    );
  }
}

/// 차원 선택 행 (E/I, S/N 등)
class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.dimension,
    required this.selection,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  final MbtiDimension dimension;
  final bool? selection; // null = 미선택, true = left, false = right
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left option
        Expanded(
          child: _DimensionTile(
            letter: dimension.left,
            label: dimension.leftLabel,
            description: dimension.leftDescription,
            icon: dimension.leftIcon,
            isSelected: selection == true,
            isOtherSelected: selection == false,
            onTap: onSelectLeft,
          ),
        ),
        const SizedBox(width: 10),
        // Right option
        Expanded(
          child: _DimensionTile(
            letter: dimension.right,
            label: dimension.rightLabel,
            description: dimension.rightDescription,
            icon: dimension.rightIcon,
            isSelected: selection == false,
            isOtherSelected: selection == true,
            onTap: onSelectRight,
          ),
        ),
      ],
    );
  }
}

/// 개별 차원 타일
class _DimensionTile extends StatelessWidget {
  const _DimensionTile({
    required this.letter,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isOtherSelected,
    required this.onTap,
  });

  final String letter;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isOtherSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    final primary = AppColors.primaryOf(context);
    final surface = AppColors.surfaceOf(context);
    final surfaceVariant = AppColors.surfaceVariantOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textTertiary = AppColors.textTertiaryOf(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isCompact ? 12 : 14),
        decoration: BoxDecoration(
          color: isSelected
              ? primary
              : isOtherSelected
              ? surfaceVariant.withValues(alpha: 0.5)
              : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : isOtherSelected
                ? border.withValues(alpha: 0.5)
                : border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아이콘 + 글자
            Row(
              children: [
                Container(
                  width: isCompact ? 36 : 40,
                  height: isCompact ? 36 : 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.white.withValues(alpha: 0.2)
                        : primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 20,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? AppColors.white : primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.titleSmall.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : isOtherSelected
                              ? textTertiary
                              : textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.white,
                    size: isCompact ? 18 : 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 설명
            Text(
              description,
              style: AppTypography.caption.copyWith(
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.85)
                    : isOtherSelected
                    ? textTertiary.withValues(alpha: 0.7)
                    : textSecondary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// MBTI 결과 카드
class _MbtiResultCard extends StatelessWidget {
  const _MbtiResultCard({
    required this.type,
    required this.nickname,
    required this.emoji,
    required this.description,
    required this.color,
  });

  final String type;
  final String nickname;
  final String emoji;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textSecondary = AppColors.textSecondaryOf(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 이모지 아이콘
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        nickname,
                        style: AppTypography.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$nickname시군요! $description',
                  style: AppTypography.bodySmall.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
