import 'package:flutter/foundation.dart';

import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import 'fortune_view_access_service.dart';

class FortuneViewPaymentService {
  static const int viewPrice = 1000;

  static Future<bool> purchaseOneView() async {
    if (!kIsWeb) {
      return false;
    }

    try {
      final bridge = AppsInTossBridge();
      final orderId = 'fortune_view_${DateTime.now().millisecondsSinceEpoch}';

      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: '2026 운세 추가 열람 1회',
        amount: viewPrice,
      );

      final result = await bridge.requestPayment(paymentRequest);

      if (result.success) {
        await FortuneViewAccessService.addCredits(1);
        bridge.showToast('결제가 완료되었습니다! 운세 1회 추가 열람이 지급되었어요.');
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
