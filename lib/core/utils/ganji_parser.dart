import '../constants/saju_constants.dart';

/// 천간/지지(干支) 문자열을 견고하게 파싱/정규화하는 유틸.
///
/// - lunar 패키지가 `乙巳`처럼 "천간+지지"를 함께 반환하거나,
/// - `...年/月/日/時` 같은 접미사가 붙거나,
/// - 공백/잡문자가 섞여도,
/// 첫 번째로 발견되는 유효한 천간/지지를 추출한다.
class GanjiParser {
  GanjiParser._();

  static final Set<String> _stemKrSet = heavenlyStemsKorean.toSet();
  static final Set<String> _stemHanjaSet = heavenlyStemsHanja.toSet();
  static final Set<String> _branchKrSet = earthlyBranchesKorean.toSet();
  static final Set<String> _branchHanjaSet = earthlyBranchesHanja.toSet();

  static String _normalize(String input) {
    // 다양한 공백(일반/전각) + zero-width 문자 제거 + 양끝 트림
    // - iOS 인앱브라우저/WKWebView 등에서 복사/입력 과정에 보이지 않는 문자가 섞이는 케이스 방어
    return input
        .trim()
        .replaceAll(RegExp(r'[\s\u3000\u200B-\u200D\u2060\uFEFF]+'), '');
  }

  static String? _firstMatchingChar(String input, bool Function(String ch) predicate) {
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      if (predicate(ch)) return ch;
    }
    return null;
  }

  /// 임의의 문자열에서 천간(한글)을 추출해 반환한다.
  ///
  /// 성공하면 '갑'~'계' 중 하나를 반환, 실패하면 null.
  static String? toKoreanHeavenlyStemOrNull(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    // 이미 한글 천간이 포함되어 있으면 그 값을 우선 사용
    final stemKr = _firstMatchingChar(normalized, (ch) => _stemKrSet.contains(ch));
    if (stemKr != null) return stemKr;

    // 한자 천간이 포함되어 있으면 인덱스 매핑
    final stemHanja = _firstMatchingChar(normalized, (ch) => _stemHanjaSet.contains(ch));
    if (stemHanja != null) {
      final idx = heavenlyStemsHanja.indexOf(stemHanja);
      if (idx >= 0) return heavenlyStemsKorean[idx];
    }

    return null;
  }

  /// 임의의 문자열에서 지지(한글)을 추출해 반환한다.
  ///
  /// 성공하면 '자'~'해' 중 하나를 반환, 실패하면 null.
  static String? toKoreanEarthlyBranchOrNull(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return null;

    final branchKr = _firstMatchingChar(normalized, (ch) => _branchKrSet.contains(ch));
    if (branchKr != null) return branchKr;

    final branchHanja = _firstMatchingChar(normalized, (ch) => _branchHanjaSet.contains(ch));
    if (branchHanja != null) {
      final idx = earthlyBranchesHanja.indexOf(branchHanja);
      if (idx >= 0) return earthlyBranchesKorean[idx];
    }

    return null;
  }
}

