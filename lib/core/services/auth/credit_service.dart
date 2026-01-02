import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 크레딧 거래 타입
enum CreditTransactionType {
  purchase,
  use,
  refund,
  bonus,
  admin,
}

extension CreditTransactionTypeExtension on CreditTransactionType {
  String get value {
    switch (this) {
      case CreditTransactionType.purchase:
        return 'purchase';
      case CreditTransactionType.use:
        return 'use';
      case CreditTransactionType.refund:
        return 'refund';
      case CreditTransactionType.bonus:
        return 'bonus';
      case CreditTransactionType.admin:
        return 'admin';
    }
  }

  static CreditTransactionType fromString(String value) {
    switch (value) {
      case 'purchase':
        return CreditTransactionType.purchase;
      case 'use':
        return CreditTransactionType.use;
      case 'refund':
        return CreditTransactionType.refund;
      case 'bonus':
        return CreditTransactionType.bonus;
      case 'admin':
        return CreditTransactionType.admin;
      default:
        return CreditTransactionType.use;
    }
  }
}

/// 기능 타입 (크레딧 사용 시)
enum FeatureType {
  sajuAnalysis,
  compatibility,
  aiConsultation,
  fortune2026,
  daewoon,
}

extension FeatureTypeExtension on FeatureType {
  String get value {
    switch (this) {
      case FeatureType.sajuAnalysis:
        return 'saju_analysis';
      case FeatureType.compatibility:
        return 'compatibility';
      case FeatureType.aiConsultation:
        return 'ai_consultation';
      case FeatureType.fortune2026:
        return 'fortune_2026';
      case FeatureType.daewoon:
        return 'daewoon';
    }
  }

  String get displayName {
    switch (this) {
      case FeatureType.sajuAnalysis:
        return '사주 분석';
      case FeatureType.compatibility:
        return '궁합 분석';
      case FeatureType.aiConsultation:
        return 'AI 상담';
      case FeatureType.fortune2026:
        return '2026년 운세';
      case FeatureType.daewoon:
        return '대운 분석';
    }
  }
}

/// 크레딧 거래 이력 모델
class CreditTransaction {
  final String id;
  final String userId;
  final CreditTransactionType type;
  final int amount;
  final int balanceAfter;
  final String? description;
  final String? paymentId;
  final String? featureUsed;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  CreditTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.paymentId,
    this.featureUsed,
    this.metadata,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: CreditTransactionTypeExtension.fromString(json['type'] as String),
      amount: json['amount'] as int,
      balanceAfter: json['balance_after'] as int,
      description: json['description'] as String?,
      paymentId: json['payment_id'] as String?,
      featureUsed: json['feature_used'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 크레딧 잔액 모델
class UserCredit {
  final String id;
  final String userId;
  final int balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCredit({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserCredit.fromJson(Map<String, dynamic> json) {
    return UserCredit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: json['balance'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 크레딧 작업 결과
class CreditResult {
  final bool success;
  final int? newBalance;
  final String? message;

  CreditResult({
    required this.success,
    this.newBalance,
    this.message,
  });
}

/// 크레딧 서비스
class CreditService {
  final SupabaseClient _client;
  static const String _creditsTable = 'user_credits';
  static const String _transactionsTable = 'credit_transactions';

  CreditService({required SupabaseClient client}) : _client = client;

  /// 사용자 크레딧 잔액 조회
  Future<int> getBalance(String userId) async {
    try {
      final response = await _client
          .from(_creditsTable)
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return 0;
      return response['balance'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting credit balance: $e');
      return 0;
    }
  }

  /// 크레딧 정보 조회 (전체)
  Future<UserCredit?> getCreditInfo(String userId) async {
    try {
      final response = await _client
          .from(_creditsTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserCredit.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error getting credit info: $e');
      return null;
    }
  }

  /// 크레딧 초기화 (신규 사용자)
  Future<bool> initializeCredit(String userId, {int initialBalance = 0}) async {
    try {
      // 이미 존재하는지 확인
      final existing = await getCreditInfo(userId);
      if (existing != null) return true;

      await _client.from(_creditsTable).insert({
        'user_id': userId,
        'balance': initialBalance,
      });

      // 초기 잔액이 있으면 거래 이력도 기록
      if (initialBalance > 0) {
        await _client.from(_transactionsTable).insert({
          'user_id': userId,
          'type': 'bonus',
          'amount': initialBalance,
          'balance_after': initialBalance,
          'description': '가입 보너스',
        });
      }

      debugPrint('✅ Credit initialized for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error initializing credit: $e');
      return false;
    }
  }

  /// 크레딧 사용 (Supabase 함수 호출)
  Future<CreditResult> useCredit({
    required String userId,
    required int amount,
    required FeatureType feature,
    String? description,
  }) async {
    try {
      final response = await _client.rpc('use_credit', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_feature': feature.value,
        'p_description': description,
      });

      if (response is List && response.isNotEmpty) {
        final result = response.first;
        return CreditResult(
          success: result['success'] as bool,
          newBalance: result['new_balance'] as int?,
          message: result['message'] as String?,
        );
      }

      return CreditResult(success: false, message: '크레딧 사용에 실패했습니다.');
    } catch (e) {
      debugPrint('❌ Error using credit: $e');
      return CreditResult(success: false, message: '크레딧 사용 중 오류가 발생했습니다.');
    }
  }

  /// 크레딧 추가 (구매/보너스)
  Future<CreditResult> addCredit({
    required String userId,
    required int amount,
    required CreditTransactionType type,
    String? description,
    String? paymentId,
  }) async {
    try {
      final response = await _client.rpc('add_credit', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_type': type.value,
        'p_description': description,
        'p_payment_id': paymentId,
      });

      if (response is List && response.isNotEmpty) {
        final result = response.first;
        return CreditResult(
          success: result['success'] as bool,
          newBalance: result['new_balance'] as int?,
          message: result['message'] as String?,
        );
      }

      return CreditResult(success: false, message: '크레딧 추가에 실패했습니다.');
    } catch (e) {
      debugPrint('❌ Error adding credit: $e');
      return CreditResult(success: false, message: '크레딧 추가 중 오류가 발생했습니다.');
    }
  }

  /// 5회권 구매 처리
  Future<CreditResult> purchaseFiveCredits({
    required String userId,
    required String paymentId,
  }) async {
    return addCredit(
      userId: userId,
      amount: 5,
      type: CreditTransactionType.purchase,
      description: '5회권 구매',
      paymentId: paymentId,
    );
  }

  /// 거래 이력 조회
  Future<List<CreditTransaction>> getTransactionHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from(_transactionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => CreditTransaction.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting transaction history: $e');
      return [];
    }
  }

  /// 특정 기능 사용 가능 여부 확인
  Future<bool> canUseFeature(String userId, {int requiredCredits = 1}) async {
    final balance = await getBalance(userId);
    return balance >= requiredCredits;
  }
}
