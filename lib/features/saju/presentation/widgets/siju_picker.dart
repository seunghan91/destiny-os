import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

/// 12시진 (十二時辰) 데이터
class Siju {
  final String name;       // 시진 이름 (자시, 축시, ...)
  final String hanja;      // 한자 (子, 丑, ...)
  final String emoji;      // 동물 이모지
  final String timeRange;  // 시간 범위
  final int startHour;     // 시작 시간
  final int endHour;       // 종료 시간

  const Siju({
    required this.name,
    required this.hanja,
    required this.emoji,
    required this.timeRange,
    required this.startHour,
    required this.endHour,
  });

  /// TimeOfDay를 반환 (시진의 중간 시간)
  TimeOfDay get middleTime => TimeOfDay(hour: (startHour + endHour) ~/ 2, minute: 0);
}

/// 12시진 목록
const List<Siju> sijuList = [
  Siju(name: '자시', hanja: '子', emoji: '🐭', timeRange: '23:00 ~ 01:00', startHour: 23, endHour: 1),
  Siju(name: '축시', hanja: '丑', emoji: '🐮', timeRange: '01:00 ~ 03:00', startHour: 1, endHour: 3),
  Siju(name: '인시', hanja: '寅', emoji: '🐯', timeRange: '03:00 ~ 05:00', startHour: 3, endHour: 5),
  Siju(name: '묘시', hanja: '卯', emoji: '🐰', timeRange: '05:00 ~ 07:00', startHour: 5, endHour: 7),
  Siju(name: '진시', hanja: '辰', emoji: '🐲', timeRange: '07:00 ~ 09:00', startHour: 7, endHour: 9),
  Siju(name: '사시', hanja: '巳', emoji: '🐍', timeRange: '09:00 ~ 11:00', startHour: 9, endHour: 11),
  Siju(name: '오시', hanja: '午', emoji: '🐴', timeRange: '11:00 ~ 13:00', startHour: 11, endHour: 13),
  Siju(name: '미시', hanja: '未', emoji: '🐑', timeRange: '13:00 ~ 15:00', startHour: 13, endHour: 15),
  Siju(name: '신시', hanja: '申', emoji: '🐵', timeRange: '15:00 ~ 17:00', startHour: 15, endHour: 17),
  Siju(name: '유시', hanja: '酉', emoji: '🐔', timeRange: '17:00 ~ 19:00', startHour: 17, endHour: 19),
  Siju(name: '술시', hanja: '戌', emoji: '🐶', timeRange: '19:00 ~ 21:00', startHour: 19, endHour: 21),
  Siju(name: '해시', hanja: '亥', emoji: '🐷', timeRange: '21:00 ~ 23:00', startHour: 21, endHour: 23),
];

/// 12시진 선택 위젯
class SijuPicker extends StatelessWidget {
  const SijuPicker({
    super.key,
    this.selectedIndex,
    required this.onSelected,
  });

  final int? selectedIndex;
  final Function(int index, Siju siju) onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: sijuList.length,
      itemBuilder: (context, index) {
        final siju = sijuList[index];
        final isSelected = selectedIndex == index;

        return _SijuCard(
          siju: siju,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(index, siju);
          },
        );
      },
    );
  }
}

class _SijuCard extends StatelessWidget {
  const _SijuCard({
    required this.siju,
    required this.isSelected,
    required this.onTap,
  });

  final Siju siju;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              siju.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              siju.name,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 12시진 선택 바텀시트
class SijuPickerBottomSheet extends StatefulWidget {
  const SijuPickerBottomSheet({
    super.key,
    this.initialIndex,
    required this.onSelected,
  });

  final int? initialIndex;
  final Function(int index, Siju siju) onSelected;

  static Future<void> show(
    BuildContext context, {
    int? initialIndex,
    required Function(int index, Siju siju) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SijuPickerBottomSheet(
        initialIndex: initialIndex,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<SijuPickerBottomSheet> createState() => _SijuPickerBottomSheetState();
}

class _SijuPickerBottomSheetState extends State<SijuPickerBottomSheet> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Column(
                    children: [
                      Text(
                        '출생 시간',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12시진으로 선택',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _selectedIndex != null
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onSelected(
                                _selectedIndex!, sijuList[_selectedIndex!]);
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      '확인',
                      style: AppTypography.bodyLarge.copyWith(
                        color: _selectedIndex != null
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 12시진 그리드
            Padding(
              padding: const EdgeInsets.all(20),
              child: SijuPicker(
                selectedIndex: _selectedIndex,
                onSelected: (index, siju) {
                  setState(() => _selectedIndex = index);
                },
              ),
            ),

            // 선택된 시진 정보
            if (_selectedIndex != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      sijuList[_selectedIndex!].emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sijuList[_selectedIndex!].name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${sijuList[_selectedIndex!].hanja}時)',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sijuList[_selectedIndex!].timeRange,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 모르겠어요 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Text(
                  '출생 시간을 모르겠어요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
