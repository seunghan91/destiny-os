import 'package:flutter/foundation.dart';

import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import 'tojung_premium_access_service.dart';

class TojungPremiumPaymentService {
  static const int price = 5000;

  static Future<bool> purchaseOneReport() async {
    if (!kIsWeb) {
      return false;
    }

    try {
      final bridge = AppsInTossBridge();
      final orderId = 'tojung_premium_${DateTime.now().millisecondsSinceEpoch}';

      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: '심층 토정비결 종합분석 1회',
        amount: price,
      );

      final result = await bridge.requestPayment(paymentRequest);

      if (result.success) {
        await TojungPremiumAccessService.addCredits(1);
        bridge.showToast('결제가 완료되었습니다! 토정비결 종합분석 1회권이 지급되었어요.');
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
