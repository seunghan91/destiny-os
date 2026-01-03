import 'package:flutter/foundation.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/services/apps_in_toss/apps_in_toss_service.dart';
import '../../../../core/services/auth/auth_manager.dart';
import 'physiognomy_premium_access_service.dart';

/// 관상 프리미엄 결제 서비스 (5,000원 1회권)
class PhysiognomyPremiumPaymentService {
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
        await PhysiognomyPremiumAccessService.addCredits(
          1,
          paymentId: 'beta_free',
          description: '베타테스트 기간 무료 제공 (관상 1회권)',
        );
        bridge.showToast('베타테스트 기간 무료로 제공됩니다. 관상 종합분석 1회권이 지급되었어요.');
        return true;
      }

      final bridge = AppsInTossBridge();
      final orderId = 'physiognomy_${DateTime.now().millisecondsSinceEpoch}';

      final paymentRequest = PaymentRequest(
        orderId: orderId,
        orderName: '관상 종합분석 1회 (사주·토정·MBTI 통합)',
        amount: price,
      );

      final result = await bridge.requestPayment(paymentRequest);

      if (result.success) {
        await PhysiognomyPremiumAccessService.addCredits(
          1,
          paymentId: result.paymentKey,
          description: '관상 종합분석 1회권 구매',
        );
        bridge.showToast('결제가 완료되었습니다! 관상 종합분석 1회권이 지급되었어요.');
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
