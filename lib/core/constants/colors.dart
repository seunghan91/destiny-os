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

  /// 현재 테마가 다크모드인지 여부
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// 다크모드 대응 배경색
  static Color backgroundOf(BuildContext context) {
    return isDarkMode(context) ? backgroundDark : background;
  }

  /// 다크모드 대응 surface 색
  static Color surfaceOf(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surface;
  }

  /// 다크모드 대응 surfaceVariant 색
  static Color surfaceVariantOf(BuildContext context) {
    return isDarkMode(context) ? surfaceVariantDark : surfaceVariant;
  }

  /// 다크모드 대응 텍스트 primary 색
  static Color textPrimaryOf(BuildContext context) {
    return isDarkMode(context) ? textPrimaryDark : textPrimary;
  }

  /// 다크모드 대응 텍스트 secondary 색
  static Color textSecondaryOf(BuildContext context) {
    return isDarkMode(context) ? textSecondaryDark : textSecondary;
  }

  /// 다크모드 대응 텍스트 tertiary 색
  static Color textTertiaryOf(BuildContext context) {
    return isDarkMode(context) ? textTertiaryDark : textTertiary;
  }

  /// 다크모드 대응 보더 색
  static Color borderOf(BuildContext context) {
    return isDarkMode(context) ? borderDark : border;
  }

  /// 다크모드 대응 라이트 보더(구분선) 색
  static Color borderLightOf(BuildContext context) {
    return isDarkMode(context) ? borderLightDark : borderLight;
  }

  /// 다크모드 대응 그림자/음영 색 (라이트: 검정, 다크: 흰색 기반)
  ///
  /// 화면에 `Colors.black.withOpacity(...)` 같은 하드코딩이 남아있으면
  /// 다크모드에서 "먼지/회색 막"처럼 보일 수 있어, 상황별로 이 헬퍼를 사용합니다.
  static Color shadowOf(
    BuildContext context, {
    double lightOpacity = 0.05,
    double darkOpacity = 0.12,
  }) {
    final base = isDarkMode(context) ? white : black;
    final opacity = isDarkMode(context) ? darkOpacity : lightOpacity;
    return base.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

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

  // ============================================
  // 추가 다크모드 헬퍼 (WCAG 4.5:1 대비 준수)
  // ============================================

  /// 다크모드 대응 primary 색상 (채도 조정)
  static Color primaryOf(BuildContext context) {
    return isDarkMode(context) ? primaryDarkMode : primary;
  }

  /// 다크모드 대응 error 색상
  static Color errorOf(BuildContext context) {
    return isDarkMode(context) ? errorDark : error;
  }

  /// 다크모드 대응 success 색상
  static Color successOf(BuildContext context) {
    return isDarkMode(context) ? successDark : success;
  }

  /// 다크모드 대응 warning 색상
  static Color warningOf(BuildContext context) {
    return isDarkMode(context) ? warningDark : warning;
  }

  /// 다크모드 대응 info 색상
  static Color infoOf(BuildContext context) {
    return isDarkMode(context) ? infoDark : info;
  }

  /// 다크모드 대응 오방색 - 목(木)
  static Color woodOf(BuildContext context) {
    return isDarkMode(context) ? woodDarkMode : wood;
  }

  /// 다크모드 대응 오방색 - 화(火)
  static Color fireOf(BuildContext context) {
    return isDarkMode(context) ? fireDarkMode : fire;
  }

  /// 다크모드 대응 오방색 - 토(土)
  static Color earthOf(BuildContext context) {
    return isDarkMode(context) ? earthDarkMode : earth;
  }

  /// 다크모드 대응 오방색 - 금(金)
  static Color metalOf(BuildContext context) {
    return isDarkMode(context) ? metalDarkMode : metalAccent;
  }

  /// 다크모드 대응 오방색 - 수(水)
  static Color waterOf(BuildContext context) {
    return isDarkMode(context) ? waterDarkMode : water;
  }

  /// 다크모드 대응 그라디언트
  static LinearGradient destinyGradientOf(BuildContext context) {
    return isDarkMode(context) ? destinyGradientDark : destinyGradient;
  }

  /// 다크모드 대응 grey 색상 (중간 톤)
  static Color grey300Of(BuildContext context) {
    return isDarkMode(context) ? borderDark : grey300;
  }

  /// 다크모드 대응 grey 색상 (밝은 톤)
  static Color grey200Of(BuildContext context) {
    return isDarkMode(context) ? surfaceVariantDark : grey200;
  }

  /// 다크모드 대응 grey 색상 (진한 톤)
  static Color grey400Of(BuildContext context) {
    return isDarkMode(context) ? textTertiaryDark : grey400;
  }

  /// 다크모드 대응 textDisabled 색상
  static Color textDisabledOf(BuildContext context) {
    return isDarkMode(context) ? textDisabledDark : textDisabled;
  }

  /// 다크모드 대응 fortuneGood 색상
  static Color fortuneGoodOf(BuildContext context) {
    return isDarkMode(context) ? successDark : fortuneGood;
  }

  /// 다크모드 대응 fortuneBad 색상
  static Color fortuneBadOf(BuildContext context) {
    return isDarkMode(context) ? warningDark : fortuneBad;
  }

  /// 오행 색상 다크모드 대응
  static Color getElementColorOf(BuildContext context, String element) {
    switch (element.toLowerCase()) {
      case '목':
      case 'wood':
        return woodOf(context);
      case '화':
      case 'fire':
        return fireOf(context);
      case '토':
      case 'earth':
        return earthOf(context);
      case '금':
      case 'metal':
        return metalOf(context);
      case '수':
      case 'water':
        return waterOf(context);
      default:
        return textSecondaryOf(context);
    }
  }
}
