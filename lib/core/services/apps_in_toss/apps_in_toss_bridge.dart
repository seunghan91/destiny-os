import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'models.dart';

/// Apps in Toss SDK External Interface
@JS('AppsInToss')
@staticInterop
class AppsInTossSDK {}

extension AppsInTossSDKExtension on AppsInTossSDK {
  external JSPromise<JSAny?> init();
  external JSPromise<JSAny?> requestPayment(JSAny options);
  external JSPromise<JSAny?> getUser();
  external void showToast(JSString message);
  external void close();
  external JSAny getEnvironment();
}

@JS('AppsInToss')
external AppsInTossSDK? get _appsInTossGlobal;

/// Apps in Toss JavaScript Bridge
///
/// Flutter Web ↔ Apps in Toss SDK 통신을 담당하는 서비스
///
/// **기능**:
/// - SDK 초기화
/// - 결제 요청 (Toss Payments)
/// - 사용자 정보 조회
/// - 토스트 메시지 표시
///
/// **사용 예시**:
/// ```dart
/// final bridge = AppsInTossBridge();
/// await bridge.initialize();
///
/// final result = await bridge.requestPayment(
///   PaymentRequest(
///     orderId: 'order_123',
///     orderName: '2026 신년운세 AI 상담',
///     amount: 9900,
///   ),
/// );
/// ```
class AppsInTossBridge {
  static AppsInTossBridge? _instance;
  bool _initialized = false;
  AppsInTossEnvironment? _environment;

  AppsInTossBridge._();

  factory AppsInTossBridge() {
    _instance ??= AppsInTossBridge._();
    return _instance!;
  }

  /// SDK 초기화
  ///
  /// 앱 시작 시 한 번만 호출해야 합니다.
  Future<void> initialize() async {
    if (!kIsWeb) {
      debugPrint('⚠️  Apps in Toss는 웹 환경에서만 사용 가능합니다.');
      return;
    }

    if (_initialized) {
      debugPrint('ℹ️  Apps in Toss SDK가 이미 초기화되었습니다.');
      return;
    }

    try {
      final sdk = _getSDK();

      // AppsInToss.init() 호출
      final result = await sdk.init().toDart.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Apps in Toss SDK 초기화 시간 초과',
          );
        },
      );

      debugPrint('✅ Apps in Toss SDK 초기화 성공: $result');

      // 환경 정보 조회
      _environment = await getEnvironment();
      debugPrint('🏪 환경: ${_environment?.isAppsInToss == true ? "Apps in Toss" : "Mock"}');

      _initialized = true;
    } catch (e) {
      debugPrint('❌ Apps in Toss SDK 초기화 실패: $e');
      rethrow;
    }
  }

  /// 결제 요청
  ///
  /// Toss Payments를 사용하여 결제를 진행합니다.
  ///
  /// **파라미터**:
  /// - [request]: 결제 요청 정보
  ///
  /// **반환**:
  /// - [PaymentResult]: 결제 결과
  ///
  /// **예외**:
  /// - [Exception]: 결제 실패 시
  Future<PaymentResult> requestPayment(PaymentRequest request) async {
    _ensureInitialized();

    try {
      debugPrint('💳 결제 요청: ${request.orderName} (${request.amount}원)');

      final sdk = _getSDK();
      final result = await sdk
          .requestPayment(request.toJson().jsify()!)
          .toDart
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('결제 시간 초과 (60초)');
        },
      );

      debugPrint('✅ 결제 성공: $result');

      return PaymentResult.fromJson(
        (result as JSObject).dartify() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ 결제 실패: $e');

      // JS 에러를 Flutter 에러로 변환
      if (e is JSObject) {
        final errorMap = e.dartify() as Map<String, dynamic>?;
        if (errorMap != null) {
          return PaymentResult.error(
            errorMap['code'] as String? ?? 'UNKNOWN_ERROR',
            errorMap['message'] as String? ?? '결제에 실패했습니다.',
          );
        }
      }

      return PaymentResult.error(
        'PAYMENT_ERROR',
        e.toString(),
      );
    }
  }

  /// 사용자 정보 조회
  ///
  /// Toss 앱의 현재 로그인한 사용자 정보를 조회합니다.
  Future<TossUser?> getUser() async {
    _ensureInitialized();

    try {
      final sdk = _getSDK();
      final result = await sdk.getUser().toDart;
      debugPrint('👤 사용자 정보 조회 성공');

      return TossUser.fromJson(
        (result as JSObject).dartify() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ 사용자 정보 조회 실패: $e');
      return null;
    }
  }

  /// 토스트 메시지 표시
  ///
  /// Toss 앱 하단에 토스트 메시지를 표시합니다.
  void showToast(String message) {
    if (!kIsWeb || !_initialized) return;

    try {
      final sdk = _getSDK();
      sdk.showToast(message.toJS);
      debugPrint('🔔 토스트 표시: $message');
    } catch (e) {
      debugPrint('❌ 토스트 표시 실패: $e');
    }
  }

  /// 앱 닫기
  ///
  /// Toss 앱으로 복귀합니다.
  void close() {
    if (!kIsWeb) return;

    try {
      final sdk = _getSDK();
      sdk.close();
      debugPrint('🚪 앱 닫기');
    } catch (e) {
      debugPrint('❌ 앱 닫기 실패: $e');
    }
  }

  /// 환경 정보 조회
  ///
  /// Apps in Toss 실행 환경 정보를 조회합니다.
  Future<AppsInTossEnvironment> getEnvironment() async {
    if (!kIsWeb) {
      return const AppsInTossEnvironment(
        isAppsInToss: false,
        platform: 'mobile',
        userAgent: '',
        isMock: false,
      );
    }

    try {
      final sdk = _getSDK();
      final result = sdk.getEnvironment();

      return AppsInTossEnvironment.fromJson(
        (result as JSObject).dartify() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ 환경 정보 조회 실패: $e');
      return const AppsInTossEnvironment(
        isAppsInToss: false,
        platform: 'web',
        userAgent: '',
        isMock: true,
      );
    }
  }

  /// 초기화 여부 확인
  bool get isInitialized => _initialized;

  /// Apps in Toss 환경 여부
  bool get isAppsInToss => _environment?.isAppsInToss ?? false;

  /// Mock 환경 여부
  bool get isMock => _environment?.isMock ?? true;

  // ========================================================================
  // Private Methods
  // ========================================================================

  /// 초기화 검증
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Apps in Toss SDK가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.',
      );
    }
  }

  /// Apps in Toss SDK 전역 객체 가져오기
  AppsInTossSDK _getSDK() {
    if (_appsInTossGlobal == null) {
      throw StateError('AppsInToss SDK를 찾을 수 없습니다.');
    }
    return _appsInTossGlobal!;
  }
}
