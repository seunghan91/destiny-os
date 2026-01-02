import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../bloc/daily_fortune_bloc.dart';
import '../bloc/daily_fortune_event.dart';
import '../bloc/daily_fortune_state.dart';
import '../widgets/advice_section.dart';
import '../widgets/fortune_category_card.dart';
import '../widgets/fortune_score_card.dart';
import '../widgets/lucky_items_section.dart';
import '../widgets/premium_features_section.dart';
import '../widgets/premium_upsell_modal.dart';

/// 오늘의 운세 페이지
class DailyFortunePage extends StatefulWidget {
  const DailyFortunePage({super.key});

  @override
  State<DailyFortunePage> createState() => _DailyFortunePageState();
}

class _DailyFortunePageState extends State<DailyFortunePage> {
  @override
  void initState() {
    super.initState();
    // 페이지 로드 시 운세 조회
    context.read<DailyFortuneBloc>().add(const LoadDailyFortune());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: _buildAppBar(),
      body: BlocBuilder<DailyFortuneBloc, DailyFortuneState>(
        builder: (context, state) {
          if (state is DailyFortuneLoading) {
            return _buildLoadingState();
          }

          if (state is DailyFortuneError) {
            return _buildErrorState(state.message);
          }

          if (state is DailyFortuneLoaded) {
            return _buildLoadedState(state);
          }

          return _buildInitialState();
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('오늘의 운세'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: 공유 기능
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            context.read<DailyFortuneBloc>().add(const RefreshDailyFortune());
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<DailyFortuneBloc>().add(const LoadDailyFortune());
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔮', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            '오늘의 운세를 확인해보세요',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<DailyFortuneBloc>().add(const LoadDailyFortune());
            },
            child: const Text('운세 보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(DailyFortuneLoaded state) {
    final fortune = state.fortune;
    final hasPremium = state.hasPremium;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DailyFortuneBloc>().add(const RefreshDailyFortune());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 헤더
            _buildDateHeader(fortune.date, fortune.dayName),

            const SizedBox(height: 16),

            // 종합 운세 점수 카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FortuneScoreCard(fortune: fortune),
            ),

            const SizedBox(height: 20),

            // 행운 아이템
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LuckyItemsSection(fortune: fortune),
            ),

            const SizedBox(height: 20),

            // 카테고리별 운세
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '세부 운세',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  FortuneCategoryCard(
                    icon: '💕',
                    category: '애정운',
                    score: fortune.loveScore,
                    message: fortune.loveMessage,
                  ),
                  const SizedBox(height: 12),
                  FortuneCategoryCard(
                    icon: '💰',
                    category: '금전운',
                    score: fortune.wealthScore,
                    message: fortune.wealthMessage,
                  ),
                  const SizedBox(height: 12),
                  FortuneCategoryCard(
                    icon: '❤️‍🩹',
                    category: '건강운',
                    score: fortune.healthScore,
                    message: fortune.healthMessage,
                  ),
                  const SizedBox(height: 12),
                  FortuneCategoryCard(
                    icon: '💼',
                    category: '직업운',
                    score: fortune.careerScore,
                    message: fortune.careerMessage,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 오늘의 조언
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AdviceSection(
                advice: fortune.advice,
                caution: fortune.caution,
              ),
            ),

            const SizedBox(height: 20),

            // 프리미엄 기능 (시간대별 운세, 주간 미리보기)
            if (hasPremium && fortune.morningFortune != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PremiumFeaturesSection(fortune: fortune),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPremiumUpsell(),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, String dayName) {
    final dateFormat = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR');
    final dateString = dateFormat.format(date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: AppColors.destinyGradient,
      ),
      child: Column(
        children: [
          Text(
            dateString,
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dayName,
            style: AppTypography.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpsell() {
    return GestureDetector(
      onTap: () => _showPremiumModal(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.fire.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프리미엄 기능 잠금 해제',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '시간대별 운세 · 주간 미리보기',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumUpsellModal(),
    );
  }
}
