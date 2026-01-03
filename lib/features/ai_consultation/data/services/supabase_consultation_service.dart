import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message.dart';

/// Supabase 상담 기록 서비스
/// 클라우드 동기화 및 백업을 위한 서비스
class SupabaseConsultationService {
  static const String _tableName = 'consultations';

  final SupabaseClient _client;

  SupabaseConsultationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// 상담 기록 저장
  Future<String?> saveConsultation({
    required String userId,
    required List<ChatMessage> messages,
    required ConsultationType type,
    Map<String, dynamic>? sajuInfo,
    String? mbtiType,
    int? fortuneScore,
  }) async {
    try {
      // Firebase UID 함께 저장 (사용자 추적)
      final currentUser = _client.auth.currentUser;

      debugPrint('📝 [ConsultationService] Saving consultation: '
          'type=$type, user_id=$userId, firebase_uid=${currentUser?.id}');

      final response = await _client.from(_tableName).insert({
        'user_id': userId,
        'firebase_uid': currentUser?.id, // Firebase UID 추가 (사용자 식별)
        'saju_info': sajuInfo,
        'mbti_type': mbtiType,
        'consultation_type': type.name,
        'messages': messages.map((m) => _messageToJson(m)).toList(),
        'fortune_score': fortuneScore,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('id');

      if (response.isEmpty) {
        debugPrint('❌ [ConsultationService] Failed to save consultation: empty response');
        return null;
      }

      final consultationId = response.first['id'] as String;
      debugPrint('✅ [ConsultationService] Consultation saved successfully: $consultationId');
      return consultationId;
    } catch (e, stackTrace) {
      debugPrint('❌ [ConsultationService] Failed to save consultation to Supabase: $e');
      debugPrint('❌ [ConsultationService] StackTrace: $stackTrace');
      return null;
    }
  }

  /// 사용자의 모든 상담 기록 조회
  Future<List<ConsultationRecord>> getConsultations({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => ConsultationRecord.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch consultations from Supabase: $e');
      return [];
    }
  }

  /// 특정 상담 기록 조회
  Future<ConsultationRecord?> getConsultation(String id) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', id).single();

      return ConsultationRecord.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to fetch consultation from Supabase: $e');
      return null;
    }
  }

  /// 상담 기록 업데이트
  Future<bool> updateConsultation({
    required String id,
    List<ChatMessage>? messages,
    int? fortuneScore,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (messages != null) {
        updateData['messages'] = messages.map((m) => _messageToJson(m)).toList();
      }
      if (fortuneScore != null) {
        updateData['fortune_score'] = fortuneScore;
      }

      if (updateData.isEmpty) return false;

      await _client.from(_tableName).update(updateData).eq('id', id);

      return true;
    } catch (e) {
      debugPrint('❌ Failed to update consultation in Supabase: $e');
      return false;
    }
  }

  /// 상담 기록 삭제
  Future<bool> deleteConsultation(String id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete consultation from Supabase: $e');
      return false;
    }
  }

  /// MBTI 타입별 평균 운세 점수 조회
  Future<Map<String, double>> getAverageScoresByMBTI() async {
    try {
      final response = await _client.from(_tableName).select(
            'mbti_type, fortune_score',
          );

      final Map<String, List<int>> scoresByType = {};

      for (final record in response) {
        final mbtiType = record['mbti_type'] as String?;
        final score = record['fortune_score'] as int?;

        if (mbtiType != null && score != null) {
          scoresByType.putIfAbsent(mbtiType, () => []);
          scoresByType[mbtiType]!.add(score);
        }
      }

      final averages = <String, double>{};
      scoresByType.forEach((type, scores) {
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        averages[type] = avg;
      });

      return averages;
    } catch (e) {
      debugPrint('❌ Failed to fetch average scores: $e');
      return {};
    }
  }

  /// 상담 타입별 통계
  Future<Map<String, int>> getConsultationStatsByType(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('consultation_type')
          .eq('user_id', userId);

      final stats = <String, int>{};

      for (final record in response) {
        final type = record['consultation_type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Failed to fetch consultation stats: $e');
      return {};
    }
  }

  // ============================================
  // Private helpers
  // ============================================

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'role': message.isUser ? 'user' : 'assistant',
      'content': message.content,
      'timestamp': message.timestamp.toIso8601String(),
    };
  }

  static ChatMessage _jsonToMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] as String,
      isUser: json['role'] == 'user',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// 상담 기록 엔티티
class ConsultationRecord {
  final String id;
  final String userId;
  final Map<String, dynamic>? sajuInfo;
  final String? mbtiType;
  final ConsultationType type;
  final List<ChatMessage> messages;
  final int? fortuneScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConsultationRecord({
    required this.id,
    required this.userId,
    this.sajuInfo,
    this.mbtiType,
    required this.type,
    required this.messages,
    this.fortuneScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    return ConsultationRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sajuInfo: json['saju_info'] as Map<String, dynamic>?,
      mbtiType: json['mbti_type'] as String?,
      type: ConsultationType.values.firstWhere(
        (t) => t.name == json['consultation_type'],
        orElse: () => ConsultationType.general,
      ),
      messages: (json['messages'] as List)
          .map((m) => SupabaseConsultationService._jsonToMessage(
              m as Map<String, dynamic>))
          .toList(),
      fortuneScore: json['fortune_score'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'saju_info': sajuInfo,
      'mbti_type': mbtiType,
      'consultation_type': type.name,
      'messages': messages
          .map((m) => SupabaseConsultationService._messageToJson(m))
          .toList(),
      'fortune_score': fortuneScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}분 전';
      }
      return '${diff.inHours}시간 전';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${createdAt.month}/${createdAt.day}';
    }
  }

  String get title {
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );

    final content = firstUserMessage.content;
    if (content.length <= 30) return content;

    return '${content.substring(0, 27)}...';
  }
}
