import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 웹에서 이미지 파일 선택
Future<Uint8List?> pickImageFromWeb() async {
  final completer = Completer<Uint8List?>();

  final input = html.FileUploadInputElement()..accept = 'image/*';
  input.click();

  input.onChange.listen((event) {
    if (input.files?.isNotEmpty == true) {
      final file = input.files!.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((event) {
        final result = reader.result;
        if (result is Uint8List) {
          completer.complete(result);
        } else if (result is List<int>) {
          completer.complete(Uint8List.fromList(result));
        } else {
          completer.complete(null);
        }
      });

      reader.onError.listen((event) {
        completer.complete(null);
      });

      reader.readAsArrayBuffer(file);
    } else {
      completer.complete(null);
    }
  });

  // 취소 시 타임아웃 (사용자가 파일 선택 취소)
  Future.delayed(const Duration(minutes: 5), () {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });

  return completer.future;
}
