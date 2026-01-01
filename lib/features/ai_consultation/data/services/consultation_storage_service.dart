import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/chat_message.dart';

/// AI 상담 기록 저장 서비스
/// SharedPreferences를 사용하여 상담 기록을 로컬에 저장
class ConsultationStorageService {
  static const String _conversationsKey = 'ai_conversations';
  static const String _currentSessionKey = 'current_session';
  static const int _maxConversations = 50;
  static const int _maxMessagesPerConversation = 100;

  /// 현재 세션 메시지 저장
  static Future<void> saveCurrentSession({
    required List<ChatMessage> messages,
    required ConsultationType type,
  }) async {
    if (messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final sessionData = {
      'type': type.name,
      'messages': messages.map((m) => _messageToJson(m)).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_currentSessionKey, jsonEncode(sessionData));
  }

  /// 현재 세션 불러오기
  static Future<SessionData?> loadCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_currentSessionKey);

    if (sessionJson == null) return null;

    try {
      final data = jsonDecode(sessionJson) as Map<String, dynamic>;
      final messages = (data['messages'] as List)
          .map((m) => _jsonToMessage(m as Map<String, dynamic>))
          .toList();

      return SessionData(
        type: ConsultationType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => ConsultationType.general,
        ),
        messages: messages,
        lastUpdated: DateTime.parse(data['lastUpdated'] as String),
      );
    } catch (e) {
      return null;
    }
  }

  /// 현재 세션 삭제
  static Future<void> clearCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
  }

  /// 상담 기록 저장 (히스토리로 이동)
  static Future<void> saveConversation({
    required List<ChatMessage> messages,
    required ConsultationType type,
    String? title,
  }) async {
    if (messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    List<Map<String, dynamic>> conversations = [];
    if (conversationsJson != null) {
      try {
        conversations = (jsonDecode(conversationsJson) as List)
            .cast<Map<String, dynamic>>();
      } catch (_) {
        conversations = [];
      }
    }

    // 새 대화 추가
    final newConversation = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type.name,
      'title': title ?? _generateTitle(messages, type),
      'messages': messages
          .take(_maxMessagesPerConversation)
          .map((m) => _messageToJson(m))
          .toList(),
      'createdAt': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
    };

    conversations.insert(0, newConversation);

    // 최대 개수 제한
    if (conversations.length > _maxConversations) {
      conversations = conversations.take(_maxConversations).toList();
    }

    await prefs.setString(_conversationsKey, jsonEncode(conversations));

    // 현재 세션 삭제
    await clearCurrentSession();
  }

  /// 모든 상담 기록 불러오기
  static Future<List<ConversationSummary>> getAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson == null) return [];

    try {
      final conversations = (jsonDecode(conversationsJson) as List)
          .cast<Map<String, dynamic>>();

      return conversations.map((c) {
        return ConversationSummary(
          id: c['id'] as String,
          type: ConsultationType.values.firstWhere(
            (t) => t.name == c['type'],
            orElse: () => ConsultationType.general,
          ),
          title: c['title'] as String,
          messageCount: c['messageCount'] as int? ?? 0,
          createdAt: DateTime.parse(c['createdAt'] as String),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 특정 상담 기록 불러오기
  static Future<List<ChatMessage>?> getConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson == null) return null;

    try {
      final conversations = (jsonDecode(conversationsJson) as List)
          .cast<Map<String, dynamic>>();

      final conversation = conversations.firstWhere(
        (c) => c['id'] == id,
        orElse: () => <String, dynamic>{},
      );

      if (conversation.isEmpty) return null;

      return (conversation['messages'] as List)
          .map((m) => _jsonToMessage(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// 상담 기록 삭제
  static Future<void> deleteConversation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);

    if (conversationsJson == null) return;

    try {
      final conversations = (jsonDecode(conversationsJson) as List)
          .cast<Map<String, dynamic>>();

      conversations.removeWhere((c) => c['id'] == id);

      await prefs.setString(_conversationsKey, jsonEncode(conversations));
    } catch (_) {}
  }

  /// 모든 상담 기록 삭제
  static Future<void> clearAllConversations() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conversationsKey);
    await prefs.remove(_currentSessionKey);
  }

  /// 저장 공간 정보
  static Future<StorageInfo> getStorageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final conversationsJson = prefs.getString(_conversationsKey);
    final currentSessionJson = prefs.getString(_currentSessionKey);

    int totalMessages = 0;
    int totalConversations = 0;

    if (conversationsJson != null) {
      try {
        final conversations = (jsonDecode(conversationsJson) as List)
            .cast<Map<String, dynamic>>();
        totalConversations = conversations.length;
        for (final c in conversations) {
          totalMessages += (c['messageCount'] as int? ?? 0);
        }
      } catch (_) {}
    }

    bool hasCurrentSession = currentSessionJson != null;

    return StorageInfo(
      totalConversations: totalConversations,
      totalMessages: totalMessages,
      hasCurrentSession: hasCurrentSession,
      approximateSizeBytes: (conversationsJson?.length ?? 0) +
          (currentSessionJson?.length ?? 0),
    );
  }

  // ============================================
  // Private helpers
  // ============================================

  static Map<String, dynamic> _messageToJson(ChatMessage message) {
    return {
      'id': message.id,
      'content': message.content,
      'isUser': message.isUser,
      'timestamp': message.timestamp.toIso8601String(),
      'status': message.status.name,
    };
  }

  static ChatMessage _jsonToMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  static String _generateTitle(List<ChatMessage> messages, ConsultationType type) {
    // 첫 번째 사용자 메시지에서 제목 생성
    final firstUserMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => messages.first,
    );

    final content = firstUserMessage.content;
    if (content.length <= 30) return content;

    return '${content.substring(0, 27)}...';
  }
}

/// 세션 데이터
class SessionData {
  final ConsultationType type;
  final List<ChatMessage> messages;
  final DateTime lastUpdated;

  const SessionData({
    required this.type,
    required this.messages,
    required this.lastUpdated,
  });
}

/// 대화 요약 정보
class ConversationSummary {
  final String id;
  final ConsultationType type;
  final String title;
  final int messageCount;
  final DateTime createdAt;

  const ConversationSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.messageCount,
    required this.createdAt,
  });

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
}

/// 저장 공간 정보
class StorageInfo {
  final int totalConversations;
  final int totalMessages;
  final bool hasCurrentSession;
  final int approximateSizeBytes;

  const StorageInfo({
    required this.totalConversations,
    required this.totalMessages,
    required this.hasCurrentSession,
    required this.approximateSizeBytes,
  });

  String get formattedSize {
    if (approximateSizeBytes < 1024) {
      return '$approximateSizeBytes B';
    } else if (approximateSizeBytes < 1024 * 1024) {
      return '${(approximateSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(approximateSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
