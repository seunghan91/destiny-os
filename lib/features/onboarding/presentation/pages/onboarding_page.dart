import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../widgets/onboarding_content.dart';
import '../widgets/onboarding_page_indicator.dart';

/// 온보딩 페이지 - 마케팅 중심 인트로
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// 온보딩 콘텐츠 데이터 - 마케팅 카피 적용
  static final List<OnboardingContentData> _pages = [
    // 페이지 1: 메인 슬로건
    OnboardingContentData(
      icon: '🔮',
      iconBackground: AppColors.primary,
      title: '운명을 읽는\n새로운 방법',
      subtitle: 'Destiny.OS',
      description: '사주 × MBTI\nAI가 분석하는 나만의 운명',
    ),
    // 페이지 2: AI 코치 강조
    OnboardingContentData(
      icon: '🤖',
      iconBackground: AppColors.wood,
      title: '24시간\nAI 운명 코치',
      subtitle: '언제든 물어보세요',
      description: '궁금한 건 바로바로\nAI가 사주와 MBTI를 기반으로\n맞춤 답변을 드려요',
      features: [
        '실시간 AI 상담',
        '사주 기반 맞춤 조언',
        '무제한 질문 가능',
      ],
    ),
    // 페이지 3: 2026년 운세
    OnboardingContentData(
      icon: '🐴',
      iconBackground: AppColors.fire,
      title: '2026년 병오년\n나의 운세는?',
      subtitle: '丙午年 火馬의 해',
      description: '불꽃처럼 열정적인 에너지의 해\n당신에게는 어떤 기회가 올까요?',
      features: [
        '2026년 총운 분석',
        '월별 에너지 흐름',
        '대운/세운 상세 분석',
      ],
    ),
    // 페이지 4: 무료 혜택 & CTA
    OnboardingContentData(
      icon: '🎁',
      iconBackground: AppColors.earth,
      title: '지금 시작하면\n특별 혜택!',
      subtitle: '무료로 시작하기',
      description: '가입만 해도 AI 상담 3회 무료\n매일 오늘의 운세도 무료!',
      features: [
        'AI 상담 3회 무료',
        '매일 오늘의 운세',
        '2026년 운세 리포트',
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

    // 무료 크레딧 초기화 (3회)
    await prefs.setInt('freeAiCredits', 3);

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
                  // 마지막 페이지는 특별 디자인
                  if (index == _pages.length - 1) {
                    return _buildFinalPage(_pages[index]);
                  }
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 페이지 카운터
          Text(
            '${_currentPage + 1}/${_pages.length}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
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

  /// 마지막 페이지 - 무료 혜택 강조
  Widget _buildFinalPage(OnboardingContentData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // 아이콘
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.fire.withAlpha(40),
                  AppColors.earth.withAlpha(40),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.fire.withAlpha(60),
                      AppColors.earth.withAlpha(60),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    data.icon,
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // 타이틀
          Text(
            data.title,
            style: AppTypography.displaySmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 서브타이틀 - 강조 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.destinyGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              data.subtitle,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 설명
          Text(
            data.description,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 혜택 리스트 - 카드 스타일
          ...data.features.map((feature) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    feature,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'FREE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Spacer(flex: 2),
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
                backgroundColor: isLastPage ? AppColors.primary : AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isLastPage ? 4 : 0,
                shadowColor: isLastPage ? AppColors.primary.withAlpha(100) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastPage ? '무료로 시작하기' : '다음',
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
                  if (isLastPage) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.celebration_rounded,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 마지막 페이지 - 부가 안내
          if (isLastPage) ...[
            const SizedBox(height: 16),
            Text(
              '가입 없이 바로 시작할 수 있어요',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
