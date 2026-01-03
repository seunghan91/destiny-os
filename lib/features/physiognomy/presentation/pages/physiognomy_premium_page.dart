import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/auth/auth_manager.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../data/services/physiognomy_premium_access_service.dart';
import '../../data/services/physiognomy_premium_payment_service.dart';
import '../../data/services/physiognomy_storage_service.dart';
import '../../data/services/physiognomy_analysis_service.dart';
import '../../data/services/image_picker_service.dart';

class PhysiognomyPremiumPage extends StatefulWidget {
  const PhysiognomyPremiumPage({super.key});

  @override
  State<PhysiognomyPremiumPage> createState() => _PhysiognomyPremiumPageState();
}

class _PhysiognomyPremiumPageState extends State<PhysiognomyPremiumPage> {
  final PhysiognomyAnalysisService _analysisService =
      PhysiognomyAnalysisService();

  bool _loadingAccess = true;
  int _remainingCredits = 0;
  bool _isPurchasing = false;
  bool _isAnalyzing = false;
  String? _report;
  String? _errorMessage;
  String? _infoMessage;
  String? _analysisStep;

  Uint8List? _selectedImageBytes;

  bool get _isAuthenticated => AuthManager().isAuthenticated;

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
    await PhysiognomyPremiumAccessService.initializeIfNeeded();
    final credits = await PhysiognomyPremiumAccessService.getCredits();
    if (!mounted) return;
    setState(() {
      _remainingCredits = credits;
      _loadingAccess = false;
    });
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인이 필요합니다'),
        content: const Text('관상 종합분석 1회권 결제/보관/재열람은 회원(로그인) 기반으로 제공됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
            },
            child: const Text('로그인하러 가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _openHistory() async {
    if (!AuthManager().isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    final items = await PhysiognomyStorageService.listReports(limit: 20);
    if (!mounted) return;

    if (items.isEmpty) {
      setState(() {
        _infoMessage = '저장된 보고서가 없습니다.';
      });
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '지난 관상 분석 보고서',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = items[index];
                      return ListTile(
                        title: Text(
                          '관상 종합분석',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${r.createdAt.toLocal()}'.split('.').first,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _report = r.reportMarkdown;
                            _errorMessage = null;
                            _infoMessage = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _purchase() async {
    if (!AuthManager().isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    var refundPolicyAgreed = false;
    if (!mounted) return;

    final agreed =
        await showDialog<bool>(
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
        ) ??
        false;

    if (!agreed || !mounted) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final ok = await PhysiognomyPremiumPaymentService.purchaseOneReport();
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

  Future<void> _selectImage() async {
    if (!kIsWeb) {
      setState(() {
        _errorMessage = '현재 웹(PWA/Apps in Toss)에서만 지원됩니다.';
      });
      return;
    }

    try {
      final imageBytes = await ImagePickerService.pickImage();
      if (imageBytes != null) {
        setState(() {
          _selectedImageBytes = imageBytes;
          _errorMessage = null;
          _infoMessage = '사진이 선택되었습니다. 분석을 시작하세요.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '사진 선택 중 오류: $e';
      });
    }
  }

  Future<void> _runAnalysis(DestinySuccess data) async {
    if (!AuthManager().isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    if (_remainingCredits <= 0) {
      setState(() {
        _errorMessage = '잔여 1회권이 없습니다. 결제 후 이용해주세요.';
      });
      return;
    }

    if (_selectedImageBytes == null) {
      setState(() {
        _errorMessage = '먼저 얼굴 사진을 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _infoMessage = null;
      _report = null;
      _analysisStep = '얼굴 특징 분석 중...';
    });

    try {
      final chart = data.sajuChart;
      final tenGods = data.tenGods;
      final fortune = data.fortune2026;
      final mbtiType = data.mbtiType.type;

      final sajuData = <String, dynamic>{
        'full_chart': chart.fullChart,
        'day_master': chart.dayMaster,
        'day_master_element': chart.dayMasterElement,
        'dominant_god': tenGods.dominantGod,
        'complementary_element': chart.complementaryElement,
        'zodiac_animal': chart.zodiacAnimal,
        'fortune_score': fortune.overallScore.toInt(),
        'year_theme': fortune.yearTheme,
      };

      setState(() => _analysisStep = '관상 분석 중...');

      // 전체 분석 파이프라인 실행
      final result = await _analysisService.runFullAnalysis(
        imageBytes: _selectedImageBytes!,
        sajuData: sajuData,
        tojungSummary: null, // 토정비결 요약은 선택적
        mbti: mbtiType,
      );

      setState(() => _analysisStep = '리포트 저장 중...');

      // 이미지 업로드
      String? imagePath;
      try {
        imagePath = await PhysiognomyStorageService.uploadFaceImage(
          _selectedImageBytes!,
        );
      } catch (e) {
        debugPrint('⚠️ Image upload failed (non-critical): $e');
      }

      // 카드 이미지 저장 (있는 경우)
      String? cardImagePath;
      if (result.cardImageBytes != null) {
        try {
          // 임시 ID로 저장 후 업데이트
          cardImagePath = await PhysiognomyStorageService.saveCardImage(
            result.cardImageBytes!,
            DateTime.now().millisecondsSinceEpoch.toString(),
          );
        } catch (e) {
          debugPrint('⚠️ Card image save failed (non-critical): $e');
        }
      }

      // DB에 저장
      final savedId = await PhysiognomyStorageService.saveReport(
        reportMarkdown: result.reportMarkdown,
        imagePath: imagePath,
        cardImagePath: cardImagePath,
        featuresJson: result.faceFeatures,
        sajuSnapshot: sajuData,
        mbti: mbtiType,
        model: 'gemini-2.5-flash',
        metadata: <String, dynamic>{
          'fortuneScore': fortune.overallScore.toInt(),
          'hasCardImage': result.cardImageBytes != null,
        },
      );

      if (savedId == null) {
        if (!mounted) return;
        setState(() {
          _report = result.reportMarkdown;
          _infoMessage = '보고서는 생성되었지만 저장에 실패했습니다. 네트워크를 확인 후 다시 시도해주세요.';
        });
        return;
      }

      // 크레딧 차감
      final consumed = await PhysiognomyPremiumAccessService.consumeOne();
      if (!consumed) {
        throw Exception('1회권 차감에 실패했습니다.');
      }

      await _loadAccess();
      if (!mounted) return;
      setState(() {
        _report = result.reportMarkdown;
        _infoMessage = '분석 완료! (저장 ID: $savedId)';
        _selectedImageBytes = null; // 초기화
        _analysisStep = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '분석 중 오류가 발생했습니다: $e';
        _analysisStep = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DestinyBloc, DestinyState>(
      builder: (context, state) {
        if (state is! DestinySuccess) {
          return Scaffold(
            appBar: AppBar(title: const Text('관상 종합분석')),
            body: const Center(child: Text('분석 데이터가 없습니다.\n먼저 사주 분석을 진행해주세요.')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: const Text('관상 종합분석'),
            backgroundColor: AppColors.surfaceOf(context),
            elevation: 0,
          ),
          body: SafeArea(
            child: _loadingAccess
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '관상 + 사주 + 토정 + MBTI\n통합 신년운세 리포트',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '정면 얼굴 사진을 업로드하면 AI가 관상을 분석하고,\n사주·토정·MBTI와 통합하여 2026 신년운세를 제공합니다.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 사진 가이드
                        _buildPhotoGuide(),
                        const SizedBox(height: 12),

                        // 사진 선택 버튼
                        _buildImageSelector(),
                        const SizedBox(height: 12),

                        _FeatureCard(
                          title: '포함 내용',
                          items: const [
                            '얼굴형/오관 관상 분석',
                            '사주+토정+MBTI 통합 해석',
                            '2026 신년운세 (연애/재물/직장/건강)',
                            '실행 체크리스트',
                            '요약 카드 이미지',
                          ],
                        ),
                        const SizedBox(height: 12),

                        _FeatureCard(
                          title: '잔여 이용권',
                          items: [
                            _isAuthenticated
                                ? '${_remainingCredits}회'
                                : '로그인 필요',
                          ],
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_isPurchasing || _isAnalyzing)
                                ? null
                                : _openHistory,
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
                              '지난 보고서 보기',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),
                        ),

                        if (_infoMessage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(25),
                              ),
                            ),
                            child: Text(
                              _infoMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ),
                        ],

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

                        if (_analysisStep != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _analysisStep!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (_report != null)
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxHeight: 400),
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

                        const SizedBox(height: 16),

                        // 메인 액션 버튼
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (_isPurchasing || _isAnalyzing)
                                ? null
                                : !_isAuthenticated
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _showLoginRequiredDialog();
                                  }
                                : (_remainingCredits > 0 &&
                                      _selectedImageBytes != null)
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _runAnalysis(state);
                                  }
                                : (_remainingCredits <= 0)
                                ? () {
                                    HapticFeedback.lightImpact();
                                    _purchase();
                                  }
                                : null,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _isAnalyzing
                                  ? '분석 중...'
                                  : _isPurchasing
                                  ? '결제 진행 중...'
                                  : !_isAuthenticated
                                  ? '로그인 후 이용하기'
                                  : (_remainingCredits <= 0)
                                  ? '5,000원 결제 후 1회 이용권 받기'
                                  : (_selectedImageBytes == null)
                                  ? '먼저 사진을 선택해주세요'
                                  : '관상 종합분석 시작 (1회 사용)',
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Text(
                          '⚠️ 면책: 이 분석은 전통 관상학 기반 엔터테인먼트입니다. 과학적 검증이 아니며, 중요한 의사결정 근거로 사용하지 마세요.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiaryOf(context),
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (_isPurchasing || _isAnalyzing)
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

  Widget _buildPhotoGuide() {
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
          Row(
            children: [
              const Text('📸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '사진 가이드',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            '정면 사진 (얼굴이 카메라를 정확히 바라봄)',
            '머리 상단 ~ 턱선까지 모두 포함',
            '밝은 조명, 그림자 최소화',
            '안경/마스크/과한 필터 제거 권장',
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondaryOf(context),
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

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: (_isAnalyzing || _isPurchasing) ? null : _selectImage,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: _selectedImageBytes != null
              ? AppColors.primary.withAlpha(10)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedImageBytes != null
                ? AppColors.primary
                : AppColors.borderOf(context),
            width: _selectedImageBytes != null ? 2 : 1,
          ),
        ),
        child: _selectedImageBytes != null
            ? Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImageBytes = null;
                          _infoMessage = null;
                        });
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 48,
                    color: AppColors.textTertiaryOf(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정면 얼굴 사진 선택',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '탭하여 사진 업로드',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiaryOf(context),
                    ),
                  ),
                ],
              ),
      ),
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
