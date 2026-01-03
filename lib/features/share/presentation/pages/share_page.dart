import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../fortune_2026/data/services/fortune_view_access_service.dart';
import '../../../compatibility/data/services/compatibility_calculator.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';

/// 공유 페이지
/// 운세 결과를 이미지로 변환하여 공유
class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final GlobalKey _shareCardKey = GlobalKey();
  bool _isGenerating = false;
  int _selectedCardIndex = 0;

  // 카드 타입 목록 (context 필요해서 build에서 초기화)
  List<_ShareCardType> _getCardTypes(BuildContext context) => [
    _ShareCardType('2026 운세', Icons.auto_awesome, AppColors.fireOf(context)),
    _ShareCardType('사주 분석', Icons.stars, AppColors.primaryOf(context)),
    _ShareCardType('Gap 분석', Icons.compare_arrows, AppColors.woodOf(context)),
  ];

  /// GoRouterState에서 extra 데이터 가져오기
  Map<String, dynamic>? _getExtraData(BuildContext context) {
    try {
      final state = GoRouterState.of(context);
      return state.extra as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final extraData = _getExtraData(context);
    final isCompatibilityShare = extraData?['type'] == 'compatibility';

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('공유하기')),
      body: isCompatibilityShare
          ? _buildCompatibilityShareView(extraData!)
          : BlocBuilder<DestinyBloc, DestinyState>(
              builder: (context, state) {
                if (state is! DestinySuccess) {
                  return _buildNoDataView();
                }

                return Column(
                  children: [
                    // 카드 타입 선택
                    _buildCardTypeSelector(),

                    // 공유 카드 미리보기
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: RepaintBoundary(
                            key: _shareCardKey,
                            child: _buildShareCard(state),
                          ),
                        ),
                      ),
                    ),

                    // 공유 버튼들
                    _buildShareButtons(),
                  ],
                );
              },
            ),
    );
  }

  /// 궁합 분석 공유 뷰
  Widget _buildCompatibilityShareView(Map<String, dynamic> data) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: RepaintBoundary(
                key: _shareCardKey,
                child: _buildCompatibilityCard(data),
              ),
            ),
          ),
        ),
        _buildShareButtons(),
      ],
    );
  }

  /// 궁합 분석 카드 UI
  Widget _buildCompatibilityCard(Map<String, dynamic> data) {
    final compatibilityResult =
        data['compatibilityResult'] as CompatibilityResult?;
    final partnerName = data['partnerName'] as String? ?? '상대방';
    final myName = data['myName'] as String? ?? '나';

    if (compatibilityResult == null) {
      return _buildNoDataView();
    }

    final summary = compatibilityResult.insights.summary;
    final chemistry = compatibilityResult.insights.chemistryPoints
        .take(3)
        .toList();
    final taboos = compatibilityResult.insights.taboos.take(2).toList();

    return Container(
      width: 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '궁합 카드',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Text('💗', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            '$myName · $partnerName',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // 총점
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '총점',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${compatibilityResult.overallScore}',
                            style: AppTypography.fortuneScore.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 6),
                            child: Text(
                              '점',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCompatibilityGrade(
                          compatibilityResult.overallScore,
                        ),
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '케미',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${compatibilityResult.loveScore}',
                        style: AppTypography.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 요약
          Text(
            '요약',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.replaceAll('\n\n', '\n').split('\n').take(3).join('\n'),
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // 케미 3개
          if (chemistry.isNotEmpty) ...[
            Text(
              '케미 포인트 TOP3',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...chemistry.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $t',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 금기 2개
          if (taboos.isNotEmpty) ...[
            Text(
              '금기 사항 TOP2',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...taboos.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '• $t',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '나의 궁합 분석 보러가기 →',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityMiniScore(String label, int score, IconData icon) {
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

  String _getCompatibilityGrade(int score) {
    if (score >= 90) return '천생연분';
    if (score >= 80) return '아주 좋은 궁합';
    if (score >= 70) return '좋은 궁합';
    if (score >= 60) return '보통 궁합';
    if (score >= 50) return '노력이 필요한 궁합';
    return '어려운 궁합';
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: AppColors.textTertiaryOf(context),
          ),
          const SizedBox(height: 16),
          Text(
            '공유할 운세 데이터가 없습니다',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '먼저 사주 분석을 완료해주세요',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTypeSelector() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _getCardTypes(context).length,
        itemBuilder: (context, index) {
          final type = _getCardTypes(context)[index];
          final isSelected = index == _selectedCardIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.white : type.color,
                  ),
                  const SizedBox(width: 6),
                  Text(type.name),
                ],
              ),
              selected: isSelected,
              selectedColor: type.color,
              backgroundColor: type.color.withValues(alpha: 0.1),
              labelStyle: AppTypography.labelMedium.copyWith(
                color: isSelected ? Colors.white : type.color,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCardIndex = index);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShareCard(DestinySuccess state) {
    switch (_selectedCardIndex) {
      case 0:
        return _buildFortuneCard(state);
      case 1:
        return _buildSajuCard(state);
      case 2:
        return _buildGapCard(state);
      default:
        return _buildFortuneCard(state);
    }
  }

  Widget _buildFortuneCard(DestinySuccess state) {
    final fortune = state.fortune2026;
    final score = fortune.overallScore.toInt();

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.fire, AppColors.fire.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.fire.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2026 신년운세',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Text('🐴', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 24),

          // 연도
          Text(
            '2026',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w200,
              letterSpacing: 8,
            ),
          ),
          Text(
            '병오년 운세',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 32),

          // 점수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: AppTypography.fortuneScore.copyWith(
                        color: Colors.white,
                      ),
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
                const SizedBox(height: 8),
                Text(
                  fortune.yearTheme,
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // MBTI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.mbtiType.type} 유형',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          // 푸터
          Text(
            '나의 2026년 운세 보러가기 →',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSajuCard(DestinySuccess state) {
    final chart = state.sajuChart;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.destinyGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOf(context).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2026 신년운세',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Text('🔮', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            '나의 사주팔자',
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),

          // 사주 4주
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPillarColumn('시', chart.hourPillar),
              _buildPillarColumn('일', chart.dayPillar),
              _buildPillarColumn('월', chart.monthPillar),
              _buildPillarColumn('년', chart.yearPillar),
            ],
          ),
          const SizedBox(height: 24),

          // 일간 설명
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '일간: ${chart.dayPillar.heavenlyStem} (${_getElementName(chart.dayPillar.heavenlyStem)})',
              style: AppTypography.labelMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '나의 사주 보러가기 →',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarColumn(String label, dynamic pillar) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                _getHanja(pillar.heavenlyStem),
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getHanja(pillar.earthlyBranch),
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGapCard(DestinySuccess state) {
    final gap = state.gapAnalysis;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wood, AppColors.wood.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.wood.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2026 신년운세',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Text('⚡', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Gap Analysis',
            style: AppTypography.titleLarge.copyWith(color: Colors.white),
          ),
          Text(
            '사주 vs MBTI 괴리 분석',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // 비교
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMbtiBox('사주 기반', gap.sajuBasedMbti),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.compare_arrows,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 32,
                ),
              ),
              _buildMbtiBox('실제', state.mbtiType.type),
            ],
          ),
          const SizedBox(height: 24),

          // 괴리 점수
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '괴리도',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${gap.gapScore.toInt()}%',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGapLevelText(gap.gapScore),
                  style: AppTypography.labelMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '나의 Gap 분석 보러가기 →',
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMbtiBox(String label, String mbti) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            mbti,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowOf(
              context,
              lightOpacity: 0.05,
              darkOpacity: 0.12,
            ),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 소셜 공유 버튼 (카카오톡, 인스타그램)
          Row(
            children: [
              Expanded(
                child: _buildSocialShareButton(
                  label: '카카오톡',
                  color: const Color(0xFFFEE500),
                  textColor: const Color(0xFF3C1E1E),
                  icon: Icons.chat_bubble,
                  onPressed: _isGenerating ? null : _shareToKakao,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialShareButton(
                  label: '인스타 스토리',
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF833AB4), // 보라
                      Color(0xFFC13584), // 분홍
                      Color(0xFFE1306C), // 빨강
                      Color(0xFFFD1D1D), // 주황
                      Color(0xFFF56040), // 노랑
                    ],
                  ),
                  textColor: Colors.white,
                  icon: Icons.camera_alt,
                  onPressed: _isGenerating ? null : _shareToInstagramStory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 메인 공유 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _shareImage,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              label: Text(_isGenerating ? '이미지 생성 중...' : '다른 앱으로 공유'),
            ),
          ),
          const SizedBox(height: 12),

          // 추가 공유 옵션
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _saveImage,
                  icon: const Icon(Icons.download),
                  label: const Text('저장'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGenerating ? null : _copyLink,
                  icon: const Icon(Icons.link),
                  label: const Text('링크 복사'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialShareButton({
    required String label,
    required IconData icon,
    Color? color,
    Gradient? gradient,
    required Color textColor,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 카카오톡으로 공유
  Future<void> _shareToKakao() async {
    setState(() => _isGenerating = true);
    HapticFeedback.lightImpact();

    await FortuneViewAccessService.claimShareBonus();

    try {
      final imageBytes = await _captureWidget();
      if (imageBytes == null) {
        _showError('이미지 생성에 실패했습니다');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/destiny_kakao_share.png');
      await file.writeAsBytes(imageBytes);

      // 카카오톡이 설치되어 있는지 확인
      final kakaoUri = Uri.parse('kakaolink://');
      final canLaunchKakao = await canLaunchUrl(kakaoUri);

      if (canLaunchKakao) {
        // 카카오톡 공유 - 시스템 공유 시트를 통해 카카오톡 선택하도록 유도
        await Share.shareXFiles([
          XFile(file.path),
        ], text: '나의 2026년 운세를 확인해보세요! 🐴✨\n#2026신년운세 #2026운세');
      } else {
        // 카카오톡이 설치되지 않은 경우
        _showKakaoNotInstalledDialog();
      }
    } catch (e) {
      _showError('카카오톡 공유에 실패했습니다');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// 카카오톡 미설치 안내
  void _showKakaoNotInstalledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble, color: Color(0xFFFEE500)),
            SizedBox(width: 8),
            Text('카카오톡'),
          ],
        ),
        content: const Text('카카오톡이 설치되어 있지 않습니다.\n다른 공유 방법을 이용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 인스타그램 스토리로 공유
  Future<void> _shareToInstagramStory() async {
    setState(() => _isGenerating = true);
    HapticFeedback.lightImpact();

    await FortuneViewAccessService.claimShareBonus();

    try {
      final imageBytes = await _captureWidget();
      if (imageBytes == null) {
        _showError('이미지 생성에 실패했습니다');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/destiny_insta_share.png');
      await file.writeAsBytes(imageBytes);

      // 인스타그램 앱 확인 (iOS/Android 다름)
      final instagramUri = Uri.parse('instagram://');
      final canLaunchInstagram = await canLaunchUrl(instagramUri);

      if (canLaunchInstagram) {
        if (Platform.isIOS) {
          // iOS: instagram-stories 스키마 사용
          await _shareToInstagramStoryIOS(file);
        } else if (Platform.isAndroid) {
          // Android: Intent를 통한 공유
          await _shareToInstagramStoryAndroid(file);
        }
      } else {
        // 인스타그램이 설치되지 않은 경우
        _showInstagramNotInstalledDialog();
      }
    } catch (e) {
      _showError('인스타그램 공유에 실패했습니다');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  /// iOS 인스타그램 스토리 공유
  Future<void> _shareToInstagramStoryIOS(File imageFile) async {
    // iOS에서는 시스템 공유 시트를 통해 인스타그램 선택
    await Share.shareXFiles([
      XFile(imageFile.path),
    ], text: '나의 2026년 운세 🐴✨ #2026신년운세');
    _showSuccess('인스타그램에서 스토리로 공유해주세요!');
  }

  /// Android 인스타그램 스토리 공유
  Future<void> _shareToInstagramStoryAndroid(File imageFile) async {
    // Android에서도 시스템 공유 시트 사용
    await Share.shareXFiles([
      XFile(imageFile.path),
    ], text: '나의 2026년 운세 🐴✨ #2026신년운세');
    _showSuccess('인스타그램에서 스토리로 공유해주세요!');
  }

  /// 인스타그램 미설치 안내
  void _showInstagramNotInstalledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF833AB4),
                    Color(0xFFE1306C),
                    Color(0xFFF56040),
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text('인스타그램'),
          ],
        ),
        content: const Text('인스타그램이 설치되어 있지 않습니다.\n다른 공유 방법을 이용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _captureWidget() async {
    try {
      final boundary =
          _shareCardKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isGenerating = true);

    await FortuneViewAccessService.claimShareBonus();

    try {
      final imageBytes = await _captureWidget();
      if (imageBytes == null) {
        _showError('이미지 생성에 실패했습니다');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/destiny_share.png');
      await file.writeAsBytes(imageBytes);

      final extraData = _getExtraData(context);
      final isCompatibilityShare = extraData?['type'] == 'compatibility';

      final text = isCompatibilityShare
          ? '우리 궁합 점수는 몇 점일까? 💗\n궁합 카드 공유해요!\n#궁합 #사주궁합 #MBTI궁합'
          : '나의 2026년 운세를 확인해보세요! 🔮\n#2026신년운세 #2026운세 #사주';

      await Share.shareXFiles([XFile(file.path)], text: text);
    } catch (e) {
      _showError('공유에 실패했습니다: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _saveImage() async {
    setState(() => _isGenerating = true);

    await FortuneViewAccessService.claimShareBonus();

    try {
      final imageBytes = await _captureWidget();
      if (imageBytes == null) {
        _showError('이미지 생성에 실패했습니다');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'destiny_$timestamp.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      HapticFeedback.mediumImpact();

      // iOS/Android 공유 시트를 통해 "이미지 저장" 옵션 제공
      // 사용자가 직접 사진 앱에 저장하거나 다른 앱으로 공유 가능
      final result = await Share.shareXFiles([
        XFile(file.path, mimeType: 'image/png'),
      ], subject: '2026 신년운세 운세 카드');

      if (result.status == ShareResultStatus.success) {
        _showSuccess('이미지가 저장되었습니다');
      } else if (result.status == ShareResultStatus.dismissed) {
        // 사용자가 취소한 경우 - 조용히 처리
      }
    } catch (e) {
      _showError('저장에 실패했습니다: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyLink() async {
    await FortuneViewAccessService.claimShareBonus();

    // 앱 링크 (Firebase 호스팅 URL - mbtiunse.com으로 리다이렉트)
    const appLink = 'https://destiny-os-2026.web.app';

    final extraData = _getExtraData(context);
    final isCompatibilityShare = extraData?['type'] == 'compatibility';

    final shareText = isCompatibilityShare
        ? '우리 궁합 카드 공유해요 💗\n\n'
              '사주 + MBTI 기반 궁합 분석\n'
              '$appLink\n\n'
              '#궁합 #사주궁합 #MBTI궁합'
        : '나의 2026년 운세를 확인해보세요! 🔮\n\n'
              '사주팔자와 MBTI를 결합한 새로운 운세 분석\n'
              '$appLink\n\n'
              '#2026신년운세 #2026운세 #사주 #MBTI';

    await Clipboard.setData(ClipboardData(text: shareText));
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('링크가 클립보드에 복사되었습니다'),
            ],
          ),
          backgroundColor: AppColors.successOf(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successOf(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getHanja(String korean) {
    // 천간 (heavenly stems)
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
    // 지지 (earthly branches)
    const jijiMap = {
      '자': '子',
      '축': '丑',
      '인': '寅',
      '묘': '卯',
      '진': '辰',
      '사': '巳',
      '오': '午',
      '미': '未',
      '유': '酉',
      '술': '戌',
      '해': '亥',
    };
    return cheonganMap[korean] ?? jijiMap[korean] ?? korean;
  }

  String _getGapLevelText(double gapScore) {
    if (gapScore >= 70) return '큰 괴리';
    if (gapScore >= 50) return '보통 괴리';
    if (gapScore >= 30) return '작은 괴리';
    return '일치';
  }

  String _getElementName(String stem) {
    const elementMap = {
      '갑': '목(木)',
      '을': '목(木)',
      '병': '화(火)',
      '정': '화(火)',
      '무': '토(土)',
      '기': '토(土)',
      '경': '금(金)',
      '신': '금(金)',
      '임': '수(水)',
      '계': '수(水)',
    };
    return elementMap[stem] ?? '';
  }
}

class _ShareCardType {
  final String name;
  final IconData icon;
  final Color color;

  const _ShareCardType(this.name, this.icon, this.color);
}
