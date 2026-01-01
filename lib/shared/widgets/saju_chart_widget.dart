import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'saju_pillar_card.dart';
import 'saju_explanations.dart';

/// 사주 기둥 데이터 모델
class SajuPillarData {
  final String pillarName;
  final String tenGod; // 십신
  final String heavenlyStem; // 천간 한자
  final String heavenlyStemReading;
  final String heavenlyStemElement;
  final String heavenlyStemElementKr;
  final String earthlyBranch; // 지지 한자
  final String earthlyBranchReading;
  final String earthlyBranchElement;
  final String earthlyBranchElementKr;
  final String twelveState; // 십이운성

  const SajuPillarData({
    required this.pillarName,
    required this.tenGod,
    required this.heavenlyStem,
    required this.heavenlyStemReading,
    required this.heavenlyStemElement,
    required this.heavenlyStemElementKr,
    required this.earthlyBranch,
    required this.earthlyBranchReading,
    required this.earthlyBranchElement,
    required this.earthlyBranchElementKr,
    required this.twelveState,
  });
}

/// 선택된 요소 정보
class _SelectedElement {
  final String key;
  final int? pillarIndex;

  const _SelectedElement({
    required this.key,
    this.pillarIndex,
  });
}

/// 사주팔자 전체 차트 위젯 (터치 가능한 설명 포함)
class SajuChartWidget extends StatefulWidget {
  final List<SajuPillarData> pillars; // [시주, 일주, 월주, 년주]
  final bool showExplanations; // 설명 기능 활성화 여부

  const SajuChartWidget({
    super.key,
    required this.pillars,
    this.showExplanations = true,
  });

  @override
  State<SajuChartWidget> createState() => _SajuChartWidgetState();
}

class _SajuChartWidgetState extends State<SajuChartWidget>
    with SingleTickerProviderStateMixin {
  _SelectedElement? _selected;
  SajuExplanation? _currentExplanation;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onElementTap(String key, {int? pillarIndex}) {
    if (!widget.showExplanations) return;

    final explanation = SajuExplanations.find(key);
    if (explanation == null) return;

    // 같은 요소 재클릭 시 닫기
    if (_selected?.key == key && _selected?.pillarIndex == pillarIndex) {
      _animController.reverse().then((_) {
        setState(() {
          _selected = null;
          _currentExplanation = null;
        });
      });
      return;
    }

    setState(() {
      _selected = _SelectedElement(key: key, pillarIndex: pillarIndex);
      _currentExplanation = explanation;
    });

    if (_animController.status == AnimationStatus.completed) {
      _animController.forward(from: 0);
    } else {
      _animController.forward();
    }
  }

  void _closeExplanation() {
    _animController.reverse().then((_) {
      setState(() {
        _selected = null;
        _currentExplanation = null;
      });
    });
  }

  bool _isSelected(String key, {int? pillarIndex}) {
    if (_selected == null) return false;
    return _selected!.key == key &&
        (pillarIndex == null || _selected!.pillarIndex == pillarIndex);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.pillars.length == 4, 'Must provide exactly 4 pillars');

    return GestureDetector(
      onTap: _selected != null ? _closeExplanation : null,
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowOf(context, lightOpacity: 0.05, darkOpacity: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 설명 패널 (상단)
            if (widget.showExplanations) _buildExplanationPanel(),

            // 기둥 이름 행 (시주, 일주, 월주, 년주)
            _buildPillarNamesRow(),
            const SizedBox(height: 12),

            // 십신 행 (천간 기준)
            _buildTenGodRow(),
            const SizedBox(height: 8),

            // 천간 카드 행
            _buildHeavenlyStemRow(),
            const SizedBox(height: 8),

            // 지지 카드 행
            _buildEarthlyBranchRow(),
            const SizedBox(height: 8),

            // 십이운성 행
            _buildTwelveStateRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationPanel() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        if (_currentExplanation == null && !_animController.isAnimating) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(20),
                    AppColors.wood.withAlpha(15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withAlpha(50),
                  width: 1,
                ),
              ),
              child: _currentExplanation != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 아이콘
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _currentExplanation!.icon,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 텍스트
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentExplanation!.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentExplanation!.shortDesc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondaryOf(context),
                                  height: 1.4,
                                ),
                              ),
                              if (_currentExplanation!.detailDesc != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _currentExplanation!.detailDesc!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiaryOf(context),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // 닫기 버튼
                        GestureDetector(
                          onTap: _closeExplanation,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.textTertiaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillarNamesRow() {
    return Row(
      children: widget.pillars.asMap().entries.map((entry) {
        final index = entry.key;
        final pillar = entry.value;
        final isSelected = _isSelected(pillar.pillarName, pillarIndex: index);

        return Expanded(
          child: _TappableCell(
            onTap: () => _onElementTap(pillar.pillarName, pillarIndex: index),
            isSelected: isSelected,
            child: Text(
              pillar.pillarName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTenGodRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.earth.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: widget.pillars.asMap().entries.map((entry) {
          final index = entry.key;
          final pillar = entry.value;
          final isLast = index == widget.pillars.length - 1;
          final isSelected = _isSelected(pillar.tenGod);

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        right: BorderSide(
                          color: AppColors.grey300,
                          width: 1,
                        ),
                      ),
              ),
              child: _TappableCell(
                onTap: () => _onElementTap(pillar.tenGod),
                isSelected: isSelected,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  pillar.tenGod,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeavenlyStemRow() {
    return Row(
      children: widget.pillars.asMap().entries.map((entry) {
        final pillar = entry.value;
        final isSelected = _isSelected(pillar.heavenlyStemElementKr);

        return Expanded(
          child: Center(
            child: _TappableGanZhiCard(
              character: pillar.heavenlyStem,
              reading: pillar.heavenlyStemReading,
              element: pillar.heavenlyStemElement,
              elementKorean: pillar.heavenlyStemElementKr,
              isSelected: isSelected,
              onTap: () => _onElementTap(pillar.heavenlyStemElementKr),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarthlyBranchRow() {
    return Row(
      children: widget.pillars.asMap().entries.map((entry) {
        final pillar = entry.value;
        final isSelected = _isSelected(pillar.earthlyBranchElementKr);

        return Expanded(
          child: Center(
            child: _TappableGanZhiCard(
              character: pillar.earthlyBranch,
              reading: pillar.earthlyBranchReading,
              element: pillar.earthlyBranchElement,
              elementKorean: pillar.earthlyBranchElementKr,
              isSelected: isSelected,
              onTap: () => _onElementTap(pillar.earthlyBranchElementKr),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTwelveStateRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: widget.pillars.asMap().entries.map((entry) {
          final index = entry.key;
          final pillar = entry.value;
          final isLast = index == widget.pillars.length - 1;
          final isSelected = _isSelected(pillar.twelveState);

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        right: BorderSide(
                          color: AppColors.grey300,
                          width: 1,
                        ),
                      ),
              ),
              child: _TappableCell(
                onTap: () => _onElementTap(pillar.twelveState),
                isSelected: isSelected,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  pillar.twelveState,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 터치 가능한 셀 위젯
class _TappableCell extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;
  final Widget child;
  final EdgeInsets padding;

  const _TappableCell({
    required this.onTap,
    required this.isSelected,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        splashColor: AppColors.primary.withAlpha(30),
        highlightColor: AppColors.primary.withAlpha(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
            color: isSelected ? AppColors.primary.withAlpha(15) : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 터치 가능한 천간/지지 카드
class _TappableGanZhiCard extends StatelessWidget {
  final String character;
  final String reading;
  final String element;
  final String elementKorean;
  final bool isSelected;
  final VoidCallback onTap;

  const _TappableGanZhiCard({
    required this.character,
    required this.reading,
    required this.element,
    required this.elementKorean,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = ElementColors.getColor(element);
    final textColor = ElementColors.getTextColor(element);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 72,
        height: 88,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 3)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 오행 표시 (상단)
            Text(
              '$element, $elementKorean',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withAlpha(204),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            // 한자 (중앙 - 크게)
            Text(
              character,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            // 한글 읽기 (하단)
            Text(
              reading,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withAlpha(230),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 예시 데이터로 위젯 생성하는 팩토리
class SajuChartExample {
  static SajuChartWidget get sample => SajuChartWidget(
        pillars: [
          SajuPillarData(
            pillarName: '시주',
            tenGod: '편인',
            heavenlyStem: '癸',
            heavenlyStemReading: '계',
            heavenlyStemElement: '水',
            heavenlyStemElementKr: '물',
            earthlyBranch: '未',
            earthlyBranchReading: '미',
            earthlyBranchElement: '土',
            earthlyBranchElementKr: '흙',
            twelveState: '양',
          ),
          SajuPillarData(
            pillarName: '일주',
            tenGod: '일원',
            heavenlyStem: '乙',
            heavenlyStemReading: '을',
            heavenlyStemElement: '木',
            heavenlyStemElementKr: '나무',
            earthlyBranch: '卯',
            earthlyBranchReading: '묘',
            earthlyBranchElement: '木',
            earthlyBranchElementKr: '나무',
            twelveState: '건록',
          ),
          SajuPillarData(
            pillarName: '월주',
            tenGod: '정관',
            heavenlyStem: '庚',
            heavenlyStemReading: '경',
            heavenlyStemElement: '金',
            heavenlyStemElementKr: '쇠',
            earthlyBranch: '子',
            earthlyBranchReading: '자',
            earthlyBranchElement: '水',
            earthlyBranchElementKr: '물',
            twelveState: '병',
          ),
          SajuPillarData(
            pillarName: '년주',
            tenGod: '편관',
            heavenlyStem: '辛',
            heavenlyStemReading: '신',
            heavenlyStemElement: '金',
            heavenlyStemElementKr: '쇠',
            earthlyBranch: '未',
            earthlyBranchReading: '미',
            earthlyBranchElement: '土',
            earthlyBranchElementKr: '흙',
            twelveState: '양',
          ),
        ],
      );
}
