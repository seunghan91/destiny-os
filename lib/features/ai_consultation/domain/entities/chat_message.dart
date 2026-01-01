import 'package:equatable/equatable.dart';

/// 채팅 메시지
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp, status];
}

/// 메시지 상태
enum MessageStatus {
  sending,
  sent,
  error,
}

/// 상담 유형
enum ConsultationType {
  career,
  relationship,
  finance,
  health,
  general,
}

extension ConsultationTypeExtension on ConsultationType {
  String get korean {
    switch (this) {
      case ConsultationType.career:
        return '직업/진로';
      case ConsultationType.relationship:
        return '연애/결혼';
      case ConsultationType.finance:
        return '재물/투자';
      case ConsultationType.health:
        return '건강/웰빙';
      case ConsultationType.general:
        return '종합 상담';
    }
  }

  String get emoji {
    switch (this) {
      case ConsultationType.career:
        return '💼';
      case ConsultationType.relationship:
        return '💕';
      case ConsultationType.finance:
        return '💰';
      case ConsultationType.health:
        return '🏃';
      case ConsultationType.general:
        return '✨';
    }
  }

  String get description {
    switch (this) {
      case ConsultationType.career:
        return '적성, 이직, 창업 등 진로에 대한 상담';
      case ConsultationType.relationship:
        return '연애, 결혼, 인간관계에 대한 상담';
      case ConsultationType.finance:
        return '재테크, 투자, 재물운에 대한 상담';
      case ConsultationType.health:
        return '건강, 스트레스, 웰빙에 대한 상담';
      case ConsultationType.general:
        return '인생 전반에 대한 종합 상담';
    }
  }

  List<String> get sampleQuestions {
    switch (this) {
      case ConsultationType.career:
        return [
          '지금 이직을 해도 될까요?',
          '나에게 맞는 직업은 무엇인가요?',
          '사업을 시작하기 좋은 시기인가요?',
        ];
      case ConsultationType.relationship:
        return [
          '올해 좋은 인연을 만날 수 있을까요?',
          '지금 연인과 결혼해도 될까요?',
          '나와 잘 맞는 상대는 어떤 유형인가요?',
        ];
      case ConsultationType.finance:
        return [
          '2026년 재물운은 어떤가요?',
          '주식 투자를 해도 될까요?',
          '돈을 모으기 좋은 시기는 언제인가요?',
        ];
      case ConsultationType.health:
        return [
          '올해 건강에 주의할 점이 있나요?',
          '스트레스 관리 방법을 알려주세요',
          '나에게 맞는 운동은 무엇인가요?',
        ];
      case ConsultationType.general:
        return [
          '2026년 나의 전체 운세는 어떤가요?',
          '올해 가장 주의해야 할 점은 무엇인가요?',
          '나의 강점을 더 살리려면 어떻게 해야 하나요?',
        ];
    }
  }
}
