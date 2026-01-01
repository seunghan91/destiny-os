import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_page_indicator.dart';

/// 온보딩 페이지 - 첫 방문 사용자용 인트로
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// 온보딩 콘텐츠 데이터
  static final List<OnboardingContentData> _pages = [
    OnboardingContentData(
      icon: '🔮',
      iconBackground: AppColors.primary,
      title: '당신의 운명을\n데이터로 분석합니다',
      subtitle: 'Destiny.OS',
      description: '동양의 지혜 사주명리학과\n현대 성격유형 MBTI를 결합한\n새로운 운세 분석 플랫폼',
    ),
    OnboardingContentData(
      icon: '🐴',
      iconBackground: AppColors.fire,
      title: '2026년 병오년\n화려한 한 해가 옵니다',
      subtitle: '丙午年 火馬',
      description: '불꽃처럼 열정적인 에너지가 가득한 해\n당신에게 어떤 영향을 미칠까요?',
      features: [
        '2026년 총운 분석',
        '월별 에너지 차트',
        '맞춤형 행동 가이드',
      ],
    ),
    OnboardingContentData(
      icon: '✨',
      iconBackground: AppColors.wood,
      title: '사주와 MBTI의 만남\nGap 분석',
      subtitle: '타고난 나 vs 현재의 나',
      description: '생년월일로 추론한 성향과\n실제 MBTI 사이의 괴리를 분석해\n숨겨진 가능성을 발견하세요',
      features: [
        '사주 기반 MBTI 추론',
        '괴리도 점수 분석',
        '성장 인사이트 제공',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();

    // 온보딩 완료 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      context.go('/input');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더 (스킵 버튼)
            _buildHeader(),

            // 페이지 콘텐츠
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingContentSimple(data: _pages[index]);
                },
              ),
            ),

            // 하단 네비게이션
            _buildBottomNavigation(isLastPage),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                '건너뛰기',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isLastPage) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 페이지 인디케이터
          OnboardingPageIndicator(
            currentPage: _currentPage,
            totalPages: _pages.length,
          ),
          const SizedBox(height: 32),

          // 액션 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? '시작하기' : '다음',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!isLastPage) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
