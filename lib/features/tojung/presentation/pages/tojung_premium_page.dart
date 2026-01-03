import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../ai_consultation/data/services/ai_consultation_service.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../data/services/tojung_premium_access_service.dart';
import '../../data/services/tojung_premium_payment_service.dart';

class TojungPremiumPage extends StatefulWidget {
  const TojungPremiumPage({super.key});

  @override
  State<TojungPremiumPage> createState() => _TojungPremiumPageState();
}

class _TojungPremiumPageState extends State<TojungPremiumPage> {
  final AIConsultationService _aiService = AIConsultationService();

  bool _loadingAccess = true;
  int _remainingCredits = 0;
  bool _isPurchasing = false;
  bool _isGenerating = false;
  String? _report;
  String? _errorMessage;

  Future<void> _openRefundPolicy() async {
    final uri = Uri.parse('https://destiny-os-2026.web.app/refund');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    await TojungPremiumAccessService.initializeIfNeeded();
    final credits = await TojungPremiumAccessService.getCredits();
    if (!mounted) return;
    setState(() {
      _remainingCredits = credits;
      _loadingAccess = false;
    });
  }

  Future<void> _purchase() async {
    var refundPolicyAgreed = false;
    if (!mounted) return;
    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('결제 전 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안내: 결제 후 보고서 생성(실행) 즉시 디지털 콘텐츠가 제공되며, 실행 후 환불이 제한될 수 있어요.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondaryOf(context),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: refundPolicyAgreed,
                      onChanged: (v) {
                        setDialogState(() {
                          refundPolicyAgreed = v ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  '[필수] 보고서 생성(실행) 즉시 디지털 콘텐츠가 제공되며, 실행 후 환불이 제한될 수 있음을 확인했고, ',
                            ),
                            TextSpan(
                              text: '환불(청약철회) 정책',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _openRefundPolicy,
                            ),
                            const TextSpan(text: '에 동의합니다.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              ),
            ),
            ElevatedButton(
              onPressed: refundPolicyAgreed
                  ? () => Navigator.pop(context, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('동의하고 결제하기'),
            ),
          ],
        ),
      ),
    );

    if (agreed != true) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    try {
      final ok = await TojungPremiumPaymentService.purchaseOneReport();
      if (!ok) {
        setState(() {
          _errorMessage = '결제에 실패했습니다. 잠시 후 다시 시도해주세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '결제 중 오류가 발생했습니다: $e';
      });
    } finally {
      await _loadAccess();
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _generateReport(DestinySuccess data) async {
    if (_remainingCredits <= 0) {
      setState(() {
        _errorMessage = '잔여 1회권이 없습니다. 결제 후 이용해주세요.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _report = null;
    });

    try {
      final chart = data.sajuChart;
      final tenGods = data.tenGods;
      final fortune = data.fortune2026;

      final sajuInfo =
          '사주팔자: ${chart.fullChart}, '
          '일주: ${chart.dayPillar.fullPillar}(${chart.dayPillar.hanjaRepresentation}), '
          '일간: ${chart.dayMaster}(${chart.dayMasterElement}), '
          '월지: ${chart.monthPillar.earthlyBranch}, '
          '강한 십성: ${tenGods.dominantGod}, '
          '부족한 오행(보완): ${chart.complementaryElement}, '
          '띠: ${chart.zodiacAnimal}';

      final mbtiType = data.mbtiType.type;
      final fortuneScore = fortune.overallScore.toInt();

      final userMessage =
          '심층 토정비결(신년운세) 방식으로 2026년 종합분석 보고서를 작성해줘.\n'
          '반드시 아래 형식을 지켜서, 매우 구체적인 실행 조언까지 포함해줘.\n\n'
          '## 1) 한 장 요약\n'
          '- 올해의 키워드 3개\n'
          '- 총운 요약 5줄\n\n'
          '## 2) 사주(타고난 기질) vs MBTI(현재 성향) 통합\n'
          '- 강점/리스크\n'
          '- 올해 흔들리는 지점\n\n'
          '## 3) 2026 월별 흐름(1~12월)\n'
          '- 각 월마다: 테마 / 좋은 행동 2개 / 피할 행동 2개 / 체크포인트 1개\n\n'
          '## 4) 분야별 심층 조언\n'
          '- 재물/일/관계/건강: 각각 핵심전략 + 실수패턴 + 체크리스트\n\n'
          '## 5) 30일 실행 플랜\n'
          '- 주차별(1~4주) 해야 할 일\n\n'
          '## 6) 올해의 경고 3개\n'
          '- 왜 위험한지와 회피법\n\n'
          '마지막에는 “다음에 더 깊게 볼 질문 3개”를 제안해줘.';

      final report = await _aiService.generateResponse(
        userMessage: userMessage,
        consultationType: '토정비결 종합분석',
        sajuInfo: sajuInfo,
        mbtiType: mbtiType,
        fortuneScore: fortuneScore,
        taskType: AITaskType.analysis,
      );

      final consumed = await TojungPremiumAccessService.consumeOne();
      if (!consumed) {
        throw Exception('1회권 차감에 실패했습니다.');
      }

      await _loadAccess();
      if (!mounted) return;
      setState(() {
        _report = report;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '보고서 생성 중 오류가 발생했습니다: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyBloc, DestinyState>(
      builder: (context, state) {
        if (state is! DestinySuccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('심층 토정비결')),
            body: const Center(child: Text('분석 데이터가 없습니다.\n먼저 사주 분석을 진행해주세요.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: const Text('심층 토정비결'),
            backgroundColor: AppColors.surfaceOf(context),
            elevation: 0,
          ),
          body: SafeArea(
            child: _loadingAccess
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '사주 + 토정비결 + MBTI\n종합분석 & 신년운세',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '전용 1회권(5,000원)으로 종합 보고서를 생성합니다.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FeatureCard(
                          title: '포함 내용',
                          items: const [
                            '한 장 요약(키워드/총운)',
                            '사주+MBTI 통합 분석',
                            '월별(1~12월) 흐름',
                            '재물/일/관계/건강 심층 조언',
                            '30일 실행 플랜',
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FeatureCard(
                          title: '잔여 이용권',
                          items: ['${_remainingCredits}회'],
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.error.withAlpha(40),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (_report != null)
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceOf(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.borderOf(context),
                                ),
                              ),
                              child: Markdown(data: _report!, selectable: true),
                            ),
                          )
                        else
                          const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_isPurchasing || _isGenerating)
                                ? null
                                : (_remainingCredits > 0)
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _generateReport(state);
                                  }
                                : () {
                                    HapticFeedback.lightImpact();
                                    _purchase();
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _isGenerating
                                  ? '보고서 생성 중…'
                                  : _isPurchasing
                                  ? '결제 진행 중…'
                                  : (_remainingCredits > 0)
                                  ? '종합분석 생성하기 (1회 사용)'
                                  : '5,000원 결제 후 1회 이용권 받기',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '안내: 보고서 생성(실행) 즉시 디지털 콘텐츠가 제공되며, 실행 후 환불이 제한될 수 있어요.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_isPurchasing || _isGenerating)
                                ? null
                                : () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: AppColors.borderOf(context),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              '닫기',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FeatureCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
