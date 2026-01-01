import 'package:flutter_test/flutter_test.dart';
import 'package:destiny_os/core/utils/ganji_parser.dart';

void main() {
  group('GanjiParser', () {
    group('toKoreanHeavenlyStemOrNull', () {
      test('결합 문자열(乙巳)에서 천간을 추출한다', () {
        expect(GanjiParser.toKoreanHeavenlyStemOrNull('乙巳'), '을');
      });

      test('접미사/공백이 있어도 천간을 추출한다', () {
        expect(GanjiParser.toKoreanHeavenlyStemOrNull(' 乙巳年 '), '을');
      });

      test('한글 결합 문자열(을사)에서도 천간을 추출한다', () {
        expect(GanjiParser.toKoreanHeavenlyStemOrNull('을사'), '을');
      });
    });

    group('toKoreanEarthlyBranchOrNull', () {
      test('결합 문자열(乙巳)에서 지지를 추출한다', () {
        expect(GanjiParser.toKoreanEarthlyBranchOrNull('乙巳'), '사');
      });

      test('접미사/공백이 있어도 지지를 추출한다', () {
        expect(GanjiParser.toKoreanEarthlyBranchOrNull(' 乙巳年 '), '사');
      });

      test('한글 결합 문자열(을사)에서도 지지를 추출한다', () {
        expect(GanjiParser.toKoreanEarthlyBranchOrNull('을사'), '사');
      });
    });
  });
}

