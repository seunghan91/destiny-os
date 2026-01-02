import 'package:flutter/foundation.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import 'credit_service.dart';

/// AI 상담 결제 서비스
class ConsultationPaymentService {
  static const int consultationPrice = 1000; // 1,000원
  static const int creditsPerPurchase = 5; // 5회 질문 가능

  /// 결제 및 크레딧 부여
  static Future<bool> purchaseConsultationCredits() async {
    if (!kIsWeb) {
      debugPrint('⚠️  결제는 웹에서만 가능합니다.');
      return false;
    }

    try {
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

        // 크레딧 부여
        await CreditService.addCredits(creditsPerPurchase);
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
    final hasCredits = await CreditService.hasCredits();
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
