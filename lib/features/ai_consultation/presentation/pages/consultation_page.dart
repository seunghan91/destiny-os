import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../../core/services/credit/unified_credit_service.dart';
import '../../../../core/services/auth/credit_service.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/services/ai_consultation_service.dart';
import '../../data/services/consultation_storage_service.dart';
import '../../data/services/consultation_payment_service.dart';

/// AI 상담 페이지
class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final AIConsultationService _aiService = AIConsultationService();
  ConsultationType? _selectedType;
  bool _isTyping = false;
  int _remainingCredits = 0;

  Future<void> _openRefundPolicy() async {
    final uri = Uri.parse('https://destiny-os-2026.web.app/refund');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 결제 필요 여부 확인 및 다이얼로그 표시
  Future<void> _checkPaymentRequired() async {
    // 페이지 로드 완료 후 확인
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final needsPayment = await ConsultationPaymentService.needsPayment();

    if (needsPayment && mounted) {
      _showPaymentDialog();
    }
  }

  /// 이전 세션 불러오기
  Future<void> _loadPreviousSession() async {
    final session = await ConsultationStorageService.loadCurrentSession();
    if (session != null && session.messages.isNotEmpty) {
      setState(() {
        _messages.addAll(session.messages);
        _selectedType = session.type;
      });
      _scrollToBottom();
    } else {
      _addWelcomeMessage();
    }
  }

  /// 현재 세션 자동 저장
  Future<void> _autoSaveSession() async {
    if (_selectedType != null && _messages.length > 1) {
      await ConsultationStorageService.saveCurrentSession(
        messages: _messages,
        type: _selectedType!,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _autoSaveSession();
    }
  }

  Future<void> _loadCredits() async {
    final credits = await UnifiedCreditService.getCredits();
    setState(() {
      _remainingCredits = credits;
    });
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content:
            '안녕하세요! 저는 사주와 MBTI 기반 AI 상담사입니다. 🔮\n\n'
            '당신의 운명을 분석하고 맞춤형 조언을 드릴게요.\n'
            '먼저 상담 유형을 선택해주세요.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 대화 히스토리에 저장
  Future<void> _saveToHistory() async {
    if (_selectedType == null || _messages.length <= 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장할 대화가 없습니다.')));
      return;
    }

    await ConsultationStorageService.saveConversation(
      messages: _messages,
      type: _selectedType!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('대화가 저장되었습니다.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 히스토리 페이지로 이동
  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _ConversationHistorySheet(onSelectConversation: _loadConversation),
    );
  }

  /// 특정 대화 불러오기
  Future<void> _loadConversation(String id, ConsultationType type) async {
    final messages = await ConsultationStorageService.getConversation(id);
    if (messages != null && mounted) {
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _selectedType = type;
      });
      _scrollToBottom();
      Navigator.pop(context);
    }
  }

  /// 새 대화 시작 확인
  void _confirmNewConversation() {
    if (_messages.length <= 1) {
      _startNewConversation();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 대화 시작'),
        content: const Text('현재 대화를 저장하고 새 대화를 시작할까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewConversation();
            },
            child: const Text('저장 안 함'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveToHistory();
              _startNewConversation();
            },
            child: const Text('저장 후 시작'),
          ),
        ],
      ),
    );
  }

  /// 새 대화 시작
  void _startNewConversation() {
    ConsultationStorageService.clearCurrentSession();
    setState(() {
      _messages.clear();
      _selectedType = null;
      _addWelcomeMessage();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectConsultationType(ConsultationType type) {
    setState(() {
      _selectedType = type;
      _messages.add(
        ChatMessage(
          id: 'type_${DateTime.now().millisecondsSinceEpoch}',
          content: '${type.emoji} ${type.korean}',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    // AI 응답 생성
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isTyping = true);
      _scrollToBottom();
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _generateContextualResponse(type);
    });
  }

  void _generateContextualResponse(ConsultationType type) {
    final destinyState = context.read<DestinyBloc>().state;
    String response;

    if (destinyState is DestinySuccess) {
      final dayMaster = destinyState.sajuChart.dayPillar.heavenlyStem;
      final mbti = destinyState.mbtiType.type;
      final yearScore = destinyState.fortune2026.overallScore.toInt();

      response = _buildPersonalizedResponse(type, dayMaster, mbti, yearScore);
    } else {
      response = _buildGenericResponse(type);
    }

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          id: 'response_${DateTime.now().millisecondsSinceEpoch}',
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    // 추천 질문 안내
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'suggest_${DateTime.now().millisecondsSinceEpoch}',
            content: '💡 아래 추천 질문을 탭하거나, 질문을 최대한 상세하게 입력해주세요!',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  String _buildPersonalizedResponse(
    ConsultationType type,
    String dayMaster,
    String mbti,
    int yearScore,
  ) {
    final element = _getDayMasterElement(dayMaster);

    switch (type) {
      case ConsultationType.career:
        return '${element.emoji} **$dayMaster 일간**과 **$mbti** 성격을 분석했습니다.\n\n'
            '2026년 직업운 점수: **$yearScore점**\n\n'
            '당신은 ${_getCareerStrength(dayMaster)}에 강점이 있어요. '
            '$mbti 특성상 ${_getMbtiCareerAdvice(mbti)}.\n\n'
            '올해는 ${yearScore >= 70 ? '새로운 도전에 유리한 해' : '내실을 다지는 데 집중할 해'}입니다.';
      case ConsultationType.relationship:
        return '💕 연애/결혼운을 분석했습니다.\n\n'
            '**$dayMaster 일간**의 관계 스타일: ${_getRelationshipStyle(dayMaster)}\n'
            '**$mbti**의 연애 특성: ${_getMbtiRelationshipStyle(mbti)}\n\n'
            '2026년 병오년은 화(火) 기운이 강한 해로, '
            '${element.name == '화' || element.name == '목' ? '인연운이 활발합니다' : '신중한 접근이 필요합니다'}.';
      case ConsultationType.finance:
        return '💰 재물운을 분석했습니다.\n\n'
            '**$dayMaster 일간**의 재물 성향: ${_getFinanceStyle(dayMaster)}\n\n'
            '2026년 재물 흐름:\n'
            '• 상반기: ${yearScore >= 70 ? '적극적 투자 가능' : '보수적 접근 권장'}\n'
            '• 5~6월: 화기 최고조, 주의 필요\n'
            '• 11월: 자오충(子午沖) 주의\n\n'
            '전체 재물운 점수: **$yearScore점**';
      case ConsultationType.health:
        return '🏃 건강운을 분석했습니다.\n\n'
            '**$dayMaster 일간**의 주의 장기: ${_getHealthFocus(dayMaster)}\n\n'
            '2026년 건강 조언:\n'
            '• 화(火) 기운이 강해 번아웃 주의\n'
            '• 규칙적인 휴식과 수분 섭취 필수\n'
            '• 5~7월 과열 주의기간\n\n'
            '$mbti 성격상 ${_getMbtiHealthAdvice(mbti)}';
      case ConsultationType.general:
        return '✨ 2026년 종합 운세(요약 + 실행 가이드)입니다.\n\n'
            '**$dayMaster 일간 + $mbti**\n'
            '종합 점수: **$yearScore점**\n\n'
            '${_getGeneralFortune(dayMaster, yearScore)}\n\n'
            '**올해의 방향성**: ${yearScore >= 75 ? '도약/확장' : '내실/준비'}\n'
            '**핵심 키워드**: ${yearScore >= 75 ? '도약, 성취, 확장' : '내실, 준비, 신중'}\n'
            '**주의 시기**: 11월 (자오충)\n\n'
            '**실행 팁(3가지)**\n'
            '• 일을 벌리기보다 “하나를 끝내는 힘”을 우선순위로 두세요.\n'
            '• 관계는 속도보다 기준이 중요합니다. 불편한 신호는 초기에 정리하세요.\n'
            '• 금전은 5~6월 과열 구간을 특히 조심하고, 계획된 소비만 하세요.\n\n'
            '원하시면 “직업/연애/재물/건강” 중 하나를 골라 더 깊게 이어갈게요.';
    }
  }

  String _buildGenericResponse(ConsultationType type) {
    switch (type) {
      case ConsultationType.career:
        return '직업/진로 상담을 시작합니다.\n\n'
            '더 정확한 분석을 위해 먼저 사주 분석을 완료해주세요.\n'
            '일반적인 질문에는 답변드릴 수 있습니다.';
      case ConsultationType.relationship:
        return '연애/결혼 상담을 시작합니다.\n\n'
            '사주 정보가 있으면 더 맞춤형 조언이 가능해요.\n'
            '궁금한 점을 자유롭게 물어보세요!';
      case ConsultationType.finance:
        return '재물/투자 상담을 시작합니다.\n\n'
            '2026년 병오년은 화(火) 기운이 강한 해입니다.\n'
            '변동성이 클 수 있으니 신중한 접근을 권장합니다.';
      case ConsultationType.health:
        return '건강/웰빙 상담을 시작합니다.\n\n'
            '2026년은 화 에너지가 강해 번아웃에 주의하세요.\n'
            '규칙적인 휴식이 중요합니다.';
      case ConsultationType.general:
        return '종합 상담을 시작합니다.\n\n'
            '어떤 것이든 물어보세요!\n'
            '사주 분석을 먼저 완료하면 더 정확한 조언이 가능합니다.';
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 크레딧 확인
    if (_remainingCredits <= 0) {
      _showNoCreditDialog();
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          content: text.trim(),
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // 크레딧 차감 (통합 크레딧 서비스 사용)
    final newCredits = await UnifiedCreditService.useCredit(
      feature: FeatureType.aiConsultation,
      description: 'AI 상담 사용',
    );
    if (newCredits >= 0) {
      setState(() {
        _remainingCredits = newCredits;
      });
    }

    // AI 응답 생성
    await _generateAIResponse(text);
  }

  void _showNoCreditDialog() {
    _showPaymentDialog();
  }

  /// 베타 테스트용: 결제 없이 다시하기 (크레딧 1회 임시 지급 + 대화 초기화)
  Future<void> _handleBetaRetry() async {
    // 웹에서만 노출/동작하도록 제한 (스토어 심사/정책 리스크 최소화)
    if (!kIsWeb) return;

    await UnifiedCreditService.addCredits(
      1,
      type: CreditTransactionType.bonus,
      description: '베타 테스트: 다시하기(임시 크레딧 1회)',
    );

    await _loadCredits();
    if (!mounted) return;

    _startNewConversation();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('베타 테스트: 크레딧 1회가 임시로 지급되었습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 결제 다이얼로그 표시
  void _showPaymentDialog() {
    var refundPolicyAgreed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('AI 운세 상담'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ConsultationPaymentService.getPurchaseMessage(),
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fortuneGood.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.fortuneGood.withAlpha(30),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      color: AppColors.fortuneGood,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '크레딧 5회',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.fortuneGood,
                            ),
                          ),
                          Text(
                            '5,000원',
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                  '[필수] 질문(질의) 실행 즉시 디지털 콘텐츠가 제공되며, 실행 후 환불이 제한될 수 있음을 확인했고, ',
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '중요 안내: 결제한 크레딧(사용권)은 “회원(로그인) 계정”에만 유지됩니다.\n'
                        '비로그인(게스트) 상태에서 결제/사용한 크레딧은 브라우저/앱 데이터 삭제, 기기 변경, 재설치, 캐시 초기화 등으로 소실될 수 있으며, 이 경우 복구/이전이 불가합니다.\n'
                        '회원가입(로그인)을 하지 않아 발생한 크레딧 소실/이용 불가 등 문제에 대해 서비스 제공자는 책임을 지지 않습니다.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondaryOf(context),
                          height: 1.45,
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
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: TextStyle(color: AppColors.textSecondaryOf(context)),
              ),
            ),
            if (kIsWeb)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _handleBetaRetry();
                },
                child: Text(
                  '베타테스트니까 그냥 다시하기',
                  style: TextStyle(color: AppColors.textSecondaryOf(context)),
                ),
              ),
            if (!UnifiedCreditService.isLoggedIn)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // 설정 > 계정 섹션에서 바로 로그인 가능
                  this.context.push('/settings');
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('결제한 크레딧을 유지하려면 회원가입/로그인이 필요합니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline, size: 20),
                label: const Text('회원가입/로그인 후 결제하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: refundPolicyAgreed
                    ? () async {
                        Navigator.pop(context);
                        await _handlePayment();
                      }
                    : null,
                icon: const Icon(Icons.payment_rounded, size: 20),
                label: const Text('결제하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 결제 처리
  Future<void> _handlePayment() async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success =
          await ConsultationPaymentService.purchaseConsultationCredits();

      if (!mounted) return;

      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (success) {
        // 크레딧 새로고침
        await _loadCredits();
        if (!mounted) return;

        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('결제가 완료되었습니다! 크레딧 5회가 충전되었어요.'),
            backgroundColor: AppColors.fortuneGood,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // 실패 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('결제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.fire,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.fire,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateAIResponse(String userMessage) async {
    final destinyState = context.read<DestinyBloc>().state;

    String? sajuInfo;
    String? mbtiType;
    int? fortuneScore;

    if (destinyState is DestinySuccess) {
      final chart = destinyState.sajuChart;
      final tenGods = destinyState.tenGods;

      sajuInfo =
          '일주: ${chart.dayPillar.fullPillar}(${chart.dayPillar.hanjaRepresentation}), '
          '일간: ${chart.dayMaster}, '
          '월지: ${chart.monthPillar.earthlyBranch}, '
          '강한 십성: ${tenGods.dominantGod}, '
          '부족한 오행: ${chart.complementaryElement}';

      mbtiType = destinyState.mbtiType.type;
      fortuneScore = destinyState.fortune2026.overallScore.toInt();
    }

    final history = _messages
        .where(
          (m) =>
              m.id != 'welcome' &&
              !m.content.startsWith('💡') &&
              m.status != MessageStatus.error,
        )
        .toList();

    if (history.isNotEmpty &&
        history.last.isUser &&
        history.last.content.trim() == userMessage.trim()) {
      history.removeLast();
    }

    const maxHistoryCount = 16;
    final trimmedHistory = history.length > maxHistoryCount
        ? history.sublist(history.length - maxHistoryCount)
        : history;

    final conversationMessages = trimmedHistory
        .map(
          (m) => <String, String>{
            'role': m.isUser ? 'user' : 'assistant',
            'content': m.content,
          },
        )
        .toList();

    try {
      final response = await _aiService.generateResponse(
        userMessage: userMessage,
        consultationType: _selectedType?.korean ?? '종합 상담',
        sajuInfo: sajuInfo,
        mbtiType: mbtiType,
        fortuneScore: fortuneScore,
        conversationMessages: conversationMessages.isEmpty
            ? null
            : conversationMessages,
      );

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              content: response,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              id: 'error_${DateTime.now().millisecondsSinceEpoch}',
              content: '죄송합니다. 일시적인 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
              isUser: false,
              timestamp: DateTime.now(),
              status: MessageStatus.error,
            ),
          );
        });
        _scrollToBottom();

        // 오류 시 크레딧 환불
        await UnifiedCreditService.addCredits(
          1,
          type: CreditTransactionType.refund,
          description: 'AI 상담 오류 환불',
        );
        await _loadCredits();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('AI 운세 상담'),
        actions: [
          // 크레딧 표시
          Tooltip(
            message: '질문 1회당 크레딧 1회가 차감됩니다.',
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingCredits > 0
                    ? AppColors.primary.withAlpha(25)
                    : AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.stars,
                    size: 16,
                    color: _remainingCredits > 0
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_remainingCredits',
                    style: AppTypography.labelMedium.copyWith(
                      color: _remainingCredits > 0
                          ? AppColors.primary
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 히스토리 버튼
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '대화 기록',
            onPressed: _showHistory,
          ),
          // 메뉴 버튼
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _saveToHistory();
                  break;
                case 'new':
                  _confirmNewConversation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(Icons.save_alt, size: 20),
                    SizedBox(width: 12),
                    Text('대화 저장'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add_comment, size: 20),
                    SizedBox(width: 12),
                    Text('새 대화'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 채팅 메시지 리스트
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length +
                  (_isTyping ? 1 : 0) +
                  (_selectedType == null ? 1 : 0),
              itemBuilder: (context, index) {
                // 상담 유형 선택 UI
                if (_selectedType == null && index == _messages.length) {
                  return _buildConsultationTypeSelector();
                }

                // 타이핑 인디케이터
                if (_isTyping &&
                    index ==
                        _messages.length + (_selectedType == null ? 1 : 0)) {
                  return _buildTypingIndicator();
                }

                // 메시지
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index]);
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // 추천 질문 (상담 유형 선택 후)
          if (_selectedType != null && !_isTyping) _buildSuggestedQuestions(),

          // 메시지 입력창
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: ConsultationType.values.map((type) {
          return InkWell(
            onTap: () => _selectConsultationType(type),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    type.korean,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Text('🔮', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : AppColors.surfaceOf(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowOf(
                      context,
                      lightOpacity: 0.05,
                      darkOpacity: 0.12,
                    ),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isUser
                  ? Text(
                      message.content,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet:
                          MarkdownStyleSheet.fromTheme(
                            Theme.of(context),
                          ).copyWith(
                            p: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              height: 1.5,
                            ),
                            strong: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
                            listBullet: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textPrimaryOf(context),
                              height: 1.5,
                            ),
                          ),
                    ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Text('🔮', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_buildDot(0), _buildDot(1), _buildDot(2)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textTertiaryOf(
              context,
            ).withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildSuggestedQuestions() {
    if (_selectedType == null) return const SizedBox.shrink();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedType!.sampleQuestions.length,
        itemBuilder: (context, index) {
          final question = _selectedType!.sampleQuestions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              label: Text(
                question,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              onPressed: () => _sendMessage(question),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '안내: 이 질의는 실행 즉시 제공되며, 실행 후 환불이 제한될 수 있어요.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryOf(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '질문을 최대한 상세하게 입력해주세요...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundOf(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _sendMessage(_messageController.text),
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods
  _ElementInfo _getDayMasterElement(String stem) {
    const mapping = {
      '갑': _ElementInfo('목', '🌳'),
      '을': _ElementInfo('목', '🌿'),
      '병': _ElementInfo('화', '☀️'),
      '정': _ElementInfo('화', '🕯️'),
      '무': _ElementInfo('토', '⛰️'),
      '기': _ElementInfo('토', '🏔️'),
      '경': _ElementInfo('금', '⚔️'),
      '신': _ElementInfo('금', '💎'),
      '임': _ElementInfo('수', '🌊'),
      '계': _ElementInfo('수', '💧'),
    };
    return mapping[stem] ?? const _ElementInfo('토', '⛰️');
  }

  String _getCareerStrength(String stem) {
    const mapping = {
      '갑': '리더십과 개척 정신',
      '을': '유연한 협상력과 네트워킹',
      '병': '추진력과 영향력',
      '정': '섬세한 전문성',
      '무': '안정적인 조직 관리',
      '기': '실무와 중재 능력',
      '경': '결단력과 실행력',
      '신': '정밀함과 디테일',
      '임': '지혜와 전략적 사고',
      '계': '적응력과 직관',
    };
    return mapping[stem] ?? '다양한 분야에서의 역량';
  }

  String _getMbtiCareerAdvice(String mbti) {
    if (mbti.startsWith('E')) {
      return '팀 협업과 대외 활동이 많은 역할이 적합합니다';
    } else {
      return '깊이 있는 전문 분야에서 두각을 나타낼 수 있습니다';
    }
  }

  String _getRelationshipStyle(String stem) {
    const mapping = {
      '갑': '주도적이고 당당한 스타일',
      '을': '부드럽고 조화로운 스타일',
      '병': '열정적이고 적극적인 스타일',
      '정': '섬세하고 배려 깊은 스타일',
      '무': '듬직하고 안정적인 스타일',
      '기': '다정하고 헌신적인 스타일',
      '경': '카리스마 있고 솔직한 스타일',
      '신': '꼼꼼하고 신중한 스타일',
      '임': '지혜롭고 포용적인 스타일',
      '계': '감성적이고 직관적인 스타일',
    };
    return mapping[stem] ?? '균형 잡힌 스타일';
  }

  String _getMbtiRelationshipStyle(String mbti) {
    if (mbti.contains('F')) {
      return '감정적 교감을 중시하는 연애';
    } else {
      return '논리적이고 솔직한 의사소통 선호';
    }
  }

  String _getFinanceStyle(String stem) {
    const mapping = {
      '갑': '대담한 투자, 큰 그림',
      '을': '유연한 재테크, 인맥 활용',
      '병': '공격적 투자, 트렌드 선도',
      '정': '꼼꼼한 관리, 안정 추구',
      '무': '부동산, 장기 투자',
      '기': '실속 재테크, 저축형',
      '경': '결단력 있는 투자',
      '신': '분석적 접근, 분산 투자',
      '임': '직관적 투자, 대세 파악',
      '계': '소액 다양화, 적금형',
    };
    return mapping[stem] ?? '균형 잡힌 재테크';
  }

  String _getHealthFocus(String stem) {
    const mapping = {
      '갑': '간, 담낭 (목 오행)',
      '을': '간, 신경계 (목 오행)',
      '병': '심장, 소장 (화 오행)',
      '정': '심장, 혈액순환 (화 오행)',
      '무': '위, 비장 (토 오행)',
      '기': '소화기, 피부 (토 오행)',
      '경': '폐, 대장 (금 오행)',
      '신': '호흡기, 피부 (금 오행)',
      '임': '신장, 방광 (수 오행)',
      '계': '생식기, 호르몬 (수 오행)',
    };
    return mapping[stem] ?? '전반적인 건강 관리';
  }

  String _getMbtiHealthAdvice(String mbti) {
    if (mbti.contains('J')) {
      return '규칙적인 운동 루틴이 잘 맞습니다';
    } else {
      return '다양한 활동으로 지루함을 피하세요';
    }
  }

  String _getGeneralFortune(String stem, int score) {
    if (score >= 80) {
      return '2026년은 $stem 일간에게 크게 유리한 해입니다. '
          '적극적으로 도전하고 기회를 잡으세요!';
    } else if (score >= 60) {
      return '2026년은 성장의 기회가 있는 해입니다. '
          '무리하지 않으면서 꾸준히 나아가세요.';
    } else {
      return '2026년은 내실을 다지는 해입니다. '
          '급한 결정보다 충분한 준비가 필요합니다.';
    }
  }
}

class _ElementInfo {
  final String name;
  final String emoji;

  const _ElementInfo(this.name, this.emoji);
}

/// 대화 기록 히스토리 시트
class _ConversationHistorySheet extends StatefulWidget {
  final Future<void> Function(String id, ConsultationType type)
  onSelectConversation;

  const _ConversationHistorySheet({required this.onSelectConversation});

  @override
  State<_ConversationHistorySheet> createState() =>
      _ConversationHistorySheetState();
}

class _ConversationHistorySheetState extends State<_ConversationHistorySheet> {
  List<ConversationSummary> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations =
        await ConsultationStorageService.getAllConversations();
    if (mounted) {
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConversation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 삭제'),
        content: const Text('이 대화를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ConsultationStorageService.deleteConversation(id);
      _loadConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiaryOf(context).withAlpha(120),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '대화 기록',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 대화 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _conversations.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.textTertiaryOf(context).withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            '저장된 대화가 없습니다',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '대화를 저장하면 여기에 표시됩니다',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ConversationSummary conversation) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
      ),
      confirmDismiss: (_) async {
        await _deleteConversation(conversation.id);
        return false;
      },
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              conversation.type.emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Text(
              conversation.type.korean,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${conversation.messageCount}개 메시지',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiaryOf(context),
              ),
            ),
          ],
        ),
        trailing: Text(
          conversation.formattedDate,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiaryOf(context),
          ),
        ),
        onTap: () =>
            widget.onSelectConversation(conversation.id, conversation.type),
      ),
    );
  }
}
