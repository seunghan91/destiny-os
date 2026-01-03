import 'package:flutter/foundation.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import '../../../../core/services/credit/unified_credit_service.dart';
import '../../../../core/services/auth/credit_service.dart';

/// AI 상담 결제 서비스
class ConsultationPaymentService {
  static const int consultationPrice = 5000; // 5,000원
  static const int creditsPerPurchase = 5; // 5회 질문 가능

  /// 결제 및 크레딧 부여
  static Future<bool> purchaseConsultationCredits() async {
    if (!kIsWeb) {
      debugPrint('⚠️  결제는 웹에서만 가능합니다.');
      return false;
    }

    try {
      // 결제한 크레딧은 계정에 귀속되므로, 결제 전 로그인(회원가입) 필수
      if (!UnifiedCreditService.isLoggedIn) {
        debugPrint('⚠️  로그인 없이 결제를 진행할 수 없습니다.');
        final bridge = AppsInTossBridge();
        bridge.showToast('결제한 크레딧을 유지하려면 회원가입/로그인이 필요합니다.');
        return false;
      }

      final bridge = AppsInTossBridge();

      // 주문 ID 생성
      final orderId = 'ai_consult_${DateTime.now().millisecondsSinceEpoch}';

      // 결제 요청
      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: 'AI 운세 상담 크레딧 5회',
        amount: consultationPrice,
      );

      debugPrint('💳 AI 상담 결제 요청: ${paymentRequest.orderName}');

      final result = await bridge.requestPayment(paymentRequest);

      if (result.success) {
        debugPrint('✅ 결제 성공: ${result.paymentKey}');

        // 크레딧 부여 (통합 크레딧 서비스 사용)
        await UnifiedCreditService.addCredits(
          creditsPerPurchase,
          type: CreditTransactionType.purchase,
          description: 'AI 상담 크레딧 5회권 구매',
          paymentId: result.paymentKey,
        );
        debugPrint('✅ 크레딧 ${creditsPerPurchase}개 부여 완료');

        // 토스트 메시지
        bridge.showToast('결제가 완료되었습니다! 크레딧 ${creditsPerPurchase}개가 지급되었어요.');

        return true;
      } else {
        debugPrint('❌ 결제 실패: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 결제 오류: $e');
      return false;
    }
  }

  /// 크레딧 부족 여부 확인
  static Future<bool> needsPayment() async {
    final hasCredits = await UnifiedCreditService.hasCredits();
    return !hasCredits;
  }

  /// 크레딧 구매 안내 메시지
  static String getPurchaseMessage() {
    return 'AI 운세 상담을 이용하시려면\n'
        '크레딧 ${creditsPerPurchase}회 (${consultationPrice}원)를 구매해주세요.\n\n'
        '• 질문 ${creditsPerPurchase}번까지 가능\n'
        '• 사주와 MBTI 기반 맞춤 상담\n'
        '• 실시간 AI 응답';
  }
}
