import 'package:flutter/material.dart';

/// Destiny.OS 컬러 팔레트
/// 토스 디자인 시스템 기반 + 오방색 파스텔 톤 재해석
class AppColors {
  AppColors._();

  // ============================================
  // 기본 색상 (흑백)
  // ============================================
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // ============================================
  // 그레이 스케일
  // ============================================
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ============================================
  // 기본 컬러 (토스 스타일)
  // ============================================

  /// 프라이머리 블루
  static const Color primary = Color(0xFF3182F6);
  static const Color primaryLight = Color(0xFF4A93F7);
  static const Color primaryDark = Color(0xFF1B64DA);

  /// 세컨더리 퍼플
  static const Color secondary = Color(0xFF764ba2);
  static const Color secondaryLight = Color(0xFF9670B8);
  static const Color secondaryDark = Color(0xFF5A3A7D);

  /// 배경색
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F4F6);

  /// 텍스트 컬러
  static const Color textPrimary = Color(0xFF191F28);
  static const Color textSecondary = Color(0xFF6B7684);
  static const Color textTertiary = Color(0xFFADB5BD);
  static const Color textDisabled = Color(0xFFDDE1E6);

  /// 보더 컬러
  static const Color border = Color(0xFFE5E8EB);
  static const Color borderLight = Color(0xFFF2F4F6);

  // ============================================
  // 오방색 (파스텔 톤 재해석)
  // ============================================

  /// 목(木) - 청색 계열
  static const Color wood = Color(0xFF4ECDC4);
  static const Color woodLight = Color(0xFFE8F8F7);
  static const Color woodDark = Color(0xFF2AB7AD);

  /// 화(火) - 적색 계열
  static const Color fire = Color(0xFFFF6B6B);
  static const Color fireLight = Color(0xFFFFE8E8);
  static const Color fireDark = Color(0xFFE55555);

  /// 토(土) - 황색 계열
  static const Color earth = Color(0xFFFFE66D);
  static const Color earthLight = Color(0xFFFFF9E0);
  static const Color earthDark = Color(0xFFE6CF5C);

  /// 금(金) - 백색/금색 계열
  static const Color metal = Color(0xFFF8F9FA);
  static const Color metalAccent = Color(0xFFD4AF37);
  static const Color metalDark = Color(0xFFB8860B);

  /// 수(水) - 흑색/남색 계열
  static const Color water = Color(0xFF4A5568);
  static const Color waterLight = Color(0xFF718096);
  static const Color waterDark = Color(0xFF2D3748);

  // ============================================
  // 시맨틱 컬러
  // ============================================

  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF5252);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ============================================
  // 운세 관련 컬러
  // ============================================

  static const Color fortuneExcellent = Color(0xFFFFD700);
  static const Color fortuneGood = Color(0xFF4CAF50);
  static const Color fortuneNeutral = Color(0xFF9E9E9E);
  static const Color fortuneBad = Color(0xFFFF9800);
  static const Color fortuneTerrible = Color(0xFFF44336);

  // ============================================
  // 차트 컬러
  // ============================================

  static const List<Color> chartColors = [wood, fire, earth, metalAccent, water];
  static const Color chartGradientStart = Color(0xFFFF6B6B);
  static const Color chartGradientEnd = Color(0xFFFFE66D);

  // ============================================
  // 그라디언트
  // ============================================

  static const LinearGradient destinyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryDark],
  );

  // ============================================
  // 다크모드 컬러
  // ============================================

  /// 다크모드 배경
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceVariantDark = Color(0xFF21262D);

  /// 다크모드 텍스트
  static const Color textPrimaryDark = Color(0xFFF0F6FC);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color textTertiaryDark = Color(0xFF6E7681);
  static const Color textDisabledDark = Color(0xFF484F58);

  /// 다크모드 보더
  static const Color borderDark = Color(0xFF30363D);
  static const Color borderLightDark = Color(0xFF21262D);

  /// 다크모드 프라이머리 (살짝 밝게)
  static const Color primaryDarkMode = Color(0xFF58A6FF);
  static const Color primaryLightDarkMode = Color(0xFF79B8FF);

  /// 다크모드 오방색 (채도/밝기 조정)
  static const Color woodDarkMode = Color(0xFF56D4CC);
  static const Color fireDarkMode = Color(0xFFFF7B7B);
  static const Color earthDarkMode = Color(0xFFFFEB7D);
  static const Color metalDarkMode = Color(0xFFE6C84B);
  static const Color waterDarkMode = Color(0xFF6B7F99);

  /// 다크모드 시맨틱 컬러
  static const Color successDark = Color(0xFF3FB950);
  static const Color warningDark = Color(0xFFD29922);
  static const Color errorDark = Color(0xFFF85149);
  static const Color infoDark = Color(0xFF58A6FF);

  /// 다크모드 그라디언트
  static const LinearGradient destinyGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7F8EF5),
      Color(0xFF9665C8),
    ],
  );

  // ============================================
  // 헬퍼 메서드
  // ============================================

  static Color getElementColor(String element) {
    switch (element.toLowerCase()) {
      case '목':
      case 'wood':
        return wood;
      case '화':
      case 'fire':
        return fire;
      case '토':
      case 'earth':
        return earth;
      case '금':
      case 'metal':
        return metalAccent;
      case '수':
      case 'water':
        return water;
      default:
        return textSecondary;
    }
  }

  static Color getFortuneColor(int level) {
    switch (level) {
      case 5:
        return fortuneExcellent;
      case 4:
        return fortuneGood;
      case 3:
        return fortuneNeutral;
      case 2:
        return fortuneBad;
      case 1:
        return fortuneTerrible;
      default:
        return fortuneNeutral;
    }
  }
}
