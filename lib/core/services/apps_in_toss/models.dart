/// Apps in Toss SDK 관련 데이터 모델
///
/// Toss Payments 결제 요청/응답 모델

/// 결제 요청 파라미터
class PaymentRequest {
  /// 주문 ID (고유값)
  final String orderId;

  /// 주문명 (결제창에 표시)
  final String orderName;

  /// 결제 금액
  final int amount;

  /// 고객 이메일 (선택)
  final String? customerEmail;

  /// 고객 이름 (선택)
  final String? customerName;

  const PaymentRequest({
    required this.orderId,
    required this.orderName,
    required this.amount,
    this.customerEmail,
    this.customerName,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'orderName': orderName,
        'amount': amount,
        if (customerEmail != null) 'customerEmail': customerEmail,
        if (customerName != null) 'customerName': customerName,
      };
}

/// 결제 결과
class PaymentResult {
  /// 결제 성공 여부
  final bool success;

  /// 주문 ID
  final String orderId;

  /// 주문명
  final String orderName;

  /// 결제 금액
  final int amount;

  /// 결제 키 (Toss Payments)
  final String? paymentKey;

  /// 승인 일시
  final String? approvedAt;

  /// 결제 수단
  final String? method;

  /// 고객 이름
  final String? customerName;

  /// 고객 전화번호
  final String? customerPhone;

  /// 에러 코드 (실패 시)
  final String? errorCode;

  /// 에러 메시지 (실패 시)
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    required this.orderId,
    required this.orderName,
    required this.amount,
    this.paymentKey,
    this.approvedAt,
    this.method,
    this.customerName,
    this.customerPhone,
    this.errorCode,
    this.errorMessage,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool? ?? false,
      orderId: json['orderId'] as String,
      orderName: json['orderName'] as String,
      amount: json['amount'] as int,
      paymentKey: json['paymentKey'] as String?,
      approvedAt: json['approvedAt'] as String?,
      method: json['method'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      errorCode: json['code'] as String?,
      errorMessage: json['message'] as String?,
    );
  }

  factory PaymentResult.error(String code, String message) {
    return PaymentResult(
      success: false,
      orderId: '',
      orderName: '',
      amount: 0,
      errorCode: code,
      errorMessage: message,
    );
  }
}

/// Toss 사용자 정보
class TossUser {
  /// 사용자 ID
  final String userId;

  /// 이름
  final String name;

  /// 전화번호
  final String phone;

  /// 인증 여부
  final bool verified;

  const TossUser({
    required this.userId,
    required this.name,
    required this.phone,
    required this.verified,
  });

  factory TossUser.fromJson(Map<String, dynamic> json) {
    return TossUser(
      userId: json['userId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

/// Apps in Toss 환경 정보
class AppsInTossEnvironment {
  /// Apps in Toss 환경 여부
  final bool isAppsInToss;

  /// 플랫폼
  final String platform;

  /// User Agent
  final String userAgent;

  /// Mock 환경 여부
  final bool isMock;

  const AppsInTossEnvironment({
    required this.isAppsInToss,
    required this.platform,
    required this.userAgent,
    required this.isMock,
  });

  factory AppsInTossEnvironment.fromJson(Map<String, dynamic> json) {
    return AppsInTossEnvironment(
      isAppsInToss: json['isAppsInToss'] as bool? ?? false,
      platform: json['platform'] as String? ?? 'web',
      userAgent: json['userAgent'] as String? ?? '',
      isMock: json['isMock'] as bool? ?? true,
    );
  }
}
