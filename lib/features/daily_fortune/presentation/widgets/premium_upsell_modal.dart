import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_bridge.dart';
import '../../../../core/services/apps_in_toss/models.dart';
import '../../../ai_consultation/data/services/credit_service.dart';
import '../bloc/daily_fortune_bloc.dart';
import '../bloc/daily_fortune_event.dart';

/// 프리미엄 업셀 모달
class PremiumUpsellModal extends StatefulWidget {
  const PremiumUpsellModal({super.key});

  @override
  State<PremiumUpsellModal> createState() => _PremiumUpsellModalState();
}

class _PremiumUpsellModalState extends State<PremiumUpsellModal> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 핸들 바
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300Of(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 아이콘
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.fire.withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('⭐', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 타이틀
              Text(
                '프리미엄 기능 잠금 해제',
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                '더 정확한 운세와 AI 상담 5회 제공',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 혜택 리스트
              _buildFeatureItem(
                icon: '🕐',
                title: '시간대별 운세',
                description: '오전, 오후, 저녁별 맞춤 운세',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: '📅',
                title: '주간 운세 미리보기',
                description: '일주일 흐름을 한눈에',
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                icon: '🤖',
                title: 'AI 상담 5회 제공',
                description: '궁금한 것을 AI에게 물어보세요',
              ),

              const SizedBox(height: 24),

              // 가격 표시
              Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '5,000',
                          style: AppTypography.displaySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '원',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI 상담 5회 + 프리미엄 운세',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 구매 버튼
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.grey300Of(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '5,000원 결제하기',
                              style: AppTypography.labelLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // 안내 문구
              Text(
                '결제 후 즉시 프리미엄 기능이 활성화됩니다',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required String icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);

    try {
      if (EnvConfig.betaPaymentsFree) {
        if (mounted) {
          context.read<DailyFortuneBloc>().add(const ActivatePremiumFeatures());
        }

        await CreditService.addCredits(5);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('베타테스트 기간 무료로 제공됩니다! 프리미엄 기능이 활성화되었습니다.'),
              backgroundColor: AppColors.fortuneGood,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      final bridge = AppsInTossBridge();

      // 결제 요청
      final orderId = 'premium_${DateTime.now().millisecondsSinceEpoch}';

      final result = await bridge.requestPayment(
        PaymentRequest(
          orderId: orderId,
          orderName: '운세 프리미엄 + AI 상담 5회권',
          amount: 5000,
        ),
      );

      if (result.success) {
        // 프리미엄 활성화
        if (mounted) {
          context.read<DailyFortuneBloc>().add(const ActivatePremiumFeatures());
        }

        // AI 상담 크레딧 추가
        await CreditService.addCredits(5);

        // 성공 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프리미엄 기능이 활성화되었습니다! 🎉'),
              backgroundColor: AppColors.fortuneGood,
            ),
          );

          Navigator.of(context).pop();
        }
      } else {
        throw Exception('결제 실패');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
