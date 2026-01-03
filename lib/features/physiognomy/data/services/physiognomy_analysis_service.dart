import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';

/// 관상 분석 서비스 - BizRouter API (Gemini Vision + 나노바나나 프로)
class PhysiognomyAnalysisService {
  final Dio _dio;

  PhysiognomyAnalysisService({Dio? dio}) : _dio = dio ?? Dio();

  // BizRouter 모델 ID
  static const String _visionModel = 'google/gemini-2.5-flash'; // Vision 지원
  static const String _imageGenModel =
      'google/gemini-3-pro-image-preview'; // 나노바나나 프로

  /// 1단계: 얼굴 특징 추출 (Gemini Vision)
  Future<Map<String, dynamic>> extractFaceFeatures(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final systemPrompt = '''
당신은 동아시아 관상학 전문 분석가입니다.
사용자가 업로드한 정면 얼굴 사진을 분석하여, 아래 JSON 스키마에 맞게 얼굴 특징을 추출하세요.

[중요 원칙]
1. 과학적 근거가 아닌 "전통 관상학" 기반 해석임을 명심
2. 차별/낙인/범죄성/지능/도덕성 판단은 절대 금지
3. 긍정적이고 건설적인 해석 위주로 작성
4. 확신도(confidence)는 사진 품질/각도에 따라 0.3~0.9 범위로 솔직하게 표기

[출력 JSON 스키마]
{
  "photo_quality": {
    "is_frontal": boolean,
    "has_full_face": boolean,
    "has_multiple_faces": boolean,
    "lighting_quality": "good|fair|poor",
    "issues": ["이슈1", "이슈2"]
  },
  "face_shape": {
    "type": "oval|round|square|triangle|long|heart",
    "description": "한국어 설명",
    "traditional_interpretation": "전통 관상에서의 해석",
    "confidence": 0.0~1.0
  },
  "five_features": {
    "forehead": {
      "size": "wide|medium|narrow",
      "shape": "설명",
      "traditional_interpretation": "초년운/지혜 관련 해석",
      "confidence": 0.0~1.0
    },
    "eyes": {
      "size": "large|medium|small",
      "shape": "설명 (눈꼬리 방향, 깊이 등)",
      "traditional_interpretation": "성격/인연 관련 해석",
      "confidence": 0.0~1.0
    },
    "nose": {
      "size": "large|medium|small",
      "shape": "설명 (콧대, 콧방울 등)",
      "traditional_interpretation": "중년운/재물 관련 해석",
      "confidence": 0.0~1.0
    },
    "mouth": {
      "size": "large|medium|small",
      "shape": "설명",
      "traditional_interpretation": "표현력/대인관계 관련 해석",
      "confidence": 0.0~1.0
    },
    "chin": {
      "size": "prominent|medium|receding",
      "shape": "설명",
      "traditional_interpretation": "말년운/의지력 관련 해석",
      "confidence": 0.0~1.0
    }
  },
  "overall_impression": {
    "dominant_element": "wood|fire|earth|metal|water",
    "energy_description": "전체적인 인상/기운 설명",
    "strengths": ["강점1", "강점2", "강점3"],
    "growth_areas": ["성장 가능성1", "성장 가능성2"]
  }
}

JSON만 출력하세요. 다른 텍스트는 포함하지 마세요.
''';

    try {
      final response = await _dio.post(
        '${EnvConfig.bizRouterBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'X-API-Key': EnvConfig.bizRouterApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _visionModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
                {'type': 'text', 'text': '이 얼굴 사진을 관상학적으로 분석해주세요.'},
              ],
            },
          ],
          'max_tokens': 2000,
          'temperature': 0.3,
        },
      );

      if (response.statusCode == 200) {
        final content =
            response.data['choices'][0]['message']['content'] as String;
        // JSON 파싱
        final jsonStr = _extractJson(content);
        return json.decode(jsonStr) as Map<String, dynamic>;
      }

      throw Exception('Vision API error: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Face feature extraction failed: $e');
      rethrow;
    }
  }

  /// 2단계: 통합 리포트 생성 (사주+토정+MBTI+관상)
  Future<String> generateIntegratedReport({
    required Map<String, dynamic> faceFeatures,
    required Map<String, dynamic> sajuData,
    String? tojungSummary,
    required String mbti,
  }) async {
    final systemPrompt = '''
당신은 "2026 신년운세" 전문 상담사입니다.
사용자의 관상 분석 결과, 사주 데이터, 토정비결 요약, MBTI를 통합하여 
2026년 병오년(丙午年) 신년운세 형식의 종합 리포트를 작성하세요.

[출력 형식 - Markdown]
# 🎴 2026 관상 종합분석 리포트

## 🔮 올해의 키워드
- **키워드1**: 설명
- **키워드2**: 설명
- **키워드3**: 설명

## 👤 관상 요약
> 전통 관상학 기반 해석입니다. 엔터테인먼트 목적으로 참고하세요.

### 얼굴형과 전체 인상
(face_shape, overall_impression 기반 설명)

### 오관 특징
- **이마(초년운)**: ...
- **눈(인연/직관)**: ...
- **코(재물/중년운)**: ...
- **입(표현력)**: ...
- **턱(말년운/의지)**: ...

## ☯️ 사주 기반 2026년 흐름
(sajuData 기반 설명)

## 📜 토정비결 포인트
(tojungSummary 기반 요약 또는 "토정비결 데이터 없음" 표시)

## 🧬 MBTI로 보는 행동 전략
(mbti 기반 2026년 실행 조언)

## 💫 통합 분석: 연애/재물/직장/건강

### 💕 연애운
(관상+사주+MBTI 종합)

### 💰 재물운
(관상+사주+MBTI 종합)

### 💼 직장/사업운
(관상+사주+MBTI 종합)

### 🏥 건강운
(관상+사주+MBTI 종합)

## ✅ 2026년 실행 체크리스트
1. [ ] 액션1
2. [ ] 액션2
3. [ ] 액션3
4. [ ] 액션4
5. [ ] 액션5

---
⚠️ **면책 고지**: 이 분석은 전통 동아시아 관상학과 사주/토정비결에 기반한 엔터테인먼트 콘텐츠입니다. 과학적으로 검증된 것이 아니며, 중요한 의사결정의 근거로 사용하지 마세요.

[작성 원칙]
1. 긍정적이고 건설적인 톤 유지
2. 구체적이고 실행 가능한 조언 제공
3. 차별/낙인/부정적 단정 금지
4. 2026년 병오년(火 기운)의 특성 반영
5. 1500~2500자 분량
''';

    final userMessage =
        '''
[관상 분석 결과]
${json.encode(faceFeatures)}

[사주 데이터]
${json.encode(sajuData)}

[토정비결 요약]
${tojungSummary ?? '없음'}

[MBTI]
$mbti

위 데이터를 종합하여 2026 신년운세 리포트를 작성해주세요.
''';

    try {
      final response = await _dio.post(
        '${EnvConfig.bizRouterBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'X-API-Key': EnvConfig.bizRouterApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _visionModel, // 텍스트 생성도 같은 모델 사용
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 4000,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'] as String;
      }

      throw Exception('Report generation error: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Report generation failed: $e');
      rethrow;
    }
  }

  /// 3단계: 관상 요약 카드 이미지 생성 (나노바나나 프로)
  Future<Uint8List?> generateSummaryCardImage({
    required Map<String, dynamic> faceFeatures,
    required String mbti,
  }) async {
    final faceShape = faceFeatures['face_shape']?['type'] ?? 'oval';
    final dominantElement =
        faceFeatures['overall_impression']?['dominant_element'] ?? 'earth';
    final strengths =
        (faceFeatures['overall_impression']?['strengths'] as List?)
            ?.take(3)
            .join(', ') ??
        '균형, 조화, 성실';

    final prompt =
        '''
2026년 신년운세 관상 요약 카드 디자인.
- 스타일: 한국 전통 미학 + 현대적 미니멀리즘
- 배경: 은은한 그라데이션 (동양적 색감)
- 중앙: "$faceShape 얼굴형" 아이콘 (추상적, 우아함)
- 오행: "$dominantElement" 원소 심볼
- MBTI: "$mbti" 배지
- 키워드: "$strengths"
- 하단: "2026 관상분석" 텍스트
- 전체 분위기: 고급스럽고 신비로운 운세 카드
정사각형 비율, 깔끔한 구도.
''';

    try {
      final response = await _dio.post(
        '${EnvConfig.bizRouterBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'X-API-Key': EnvConfig.bizRouterApiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _imageGenModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1000,
        },
      );

      if (response.statusCode == 200) {
        // 나노바나나 프로의 이미지 응답 처리
        final content = response.data['choices'][0]['message']['content'];

        // content가 base64 이미지인 경우
        if (content is String && content.contains('base64')) {
          final base64Match = RegExp(
            r'data:image/[^;]+;base64,([^"]+)',
          ).firstMatch(content);
          if (base64Match != null) {
            return base64Decode(base64Match.group(1)!);
          }
        }

        // 이미지 URL인 경우
        if (content is String && content.startsWith('http')) {
          final imageResponse = await _dio.get<List<int>>(
            content,
            options: Options(responseType: ResponseType.bytes),
          );
          return Uint8List.fromList(imageResponse.data!);
        }

        debugPrint('⚠️ Image generation returned unexpected format');
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Card image generation failed (non-critical): $e');
      return null; // 이미지 생성 실패는 치명적이지 않음
    }
  }

  /// JSON 추출 헬퍼
  String _extractJson(String text) {
    // ```json ... ``` 블록 추출
    final jsonBlockMatch = RegExp(
      r'```json\s*([\s\S]*?)\s*```',
    ).firstMatch(text);
    if (jsonBlockMatch != null) {
      return jsonBlockMatch.group(1)!.trim();
    }

    // { } 블록 추출
    final braceMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (braceMatch != null) {
      return braceMatch.group(0)!;
    }

    return text;
  }

  /// 전체 분석 파이프라인 실행
  Future<PhysiognomyAnalysisResult> runFullAnalysis({
    required Uint8List imageBytes,
    required Map<String, dynamic> sajuData,
    String? tojungSummary,
    required String mbti,
  }) async {
    // 1. 얼굴 특징 추출
    debugPrint('🔍 Step 1: Extracting face features...');
    final faceFeatures = await extractFaceFeatures(imageBytes);

    // 사진 품질 체크
    final photoQuality = faceFeatures['photo_quality'] as Map<String, dynamic>?;
    if (photoQuality != null) {
      if (photoQuality['has_multiple_faces'] == true) {
        throw Exception('사진에 여러 얼굴이 감지되었습니다. 본인 얼굴만 나온 사진을 사용해주세요.');
      }
      if (photoQuality['is_frontal'] == false) {
        throw Exception('정면 사진이 아닙니다. 얼굴이 정면을 향한 사진을 사용해주세요.');
      }
    }

    // 2. 통합 리포트 생성
    debugPrint('📝 Step 2: Generating integrated report...');
    final report = await generateIntegratedReport(
      faceFeatures: faceFeatures,
      sajuData: sajuData,
      tojungSummary: tojungSummary,
      mbti: mbti,
    );

    // 3. 요약 카드 이미지 생성 (선택적)
    debugPrint('🎴 Step 3: Generating summary card image...');
    Uint8List? cardImage;
    try {
      cardImage = await generateSummaryCardImage(
        faceFeatures: faceFeatures,
        mbti: mbti,
      );
    } catch (e) {
      debugPrint('⚠️ Card image generation skipped: $e');
    }

    return PhysiognomyAnalysisResult(
      faceFeatures: faceFeatures,
      reportMarkdown: report,
      cardImageBytes: cardImage,
    );
  }
}

/// 분석 결과 모델
class PhysiognomyAnalysisResult {
  final Map<String, dynamic> faceFeatures;
  final String reportMarkdown;
  final Uint8List? cardImageBytes;

  const PhysiognomyAnalysisResult({
    required this.faceFeatures,
    required this.reportMarkdown,
    this.cardImageBytes,
  });
}
