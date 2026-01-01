import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/constants/typography.dart';
import '../../../saju/presentation/bloc/destiny_bloc.dart';
import '../../domain/entities/chat_message.dart';

/// AI 상담 페이지
class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  ConsultationType? _selectedType;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        content: '안녕하세요! 저는 사주와 MBTI 기반 AI 상담사입니다. 🔮\n\n'
            '당신의 운명을 분석하고 맞춤형 조언을 드릴게요.\n'
            '먼저 상담 유형을 선택해주세요.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            content: '💡 아래 추천 질문을 탭하거나, 궁금한 점을 직접 입력해주세요!',
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
        return '✨ 2026년 종합 운세입니다.\n\n'
            '**$dayMaster 일간 + $mbti**\n'
            '종합 점수: **$yearScore점**\n\n'
            '${_getGeneralFortune(dayMaster, yearScore)}\n\n'
            '핵심 키워드: ${yearScore >= 75 ? '도약, 성취, 확장' : '내실, 준비, 신중'}\n'
            '주의 시기: 11월 (자오충)';
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

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

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

    // AI 응답 시뮬레이션
    Future.delayed(const Duration(milliseconds: 1500), () {
      _generateAIResponse(text);
    });
  }

  void _generateAIResponse(String userMessage) {
    final destinyState = context.read<DestinyBloc>().state;
    String response;

    if (destinyState is DestinySuccess) {
      response = _buildSmartResponse(userMessage, destinyState);
    } else {
      response = _buildDefaultResponse(userMessage);
    }

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

  String _buildSmartResponse(String question, DestinySuccess state) {
    final lowerQ = question.toLowerCase();
    final score = state.fortune2026.overallScore;
    final mbti = state.mbtiType.type;

    if (lowerQ.contains('이직') || lowerQ.contains('퇴사')) {
      return '🎯 이직에 대한 조언입니다.\n\n'
          '당신의 2026년 운세 점수(${score.toInt()}점)를 고려할 때, '
          '${score >= 70 ? '상반기에 좋은 기회가 올 수 있습니다' : '하반기까지 더 준비하는 것을 권장합니다'}.\n\n'
          '특히 11월은 중요한 결정을 피하세요.';
    }

    if (lowerQ.contains('연애') || lowerQ.contains('인연') || lowerQ.contains('만남')) {
      return '💕 연애운에 대한 조언입니다.\n\n'
          '2026년 병오년은 화(火) 에너지가 넘쳐 열정적인 만남이 기대됩니다.\n'
          '5~6월이 가장 인연운이 좋은 시기예요.\n\n'
          '다만 너무 급하게 진행하지 말고, 상대를 충분히 알아가세요.';
    }

    if (lowerQ.contains('투자') || lowerQ.contains('주식') || lowerQ.contains('돈')) {
      return '💰 재물운에 대한 조언입니다.\n\n'
          '2026년 재물운: ${score.toInt()}점\n\n'
          '${score >= 75 ? '적극적인 투자가 가능한 해입니다' : '보수적인 접근을 권장합니다'}.\n'
          '단, 11월 자오충 시기에는 큰 결정을 피하세요.';
    }

    if (lowerQ.contains('건강') || lowerQ.contains('운동')) {
      return '🏃 건강에 대한 조언입니다.\n\n'
          '2026년은 화 에너지가 강해 다음을 주의하세요:\n'
          '• 과로와 번아웃\n'
          '• 심장과 혈압 관리\n'
          '• 충분한 수분 섭취\n\n'
          '수(水) 기운의 활동(수영, 명상)이 도움됩니다.';
    }

    // 기본 응답
    return '좋은 질문이에요! 🌟\n\n'
        '당신의 $mbti 성격과 사주를 종합해보면,\n'
        '2026년은 ${score >= 70 ? '도약의 해' : '준비의 해'}가 될 것입니다.\n\n'
        '더 구체적인 질문을 해주시면 자세히 답변드릴게요!';
  }

  String _buildDefaultResponse(String question) {
    return '좋은 질문이에요! 🌟\n\n'
        '더 정확한 답변을 드리려면 먼저 사주 분석이 필요합니다.\n'
        '홈에서 생년월일을 입력하고 분석을 완료해주세요.\n\n'
        '일반적인 2026년 운세: 화(火) 에너지가 강한 해로, '
        '변화와 도전의 기회가 많습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI 운세 상담'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _selectedType = null;
                _addWelcomeMessage();
              });
            },
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
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_selectedType == null ? 1 : 0),
              itemBuilder: (context, index) {
                // 상담 유형 선택 UI
                if (_selectedType == null && index == _messages.length) {
                  return _buildConsultationTypeSelector();
                }

                // 타이핑 인디케이터
                if (_isTyping && index == _messages.length + (_selectedType == null ? 1 : 0)) {
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
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                    : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: AppTypography.bodyMedium.copyWith(
                  color: message.isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.5,
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
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
            color: AppColors.textTertiary.withValues(alpha: 0.3 + (value * 0.7)),
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
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '질문을 입력하세요...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.background,
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
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
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
