import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// MBTI 차원 데이터
class MbtiDimension {
  final String letter;
  final String label;
  final String description;
  final Color color;

  const MbtiDimension({
    required this.letter,
    required this.label,
    required this.description,
    required this.color,
  });
}

/// MBTI 차원 정의
class MbtiDimensions {
  // 에너지 방향
  static const e = MbtiDimension(
    letter: 'E',
    label: '외향형',
    description: '사람들과 어울리며\n에너지를 얻어요',
    color: Color(0xFFFF6B6B),
  );
  static const i = MbtiDimension(
    letter: 'I',
    label: '내향형',
    description: '혼자만의 시간에서\n에너지를 얻어요',
    color: Color(0xFF4ECDC4),
  );

  // 인식 기능
  static const s = MbtiDimension(
    letter: 'S',
    label: '감각형',
    description: '현실적이고\n구체적인 것을 선호해요',
    color: Color(0xFFFFE66D),
  );
  static const n = MbtiDimension(
    letter: 'N',
    label: '직관형',
    description: '가능성과\n큰 그림을 봐요',
    color: Color(0xFF9B59B6),
  );

  // 판단 기능
  static const t = MbtiDimension(
    letter: 'T',
    label: '사고형',
    description: '논리와 객관성을\n중시해요',
    color: Color(0xFF3498DB),
  );
  static const f = MbtiDimension(
    letter: 'F',
    label: '감정형',
    description: '공감과 조화를\n중시해요',
    color: Color(0xFFE91E63),
  );

  // 생활 양식
  static const j = MbtiDimension(
    letter: 'J',
    label: '판단형',
    description: '계획적이고\n체계적이에요',
    color: Color(0xFF2ECC71),
  );
  static const p = MbtiDimension(
    letter: 'P',
    label: '인식형',
    description: '유연하고\n즉흥적이에요',
    color: Color(0xFFF39C12),
  );

  static List<List<MbtiDimension>> get allPairs => [
        [e, i],
        [s, n],
        [t, f],
        [j, p],
      ];
}

/// 개별 MBTI 타일
class MbtiTile extends StatelessWidget {
  final MbtiDimension dimension;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showDescription;

  const MbtiTile({
    super.key,
    required this.dimension,
    required this.isSelected,
    required this.onTap,
    this.showDescription = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? dimension.color : AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? dimension.color : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: dimension.color.withAlpha(77), // 0.3 * 255
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 알파벳
            Text(
              dimension.letter,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.white : AppColors.grey600,
              ),
            ),
            const SizedBox(height: 4),
            // 한글 레이블
            Text(
              dimension.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.white.withAlpha(230) // 0.9 * 255
                    : AppColors.grey500,
              ),
            ),
            if (showDescription) ...[
              const SizedBox(height: 8),
              Text(
                dimension.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: isSelected
                      ? AppColors.white.withAlpha(204) // 0.8 * 255
                      : AppColors.grey400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 4x2 그리드 MBTI 선택 위젯
class MbtiSelectorWidget extends StatefulWidget {
  final String? initialMbti;
  final ValueChanged<String>? onMbtiChanged;
  final bool showDescriptions;

  const MbtiSelectorWidget({
    super.key,
    this.initialMbti,
    this.onMbtiChanged,
    this.showDescriptions = false,
  });

  @override
  State<MbtiSelectorWidget> createState() => _MbtiSelectorWidgetState();
}

class _MbtiSelectorWidgetState extends State<MbtiSelectorWidget> {
  // 각 차원별 선택 상태 (0: 첫번째, 1: 두번째)
  late List<int> _selections;

  @override
  void initState() {
    super.initState();
    _selections = _parseInitialMbti(widget.initialMbti);
  }

  List<int> _parseInitialMbti(String? mbti) {
    if (mbti == null || mbti.length != 4) {
      return [-1, -1, -1, -1]; // 미선택 상태
    }

    return [
      mbti[0] == 'E' ? 0 : 1, // E/I
      mbti[1] == 'S' ? 0 : 1, // S/N
      mbti[2] == 'T' ? 0 : 1, // T/F
      mbti[3] == 'J' ? 0 : 1, // J/P
    ];
  }

  String? get _currentMbti {
    if (_selections.contains(-1)) return null;

    final pairs = MbtiDimensions.allPairs;
    return _selections.asMap().entries.map((entry) {
      return pairs[entry.key][entry.value].letter;
    }).join();
  }

  void _onTileSelected(int dimensionIndex, int optionIndex) {
    setState(() {
      _selections[dimensionIndex] = optionIndex;
    });

    final mbti = _currentMbti;
    if (mbti != null) {
      widget.onMbtiChanged?.call(mbti);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = MbtiDimensions.allPairs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withAlpha(13), // 0.05 * 255
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 행 (E, S, T, J)
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 3 ? 0 : 4,
                  ),
                  child: MbtiTile(
                    dimension: pairs[index][0],
                    isSelected: _selections[index] == 0,
                    onTap: () => _onTileSelected(index, 0),
                    showDescription: widget.showDescriptions,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // 하단 행 (I, N, F, P)
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 3 ? 0 : 4,
                  ),
                  child: MbtiTile(
                    dimension: pairs[index][1],
                    isSelected: _selections[index] == 1,
                    onTap: () => _onTileSelected(index, 1),
                    showDescription: widget.showDescriptions,
                  ),
                ),
              );
            }),
          ),
          // 결과 표시
          if (_currentMbti != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: AppColors.destinyGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentMbti!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _getMbtiNickname(_currentMbti!),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white.withAlpha(230), // 0.9 * 255
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

  String _getMbtiNickname(String mbti) {
    const nicknames = {
      'INTJ': '전략가',
      'INTP': '논리술사',
      'ENTJ': '통솔자',
      'ENTP': '변론가',
      'INFJ': '옹호자',
      'INFP': '중재자',
      'ENFJ': '선도자',
      'ENFP': '활동가',
      'ISTJ': '현실주의자',
      'ISFJ': '수호자',
      'ESTJ': '경영자',
      'ESFJ': '집정관',
      'ISTP': '장인',
      'ISFP': '모험가',
      'ESTP': '사업가',
      'ESFP': '연예인',
    };
    return nicknames[mbti] ?? '';
  }
}

/// 컴팩트 버전 (설명 없이 타일만)
class MbtiSelectorCompact extends StatelessWidget {
  final String? initialMbti;
  final ValueChanged<String>? onMbtiChanged;

  const MbtiSelectorCompact({
    super.key,
    this.initialMbti,
    this.onMbtiChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MbtiSelectorWidget(
      initialMbti: initialMbti,
      onMbtiChanged: onMbtiChanged,
      showDescriptions: false,
    );
  }
}
