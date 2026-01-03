import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import '../../../../core/services/auth/auth_manager.dart';
import 'tojung_premium_access_service.dart';

class TojungPremiumPaymentService {
  static const int price = 5000;

  static Future<bool> purchaseOneReport() async {
    if (!kIsWeb) {
      return false;
    }

    try {
      if (!AuthManager().isAuthenticated) {
        final bridge = AppsInTossBridge();
        bridge.showToast('결제한 이용권을 유지하려면 로그인(회원가입)이 필요합니다.');
        return false;
      }

      if (EnvConfig.betaPaymentsFree) {
        final bridge = AppsInTossBridge();
        await TojungPremiumAccessService.addCredits(
          1,
          paymentId: 'beta_free',
          description: '베타테스트 기간 무료 제공 (토정비결 1회권)',
        );
        bridge.showToast('베타테스트 기간 무료로 제공됩니다. 토정비결 종합분석 1회권이 지급되었어요.');
        return true;
      }

      final bridge = AppsInTossBridge();
      final orderId = 'tojung_premium_${DateTime.now().millisecondsSinceEpoch}';

      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: '심층 토정비결 종합분석 1회',
        amount: price,
      );

      final result = await bridge.requestPayment(paymentRequest);

      if (result.success) {
        await TojungPremiumAccessService.addCredits(
          1,
          paymentId: result.paymentKey,
          description: '토정비결 종합분석 1회권 구매',
        );
        bridge.showToast('결제가 완료되었습니다! 토정비결 종합분석 1회권이 지급되었어요.');
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
