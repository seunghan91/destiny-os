import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';

/// 온보딩 페이지 콘텐츠 데이터
class OnboardingContentData {
  const OnboardingContentData({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.description,
    this.features = const [],
  });

  final String icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
}

/// 온보딩 콘텐츠 위젯
class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.data,
    required this.animation,
  });

  final OnboardingContentData data;
  final Animation<double> animation;

  /// 콘텐츠의 최소 필요 높이 (아이콘 + 텍스트들 + 패딩)
  static const double _minContentHeight = 450;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation as AnimationController,
          curve: Curves.easeOut,
        )),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = _buildContent(context);
            
            // 화면이 충분히 크면 중앙 정렬, 작으면 스크롤 가능
            if (constraints.maxHeight >= _minContentHeight) {
              return Center(
                child: SingleChildScrollView(
                  child: content,
                ),
              );
            }
            
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: content,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(),
          const SizedBox(height: 24),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(context),
          const SizedBox(height: 16),
          _buildDescription(context),
          if (data.features.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFeatures(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: data.iconBackground.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: data.iconBackground.withValues(alpha: 0.25),
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
    );
  }

  Widget _buildTitle() {
    return Text(
      data.title,
      style: AppTypography.displaySmall.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      data.subtitle,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.primaryOf(context),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      data.description,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textSecondaryOf(context),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      children: data.features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                feature,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// 온보딩 페이지 콘텐츠 (간단 버전 - 애니메이션 없음)
class OnboardingContentSimple extends StatelessWidget {
  const OnboardingContentSimple({
    super.key,
    required this.data,
  });

  final OnboardingContentData data;

  /// 콘텐츠의 최소 필요 높이 (아이콘 + 텍스트들 + 패딩)
  static const double _minContentHeight = 450;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = _buildContent(context);
        
        // 화면이 충분히 크면 중앙 정렬, 작으면 스크롤 가능
        if (constraints.maxHeight >= _minContentHeight) {
          return Center(
            child: SingleChildScrollView(
              child: content,
            ),
          );
        }
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(),
          const SizedBox(height: 24),
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(context),
          const SizedBox(height: 16),
          _buildDescription(context),
          if (data.features.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildFeatures(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: data.iconBackground.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: data.iconBackground.withValues(alpha: 0.25),
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
    );
  }

  Widget _buildTitle() {
    return Text(
      data.title,
      style: AppTypography.displaySmall.copyWith(
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      data.subtitle,
      style: AppTypography.headlineMedium.copyWith(
        color: AppColors.primaryOf(context),
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      data.description,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textSecondaryOf(context),
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Column(
      children: data.features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primaryOf(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                feature,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
