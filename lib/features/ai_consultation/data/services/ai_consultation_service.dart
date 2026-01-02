import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/env_config.dart';

/// AI 상담 유형
enum AITaskType {
  consultation, // 상담 (GPT-4o 사용)
  analysis, // 분석 (Gemini 2.5 Flash 사용)
}

/// AI 상담 서비스 - BizRouter API 연동
class AIConsultationService {
  final Dio _dio;

  AIConsultationService({Dio? dio}) : _dio = dio ?? Dio();

  /// AI 상담 응답 생성
  Future<String> generateResponse({
    required String userMessage,
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
    List<Map<String, String>>? conversationMessages,
    AITaskType taskType = AITaskType.consultation,
  }) async {
    // 1. BizRouter API 사용 (권장)
    if (EnvConfig.hasBizRouterKey) {
      try {
        return await _callBizRouter(
          userMessage: userMessage,
          consultationType: consultationType,
          sajuInfo: sajuInfo,
          mbtiType: mbtiType,
          fortuneScore: fortuneScore,
          conversationMessages: conversationMessages,
          taskType: taskType,
        );
      } catch (e) {
        debugPrint('BizRouter API failed, falling back: $e');
      }
    }

    // 2. Supabase Edge Function 사용 시도
    if (EnvConfig.hasSupabaseKey) {
      try {
        return await _callSupabaseEdgeFunction(
          userMessage: userMessage,
          consultationType: consultationType,
          sajuInfo: sajuInfo,
          mbtiType: mbtiType,
          fortuneScore: fortuneScore,
        );
      } catch (e) {
        debugPrint('Edge Function failed, falling back to direct API: $e');
      }
    }

    // 3. OpenAI 직접 호출
    if (EnvConfig.hasOpenAiKey) {
      try {
        return await _callOpenAiDirect(
          userMessage: userMessage,
          consultationType: consultationType,
          sajuInfo: sajuInfo,
          mbtiType: mbtiType,
          fortuneScore: fortuneScore,
          conversationMessages: conversationMessages,
        );
      } catch (e) {
        debugPrint('OpenAI API failed: $e');
      }
    }

    // 4. API 미설정 시 로컬 응답 생성
    return _generateLocalResponse(
      userMessage: userMessage,
      consultationType: consultationType,
      sajuInfo: sajuInfo,
      mbtiType: mbtiType,
      fortuneScore: fortuneScore,
    );
  }

  /// BizRouter API 호출
  /// - 상담: GPT-4o (감성적, 자연스러운 대화)
  /// - 분석: Gemini 2.5 Flash (빠르고 저렴)
  Future<String> _callBizRouter({
    required String userMessage,
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
    List<Map<String, String>>? conversationMessages,
    required AITaskType taskType,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      consultationType: consultationType,
      sajuInfo: sajuInfo,
      mbtiType: mbtiType,
      fortuneScore: fortuneScore,
    );

    // 태스크 유형에 따라 모델 선택
    final model = taskType == AITaskType.consultation
        ? EnvConfig
              .consultationModel // GPT-4o
        : EnvConfig.analysisModel; // Gemini 2.5 Flash

    final response = await _dio.post(
      '${EnvConfig.bizRouterBaseUrl}/chat/completions',
      options: Options(
        headers: {
          'X-API-Key': EnvConfig.bizRouterApiKey,
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...?conversationMessages,
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 500,
        'temperature': taskType == AITaskType.consultation ? 0.8 : 0.3,
      },
    );

    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'] as String;
    }

    throw Exception('BizRouter API error: ${response.statusCode}');
  }

  /// Supabase Edge Function 호출
  Future<String> _callSupabaseEdgeFunction({
    required String userMessage,
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
  }) async {
    final response = await _dio.post(
      EnvConfig.aiConsultationUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${EnvConfig.supabaseAnonKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'userMessage': userMessage,
        'consultationType': consultationType,
        'sajuInfo': sajuInfo,
        'mbtiType': mbtiType,
        'fortuneScore': fortuneScore,
      },
    );

    if (response.statusCode == 200 && response.data['success'] == true) {
      return response.data['response'] as String;
    }

    throw Exception('Edge Function error: ${response.data['error']}');
  }

  /// OpenAI API 직접 호출
  Future<String> _callOpenAiDirect({
    required String userMessage,
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
    List<Map<String, String>>? conversationMessages,
  }) async {
    final systemPrompt = _buildSystemPrompt(
      consultationType: consultationType,
      sajuInfo: sajuInfo,
      mbtiType: mbtiType,
      fortuneScore: fortuneScore,
    );

    final response = await _dio.post(
      '${EnvConfig.openAiBaseUrl}/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer ${EnvConfig.openAiApiKey}',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': EnvConfig.openAiModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...?conversationMessages,
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 500,
        'temperature': 0.7,
      },
    );

    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'] as String;
    }

    throw Exception('OpenAI API error: ${response.statusCode}');
  }

  /// 시스템 프롬프트 생성
  String _buildSystemPrompt({
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
  }) {
    String userContext = '';
    if (sajuInfo != null) userContext += '사용자 사주(타고난 성향): $sajuInfo\n';
    if (mbtiType != null) userContext += '사용자 MBTI(현재/후천적 성향): $mbtiType\n';
    if (fortuneScore != null) userContext += '2026년 운세 점수: $fortuneScore점\n';

    return '''
당신은 사주와 MBTI를 결합하여 분석하는 전문 상담사 'BizRouter GPT'입니다.
2026년 병오년(丙午年)의 강한 화(火) 에너지를 바탕으로 사용자의 운세를 심층 분석합니다.

[분석 철학]
1. 사주는 사용자가 타고난 '기질'과 '잠재력'입니다.
2. MBTI는 사용자가 살아가면서 형성된 '현재의 성향'과 '사회적 페르소나'입니다.
3. 이 둘의 차이(Gap)를 분석하여, 타고난 기질을 어떻게 현재의 성향과 조화시켜 2026년을 살아가야 할지 조언합니다.

상담 유형: $consultationType

[사용자 데이터]
$userContext

[상담 지침]
1. **성향 융합 분석**: 타고난 사주 기질과 현재의 MBTI 성향이 일치하는지, 혹은 다른지를 먼저 언급하며 상담을 시작하세요. (예: "타고난 열정적인 기질이 현재의 신중한 MBTI와 만나 균형을 이루고 있군요")
2. **2026년 병오년 특화**: 2026년의 강한 화(火) 기운이 사용자의 타고난 기질과 현재 성향에 어떤 영향을 줄지 구체적으로 설명하세요.
3. **심층 조언**: 단순한 운세 풀이를 넘어, 사용자가 2026년에 취해야 할 구체적인 행동 전략(직업, 인간관계, 금전 등)을 제시하세요.
4. **결제 유도 연계**: 상담 마지막에는 "더 궁금하신 점이 있다면 언제든 물어봐 주세요. 5회권 결제로 더 깊은 상담이 가능합니다."라는 느낌을 자연스럽게 녹여주세요.
5. **어조**: 친절하고 전문적이며, 사용자의 마음을 읽어주는 공감적인 태도를 유지하세요.
6. **형식**: 한국어로 답변하며, 마크다운(**, •)을 활용해 가독성을 높이세요. 답변은 400자 이내로 구성합니다.
''';
  }

  /// 로컬 응답 생성 (API 미연동 시)
  String _generateLocalResponse({
    required String userMessage,
    required String consultationType,
    String? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
  }) {
    final lowerQ = userMessage.toLowerCase();
    final score = fortuneScore ?? 70;
    final mbti = mbtiType ?? 'INFJ';

    // 키워드 기반 지능형 응답
    if (lowerQ.contains('이직') ||
        lowerQ.contains('퇴사') ||
        lowerQ.contains('직장')) {
      return _buildCareerResponse(score, mbti);
    }

    if (lowerQ.contains('연애') ||
        lowerQ.contains('인연') ||
        lowerQ.contains('만남') ||
        lowerQ.contains('결혼')) {
      return _buildRelationshipResponse(score, mbti);
    }

    if (lowerQ.contains('투자') ||
        lowerQ.contains('주식') ||
        lowerQ.contains('돈') ||
        lowerQ.contains('재물')) {
      return _buildFinanceResponse(score, mbti);
    }

    if (lowerQ.contains('건강') ||
        lowerQ.contains('운동') ||
        lowerQ.contains('스트레스')) {
      return _buildHealthResponse(score, mbti);
    }

    if (lowerQ.contains('2026') ||
        lowerQ.contains('올해') ||
        lowerQ.contains('운세')) {
      return _buildYearlyFortuneResponse(score, mbti);
    }

    // 기본 응답
    return _buildDefaultResponse(consultationType, score, mbti);
  }

  String _buildCareerResponse(int score, String mbti) {
    if (score >= 75) {
      return '🎯 **직업운 분석**\n\n'
          '2026년은 커리어에 유리한 해입니다!\n\n'
          '• **상반기**: 새로운 기회 포착 시기\n'
          '• **3~4월**: 이직/전환 최적기\n'
          '• **하반기**: 성과가 인정받는 시기\n\n'
          '$mbti 성격을 살려 전략적으로 움직이세요.\n'
          '단, 11월은 큰 결정을 피하세요.';
    } else {
      return '🎯 **직업운 분석**\n\n'
          '2026년은 내실을 다지는 해입니다.\n\n'
          '• **스킬 업**: 새로운 역량 개발에 집중\n'
          '• **네트워킹**: 인맥 확장에 투자\n'
          '• **준비**: 2027년 도약을 위한 기반 마련\n\n'
          '급한 이직보다 현 위치에서 성장에 집중하세요.';
    }
  }

  String _buildRelationshipResponse(int score, String mbti) {
    final isFeeler = mbti.contains('F');
    return '💕 **연애운 분석**\n\n'
        '2026년 병오년은 화(火) 에너지로 열정적인 해!\n\n'
        '• **5~6월**: 인연운 최고조\n'
        '• **좋은 만남**: 화(火), 목(木) 기운 가진 사람\n'
        '• **주의 시기**: 11월 (자오충)\n\n'
        '${isFeeler ? '감정에 솔직해도 좋지만, 이성적 판단도 함께 하세요.' : '논리적인 당신, 마음을 조금 더 열어보세요.'}\n'
        '진지한 만남을 원한다면 하반기가 유리합니다.';
  }

  String _buildFinanceResponse(int score, String mbti) {
    if (score >= 70) {
      return '💰 **재물운 분석**\n\n'
          '2026년 재물운: **$score점**\n\n'
          '• **투자**: 상반기 적극적 접근 가능\n'
          '• **저축**: 하반기 내실 다지기\n'
          '• **주의**: 5~6월 충동적 소비 경계\n\n'
          '11월 자오충 시기에는 큰 투자를 피하고,\n'
          '안정적인 포트폴리오를 유지하세요.';
    } else {
      return '💰 **재물운 분석**\n\n'
          '2026년은 보수적 접근을 권장합니다.\n\n'
          '• **절약**: 불필요한 지출 줄이기\n'
          '• **투자**: 안전자산 위주\n'
          '• **기회**: 2027년 도약 준비\n\n'
          '지금은 무리한 투자보다\n'
          '탄탄한 기반을 다지는 시기입니다.';
    }
  }

  String _buildHealthResponse(int score, String mbti) {
    return '🏃 **건강운 분석**\n\n'
        '2026년 병오년은 화(火) 과다 주의!\n\n'
        '• **주의 장기**: 심장, 혈압, 순환기\n'
        '• **과열 시기**: 5~7월 특히 조심\n'
        '• **권장 활동**: 수영, 명상, 요가\n\n'
        '충분한 수분 섭취와 규칙적인 휴식이 필수입니다.\n'
        '스트레스 관리를 위해 취미 활동도 권장해요.';
  }

  String _buildYearlyFortuneResponse(int score, String mbti) {
    final keyword = score >= 75
        ? '도약과 성취'
        : score >= 60
        ? '성장과 준비'
        : '내실과 정비';
    return '✨ **2026년 종합 운세**\n\n'
        '병오년(丙午年) - 붉은 말의 해\n'
        '종합 점수: **$score점**\n\n'
        '**핵심 키워드**: $keyword\n\n'
        '• **상반기**: 화(火) 기운으로 활발한 에너지\n'
        '• **하반기**: 결실을 맺는 시기\n'
        '• **주의 시기**: 11월 (자오충)\n\n'
        '$mbti 성격을 살려 전략적으로 한 해를 설계하세요!';
  }

  String _buildDefaultResponse(String type, int score, String mbti) {
    return '🔮 **맞춤 상담**\n\n'
        '질문 주셔서 감사합니다!\n\n'
        '당신의 $mbti 성격과 2026년 운세($score점)를 종합하면,\n'
        '${score >= 70 ? '긍정적인 변화가 기대되는 해' : '차분히 준비하는 것이 좋은 해'}입니다.\n\n'
        '더 구체적인 질문을 해주시면\n'
        '더욱 자세한 조언을 드릴 수 있어요!\n\n'
        '💡 예: "올해 이직해도 될까요?"\n'
        '    "연애운이 어떤가요?"';
  }
}
